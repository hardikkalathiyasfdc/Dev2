# BRME-7045 — Plan (v2): Send Back for Revisions Action on Initiative

> **v3 (review rework, 2026-10-23):** Per review comments from Neha Gire / Gauri Sagane, the `@AuraEnabled` controller **`IMRevisionsNeededCntrl` (+ test) was removed**. The LWC now submits via **`lightning-record-edit-form` (LDS)** — hidden fields set `Status__c = In Development` + `Revisions_Needed__c = 'Yes'` alongside the visible `Revisions_Reason__c` — so field-length changes need no LWC edit. The **Grants Contact email moved into the trigger**: both [IMBudgetedInitiativeHandler](../force-app/main/default/classes/IMBudgetedInitiativeHandler.cls) and [IMAmendmentInitiativeHandler](../force-app/main/default/classes/IMAmendmentInitiativeHandler.cls) detect the `Ready for Approval → In Development` transition in `afterUpdate` and call `NotificationService.sendEmail('IM_Initiative_Revisions_Needed', {id}, grantsContactId)` (per-record, since `targetObjectId` differs) in `andFinally`, mirroring the existing Ready-for-Approval pattern. Class access was removed from `IM_Approval_Tab_Edit_Access`; the 4 Apex files are in [destructiveChanges.xml](../destructive/destructiveChanges.xml). Server-side reason/status guards moved to LWC client validation + action visibility. Dry-run deploy of the 6 changed components passed.

## Summary

Add a **Send Back for Revisions** LWC screen quick action on the Initiative record page, visible only to Pipeline Managers when `Status = Ready for Approval`. The modal captures a required **Revisions Reason** (255 chars); on confirm it sets `Status__c = In Development` and `Revisions_Needed__c = "Yes"`, saves the reason, and emails the Grants Contact (best-effort — send-back succeeds even if the email can't be sent). Grants correct and re-submit with the existing **Ready For Approval** action. The previous Revisions Reason stays on the record for the PM to see at re-submission.

## Key Findings (from workspace)

- **`Revisions_Reason__c` exists** (BRME-7039): [Revisions_Reason__c](../force-app/main/default/objects/IM_Initiative__c/fields/Revisions_Reason__c.field-meta.xml) — TextArea, fixed 255 chars. Not placed on the flexipage; nothing references it in Apex.
- **`Revisions_Needed__c` is a Checkbox today** ([field](../force-app/main/default/objects/IM_Initiative__c/fields/Revisions_Needed__c.field-meta.xml)) and **must be replaced with a Picklist** (user decision). Only reference: read-only FLS in the managed [sfdcInternalInt__sfdc_a360_sfcrm_data_extract](../force-app/main/default/permissionsets/sfdcInternalInt__sfdc_a360_sfcrm_data_extract.permissionset-meta.xml) permission set (keep as-is; readable FLS is valid on any field type).
- **No "Revisions Needed" Status value** — by design. Status goes back to **In Development** (no `Status__c` picklist changes, no `Status__c` record-type changes). The **Ready For Approval** action already fires on In Development → **AC #5 works unchanged**.
- **Action patterns:** headless LWC action (BRME-7043): [initiativeReadyForApproval](../force-app/main/default/lwc/initiativeReadyForApproval/initiativeReadyForApproval.js) + [InitiativeReadyForApprovalController](../force-app/main/default/classes/InitiativeReadyForApprovalController.cls) (`with sharing`, `WITH USER_MODE`, `BBApps_Crud.doUpdateWithHandling`, `BBApps_ErrorHandler`, `AuraHandledException`), custom-permission-gated dynamic action in the [highlights panel](../force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml). Modal (IM-52): [imFinalApproval](../force-app/main/default/lwc/imFinalApproval/imFinalApproval.js) `ScreenAction` + `CloseActionScreenEvent`.
- **PM identity:** custom permission `IM_Final_Approval_Access`, granted by [IM_Approval_Tab_Edit_Access](../force-app/main/default/permissionsets/IM_Approval_Tab_Edit_Access.permissionset-meta.xml) (also has editable FLS on `IM_Initiative__c.Status__c`). USER_MODE controller ⇒ PM needs **editable FLS** on `Revisions_Reason__c` + `Revisions_Needed__c` — added to that set (Change #7).
- **Grants Contact:** [Grants_Team_Contact__c](../force-app/main/default/objects/IM_Initiative__c/fields/Grants_Team_Contact__c.field-meta.xml) — Lookup to **User**. **Blank on 100% of initiatives** in dev2Current (verified 2026-10-15). Email is **best-effort** (Decision #6): blank contact ⇒ send-back succeeds, email skipped.
- **Email framework:** `NotificationService.sendEmail(configDeveloperName, recordIds, targetObjectId)` — `targetObjectId` = Grants Contact User Id ⇒ `setTargetObjectId(userId)` sends directly to that user and renders the template with whoId = that user. Config via `Notification_Config__mdt` (Active, From `bim@e.bloomberg.org`, template developer name, SaveAsActivity, async). `Recipient_Source__c`/`Recipient_Field_API_Name__c` exist on `Notification_Receipient__mdt` but are **not consumed** by `NotificationService` — dynamic-field recipients are NOT supported by the service; the controller passes the User Id directly. **No static CC/BCC** (Decision #7) ⇒ **no `Notification_Receipient__mdt` rows needed**.
- **Email templates are NOT in the repo** (no `EmailTemplate` manifest entry); templates live in the org ([IM_Initiative_Pending_Approval config](../force-app/main/default/customMetadata/Notification_Config.IM_Initiative_Pending_Approval.md-meta.xml) references template `IM_Initiative_Pending_Approval_Template`). The new template is **created in the org** + retrieved into `force-app/main/default/email/`.
- Validation rules [Status_restriction_if_not_approved](../force-app/main/default/objects/IM_Initiative__c/validationRules/Status_restriction_if_not_approved.validationRule-meta.xml) / [if_approved](../force-app/main/default/objects/IM_Initiative__c/validationRules/Status_restriction_if_approved.validationRule-meta.xml) restrict only Ongoing/Completed — In Development is always allowed pre-approval. No change.
- Bgive sync actions are gated on `Approved__c = true` — this pre-approval transition never syncs.
- Approval Overview tab stays visible on In Development (hides only Draft/Completed/Declined/Approved).
- **Deleting a field with existing data** (the checkbox) ⇒ deploy as **destructiveChanges** (separate step) plus the new picklist creation.

## Changes

### 1. Replace `Revisions_Needed__c` checkbox with Picklist (destructive + new field)

- **Destructive deploy** [objects/IM_Initiative__c/fields/Revisions_Needed__c.field-meta.xml](../force-app/main/default/objects/IM_Initiative__c/fields/Revisions_Needed__c.field-meta.xml) (checkbox) via `destructiveChanges.xml`.
- **Recreate** same API name, `Revisions_Needed__c`, type **Picklist**, label **Revisions Needed**, values **Yes** / **No**, **no default**, restricted, `BRME-7045:` description.
- Add `Revisions_Needed__c` picklistValues (**Yes** + **No**) to [Budgeted_Initiative.recordType-meta.xml](../force-app/main/default/objects/IM_Initiative__c/recordTypes/Budgeted_Initiative.recordType-meta.xml) and [Amendment.recordType-meta.xml](../force-app/main/default/objects/IM_Initiative__c/recordTypes/Amendment.recordType-meta.xml).

### 2. New Apex controller (1 class + meta)

`InitiativeSendBackForRevisionsController.cls` — mirrors the BRME-7043 controller conventions:

- `@AuraEnabled public static void sendBackForRevisions(Id recordId, String revisionsReason)`
- Guards before DML:
  - `String.isBlank(revisionsReason)` → `AuraHandledException('A Revisions Reason is required before sending back for revisions.')`
  - `revisionsReason.length() > 255` → `AuraHandledException(...)` (clean message instead of `STRING_TOO_LONG`)
  - `record.Status__c != Assets.READY_FOR_APPROVAL` → `AuraHandledException(...)` (stale page safety)
- Query `WITH USER_MODE` (Status, Grants_Team_Contact__c, Name); single DML via `BBApps_Crud.doUpdateWithHandling(toUpdate, true, ERR_UPDATE)`:
  - `Status__c = Assets.IN_DEVELOPMENT`
  - `Revisions_Needed__c = 'Yes'`
  - `Revisions_Reason__c = revisionsReason.trim()`
- **Email (best-effort, wrapped in its own try/catch so failure never rolls back the update):**
  ```java
  if (String.isNotBlank(record.Grants_Team_Contact__c)) {
      try {
          NotificationService.sendEmail(
              IM_INITIATIVE_REVISIONS_NEEDED,           // Notification_Config developer name
              new Set<Id>{ recordId },
              record.Grants_Team_Contact__c             // targetObjectId = Grants Contact User
          );
      } catch (Exception emailEx) {
          BBApps_ErrorHandler.logErrors(emailEx, new BBApps_ErrorCustomFields(ERR_EMAIL));
      }
  }
  ```
  Async path: config `Send_Asynchronously__c = true` queues `NotificationQueueable` after the DML commits in the controller transaction.
- Error handling on the main path: `BBApps_ErrorCustomFields` + `BBApps_ErrorHandler.logErrors` + `AuraHandledException`, same shape as [InitiativeReadyForApprovalController](../force-app/main/default/classes/InitiativeReadyForApprovalController.cls).

### 3. New Apex test class (1 class + meta)

`InitiativeSendBackForRevisionsControllerTest.cls` (repo `TestDataFactory` conventions):

- Happy path: Ready for Approval initiative + Grants Contact set → Status = In Development, `Revisions_Needed__c = 'Yes'`, reason saved.
- Blank/null reason → `AuraHandledException`, record unchanged.
- Reason > 255 chars → `AuraHandledException`.
- Wrong status (Draft / In Development) → `AuraHandledException`, record unchanged.
- Blank Grants Contact → send-back succeeds, no email attempt (no exception).
- Round-trip (AC #5): after send-back, `InitiativeReadyForApprovalController.markReadyForApproval` succeeds (checklist gates enforced); `Revisions_Reason__c` is preserved.

### 4. New LWC `initiativeSendBackForRevisions` (3 files)

- `js-meta.xml`: `isExposed`, `lightning__RecordAction`, `<actionType>ScreenAction</actionType>`, apiVersion 67.0, `BRME-7045:` description.
- HTML: `lightning-quick-action-panel` modal, header **Send Back for Revisions**; single `lightning-textarea` label **Revisions Reason**, `required`, `max-length="255"`, with `message-when-value-missing` / `message-when-too-long`; footer **Cancel** + **Send Back for Revisions** (brand, spinner while saving).
- JS: `@api recordId`; confirm → `reportValidity()` → Apex → success toast *"Initiative sent back for revisions."* + `CloseActionScreenEvent` + `notifyRecordUpdateAvailable` + `RefreshEvent`; sticky error toast using the same `getErrorMessage` shape as [initiativeReadyForApproval](../force-app/main/default/lwc/initiativeReadyForApproval/initiativeReadyForApproval.js).

### 5. New quick action (1 file)

`IM_Initiative__c.Send_Back_for_Revisions.quickAction-meta.xml` — `type: LightningWebComponent`, `actionSubtype: ScreenAction`, `lightningWebComponent: initiativeSendBackForRevisions`, `optionsCreateFeedItem: false`, label **Send Back for Revisions**, `BRME-7045:` description.

### 6. Flexipage — new dynamic action (1 edited file)

In [IM_Budgeted_Initiative_Page.flexipage-meta.xml](../force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml) highlights `actionNames` list, insert `IM_Initiative__c.Send_Back_for_Revisions` immediately after `IM_Initiative__c.Ready_For_Approval`:

```xml
<visibilityRule>
    <booleanFilter>1 AND 2</booleanFilter>
    <criteria>
        <leftValue>{!Record.Status__c}</leftValue>
        <operator>EQUAL</operator>
        <rightValue>Ready for Approval</rightValue>
    </criteria>
    <criteria>
        <leftValue>{!$Permission.CustomPermission.IM_Final_Approval_Access}</leftValue>
        <operator>EQUAL</operator>
        <rightValue>true</rightValue>
    </criteria>
</visibilityRule>
```

**No change** to the Ready For Approval rule — In Development is already its trigger status (AC #5).

### 7. Permission set (1 edited file)

Add to [IM_Approval_Tab_Edit_Access.permissionset-meta.xml](../force-app/main/default/permissionsets/IM_Approval_Tab_Edit_Access.permissionset-meta.xml) (the PM persona set; already grants `IM_Final_Approval_Access` + editable `Status__c`):

- **Editable** FLS: `IM_Initiative__c.Revisions_Reason__c`, `IM_Initiative__c.Revisions_Needed__c`
- `classAccesses`: `InitiativeSendBackForRevisionsController` enabled

Grants/L Leadership read-only visibility of the reason on the Approval Overview tab is already covered by the BRME-7039/7042 Read sets.

### 8. Email notification config (CMDT + org-side template)

- **New CMDT:** `Notification_Config.IM_Initiative_Revisions_Needed.md-meta.xml` — label **IM Initiative Revisions Needed**; `Active__c = true`; `Email_Template_Name__c = IM_Initiative_Revisions_Needed_Template`; `From_Address__c = bim@e.bloomberg.org`; `Object_API_Name__c = IM_Initiative__c`; `Save_As_Activity__c = true`; `Send_Asynchronously__c = true`. **No `Notification_Receipient__mdt` rows** (Decision #7 — recipient is the Grants Contact User passed as `targetObjectId`).
- **New email template (org-side, then retrieve):** developer name `IM_Initiative_Revisions_Needed_Template`, **Classic "Custom" template** in the public classic folder **IM Email Templates** (same folder/type as `IM_Initiative_Pending_Approval_Template` — verified in org), subject `An Initiative or Amendment needs your attention in BIM`, body:

  > `{!IM_Initiative__c.Name}` was moved back to In Development because revisions were requested. Please see the notes for additional details.
  >
  > `{!IM_Initiative__c.Revisions_Reason__c}`
  >
  > Link to initiative: `{!IM_Initiative__c.Link}` (or the record-URL merge used by the Pending Approval template — mirror its markup)

- Deploy sequence: template first (or same package), CMDT second; verify `OrgWideEmailAddress bim@e.bloomberg.org` exists in the target org.

### 9. Manifest

Add to [manifest/package.xml](../manifest/package.xml): `CustomField: IM_Initiative__c.Revisions_Needed__c` (+ confirm `Revisions_Reason__c` covered), `RecordType: Budgeted_Initiative` + `Amendment` (for the picklist values), `ApexClass: InitiativeSendBackForRevisionsController(+Test)`, `LightningComponentBundle: initiativeSendBackForRevisions`, `QuickAction: IM_Initiative__c.Send_Back_for_Revisions`, `PermissionSet: IM_Approval_Tab_Edit_Access`, `CustomMetadata: Notification_Config.IM_Initiative_Revisions_Needed`, `EmailTemplate: <folder>/IM_Initiative_Revisions_Needed_Template` + its `EmailFolder` member if the folder is new, confirm `FlexiPage: IM_Budgeted_Initiative_Page` covered. Add the destructive-changes package for the checkbox delete.

### 10. Deploy & verify

Dry-run first; verify via org `DeployRequest` (Tooling API), not CLI output (repo lessons #4/#5: cosmetic "locale en_US" errors; `--test-level NoTestRun` for metadata, run tests separately). **Destructive deploy (checkbox delete) runs before the picklist create.** Assign/confirm the permission set before UI/SOQL checks (FLS gates visibility).

## Decisions (confirmed with user)

1. **Ticket number** — **BRME-7045**.
2. **PM gating** — reuse **`IM_Final_Approval_Access`** custom permission (granted by `IM: Approval Tab Edit Access`); add the two Revisions-field FLS grants + class access to that set. No new permission artifacts.
3. **Action label** — **Send Back for Revisions**.
4. **Status transition** — **no new Status value**; action sets `Status__c = In Development`. (Matches the email copy.)
5. **Revisions Reason lifecycle** — captured **only** when the button is clicked (required in the modal); **kept** on re-submission (PM sees the previous reason when reviewing the re-submit). `Revisions_Needed__c` is set to `"Yes"` by the action; re-submit does not clear it (Ready For Approval logic untouched).
6. **Blank Grants Contact** — **send-back succeeds; email is skipped** (email is best-effort; failures are logged, never rolled back).
7. **No static CC/BCC** — To = Grants Contact only; no `Notification_Receipient__mdt` rows.
8. **From address** — `bim@e.bloomberg.org` org-wide address.
9. **`Revisions_Needed__c`** — **delete the Checkbox, recreate as Picklist (Yes/No)** ⇒ record-type changes **are** in scope (Budgeted Initiative + Amendment).
10. **Record types** — **Budgeted Initiative + Amendment** only.
11. **No Grants Contact backfill** — out of scope. Field stays blank until normal hygiene populates it; email simply skips until then (per Decision #6).
12. **Email template folder/sharing** — **Classic "Custom" template** in the public classic folder **IM Email Templates** (same folder + type as the existing `IM_Initiative_Pending_Approval_Template`; org has folder sharing / enhanced sharing OFF → visible to all internal users). `NotificationService` renders via `Messaging.renderStoredEmailTemplate`, which supports classic Custom templates.

## Open Decisions

**None.** All decisions confirmed. Ready to implement.

## Verification

1. Deploy to dev2Current with `--test-level NoTestRun`; verify via `DeployRequest` Tooling API query (not CLI exit code). Destructive delete of the checkbox runs first.
2. Permission set updated before UI checks (FLS gates the fields + class).
3. **Visibility matrix:** PM + Status = Ready for Approval → action visible; non-PM → hidden; Status ≠ Ready for Approval → hidden.
4. **Modal:** reason empty → cannot submit; > 255 chars → blocked; Cancel closes with no changes.
5. **Success path:** Status = In Development, `Revisions_Needed__c = Yes`, `Revisions_Reason__c` populated; Approval Overview tab still visible; Grants can read the reason.
6. **Email:** with Grants Contact populated → Grants Contact receives the email (subject/body/link per spec), saved as activity; with blank contact → send-back succeeds, no email, no error surfaced.
7. **Round-trip (AC #5):** as Grants, on the In Development record → Ready For Approval → checklist gates enforced → back to Ready for Approval; previous Revisions Reason still on the record.
8. Apex tests pass (run separately from metadata deploy).

## Out of scope / notes

- No `Status__c` picklist change; no `Status__c` record-type change; no change to Ready For Approval / Final Approval logic or their visibility rules.
- Grants Contact backfill is a data question (O1), not part of this build.
- `NotificationService` is not modified — dynamic-field recipients (`Recipient_Field_API_Name__c`) remain unconsumed by the service; the controller passes the Grants Contact User Id directly.
- No page layout (classic) changes — everything surfaces via the dynamic-forms flexipage.

## Implementation Log (completed 2026-10-15)

### Deployed to dev2Current — all Succeeded (verified via `DeployRequest`)

| Component | File(s) | Deploy ID |
|---|---|---|
| Picklist field | [Revisions_Needed__c.field-meta.xml](../force-app/main/default/objects/IM_Initiative__c/fields/Revisions_Needed__c.field-meta.xml) (Picklist Yes/No, restricted, no default) | `0Afbc00000D8SEBCA3` |
| Record types | [Budgeted_Initiative](../force-app/main/default/objects/IM_Initiative__c/recordTypes/Budgeted_Initiative.recordType-meta.xml), [Amendment](../force-app/main/default/objects/IM_Initiative__c/recordTypes/Amendment.recordType-meta.xml) — added Revisions_Needed Yes/No values | `0Afbc00000D8SEBCA3` |
| Apex controller | [InitiativeSendBackForRevisionsController.cls](../force-app/main/default/classes/InitiativeSendBackForRevisionsController.cls) | `0Afbc00000D8SEBCA3` |
| Apex test | [InitiativeSendBackForRevisionsTest.cls](../force-app/main/default/classes/InitiativeSendBackForRevisionsTest.cls) | `0Afbc00000D8SEBCA3` (+redeploys) |
| LWC | [initiativeSendBackForRevisions](../force-app/main/default/lwc/initiativeSendBackForRevisions) (ScreenAction modal) | `0Afbc00000D8SEBCA3` |
| Quick action | [IM_Initiative__c.Send_Back_for_Revisions](../force-app/main/default/quickActions/IM_Initiative__c.Send_Back_for_Revisions.quickAction-meta.xml) | `0Afbc00000D8SEBCA3` |
| Permission set | [IM_Approval_Tab_Edit_Access](../force-app/main/default/permissionsets/IM_Approval_Tab_Edit_Access.permissionset-meta.xml) — editable FLS on 2 Revisions fields + class access | `0Afbc00000D8SEBCA3` |
| CMDT config | [Notification_Config.IM_Initiative_Revisions_Needed](../force-app/main/default/customMetadata/Notification_Config.IM_Initiative_Revisions_Needed.md-meta.xml) | `0Afbc00000D8SEBCA3` |
| Email template | [IM_Initiative_Revisions_Needed_Template](../force-app/main/default/email/IM_Email_Templates/IM_Initiative_Revisions_Needed_Template.email-meta.xml) (IM Email Templates folder, Custom/Aloha) | `0Afbc00000D8SEBCA3` |
| Flexipage | [IM_Budgeted_Initiative_Page](../force-app/main/default/flexipages/IM_Budgeted_Initiative_Page.flexipage-meta.xml) — new dynamic action | separate flexipage deploy |

> **No destructive delete was needed** — `Revisions_Needed__c` did not exist in dev2Current, so the picklist was created directly.
> **No manifest edits** — [manifest/package.xml](../manifest/package.xml) uses `<members>*</members>` wildcards for all relevant types.

### Test results

- **6/6 tests pass (100%)** — happy path, blank reason, >255 reason, wrong status, blank Grants Contact (no email), and the re-submit round-trip (AC #5) preserving the Revisions Reason.

### Gotchas hit during implementation

1. **Apex identifier 40-char limit** — test class `InitiativeSendBackForRevisionsControllerTest` (44 chars) renamed to `InitiativeSendBackForRevisionsTest`.
2. **Test data setup** — `createBudgetedInitiative` requires the BFF `Segment__c`; add `TestDataFactory.createInitiativeBaseData()` in `@testSetup` (matches passing IM tests).
3. **Ready For Approval formula gates** — the round-trip test needs a Current Budget (term = 36) + all 3 doc links (`Final_Memo_Link__c`/`Budget_Narrative_Link__c`/`Approval_Email_Link__c`) for `Term_Alignment__c`/`Required_Approval_Docs__c` to be "Yes". Field is `Approval_Email_Link__c`, **not** `Approval_Doc_Link__c`.
4. **Current Budget assignment in tests** — a Pending Approval budget insert auto-sets Current Budget (BRME-7040) → fires `IMBudgetHelper.updateActiveStatus` → `AuraHandledException` outside Lightning context. Wrap the **budget insert + Current Budget assignment** in `TriggerFactory.setBypass/removeBypass('IMBudgetedInitiativeHandler')` (BRME-7039 gotcha #8). Method is `removeBypass`, not `clearBypass`.
5. **Flexipage `$Permission` syntax** — the pre-existing repo copy had `IM_Final_Approval_Access` wrapped two-line, which failed dry-run with "invalid field syntax". Retrieving the org's flexipage (single-line, valid) and re-adding the action resolved it.
6. **`SaveAsActivity` + User recipient = silent email failure** — `NotificationService.processEmail` uses `Messaging.sendEmail(emails, false)`, so when the recipient is a **User** (`targetObjectId`) and `Save_As_Activity__c = true`, the send fails with `INVALID_SAVE_AS_ACTIVITY_FLAG` but is swallowed (queueable "Completes", no email, nothing in Email Log). Fix: `Save_As_Activity__c = false` on the config (deployed 2026-10-15). The Pending Approval config gets away with `true` because its recipients are static addresses, not a User.
7. **Grants Contact must be Bgive-linked** — `Grants_Team_Contact__c`/`Program_Contact__c` validate via trigger that the user's Contact has a `Bgive_Id__c`; otherwise `FIELD_CUSTOM_VALIDATION_EXCEPTION`. For test data, create a Contact with `BRM_User__c` = the user + `Bgive_Id__c` set, then assign.

### Remaining manual verification

- Assign/confirm `IM: Approval Tab Edit Access` to a PM user; confirm the action appears on a Ready for Approval record and the modal enforces the required reason.
- Populate `Grants_Team_Contact__c` on a record and confirm the email fires to that contact with the correct subject/body/link.
- Round-trip in the UI: send back → Grants edits → Ready For Approval → confirm reason retained.
