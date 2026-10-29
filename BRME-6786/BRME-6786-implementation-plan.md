# BRME-6786 — Implementation Plan (Phase 1: investigation complete, awaiting approval)

**Ticket:** DIT Review Errors — align organization error messages with the actual resolution flow.

**Status:** Phase 2 implemented and deployed to dev2Current. User confirmed complete.

## 13. Final implementation (Phase 2 — completed 2026-10-23)

**Changed components**

1. [reusableLookup.js](force-app/main/default/lwc/reusableLookup/reusableLookup.js) — emits `candidateschecked` (`{dlRecordId, fieldChanged, hasCandidates}`) after each candidate fetch in `fetchSobjectRecords`, and on `handleCommit` (clear → `hasCandidates:false`).
2. [DITConfirmRecords.cmp](force-app/main/default/aura/DITConfirmRecords/DITConfirmRecords.cmp) — org `c:reusableLookup` gets `oncandidateschecked="{!c.handleCandidatesChecked}"`.
3. [DITConfirmRecordsController.js](force-app/main/default/aura/DITConfirmRecords/DITConfirmRecordsController.js) — `handleCandidatesChecked` → helper.
4. [DITConfirmRecordsHelper.js](force-app/main/default/aura/DITConfirmRecords/DITConfirmRecordsHelper.js) — `updateOrgMessage(cmp, detail)`: org rows in error get "Similar records exist in BRM. Please review potential duplicates." when the modal has candidates, else "Org not found in BRM. Please create new Organization."; V3 rows ("Potential match found…") unchanged.

**Deployment & tests:** deployed `lwc/reusableLookup` + `aura/DITConfirmRecords` with `RunSpecifiedTests -t DITCmpControllerTest -t ReusableLookupControllerTest`. `DeployRequest 0Afbc00000DEUbRCAX` — **Succeeded, 0 errors, 19/19 tests passed**. BRME-7012 / BRME-4425 untouched.

**Org:** `dev2Current` → `https://bbrm--dev2.sandbox.my.salesforce.com` (sandbox, verified this session). No git; rollback via re-retrieved copies.

---

## 1. Requirements and acceptance criteria

At the **Review Errors** stage, the organization error message must match what the row's resolution flow actually offers:

| Scenario | Current message | New message (exact) |
|---|---|---|
| 1. "not found" but duplicates modal has candidates | `X not found in BRM` | **Similar records exist in BRM. Please review potential duplicates.** |
| 2. "not found" and no candidates | `X not found in BRM` | **Org not found in BRM. Please create new Organization.** |
| 3. "Multiple X found…" and duplicates available | `Multiple X found in BRM. Please search for correct one.` | **Similar records exist in BRM. Please review potential duplicates.** |

- No org-name interpolation in the new messages (per ticket).
- Matching criteria, lookup search, duplicate modal, Create Organization, Use Existing / Ignore and Create New, Cancel, and navigation behavior unchanged.
- Selecting a valid org still clears the error; messages don't go stale on edit/select/cancel.
- BRME-7012 / BRME-4425 behavior intact.

## 2. Verified current execution flow (Review Errors stage = `unconfirm`, `c:DITConfirmRecords`)

1. `loadData` → Apex `loadUnconfirmedData` → `getOrgMap(records)` (batch) + `normalizeOrgNames` (per-name normalization).
2. `setUnconfirmedRecords` ([DITConfirmRecordsHelper.js](force-app/main/default/aura/DITConfirmRecords/DITConfirmRecordsHelper.js#L57-L117)) computes per-row org state and **sets the message**:
   - no orgMap entry, or `countOrg === 0` → `orgName + ' not found in BRM'`
   - `countOrg > 1` → `'Multiple ' + orgName + ' found in BRM. Please search for correct one.'`
   - `countOrg === 1` + compare-name match → auto-links `Organization_Id__c` (no error)
   - `countOrg === 1` + compare mismatch → `'Potential match found for ' + orgName + '. Please search for and confirm the correct organization.'`
3. Each org cell renders `c:reusableLookup` (LWC) with `searchString = Organization_Name__c`.

## 3. The resolution flow (what the user can actually do)

- `reusableLookup.connectedCallback` runs `fetchSobjectRecords(true,false)` → Apex `DITLookupController.fetchRecords` (LIKE on `Name` contains; `Converted_AKA__c`/`Converted_Legal_Name__c`/`Converted_Org_Name__c` prefix; LIMIT 200) and stores candidates in `duplicaterec` ([reusableLookup.js](force-app/main/default/lwc/reusableLookup/reusableLookup.js#L124-L135)).
- The **+ button** (`handleCreate`) opens `c-create-new-lookup` with `duplicaterec`.
- `createNewLookup`: `duplidateDone = duplicaterec.length > 0` → shows **"Potential Duplicate Records"** modal (datatable + Use Existing / Ignore and Create New / Cancel); otherwise the **"Create Organization"** modal ([createNewLookup.js](force-app/main/default/lwc/createNewLookup/createNewLookup.js#L25-L31), [createNewLookup.html](force-app/main/default/lwc/createNewLookup/createNewLookup.html)).
- Selecting a candidate fires `valueselect` → `handleValueSelected` ([DITConfirmRecordsController.js](force-app/main/default/aura/DITConfirmRecords/DITConfirmRecordsController.js#L104)) → persists `Organization_Id__c` and clears `orgError`.

## 4. Evidence-backed explanation of the message mismatch

The **message** is driven by `getOrgMap` + strict normalized **equality** in `setUnconfirmedRecords` (`accNameNormalised === uploadedOrgCompareName`, spaces/special chars stripped, leading-"the" rules). The **duplicate modal** is driven by the lookup's **broader LIKE** search (`fetchRecords`). These are different predicates over the same data, so:

- **Scenario 1** (verified live with "BRME6786 Holdings" vs existing "BRME6786 Holdings Group"): strict equality fails → countOrg=0 → "not found in BRM"; the LIKE search finds the record → the + button opens Potential Duplicates with 1 candidate. Message contradicts the available resolution. ✅ matches the Gambit Tech screenshot.
- **Scenario 2** (verified with "BRME6786 Nonexistent Foundation"): both paths find nothing → "not found" + Create Organization. Message is fine but doesn't say what to do.
- **Scenario 3** (verified with two identical "BRME6786 City Foundation" accounts): countOrg=2 → "Multiple … found…" + modal has 2 candidates. ✅ matches the City of London screenshot.

**Constraint:** candidate availability for the modal is only known after the lookup's `fetchRecords` call — which **already runs at load for every row** with a search string (connectedCallback). So no new server calls are needed; the parent just never learns the result today.

## 5. Proposed changes (Phase 2 — smallest justified fix)

**Approach:** the lookup already knows whether candidates exist. Surface that to the row.

1. [reusableLookup.js](force-app/main/default/lwc/reusableLookup/reusableLookup.js) — after `fetchSobjectRecords` computes `duplicaterec`, when `fieldChanged == 'Organization_Name__c'` and no record is selected, dispatch a small event (e.g. `duplicateschecked`) with `{ dlRecordId, fieldChanged, hasDuplicates: duplicaterec.length > 0 }`. Also re-dispatch after `handleChange` fetches (covers edits) and after `handleCommit` (clear → hasDuplicates false).
2. [DITConfirmRecords.cmp](force-app/main/default/aura/DITConfirmRecords/DITConfirmRecords.cmp) — handle the event on `c:reusableLookup` (add `onduplicateschecked="{!c.handleDuplicatesChecked}"`).
3. [DITConfirmRecordsController.js](force-app/main/default/aura/DITConfirmRecords/DITConfirmRecordsController.js) — new `handleDuplicatesChecked` → helper updates the row's message:
   - `orgError` stays true (red box stays).
   - `hasDuplicates` → `orgErrorMsg = 'Similar records exist in BRM. Please review potential duplicates.'`
   - `!hasDuplicates` → `orgErrorMsg = 'Org not found in BRM. Please create new Organization.'`
   - Only for `fieldChanged == 'Organization_Name__c'`, matching `rec.Id == dlRecordId` (no cross-row state bleed).
4. This replaces the current variants on error rows as follows:
   - V1b ("not found" but modal has candidates) → "Similar records exist in BRM. Please review potential duplicates."
   - V1a ("not found", no candidates) → "Org not found in BRM. Please create new Organization."
   - V2 ("Multiple X found…") → "Similar records exist in BRM. Please review potential duplicates."
   - **V3 ("Potential match found for X. Please search for and confirm the correct organization.") → UNCHANGED** (user decision 2026-10-23). The event handler must therefore only rewrite the message when the current message is V1a/V1b/V2 — i.e. skip rows whose state is V3 (countOrg === 1 auto-link-failed).

**Why this approach:** the message then literally reflects the modal's content (same `duplicaterec` the modal renders), with zero new matching rules and zero extra server calls.

## 6. Message refresh / stale-response handling

- Load: initial `fetchSobjectRecords(true,false)` emits the event → message set correctly from the start.
- Edit org text: `handleChange` re-fetches → re-emits → message updates (covered by `updateError`/`handleInputChange` paths clearing `orgError` on valid entry).
- Select a value: `handleSelect` → `valueselect` → `handleValueSelected` clears `orgError` (unchanged).
- Clear a value: `handleCommit` → `valueselect` (empty) → existing behavior; re-emit `hasDuplicates=false` so if an error is re-shown it says the create-new variant.
- Modal Cancel: no state change → message unchanged (correct).
- Rows are keyed by `dlRecordId`; mixed uploads can't share message state.

## 7. Performance and bulk considerations

- **No new Apex/SOQL** — reuses the per-row `fetchRecords` call that already happens at load. Event dispatch is O(1) per row.
- Message computation stays client-side in `setUnconfirmedRecords`/event handler. No governor-limit impact.

## 8. Test-data inventory and baseline instructions

See [README.md](BRME-6786/README.md). Baseline Accounts created in dev2 (synthetic, `Description='BRME-6786 synthetic test data'`):

| ID | Name | Scenario |
|---|---|---|
| `001bc00000kjz4sAAA` | BRME6786 Holdings Group | 1 (candidate for "BRME6786 Holdings") |
| `001bc00000kjz4tAAA` / `001bc00000kjz4uAAA` | BRME6786 City Foundation ×2 | 3 (identical names) |
| `001bc00000kjz4vAAA` | BRME6786 Exact Org | exact-match control |

Workbooks ([test-data/](BRME-6786/test-data/), 32-col DIT template, org values under **"Organization Name"** header so it auto-maps; the legacy "Company" header does not auto-map — mapped manually in real use):
1. `BRME-6786-scenario1-similar-records.xlsx` — "BRME6786 Holdings"
2. `BRME-6786-scenario2-create-org.xlsx` — "BRME6786 Nonexistent Foundation"
3. `BRME-6786-scenario3-multiple.xlsx` — "BRME6786 City Foundation"
4. `BRME-6786-mixed.xlsx` — all three + exact-match control row

Classification pre-verified against live data ([setup/brme6786-classification-precheck.apex](BRME-6786/setup/brme6786-classification-precheck.apex)) — each row lands in the intended current message bucket with the intended modal candidate count.

## 9. Automated tests and manual checks (Phase 2)

- The message logic under test lives in the Aura helper + LWC — no Apex changes needed, so no new Apex tests strictly required. `DITCmpControllerTest` (18/18) + `ReusableLookupController_Test` must stay green.
- If we want a cheap guard: none of the changed Apex exists; recommend manual UI acceptance (same convention as BRME-7012 front-end / BRME-4425).

**Manual before/after:**

| Workbook | Row | Before | After |
|---|---|---|---|
| scenario1 | BRME6786 Holdings | "…not found in BRM" | "Similar records exist in BRM. Please review potential duplicates." (+ modal offers Holdings Group) |
| scenario2 | BRME6786 Nonexistent Foundation | "…not found in BRM" | "Org not found in BRM. Please create new Organization." (+ opens Create Organization) |
| scenario3 | BRME6786 City Foundation | "Multiple … found in BRM. Please search for correct one." | "Similar records exist in BRM. Please review potential duplicates." (+ modal offers 2) |
| mixed | all 3 + control | per-row mixed messages | per-row correct messages; control row absent from Review Errors |
| regression | select a candidate / create org | error clears | unchanged |

## 10. Impact on shared code and earlier tickets

- `reusableLookup` is shared (org, significant other, staff cells; also used elsewhere). The new event is emitted only for `fieldChanged == 'Organization_Name__c'` rows on this screen; other consumers don't handle the event → unaffected.
- No changes to `DITCmpController` matching methods, `DITStareCompareCmp`, `DITWorker`, or `MyTable` → BRME-7012 and BRME-4425 untouched.
- All changes carry `BRME-6786` comments.

## 11. Deployment and rollback (Phase 2)

- Deploy `lwc/reusableLookup` + `aura/DITConfirmRecords` with `RunSpecifiedTests -t DITCmpControllerTest -t ReusableLookupController_Test`; verify via org `DeployRequest` (CLI `locale en_US` error is cosmetic).
- No production deploy. Rollback: re-retrieve the current bundle before editing into `other-org/retrieve-brme6786-rollback/` and redeploy that.

## 12. Open questions and assumptions

**Resolved with the user (2026-10-23)**

1. **V3 variant ("Potential match found for X…")** — user chose to **keep it unchanged**. Only V1a/V1b/V2 messages are rewritten by the new logic. The handler will distinguish V3 by checking the row's existing message/state before rewriting.
2. **Approach approved** — reusableLookup notifies the row of modal candidate availability; message follows the resolution flow.

**Technical findings (verified, not questions)**

- Mismatch mechanism confirmed: strict normalized equality (message) vs broader LIKE (modal candidates).
- Candidate availability is already computed client-side per row at load — no extra server calls needed.
- The "Company" Excel header does NOT auto-map to Organization Name (label is "Organization Name"); fixtures use "Organization Name" so they auto-map.

**Assumptions**

- New messages used verbatim, no org-name interpolation (per ticket).
- The red error styling (`orgError=true`) stays in both message variants.
- dev2Current remains the target sandbox.
