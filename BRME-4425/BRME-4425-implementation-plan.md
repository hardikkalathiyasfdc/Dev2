# BRME-4425 — Implementation Plan (Phase 1: investigation complete, awaiting approval)

**Ticket:** Display contacts that require no review in an expandable table at the Compare Potential Duplicates stage.

**Status:** Phase 2 implemented, deployed to dev2Current, and visually confirmed by the user (mixed load screenshot 2026-10-23).", "oldString": "**Status:** Phase 2 implemented and deployed to dev2Current. Awaiting final user UI confirmation.", "filePath_placeholder": ""}

**Org:** `dev2Current` → `https://bbrm--dev2.sandbox.my.salesforce.com` (sandbox, confirmed earlier this session). No git; rollback via retrieved copies.

---

## 1. Requirement and acceptance criteria

Add an expandable/collapsible section tied to the existing "**N Contact(s) Require No Review**" text so users can inspect those contacts.

**Acceptance criteria**

1. Section header shows the count of no-review contacts.
2. Section starts **collapsed**; expanding shows the contacts, collapsing hides them.
3. Table uses the **same headers, column order, and value formatting as the Compare-stage duplicates ("Undo") table** — see §4.
4. Visibility-only: classification, matching, confirmation, and import behavior unchanged.
5. All qualifying rows accessible (no silent truncation); no unintended duplicate rows.
6. Count and table stay consistent as the workflow changes.
7. BRME-7012 preferred-first-name matching remains intact.

## 2. Current behavior and the verified meaning of "requires no review"

**Where the count comes from** — [DITStareCompareCmp.cmp](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmp.cmp#L126):
```
{!(v.totalRecordCount - v.contactList.length)} Contact(s) Require No Review
```
Helptext: *"Includes Exact Matches and New Contacts to be Created."* — this is the **authoritative business definition**, confirmed against code.

- `totalRecordCount` = `result.records.length` ([setContactList caller, loadData line 235](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L235)) = **all staged `Data_Load_Record__c` rows** for the load ([getPreviewRecords](force-app/main/default/classes/DITCmpController.cls#L1648), no status filter / no LIMIT).
- `contactList` = rows pushed for review in [setContactList (line 328)](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L328).

**So "no review" = rows NOT in `contactList` = exactly two populations:**

**(a) Auto-confirmed exact matches** — pushed to `defaultConfirmed`. A row auto-confirms only when **all** hold ([setContactList](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L328)):
- it has ≥1 candidate (`hasDuplicates`),
- `isSame === true`: for every mapped cell, `excel.value` whitespace-stripped-lowercase == `sf.value` (empty Excel values never count as a difference),
- not `isAlredaySignificantOther`,
- **First Name, Last Name, AND Business Email all present** on the row (else forced to review unless a UUID exact match).

These are persisted by [updateDataLoadRecords](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L77) (`IsConfirmed__c=true`, `Contact_ID__c`/`Contact__c` = candidate Id; `Contact_Data__c` left blank) → at Import they're treated as updates to the existing contact ([isUpdate](force-app/main/default/classes/DITCmpController.cls#L824)).

**(b) Rows with no candidates** — fail the `if (result[fullNameKey] || result[firstLastNameKey])` gate; pushed to neither list. Blank `Contact_Data__c` + `IsConfirmed__c=false` → at Import they're created as new contacts ([isCreate](force-app/main/default/classes/DITCmpController.cls#L834)). These are the "New Contacts to be Created."

**Manually confirmed contacts are NOT no-review** — `confirmContact`/`unconfirmContact`/`deleteContact` keep the row in `contactList`, so they never enter the no-review arithmetic. ✅ (satisfies the "distinguish" requirement.)

**Caveat found (edge case):** a no-candidate row that was confirmed in a *prior session* is restored into `contactList` via `prevMap` ([lines 462-463](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L462)), so it's excluded from the count then. Out of scope for this ticket's main flow.

## 3. Relevant components, methods, and data collections

| Concern | Location |
|---|---|
| Count expression | [DITStareCompareCmp.cmp:126](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmp.cmp#L126) |
| Classification | [setContactList](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L328) (`defaultConfirmed`, `contactList`, `previewData`) |
| Auto-confirm persistence | [updateDataLoadRecords](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L77) → `DITCmpController.updateDataRecords` |
| Candidate retrieval (BRME-7012) | `getDupes`/`getDupeContactList` + `prepareResult` |
| Table component | `c:MyTable` (`multipleDupes`) |
| Row builder | [formatDataToDisplayInTable](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L649) + [getCell](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L607) |

**The exact collection to populate the table** must equal the count's population: auto-confirmed (`defaultConfirmed`) + no-candidate rows. These are computed in `setContactList` but currently only `defaultConfirmed` is captured (and immediately persisted, not kept for display). The fix needs a new attribute, e.g. `v.noReviewList`, populated in `setContactList` from `defaultConfirmed` + the no-candidate rows, and rendered via `c:MyTable`.

## 4. Exact Undo (Compare duplicates) table — headers, order, mappings

The "Undo screen" on the Compare stage = the duplicates modal table (`c:MyTable` `tableId="multipleDupes"`). Its columns are the hard-coded `v.columns` in [DITStareCompareCmpController.js (lines 81-98)](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpController.js#L81):

**Headers in exact order (16):** Contact Alert Reason · First Name · Middle Name · Last Name · Preferred First Name · Title · Organization Name · Business Email · Personal Email · Additional Email · Confidential Email · Business Phone · Mobile Phone · Additional Phone · Significant Other · UUID.

**Field mapping (Contact SF fields):** `FirstName`, `MiddleName`, `LastName`, `Preferred_First_Name__c`, `Title`, `Account.Name`, `Email`, `Alternate_Email__c`, `Business_Email_2__c`, `Personal_Email_2__c`, `Phone`, `MobilePhone`, `AdditionalPhone__c`, `Significant_Name__c`, `UUID__c`. First/Last Name are `HYPERLINK` to the record; Contact Alert Reason cell gets a yellow highlight when set. Rows built by `formatDataToDisplayInTable(records, v.columns, contacts)`.

> Note: the literal **Review Errors** stage (`unconfirm`, `c:DITConfirmRecords`) uses a *different* field-set-driven plain SLDS table. Per the ticket wording ("Compare stage Undo screen"), the intended target is the **Compare duplicates `c:MyTable`** above. See open question Q1.

## 5. Proposed section placement, label, and behavior

- **Placement:** directly under the existing count line ([cmp:126](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmp.cmp#L126)), in the left `slds-size_1-of-5` column above the review list — or spanning the content column under the count; recommend keeping it in the left column so the review layout is unchanged.
- **Header/label:** keep the existing text `{!(v.totalRecordCount - v.contactList.length)} Contact(s) Require No Review` as the expandable section header (with the existing helptext preserved). Add a chevron/toggle.
- **Initial state:** collapsed (`v.showNoReview = false` default).
- **Expand/collapse:** a `lightning:button-icon` (`utility:chevrondown`/`chevronright`) toggling `v.showNoReview`; table rendered inside `<aura:if isTrue="{!v.showNoReview}">`.
- **Table:** `<c:MyTable columns="{!v.columns}" data="{!v.noReviewData}" hideCheckboxColumn="true" singleRowSelection="true" hideHeaderCheckbox="true" tableId="noReview"/>`. Read-only (checkboxes hidden, no row actions) — it's for visibility only.

## 6. Row identity and count calculation

- **Row identity** = the staged `Data_Load_Record__c` (its `Id`); for matched rows also the matched Contact Id. Dedup by Data_Load_Record__c Id when building `noReviewData` (same-name rows share keys — BRME-7012 behavior — but each upload row is its own entry).
- **Count consistency:** make the table length equal the header count. `v.noReviewList.length` must equal `totalRecordCount - contactList.length`. Since `contactList.length` changes as rows are confirmed/unconfirmed/deleted *within* the review list, but no-review rows never enter `contactList`, `noReviewList` is stable across those actions — the count expression and table stay in sync automatically. On navigating away/back, `loadData` recomputes from the persisted `Data_Load_Record__c` state (auto-confirmed rows are restored via `prevMap`), so the table repopulates.

## 7. Large lists and zero results

- **Large lists:** `c:MyTable` already renders inside a fixed-size scrollable container (`tableWidth`/`tableHeight`, `overflow:auto` in [MyTable.cmp](force-app/main/default/aura/MyTable/MyTable.cmp#L46-L48)) — follow that convention: set a bounded height with vertical scroll so all rows are reachable without pagination. No silent truncation. (DIT itself caps uploads ~200 rows.)
- **Zero results:** recommend **hiding the toggle and showing the section header with a disabled/empty state** (e.g. "0 Contact(s) Require No Review", no expand control) — the count text already exists, so zero-count just doesn't render the table. Recommend hide-the-table + keep-the-label. See open question Q2.

## 8. Interaction with BRME-7012

- No overlap in code paths: BRME-7012 changed `prepareResult` (candidate keying); BRME-4425 adds display of `defaultConfirmed`/no-candidate rows in `setContactList`/cmp. The 7012 fix is preserved untouched.
- New work will be identifiable by `BRME-4425` comments at the changed locations.
- BRME-4425 fixtures use distinct last names (`BRME4425Exact`/`BRME4425New`) so they never collide with `BRME7012Test`/`BRME7012Email` data or change 7012's expected results.

## 9. Test-data inventory and baseline instructions

See [README.md](BRME-4425/README.md). Baseline Contacts created in dev2 (synthetic, `.invalid`, `Description='BRME-4425 synthetic test data'`):

| ID | Name | Email | Role |
|---|---|---|---|
| `003bc000018J9ykAAC` | Alice BRME4425Exact | alice.brme4425@brme4425.invalid | exact-match target |
| `003bc000018J9ylAAC` | Brendan BRME4425Exact | brendan.brme4425@brme4425.invalid | exact-match target |
| `003bc000018J9ymAAC` | Carla BRME4425Exact | carla.brme4425@brme4425.invalid | exact-match / review target |

Scripts: [setup/brme4425-create-baseline-contacts.apex](BRME-4425/setup/brme4425-create-baseline-contacts.apex), [setup/brme4425-cleanup.apex](BRME-4425/setup/brme4425-cleanup.apex), evidence [setup/brme4425-classification-precheck.apex](BRME-4425/setup/brme4425-classification-precheck.apex).

**Upload workbooks** (32-col DIT template, sheet `Sheet1`, headers auto-map): [test-data/](BRME-4425/test-data/)
1. `BRME-4425-exact-matches.xlsx` — 3 exact matches → **3 no-review** (count shows 3, list empty).
2. `BRME-4425-mixed.xlsx` — 2 exact + 1 review (Carla, different email) + 1 new (Derek) → **3 no-review, 1 to review**.
3. `BRME-4425-zero-no-review.xlsx` — Alice/Brendan exact name but different email → **0 no-review, 2 to review**.

Classification pre-check against live org data confirmed each row's expected bucket (exact/review/new).

## 10. Proposed automated tests and manual checks (Phase 2)

This is a front-end (Aura) display change — no Apex logic changes, so no new Apex tests are strictly required by the change itself. Options:
- Keep `DITCmpControllerTest` green (it covers the unchanged `getDupes`/classification Apex). 
- The no-review collection logic lives in `setContactList` (Aura helper); the repo has no Aura Jest harness (`sfdx-lwc-jest` covers `lwc/**` only). **Recommend manual UI acceptance** (below) as the primary verification, consistent with how BRME-7012's front-end fix was verified. If desired, add a one-off Jest test for the helper — see open question Q3.

**Manual acceptance (dev2):**
| Workbook | No-review count | Table contents (expanded) |
|---|---|---|
| exact-matches | 3 | Alice, Brendan, Carla (16 Undo columns) |
| mixed | 3 | Alice, Brendan, Derek (new) — Carla in review list |
| zero-no-review | 0 | section shows 0; expand shows empty / hidden |
Also: toggle collapse/expand; confirm BRME-7012 single-row still lists Patricia + Patti; confirm Import completes.

## 11. Deployment and rollback (Phase 2)

- Dry-run validate, then deploy `DITStareCompareCmp` (Aura bundle only) with `RunSpecifiedTests -t DITCmpControllerTest`; verify via `DeployRequest`.
- No production deploy. Rollback: redeploy the pre-BRME-4425 retrieved copy (re-retrieve before editing to capture the 7012-fixed version as the rollback baseline).

## 13. Final implementation (Phase 2 — completed 2026-10-23)

**Changed files** (all in the `DITStareCompareCmp` Aura bundle; visibility-only, no logic/process change):

1. [DITStareCompareCmp.cmp](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmp.cmp#L19-L21) — new attributes `showNoReview` (default false = collapsed), `noReviewData`, `noReviewCount`. [Lines 133-153](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmp.cmp#L133) — collapsible section under the existing count: `lightning:buttonIcon` toggle (chevronright/chevrondown, `alternativeText`/`title`/`ariaExpanded` for accessibility) + `c:MyTable` (`tableId="noReview"`, `columns={!v.columns}`, checkboxes hidden) inside a bounded scroll container (`max-height:300px; overflow-y:auto`). Rendered only when `noReviewCount > 0` (per user: nothing shown at zero).
2. [DITStareCompareCmpController.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpController.js#L101) — `toggleNoReview` handler flips `v.showNoReview`.
3. [DITStareCompareCmpHelper.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L331) — new `buildNoReviewTable(cmp, defaultConfirmed, newContactData)`: exact-match rows use the matched BRM Contact's values (HYPERLINK First/Last Name via Contact Id), new-contact rows use the imported Excel values; built via `formatDataToDisplayInTable` + `v.columns` (the exact Undo/"Potential Duplicate From BRM" headers/order); deduped by Contact Id. `setContactList` collects `newContactData` (no-candidate rows) and calls it ([line 502](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L502)); sets `noReviewCount = defaultConfirmed.length + newContactData.length`.

**BRME-4425 comments** added at each changed location. BRME-7012's `prepareResult` change untouched.

**Deployment & tests**

- Dry-run validated clean (caught + fixed a dropped `for` header), then deployed `DITStareCompareCmp` with `RunSpecifiedTests -t DITCmpControllerTest`.
- Verified via org `DeployRequest 0Afbc00000DEMVpCAP`: **Succeeded, 0 component errors, 1 component, 18/18 tests passed, 0 test errors**. (CLI printed the known cosmetic `locale en_US` error; org result is authoritative.)

**Validation**

- Fixture classification pre-verified against live org data ([setup/brme4425-classification-precheck.apex](BRME-4425/setup/brme4425-classification-precheck.apex)): 3 exact matches, mixed = 2 exact + 1 review + 1 new, zero file = 2 review.
- Live UI spot-check (automated browser): zero-no-review load correctly shows **"0 Contact(s) Require No Review"** with **no toggle** (per the zero-count decision).
- Full visual confirmation (expand shows the 3 exact matches; mixed shows Alice/Brendan/Derek) is the user's — automated browser can't clear the DIT loading spinner (static resources blocked → web worker dead), same limitation as BRME-7012.

**Remaining limitations**

- Table is read-only (no selection/actions) — matches "visibility only" scope.
- No-review list is computed at stage load; it does not change as review rows are confirmed (those stay in the review list by design).

## 12. Open questions and assumptions

**Resolved with the user (2026-10-23)**

1. **Which table to mirror** — the **"Potential Duplicate From BRM"** table on the Compare stage (the `c:MyTable` `multipleDupes` table shown with "Excel Field Values" when there are multiple matches). Confirmed by the user's screengrab (2026-10-23) showing headers: Contact Alert Reason, First Name, Middle Name, Last Name, Preferred First Name, Title, Organization Name, Business Email, Personal Email, Additional Email. The new no-review table mimics that table's headers/order/formatting, but is **collapsible**. → use `v.columns` (16 columns) + `c:MyTable` + `formatDataToDisplayInTable`. User: "feel free to improvise as you see best" on presentation.
2. **Zero-count** — "just like current, don't show anything on the top anywhere": when the count is 0, do **not** render the section/toggle at all (count text stays as today; no empty table). When count > 0, show the collapsible section, initially collapsed.
3. **Test depth** — appearance-only, no logical/process changes: verify by manual UI acceptance; keep `DITCmpControllerTest` green; no new Jest harness.

**Assumptions**

- "Requires no review" = auto-confirmed exact matches + no-candidate (new) rows, per the helptext + code. Manually confirmed contacts excluded.
- The table is read-only (visibility only).
- Displaying the no-review rows does not change how they're imported (exact matches → update existing; new → create).
