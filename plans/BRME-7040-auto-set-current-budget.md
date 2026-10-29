# BRME-7040 — Plan: Auto-set Current Budget + Require Type of Work when Budget → Pending Approval

## Summary

When a Budget Version's **Status** changes to **Pending Approval**, automatically populate **Initiative.Current Budget** with that Budget Version; when its Status changes from Pending Approval, clear Current Budget. Add a **validation rule** requiring **Type of Work** on the Budget before it can enter Pending Approval. Implemented in the existing Apex trigger framework on `IM_Budget__c` (see Decision #1) — fully bulkified, works for Budgeted Initiative **and** Amendment records (both are `IM_Initiative__c`).

## Key Findings (from workspace)

- **Trigger entry point exists.** [IMBudgetTrigger.trigger](force-app/main/default/triggers/IMBudgetTrigger.trigger) (before insert, after insert, before update, after update, before delete) → `TriggerFactory` → [IMBudgetTriggerHandler.cls](force-app/main/default/classes/IMBudgetTriggerHandler.cls). The handler **already reacts to the exact same transition**: `beforeUpdate` collects `pendingApprovalIds` on `isFieldChanged(Assets.STATUS) && Status = Pending Approval` → `validateOverUnderAllocation()` + `validatePendingApprovalBudgets()` ("only one budget can be in pending approval status for an initiative"); `afterUpdate` collects `pendingApprovalBudgets` → `andFinally` sends the `IM_INITIATIVE_PENDING_APPROVAL` email. Our logic extends these existing branches.
- **"Type of Work" is the existing checkbox** [Type_of_Work__c.field-meta.xml](force-app/main/default/objects/IM_Budget__c/fields/Type_of_Work__c.field-meta.xml) — label *Type of Work*, description "Box to be checked to include Type of Work in Initiative Budget template". A checkbox can't be null, so ticket "Type Of Work = BLANK" = **unchecked (`FALSE`)**. Precedent: [Partner_Partner_Role_Or_Type_of_work_req](force-app/main/default/objects/IM_Budget__c/validationRules/Partner_Partner_Role_Or_Type_of_work_req.validationRule-meta.xml) already tests `Type_of_Work__c == FALSE`. The ticket's error wording ("must be added in budget template") matches this checkbox's purpose.
- **`Current_Budget__c` lookup filter is the controlling constraint.** [Current_Budget__c.field-meta.xml](force-app/main/default/objects/IM_Initiative__c/fields/Current_Budget__c.field-meta.xml): budget must belong to the **same initiative** AND `IM_Budget__c.Status__c` ∈ {Pending Approval, Approved}, `isOptional=false`. → The Initiative update must run in **AFTER** context (status already committed in the transaction) or the filter throws `FIELD_FILTER_VALIDATION_EXCEPTION`. Clearing to blank always passes.
- **Existing automation when Current Budget is populated** (the ticket's "check existing automation" item — to discuss with Neha):
  1. [IMBudgetedInitiativeHandler.cls](force-app/main/default/classes/IMBudgetedInitiativeHandler.cls) `afterInsert`/`afterUpdate` detects `Current_Budget__c` change → `andFinally` calls [IMBudgetHelper.updateActiveStatus](force-app/main/default/classes/IMBudgetHelper.cls) → old budget `Is_Active__c=false` + `Disable_Budget_Options__c` cleared; new budget `Is_Active__c=true` + disable-options computed; Budget Grants activated/deactivated in step.
  2. Side chain: `Is_Active__c` false→true re-fires `IMBudgetTrigger` → `bulkBefore.setBudgetVersion()` sets `Version__c = Initiative.Amendment_Number__c + 1`. This is the same chain a **manual** Current Budget selection fires today — the automation inherits existing behavior, no new side effects.
  3. [IMInitiativeTriggerHandlerHelper.updateCurrentBudgetStatus](force-app/main/default/classes/IMInitiativeTriggerHandlerHelper.cls#L286): when `Initiative.Approved__c` false→true, the Current Budget's `Status__c` → **Approved** (so the new automation feeds the existing approval chain).
  4. Clone path: [IMService.cls](force-app/main/default/classes/IMService.cls#L41) sets `Current_Budget__c = clonedBudgetRec.Id` on clone.
  5. **No Flow/Process Builder** touches `Current_Budget__c` or budget Status (flows/ grep is empty) — today the field is populated manually via the lookup or by clone. No conflicting automation to retire.
- **`updateActiveStatus` wraps failures in `AuraHandledException`** (repo lesson) — anonymous Apex data loads touching `Current_Budget__c` need `TriggerFactory.setBypass('IMBudgetedInitiativeHandler')`. Applies to verification scripts, not the trigger itself.
- **Conventions:** status constants in [Assets.cls](force-app/main/default/classes/Assets.cls) (`STATUS`, `PENDING_APPROVAL`, `DRAFT`, `APPROVED`); per-record collection in `afterUpdate`, DML in `andFinally`; DML via `BBApps_Crud`; validation-rule bypass via `$Setup.Bypass_Automation_Setting__c.IM_Budget_Validation__c`; validation-rule `fullName` ≤ 40 chars.
- **No recursion guard in `TriggerHandler`** — safe because the re-fired budget update only changes `Is_Active__c`, not `Status__c`, so the `isFieldChanged(Status__c)` collections don't re-trigger.
- **One Pending Approval budget per initiative is already enforced** (`validatePendingApprovalBudgets`), so "set Current Budget" can never race a second pending budget on the same initiative.

## Changes

### 1. `IMBudgetTriggerHandler.cls` (edit)

**a) New instance collections:**

```java
public Map<Id, Id> budgetToSetAsCurrentMap = new Map<Id, Id>();      // budget Id → initiative Id (entering Pending Approval)
public Map<Id, Id> budgetToClearAsCurrentMap = new Map<Id, Id>();    // budget Id → initiative Id (Status changed from Pending Approval)
```

**b) `afterUpdate`** — extend the existing `isFieldChanged(newBudget, Assets.STATUS)` branch:

- `Assets.PENDING_APPROVAL.equalsIgnoreCase(newBudget.Status__c)` → also `budgetToSetAsCurrentMap.put(newBudget.Id, newBudget.Initiative__c)` (new `else if` for the leave case below).
- `isFieldChanged(newBudget, Assets.STATUS)` **AND** `Assets.PENDING_APPROVAL.equalsIgnoreCase(oldBudget.Status__c)` → `budgetToClearAsCurrentMap.put(newBudget.Id, newBudget.Initiative__c)`. The destination status is intentionally unrestricted.

**c) New private method `syncCurrentBudgetOnInitiatives()`**, called from `andFinally` in the `Trigger.isAfter && Trigger.isUpdate` block (single bulkified DML):

- **Clear:** query `[SELECT Id, Current_Budget__c FROM IM_Initiative__c WHERE Id IN :budgetToClearAsCurrentMap.values() AND Current_Budget__c IN :budgetToClearAsCurrentMap.keySet() WITH SYSTEM_MODE]`; for each row where `Current_Budget__c` maps back to that initiative's budget, add `new IM_Initiative__c(Id = …, Current_Budget__c = null)`. **Only clear when the initiative still points at this budget** — never wipe a manually re-pointed value.
- **Set:** for each entry in `budgetToSetAsCurrentMap`, add `new IM_Initiative__c(Id = initiativeId, Current_Budget__c = budgetId)`.
- One `BBApps_Crud.doUpdate(initiativesToUpdate)` (single-arg = allOrNothing **true**) so a lookup-filter/DML failure surfaces to the user instead of being swallowed (repo lesson #2 — avoid the `allOrNothing=false` + uninspected-results pattern here).

### 2. New validation rule (1 new file)

`force-app/main/default/objects/IM_Budget__c/validationRules/Type_of_Work_Req_Pending_Approval.validationRule-meta.xml` (33 chars, under the 40-char limit):

- **errorConditionFormula:**
  ```
  !$Setup.Bypass_Automation_Setting__c.IM_Budget_Validation__c
  && ISPICKVAL(Status__c, 'Pending Approval')
  && Type_of_Work__c = FALSE
  ```
- **errorMessage:** `Type of Work must be added in budget template to proceed further.`
- **errorDisplayField:** `Type_of_Work__c`; **active:** true; description `BRME-7040: ...`.

### 3. Apex tests — `IMBudgetTriggerHandlerTest.cls` (edit, follows existing conventions: `TestDataFactory.createInitiativeBaseData()` + `createBudgetedInitiative`, `insert/update as system`, `Assert.*`)

| Test | Assert |
|---|---|
| `testSetCurrentBudgetOnPendingApproval` | budget (with `Type_of_Work__c=true`) → Pending Approval ⇒ `Initiative.Current_Budget__c = budget.Id`; `Is_Active__c=true` via existing chain |
| `testClearCurrentBudgetOnReturnToDraft` | Pending Approval → Draft ⇒ `Current_Budget__c = null` |
| `testClearDoesNotWipeRepointedBudget` | initiative re-pointed to another (Pending Approval/Approved) budget; first budget → Draft ⇒ Current Budget unchanged |
| `testBulkSetCurrentBudget` | 2 initiatives × 1 budget each → Pending Approval in one `update` ⇒ both currents set (bulk) |
| `testTypeOfWorkRequiredForPendingApproval` | `Type_of_Work__c=false` → Pending Approval ⇒ `DmlException` containing the ticket message; with `true` ⇒ saves |

### 4. Manifest

**No change** — [manifest/package.xml](manifest/package.xml) uses `<members>*</members>` for `ApexClass`, `ApexTrigger`, and `ValidationRule`; the new rule is picked up automatically.

## Decisions (confirmed with user)

1. **Apex trigger, not Flow** — the Description mentions "Automation (Flow)" but the Technical Details specify "Budget Trigger", and `IM_Budget__c` already has a full Apex handler reacting to this exact transition (validation + email). Extending [IMBudgetTriggerHandler.cls](force-app/main/default/classes/IMBudgetTriggerHandler.cls) keeps one automation path; no record-triggered flow is added.
2. **DML in AFTER context (`andFinally`)** — the `Current_Budget__c` lookup filter requires the budget's saved Status ∈ {Pending Approval, Approved}; a before-trigger update would fail the filter.
3. **Clear is conditional** — only blank Current Budget if it still points at the budget leaving Pending Approval (never wipe a manual re-point).
4. **Validation rule (not trigger `addError`)** for Type of Work, per ticket; includes the standard `IM_Budget_Validation__c` bypass; error displayed on the Type of Work field.
5. **"Type of Work" = existing `Type_of_Work__c` checkbox**; "BLANK" = unchecked (confirmed).
6. **Any status change from Pending Approval clears** — no destination-status check; covers Draft, Declined, blank, Approved, and future statuses.
7. **Insert also auto-sets** — a budget inserted directly as `Pending Approval` sets Current Budget (Update + Insert scope); the validation rule has NO `NOT(ISNEW())` guard so it blocks such inserts when Type of Work is unchecked.
8. **"Initiatives and Amendments"** = Budgeted Initiative + Amendment **record types** on `IM_Initiative__c` — same object/trigger covers both.
9. **Existing automation chain inherited** — `updateActiveStatus` / `setBudgetVersion` fire exactly as with a manual Current Budget selection (confirmed with user; this was the ticket's "check existing automation / discuss with Neha" item).
10. **No backfill** — new system; only transitions going forward. No downstream-system heads-up needed.

## Verification

1. Deploy to dev2Current (`--test-level RunSpecifiedTests --tests IMBudgetTriggerHandlerTest`); verify via `DeployRequest` Tooling API query — CLI exit code / "locale en_US" error are not authoritative (repo lessons #4/#5).
2. UI on test initiative `a0qbc00000HmnW5AAJ`: set budget to Pending Approval → Current Budget populates (and the BRME-7042 Approval Overview tab Details reflect it); set back to Draft → cleared.
3. Validation: budget with Type of Work unchecked → Pending Approval ⇒ error on the Type of Work field with the exact ticket message.
4. Amendment record: repeat set/clear on an Amendment's budget.
5. Bulk: anonymous Apex updating budgets across 2 different initiatives in one statement ⇒ both initiatives updated (use `TriggerFactory.setBypass('IMBudgetedInitiativeHandler')` only if the script itself writes `Current_Budget__c` — repo lesson).
6. Regression: pending-approval email still sent; "only one budget in pending approval per initiative" still blocks; `Is_Active__c`/`Version__c` chain unchanged.

## Out of scope / notes

- No Flow; no changes to the `Current_Budget__c` lookup filter, `IMBudgetHelper.updateActiveStatus`, or `updateCurrentBudgetStatus`.
- A transition from Pending Approval to any other status clears Current Budget, per the handler review feedback.
- `Version__c` auto-increment and the pending-approval email are untouched.

## Implementation Log (deployed to dev2Current 2026-10-13 — Deploy ID `0Afbc00000D6bjlCAB`, Succeeded, 15/15 tests, 0 errors)

| Component | Files | Notes |
|---|---|---|
| Trigger handler | [IMBudgetTriggerHandler.cls](force-app/main/default/classes/IMBudgetTriggerHandler.cls) | `budgetToSetAsCurrentMap` collected in `afterInsert` (insert-as-Pending-Approval) and `afterUpdate` (status → Pending Approval); `budgetToClearAsCurrentMap` in `afterUpdate` whenever status changes from Pending Approval; `syncCurrentBudgetOnInitiatives()` called from `andFinally` for after-insert **and** after-update — one bulkified `BBApps_Crud.doUpdate` (allOrNothing=true); clear only when the initiative still points at that budget |
| Validation rule | [Type_of_Work_Req_Pending_Approval.validationRule-meta.xml](force-app/main/default/objects/IM_Budget__c/validationRules/Type_of_Work_Req_Pending_Approval.validationRule-meta.xml) | Fires on insert AND update (no `NOT(ISNEW())` guard, per Decision #7); error displayed on the Type of Work field; standard `IM_Budget_Validation__c` bypass; exact ticket error message |
| Tests | [IMBudgetTriggerHandlerTest.cls](force-app/main/default/classes/IMBudgetTriggerHandlerTest.cls) | 7 new tests: set on Pending Approval (incl. `Is_Active__c` chain), clear on Draft, clear on Declined, no-wipe when repointed, bulk across 2 initiatives, Type of Work validation (fail + happy path), set on insert-as-Pending-Approval |

### Gotchas hit during deploy

1. **`Budget_Amount__c` is a formula** (`Total_BP_Amount__c + …`, not writeable). Tests must create a budget row (`TestDataFactory.createBudgetRow`, sets `Period_*_Amount__c`) so the formula is > 0 and the `Budget_Amount_Should_be_Non_Zero` rule passes when moving to Pending Approval — not set `Budget_Amount__c` directly.
2. **Insert-as-Pending-Approval surfaces the known `updateActiveStatus` `AuraHandledException`** (repo lesson). The auto-set fires `IMBudgetedInitiativeHandler` → `IMBudgetHelper.updateActiveStatus` → `AuraHandledException` in trigger/test context. Existing `testPendingApprovalBudgets` was also caught (its `@TestSetup` inserted two Pending-Approval budgets that previously didn't auto-set). Fixed per the documented workaround: `TriggerFactory.setBypass('IMBudgetedInitiativeHandler')` around the insert, `removeBypass` after. Note the method is `removeBypass` (not `clearBypass`).
