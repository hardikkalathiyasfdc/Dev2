# BRME-6993 — Implementation Plan (Phase 1: investigation complete, awaiting approval)

**Ticket:** DIT Compare Potential Duplicates — warn when selecting a different Organization from Excel; conditionally highlight related fields; add an editable **Use Same Address as Organization** checkbox.

**Status:** Phase 2 implemented, deployed to dev2Current, and user-verified. Complete.

## 14. Final implementation (Phase 2 — completed 2026-10-23)

**Changed components** (all carry `BRME-6993` comments):

1. [DITCmpController.cls](force-app/main/default/classes/DITCmpController.cls) — read-only: `getDupeContactList` SOQL now also selects `Phone`, `Use_Same_Address_as_Organization__c`, `MailingStreet/City/State/PostalCode/Country` so the Compare stage has the existing BRM values for the highlight conditions. No logic change.
2. [DITStareCompareCmpHelper.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js) — `recalcOrgChange` (different-org detection by resolved Id + conditional highlight flags), `showStickyToast`, checkbox field build (init unchecked), `Organization_Id__c` carried onto the row.
3. [DITStareCompareCmpController.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpController.js) — `columnMap` entry for the checkbox; `recalcOrgChange` wired into `handleExcelSelect`/`handleSFSelect`/`selectAllExcel`/`selectAllSf`/`handleInputChange`; sticky toast on `confirmContact`; checkbox `checked`→`value` sync for persistence.
4. [DITStareCompareCmp.cmp](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmp.cmp) — BOOLEAN checkbox input in the Excel column; "(NEW)" marker + yellow highlight on qualifying fields (`isNewHighlight`).

**Deployed behavior (per resolved rules):**
- Confirm shows a sticky toast "Please review and update highlighted fields related to this change." only when a different Excel org is selected AND the BRM contact's `Use_Same_Address_as_Organization__c = true` (the org change will overwrite the address via the trigger).
- Highlights + "(NEW)": Email/Phone when populated on BRM; Address when populated AND the effective checkbox = false. Recalculated live on every selection/checkbox change; per-contact; advisory (proceed without editing).
- Checkbox editable in the Excel column; value persists through `Contact_Data__c` → final Contact update.

**Deployment & tests:** deployed `aura/DITStareCompareCmp` + `classes/DITCmpController` with `RunSpecifiedTests -t DITCmpControllerTest`. `DeployRequest 0Afbc00000DExS9CAL` — **Succeeded, 0 errors, 18/18 tests passed**. Logic verified across all scenarios (s1–s5, s9) via the deployed `recalcOrgChange` against live data shapes. BRME-7012 / BRME-4425 / BRME-6786 untouched.

**Org:** `dev2Current` → `https://bbrm--dev2.sandbox.my.salesforce.com` (sandbox, verified this session). No git; rollback via re-retrieved copies.

---

## 1. Requirements and acceptance criteria

- On **Confirm** (per contact), if the user selected the **Excel** Organization Name and it resolves to a **different org** than the existing BRM contact's org → show: **"Please review and update highlighted fields related to this change."** (advisory; user can proceed without editing).
- Yellow highlight + "(NEW)" on **Business Email**, **Business Phone**, **Business Address** when the different-Excel-org is selected AND the respective **existing BRM** value is populated; Address additionally requires the applicable **Use Same Address as Organization = FALSE**.
- New editable checkbox **Use Same Address as Organization** in the Excel column of the Compare stage.
- No warning when: keeping the BRM org, selecting the same org, or the org field isn't Excel-selected.
- Selections/checkbox changes recalc without stale state; state is per-contact.
- Preserve BRME-7012 (preferred-name matching), BRME-4425 (no-review/compare collapsible tables), BRME-6786 (org error messages).

## 2. Current field-selection, confirmation, and save flow

Compare stage `DITStareCompareCmp` (stage `contact`):

- Each row's fields render as `selectedContact.fields[]` with `{api, excel:{value,isSelected,...}, sf:{value,isSelected,...}}`. Per-field radio: `handleSFSelect` / `handleExcelSelect` ([DITStareCompareCmpController.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpController.js#L368-L444)) toggle `excel.isSelected`/`sf.isSelected`. "Select All" links: `selectAllExcel` / `selectAllSf` set all flags (L334-L366).
- Every selection/edit persists via `updateSelected`/`saveRecord` → Apex `updateDataRecord` writes `Contact_Data__c` = JSON of the row (including the isSelected flags).
- **Confirm** = `confirmContact` (controller L213) → helper `confirmContact` → `updateSelected` (persists Contact_Data__c). No modal today.
- **Final update** (Import stage): `getUpdateContact` ([DITCmpController.cls](force-app/main/default/classes/DITCmpController.cls#L752)) reads `Contact_Data__c`; for each `isShow` field where `excel.isSelected == true`, it puts `columnMap[fieldApi]` = the excel value. For `Organization_Name__c` it sets `AccountId = Organization_Id__c` (L784-787).
- **Org resolution**: `Organization_Id__c` is set at Review Errors (BRME-6786 flow). The Compare row's `Organization_Name__c` field shows the org **name**; the resolved Id lives on the DLR.

## 3. Verified field API names (org-verified 2026-10-23)

| Label | Contact API | Notes |
|---|---|---|
| Organization Name | `AccountId` | lookup to Account |
| Business Email | `Email` | |
| Business Phone | `Phone` | requires `Office_Phone_Country_Code__c` on insert (validation rule) |
| Business Address | `MailingAddress` (compound) = `MailingStreet`, `MailingCity`, `MailingState`, `MailingPostalCode`, `MailingCountry` (+ `MailingStateCode`/`MailingCountryCode`) | compare columns map `Business_Street_1__c→MailingStreet`, `Business_City__c→MailingCity`, `Business_State__c→MailingState`, `Business_Postal_Code__c→MailingPostalCode`, `Business_Country__c→MailingCountry` |
| **Use Same Address as Organization** | `Contact.Use_Same_Address_as_Organization__c` (Checkbox) | **not** present on `Data_Load_Record__c` (verified) — so it's a Compare-stage-only control, not an upload column |

DLR org fields: `Organization_Name__c` (label "Organization Name"), `Organization_Id__c` (Text(20) — holds the resolved Account Id), `Contact_Data__c`.

## 4. Organization comparison approach

Compare **resolved IDs**, not labels: the BRM side's org Id = `selectedContact.sfContacts[0].AccountId` (available on the candidate — `getDupes` selects `AccountId`, `Account.Name`). The Excel side's org Id = the DLR's `Organization_Id__c` (resolved at Review Errors). "Different organization" = Excel org field selected **and** `Organization_Id__c != sfContacts[0].AccountId` (both non-blank). Same-org labels / same Id ⇒ no warning.

## 5. Highlight and "(NEW)" conditions

Evaluated when the different-Excel-org is selected, per field, against the **existing BRM** record:

- **Business Email**: `sfContacts[0].Email` populated.
- **Business Phone**: `sfContacts[0].Phone` populated.
- **Business Address**: BRM address populated (any of MailingStreet/City/State/PostalCode/Country non-blank) **and** `Use_Same_Address_as_Organization__c == false` (see Q1 — original vs effective value).

> ⚠️ Gap found: the `getDupes` SOQL selects `AccountId`/`Account.Name` but **not** `Use_Same_Address_as_Organization__c`, `Phone`, or `Mailing*`. `Phone` and address values ARE needed for the highlight conditions. Phase 2 must add these to the SELECT (read-only, no logic change). Confirm in Phase 2.

## 6. Checkbox initialization, editing, selection, persistence

- Not an upload column (no DLR field) → Compare-stage control only.
- **Init:** default to the **existing BRM value** `sfContacts[0].Use_Same_Address_as_Organization__c` (so it reflects the record being compared); when no BRM contact (new contact row), default unchecked. See Q4.
- **Render:** new checkbox input in the Excel column for a new row `Use_Same_Address_as_Organization__c` (the field template currently has no CHECKBOX type — Phase 2 adds one).
- **Persist:** same path as other fields — the row's field entry (with the checkbox value) serializes into `Contact_Data__c` via `updateSelected`/`saveRecord`; on Import, `getUpdateContact` writes it when selected. `columnMap` needs `Use_Same_Address_as_Organization__c → Use_Same_Address_as_Organization__c` added (controller columnMap) and the field added to the Compare `v.columns`/field build.

## 7. Trigger findings and expected address effects

- `ContactTriggerHandler.setContactBusinessAddress` (L784): on Contact insert/update, when `Use_Same_Address_as_Organization__c == true` and the account is in `accountMap`, copies the **Account Billing\*** fields into the Contact **Mailing\*** fields.
- `AccountTriggerHandler.updateContactsBusinessAddress` (L281): when an Account's address changes, re-copies Billing→Mailing for all Contacts with the checkbox true.
- **Net effect for DIT:** if the org changes (AccountId → Org B) and the checkbox is true, the Contact's business address becomes Org B's address on save. If the checkbox is false, the address stays whatever was written. So the "highlight address only when checkbox=false" rule reflects that with checkbox=true the address will be overwritten by the org anyway (no point flagging the Excel address). **No trigger changes needed.**

## 8. Proposed warning flow

- On **Confirm** (`confirmContact`), before completing: if the org-change condition holds → show an advisory modal (existing pattern: `lightning:confirm` is used elsewhere, e.g. contactCreation) with exactly **"Please review and update highlighted fields related to this change."**
- Buttons: **Continue** (proceed with the confirmation — advisory, no edits required) and **Go Back**/**Review** (close modal, stay on the row to edit highlighted fields). See Q5.
- Highlight + "(NEW)" appear immediately when the different Excel org is selected (recalc on every selection change), independent per contact. See Q3.

## 9. Proposed changes by component/method (Phase 2)

All in the `DITStareCompareCmp` bundle + one read-only SOQL addition in `DITCmpController`:

1. `DITCmpController.getDupeContactList` — add `Phone`, `Use_Same_Address_as_Organization__c`, `MailingStreet`, `MailingCity`, `MailingState`, `MailingPostalCode`, `MailingCountry` to the SELECT (read-only; enables the conditions).
2. `DITStareCompareCmpHelper.setContactList` / `getContactCell` — capture BRM `AccountId`, checkbox value, email/phone/address on the row; build the checkbox field entry.
3. `DITStareCompareCmpController.js` — add `columnMap` entry for the checkbox; new handlers: org-change detection + highlight recalc (`handleExcelSelect`/`handleSFSelect`/`selectAll*` paths), `confirmContact` guard showing the modal, modal Continue/Go Back.
4. `DITStareCompareCmp.cmp` — add checkbox input in the Excel column template; add the "(NEW)" marker + yellow highlight binding; add the confirm modal markup.
5. `DITCmpController.columnMap` (Import) — ensure the checkbox maps through to the Contact update.

BRME-6993 comments at each change.

## 10. Test-data inventory and manual checks

See [README.md](BRME-6993/README.md) and [setup/record-manifest.md](BRME-6993/setup/record-manifest.md).

**Baseline (created in dev2):** Org A `001bc00000kkfowAAA` (BRM), Org B `001bc00000kkfoxAAA` (Excel); contacts Fiona `003bc000018L8YYAA0` (full, chk=false), Theo `003bc000018L8YZAA0` (full, chk=true), Paula `003bc000018KoOdAAK` (email only), Adam `003bc000018KoOeAAK` (address only), Bianca `003bc000018KoOfAAK` (none).

**Workbooks** ([test-data/](BRME-6993/test-data/)): s1 diffOrg full chkFalse; s2 diffOrg chkTrue; s3 partial fields (3 rows); s4 sameOrg; s5 keepBrm; s9 checkbox.

## 11. Automated tests and regression checks

- `getDupes` SELECT addition is read-only — covered by existing `DITCmpControllerTest` (18/18) staying green; add an assertion that the new fields are returned (cheap guard).
- The warning/highlight logic is front-end (Aura) — verified manually (consistent with BRME-7012/4425 front-end verification). No new Jest harness.
- Regression: confirm BRME-7012 (preferred-name candidates) and BRME-4425 (no-review table) still behave; DITCmpControllerTest + ReusableLookupController_Test stay green.

## 12. Deployment and rollback

- Deploy `DITStareCompareCmp` + `DITCmpController` (read-only SELECT addition) with `RunSpecifiedTests`. Verify via `DeployRequest`.
- No production. Rollback: re-retrieve current bundle into `other-org/retrieve-brme6993-rollback/` before editing; redeploy that.

## 13. Open questions and assumptions — RESOLVED with the user (2026-10-23)

1. **Address highlight checkbox value** — the **effective/current** value (what the user has selected now), not the original BRM value.
2. **"Populated Business Address"** — **any** of MailingStreet/City/State/PostalCode/Country non-blank.
3. **Highlight timing** — **immediately** on selecting the different Excel org (live feedback, before Confirm).
4. **Checkbox init** (upload has no value) — **always unchecked** (user chose this over mirroring the BRM value).
5. **Warning gating** — the **Confirm warning appears only when the BRM contact's `Use_Same_Address_as_Organization__c` is `true`** (the org change will overwrite the address via the trigger). **Within** that warning, the **Address** highlight shows only when the checkbox is **false**; **Email/Phone** highlight when populated. (I.e. warning gated on checkbox=true; address highlight when false.)
6. **Warning UI** — a **sticky toast** (not a blocking modal). User can proceed without editing. No Continue/Go-Back modal.
7. **Confirm All** — not present on this stage (per-contact Confirm only); nothing to change.

**Assumptions:** warning is advisory (sticky toast, non-blocking); org comparison by resolved Id (`Organization_Id__c` vs `sfContacts[0].AccountId`); no trigger changes; BRME-7012/4425/6786 preserved.
