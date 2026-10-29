# BRME-7039 — Plan: Approval Overview Checklist Fields on Initiative

## Summary

Add the Approval Checklist fields to `IM_Initiative__c`: four manual Yes/No picklists (three with paired Notes Long Text Areas), two auto-check Formula (Text) fields (Term Alignment, Required Approval Docs), an Approval Notes field, a Revisions Reason field, and a Revisions Needed checkbox. Enforce the Notes-required-on-"No" rule with validation rules, surface everything in an **Approval Checklist** section on the Approval Overview tab of the Initiative record page with dynamic-form visibility, and wire FLS into two **new** Approval Overview Tab permission sets.

## Key Findings (from workspace)

- **4 of the ticket's fields already exist** (built under BRME-7038): `Final_Memo_Link__c`, `Budget_Narrative_Link__c`, `Approval_Doc_Link__c` (label *Approval Email Link*), and `View_Required_Docs__c` (the combined hyperlink formula = ticket's *Final Documents Links*). **No creation needed** — only FLS if not already granted.
- **Term API name discrepancy:** the ticket formula references `Term_months__c`, but the actual Initiative term-months field is `Term__c` (Number formula: `CEILING((End_Date__c - Start_Date__c) / 30.5)`, blank when either date is blank). The Budget side, `IM_Budget__c.Budget_Term_months__c`, exists as named.
- An existing validation rule [Budget_term_must_match_Initiative_term](force-app/main/default/objects/IM_Initiative__c/validationRules/Budget_term_must_match_Initiative_term.validationRule-meta.xml) already compares `Term__c` to `Current_Budget__r.Budget_Term_months__c`, but it is **`<active>false</active>`** — so the Term Alignment formula is still meaningful. Reuse the same comparison expression.
- `Approved_Date__c` (label *Approval Date*) and `Approver__c` already exist for the Edit permission-set grant.
- **"Revisions Needed" does not exist** on `IM_Initiative__c` (grep confirms). The Read permission-set requirement referencing it cannot be fulfilled as written — likely means `Revisions_Reason__c` or a field from a sibling ticket.
- Existing permission sets are `IM: Approval Tab Edit Access` / `IM: Approval Tab Read Access` ([IM_Approval_Tab_Edit_Access](force-app/main/default/permissionsets/IM_Approval_Tab_Edit_Access.permissionset-meta.xml), [IM_Approval_Tab_Read_Access](force-app/main/default/permissionsets/IM_Approval_Tab_Read_Access.permissionset-meta.xml)); the ticket's "IM: Approval Overview Tab Edit/Read Access" names don't exist (same discrepancy as BRME-7038 decision #3).
- Field files live in [objects/IM_Initiative__c/fields](force-app/main/default/objects/IM_Initiative__c/fields); validation rules in [objects/IM_Initiative__c/validationRules](force-app/main/default/objects/IM_Initiative__c/validationRules); record page is [IM_Budgeted_Initiative_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml) (shared by Budgeted Initiative and Amendment record types).

## Changes

### 1. New fields (12 files in `force-app/main/default/objects/IM_Initiative__c/fields/`)

| File | Label | API | Type |
|---|---|---|---|
| Term_Alignment__c.field-meta.xml | Term Alignment | `Term_Alignment__c` | Text (formula) |
| Required_Approval_Docs__c.field-meta.xml | Required Approval Docs | `Required_Approval_Docs__c` | Text (formula) |
| Strategic_Locations_Aligned__c.field-meta.xml | Strategic Locations Aligned | `Strategic_Locations_Aligned__c` | Picklist (Yes/No) |
| Strategic_Locations_Aligned_Notes__c.field-meta.xml | Strategic Locations Aligned Notes | `Strategic_Locations_Aligned_Notes__c` | LongTextArea |
| Budget_Aligns_with_Memo__c.field-meta.xml | Budget Aligns with Memo | `Budget_Aligns_with_Memo__c` | Picklist (Yes/No) |
| Budget_Aligns_with_Memo_Notes__c.field-meta.xml | Budget Aligns with Memo Notes | `Budget_Aligns_with_Memo_Notes__c` | LongTextArea |
| Type_of_Work_Aligns_Memo__c.field-meta.xml | Type of Work Aligns Memo | `Type_of_Work_Aligns_Memo__c` | Picklist (Yes/No) |
| Type_of_Work_Aligns_Memo_Notes__c.field-meta.xml | Type of Work Aligns Memo Notes | `Type_of_Work_Aligns_Memo_Notes__c` | LongTextArea |
| Initiative_Name_and_Budget_Name_Review__c.field-meta.xml | Initiative Name and Budget Name Review | `Initiative_Name_and_Budget_Name_Review__c` | Picklist (Yes/No) |
| Approval_Notes__c.field-meta.xml | Approval Notes | `Approval_Notes__c` | LongTextArea (32768) |
| Revisions_Reason__c.field-meta.xml | Revisions Reason | `Revisions_Reason__c` | TextArea |

> Note: TextArea has a fixed 255-char limit — no `length` element allowed (deploy error otherwise). The `Revisions_Needed__c` checkbox from the original plan was dropped (see Decisions #3).

Picklists: values `Yes` / `No`, **no default value**, restricted. Long Text Area fields use length **32768** — the repo convention for IM notes fields ([Next_Touchpoint_Notes__c](force-app/main/default/objects/IM_Initiative__c/fields/Next_Touchpoint_Notes__c.field-meta.xml), [Program_Overview_Alert__c](force-app/main/default/objects/IM_Initiative__c/fields/Program_Overview_Alert__c.field-meta.xml)). Each field gets a `BRME-7039: ...` description per the existing `IM-433:` / `BRME-7038:` convention.

**Term Alignment formula** (blank-safe per acceptance criteria — returns "No" when dates or Current Budget are missing):

```
IF(OR(ISBLANK(Term__c), ISBLANK(Current_Budget__c)),
   "No",
   IF(Term__c = Current_Budget__r.Budget_Term_months__c, "Yes", "No"))
```

Note: cross-object reference to a null lookup returns blank (no error), so the `ISBLANK(Current_Budget__c)` guard covers the "missing Current Budget" case.

**Required Approval Docs formula:**

```
IF(AND(NOT(ISBLANK(Final_Memo_Link__c)),
       NOT(ISBLANK(Budget_Narrative_Link__c)),
       NOT(ISBLANK(Approval_Doc_Link__c))),
   "Yes", "No")
```

### 2. New validation rules (3 files in `objects/IM_Initiative__c/validationRules/`)

| File | Condition |
|---|---|
| Strategic_Locations_Aligned_Notes_Required.validationRule-meta.xml | `TEXT(Strategic_Locations_Aligned__c) = "No" && ISBLANK(Strategic_Locations_Aligned_Notes__c)` |
| Budget_Aligns_with_Memo_Notes_Required.validationRule-meta.xml | `TEXT(Budget_Aligns_with_Memo__c) = "No" && ISBLANK(Budget_Aligns_with_Memo_Notes__c)` |
| Type_of_Work_Aligns_Memo_Notes_Required.validationRule-meta.xml | `TEXT(Type_of_Work_Aligns_Memo__c) = "No" && ISBLANK(Type_of_Work_Aligns_Memo_Notes__c)` |

Follow the existing rule pattern: bypass guard `!$Setup.Bypass_Automation_Setting__c.IM_Initiative_Validation__c &&`, error displayed on the Notes field. Naming-review picklist has no paired Notes (confirm — see Open Decisions).

### 3. Flexipage — Approval Checklist section

In [IM_Budgeted_Initiative_Page.flexipage-meta.xml](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml), add a `flexipage:fieldSection` (label `Approval Checklist`) to the **Approval Overview** tab:

- **Always-visible fields:** the 4 Yes/No picklists, Term Alignment, Required Approval Docs (both `uiBehavior` readonly), Approval Notes, plus the existing `View_Required_Docs__c` link summary if desired.
- **Dynamic visibility:** each `..._Notes__c` field item gets a `visibilityRule` filter so it only renders when its paired picklist equals `No` (`{field: Strategic_Locations_Aligned__c, operator: EQUAL, value: "No"}` etc.).
- Revisions Reason placement: per ticket it is Grants-read/PM-related — include in the section but confirm whether it belongs on the Approval Overview tab or the revisions flow.

### 4. Permission sets (FLS) — two NEW sets

The ticket explicitly names new sets, so **create** (unlike BRME-7038, which reused the Approval Tab sets):

- **`IM: Approval Overview Tab Edit Access`** (`IM_Approval_Overview_Tab_Edit_Access.permissionset-meta.xml`): editable FLS on all 9 new non-formula fields (4 picklists, 4 Notes LTAs, Revisions Reason) + `Approved_Date__c` + `Approver__c`; read-only FLS on the 2 formula fields + `Revisions_Needed__c`; **no edit** on `Revisions_Needed__c` (ticket: read-only).
- **`IM: Approval Overview Tab Read Access`** (`IM_Approval_Overview_Tab_Read_Access.permissionset-meta.xml`): readable FLS on all 12 new fields (incl. `Revisions_Needed__c`) + the 3 BRME-7038 URL fields + `View_Required_Docs__c`.

`Revisions_Needed__c` is a **new checkbox** per ticket's Read-set reference (confirmed: create it).

### 5. Apex test class (formula coverage)

New test class (e.g. `IM_InitiativeApprovalChecklistTest`) covering acceptance criteria:

- Term Alignment: aligned (Start/End ≈ Budget term → "Yes"), misaligned ("No"), blank dates ("No"), no Current Budget ("No").
- Required Approval Docs: all 3 links ("Yes"), 1–2 links ("No"), none ("No").
- Validation rules: save with picklist = "No" + blank Notes → expect DML exception; with Notes → succeeds.

### 6. Manifest

Add the 12 `CustomField` + 3 `ValidationRule` + 2 `PermissionSet` entries (and confirm `FlexiPage` coverage) in [manifest/package.xml](manifest/package.xml).

## Decisions (confirmed with user)

1. **Notes character limit** — 32,768 chars, matching the repo convention for IM notes fields.
2. **Permission set naming** — **create new** `IM: Approval Overview Tab Edit/Read Access` sets as the ticket literally requests.
3. **"Revisions Needed" field** — revised by user during implementation: "Revisions Needed" **is** `Revisions_Reason__c` (same field, renamed). No separate checkbox created.
4. **Revisions Reason FLS** — **read-only** in the Edit set; edit access is controlled by a different (revisions-flow) permission. Matches the ticket's "All Above Fields Except Revisions Reason" wording.
5. **Naming-review Notes** — confirmed: **no** paired Notes field for Initiative Name and Budget Name Review; Approval Notes is the catch-all.
6. **Term Alignment blank fallback** — returns **"No"** for blank dates/no Current Budget.
7. **Deploy + test data** — deploy to dev2Current and create test records covering all scenarios (aligned/misaligned term, blank dates, no budget, partial/all links, validation rule fires).

## Open Questions (for BA, non-blocking)

- **Type of Work source field (C3 vs C4)** — this plan only creates the manual Yes/No check; no automation depends on the answer.

## Verification

1. Deploy to dev2Current; verify via `DeployRequest` query (per repo lesson #4 — don't trust CLI exit code).
2. Apex tests pass (6 formula scenarios + 2 validation-rule scenarios).
3. Create test data on dev2Current covering all scenarios: aligned/misaligned term, blank Start/End Date, no Current Budget, partial links, all links, picklist="No" with blank Notes (validation fires) and with Notes (saves).
4. Manual UI: Approval Overview tab → Approval Checklist section; toggle each picklist to "No" → Notes appears; change dates/budget → Term Alignment recalculates.
5. FLS spot-check: Edit-set user can edit picklists/Notes; Read-set user sees everything read-only; neither-set user sees nothing.

## Out of scope / notes

- No changes to the existing BRME-7038 URL fields or `View_Required_Docs__c` formula.
- The inactive `Budget_term_must_match_Initiative_term` validation rule stays as-is; reactivating it would make Term Alignment always "Yes" and is a separate business decision.

## Implementation Log (completed 2026-10-08)

### Deployed to dev2Current

| Component | Files | Deploy IDs |
|---|---|---|
| 11 fields | [objects/IM_Initiative__c/fields](force-app/main/default/objects/IM_Initiative__c/fields) (Term_Alignment, Required_Approval_Docs, 4 picklists, 3 paired Notes, Approval_Notes, Revisions_Reason) | `0Afbc00000D3CGVCA3` |
| 3 validation rules | [validationRules](force-app/main/default/objects/IM_Initiative__c/validationRules) — note: `Strategic_Locations_Notes_Required` (fullName shortened; 40-char limit) | same |
| 2 permission sets | [IM_Approval_Overview_Tab_Edit_Access](force-app/main/default/permissionsets/IM_Approval_Overview_Tab_Edit_Access.permissionset-meta.xml), [IM_Approval_Overview_Tab_Read_Access](force-app/main/default/permissionsets/IM_Approval_Overview_Tab_Read_Access.permissionset-meta.xml) | `0Afbc00000D30P3CAJ` |
| Flexipage | [IM_Budgeted_Initiative_Page](force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml) — "Approval Checklist" section in Approvals tab, Notes fields with `= "No"` visibility rules | same |
| Test class | [IMInitiativeApprovalChecklistTest.cls](force-app/main/default/classes/IMInitiativeApprovalChecklistTest.cls) | `0Afbc00000D3FsgCAF` |

### Test results

- **12/12 tests pass (100%)** — test run on dev2Current covering: term aligned/misaligned/blank-dates/no-budget, all/partial/no doc links, all 3 Notes-required validation rules, "No"+Notes saves, all-"Yes" saves.

### Test data created (dev2Current)

| Record | Scenario | Result |
|---|---|---|
| Test - 08/14/2026 1.0 (`a0qbc00000HmnW5AAJ`) | Aligned term (24=24), checklist: Strategic Locations = No + Notes | Term Alignment **Yes** ✅ |
| Test - 08/14/2026 2.0 (`a0qbc00000I0wsrAAB`) | Misaligned term (24 vs 36), all 3 doc links | Term Alignment **No**, Required Approval Docs **Yes** ✅ |
| Test - 08/14/2026 3.0 (`a0qbc00000I5Kq9AAF`) | No Current Budget, partial links, checklist untouched | Both formulas **No** ✅ |

Script: [scripts/brme7039-test-data.apex](scripts/brme7039-test-data.apex). Both new permission sets assigned to hkalathiya@bloomberg.org.dev2.

### Gotchas hit during implementation

1. **TextArea `length`** — `Revisions_Reason__c` (TextArea) must NOT include `<length>`; fixed 255. Deploy error: "Can not specify 'length' for a CustomField of type TextArea".
2. **Validation rule name limit** — `fullName` max 40 chars: `Strategic_Locations_Aligned_Notes_Required` → renamed `Strategic_Locations_Notes_Required`.
3. **Failing test run rolls back the entire deploy** (repo lesson #5) — deploy metadata with `--test-level NoTestRun`, then run tests separately.
4. **CLI "locale en_US" error is cosmetic** (repo lesson #4) — verify with `DeployRequest` Tooling API query.
5. **New fields invisible to SOQL until FLS granted** — "No such column" errors after deploy were FLS, not missing metadata; assign the new permission sets first. `sf org assign permset` needs one `--name` per invocation (comma-separated list fails).
6. **`Current_Budget__c` lookup filter** requires budget Status = Pending Approval/Approved and matching Initiative — Draft budgets fail with `FIELD_FILTER_VALIDATION_EXCEPTION`.
7. **"Pending Approval" budget with zero amount** fails validation ("Budget amount is zero") — tests must create a `IM_Budget_Row__c` via `TestDataFactory.createBudgetRow` first.
8. **Anonymous Apex data loads**: setting `Current_Budget__c` triggers `IMBudgetHelper.updateActiveStatus` → `AuraHandledException`, which cannot be thrown outside Lightning context (`System.LimitException`). Workaround: `TriggerFactory.setBypass('IMBudgetedInitiativeHandler')` in the script.
