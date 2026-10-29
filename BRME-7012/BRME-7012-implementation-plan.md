# BRME-7012 — Implementation Plan (Phase 1: investigation complete, awaiting approval)

**Ticket:** DIT — Compare Potential Duplicates should match imported First Name against existing Contact First Name **OR** Preferred First Name, combined with Last Name.

**Status:** Phase 2 implemented and deployed to dev2Current. Awaiting final user UI confirmation.

---

## 1. Requirement and acceptance criteria

At DIT's **Compare Potential Duplicates** stage, an imported row must flag an existing BRM Contact when:

- imported First Name == existing `Contact.FirstName` **and** Last Name matches; **or**
- imported First Name == existing `Contact.Preferred_First_Name__c` **and** Last Name matches.

**Acceptance criteria**

1. Single-row upload: imported `Patti / <LastName>` with blank Business Email flags existing `Patricia / pref=Patti / <LastName>` as a potential duplicate (no email required).
2. All valid candidates are returned: if both `Patricia (pref=Patti)` and an exact `Patti` Contact exist with that Last Name, **both** appear as candidates. No candidate is replaced, auto-merged, or auto-selected away.
3. Each upload row is matched independently — one row's email is never required for another row's preferred-name match.
4. Existing behavior preserved: email matching (`Email`, `Alternate_Email__c`, `Business_Email_2__c`, `Personal_Email_2__c`), exact first-name matching, UUID matching, the review/import workflow, and candidate lists deduped by Contact Id.
5. No fuzzy matching introduced; case/whitespace semantics stay as today (SOQL `LIKE` = case-insensitive exact; JS keys trimmed/lowercased).

## 2. Org, branch, and inspected components

| Item | Value |
|---|---|
| Org alias | `dev2Current` |
| Instance | `https://bbrm--dev2.sandbox.my.salesforce.com` (**sandbox** — confirmed via `sf org display` 2026-10-23) |
| User | hkalathiya@bloomberg.org.dev2 |
| Branch | **None — this workspace is not a git repository** (no `.git` found at `Dev2Current` or any parent). Version control location is an open question (§11). |

**Org ↔ repo drift check:** retrieved `ApexClass:DITCmpController`, `AuraDefinitionBundle:DITStareCompareCmp`, `StaticResource:DITWorker` from the org into `other-org/retrieve-brme7012/` — MD5-identical to the workspace copies. **The repo code is what is deployed.**

Inspected components:

- Aura bundle: `DITCmp` (stage shell), `DITLoadCmp` (upload), `DITSetupCmp` (column mapping), `DITValidationCmp` (preview/validation), `DITConfirmRecords` (review errors), `DITConfirmValue`, `DITStareCompareCmp` (**Compare Potential Duplicates**), `DITCreateCmp` (import).
- Apex: `DITCmpController.cls` (+ `DITCmpControllerTest.cls`), `DataLoadRecordTriggerHandler.cls`, `SpecialCharactersHelper.cls`, `ContactTriggerHandler.cls` (populates `Converted_*` on Contact, lines 982–984).
- Static resource: `DITWorker.js` (web worker: parse, validate, `getContacts`).
- Objects: `Data_Load__c`, `Data_Load_Record__c` (+ field sets `Data_Import_Fields`, `Data_Import_Required_Fields`).

## 3. Verified field API names (from org Tooling API `FieldDefinition`, 2026-10-23)

**Contact**

| API name | Label | Type |
|---|---|---|
| `Email` | **Business Email** | Email |
| `Preferred_First_Name__c` | Preferred First Name | Text(40) |
| `Preferred_Last_Name__c` | Preferred Last Name | Text(80) |
| `Converted_FirstName__c` / `Converted_LastName__c` | Converted FirstName / LastName | Text(255), set by Contact trigger |
| `Converted_Full_Name__c` | Converted Full Name | Formula (Text) — **concatenation with NO space** (verified: `PatriciaEHarris` for "Patricia E. Harris"; `PattiBRME7012Test` for our record) |
| `FirstName_LastName__c` | FirstName LastName | Formula (Text) — space-joined |
| `Alternate_Email__c` | Personal Email | Email (External ID) |
| `Business_Email_2__c` | Additional Email | Email (External ID) |
| `Personal_Email_2__c` | Confidential Email | Email (External ID) |
| `Web_Email__c` | Web: Email | Email (External ID) |
| `UUID__c` | UUID | Text(255), External ID, unique, case-insensitive |

**Data_Load_Record__c** (import staging object): `First_Name__c` "First Name" Text(50), `Last_Name__c` "Last Name" Text(50), `Preferred_First_Name__c` "Preferred First Name" Text(50), `Business_Email__c` "Business Email" Email, `Converted_FirstName__c`/`Converted_LastName__c` Text(255) (trigger-set), `Converted_Full_Name__c` Formula = `TRIM(Converted_FirstName__c & " " & … & Converted_LastName__c)` (**space-joined**), `UUID__c`, `Contact_ID__c`, `Contact_Data__c`, `IsConfirmed__c`, `Row_Index__c`, `Excel_Row__c`.

Note the asymmetry: Contact's converted full name is space-less; DLR's is space-joined. This matters for the key analysis below.

## 4. Current execution flow (Compare Potential Duplicates stage)

Stage `contact`, component `DITStareCompareCmp`:

1. `init` → `loadData` ([DITStareCompareCmpHelper.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L209)):
   `getColumns` → `loadPreviewData` (DLR rows) → worker `validate` → worker `getContacts`.
2. **Worker `ContactWorker.getContactMap`** ([DITWorker.js](force-app/main/default/staticresources/DITWorker.js#L81-L137)): builds one entry per upload row keyed by `normalize(firstName + lastName)` and `normalize(Converted_Full_Name__c)` where `normalize` = lowercase + **strip ALL whitespace**. → keys like `pattiharris`. **Identical-name rows overwrite each other (last row wins).**
3. **Apex `getDupes` → `getDupeContactList`** ([DITCmpController.cls](force-app/main/default/classes/DITCmpController.cls#L914-L980)): ONE batch-wide SOQL over the whole file. Name branches (verified present in org):
   - `(Converted_FirstName__c LIKE :firstNames OR Preferred_First_Name__c LIKE :firstNames) AND Converted_LastName__c LIKE :lastNames` (line 969)
   - `(FirstName LIKE :firstNames OR Preferred_First_Name__c LIKE :firstNames) AND LastName LIKE :lastNames` (line 973)
   plus email branches (`Personal_Email_2__c`, `Business_Email_2__c`, `Alternate_Email__c`, `Email IN :emails`), `Name`/`Converted_Full_Name__c IN :ConvertedFullName`, and `UUID__c IN :uuids`. `LIMIT 10000`.
   → **Candidate retrieval already includes Preferred First Name.** Verified live: probe ([scripts/brme7012-probe.apex](scripts/brme7012-probe.apex)) with `firstNames={'Patti'}`, `lastNames={'Harris'}` returned Patricia Harris (pref=Patti) in the org today. `LIKE` with a `Set<String>` bind works (acts as OR; case-insensitive).
4. **`prepareResult`** ([DITStareCompareCmpHelper.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L751)): re-keys the flat SF candidate list under row-lookup keys:
   - by candidate's own `Converted_Full_Name__c` / `Converted_FirstName__c+Converted_LastName__c` (only helps exact-name matches),
   - by **email attribution**: for each row entry, if the row's `Business_Email__c` equals any of the candidate's 4 email fields, the candidate is filed under **that row's** `Converted_Full_Name__c` key (space preserved, e.g. `patti harris`),
   - by UUID, and finally the **preferred-name block** (lines 820–834).
5. **`setContactList`** ([DITStareCompareCmpHelper.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L328)): per row, reads ONLY `result[fullNameKey]` (row's space-joined converted full name, trimmed, lowercased) and `result[firstLastNameKey]` (row's trimmed-concatenated first+last, lowercased), unions and dedups by Id → `contact.sfContacts`. Duplicates modal / auto-select then run through the permissive `filterDup` ([line 2](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L2)).

## 5. Root cause (evidence-backed)

**Preferred-name candidates are retrieved from the database but silently dropped during client-side row assignment.**

The dedicated preferred-name block in `prepareResult` (lines 820–834):

```js
let preferredNameKey = (contactRecord.Preferred_First_Name__c + '-' + contactRecord.LastName).toLowerCase(); // "patti-harris"
if (contactMap[preferredNameKey]) { … }
```

1. The guard `contactMap[preferredNameKey]` can **never** be true: the worker only creates whitespace-stripped concatenated keys (`pattiharris`) and converted-full-name keys — never hyphenated `pref-last` keys. **The block is dead code.**
2. Even if it fired, it files the candidate under `patti-harris`, a key `setContactList` never reads (it reads `patti harris` and `pattiharris`).
3. No other path can surface a preferred-name-only match: the exact-name paths key by the candidate's OWN names (`patriciabrme7012test` ≠ row keys), and the email/UUID paths need an email/UUID match.

**Why the single-row case fails:** Patricia is returned by the SOQL (preferred-name branch) → `prepareResult` cannot file her under any key the row reads → row shows no Patricia. ✅ matches report #1.

**Why the two-row case flags Patricia for both rows:** the worker map collapses identical-name rows (last wins → the row **with** the email); the email-attribution loop files Patricia under the shared row key `patti harris`; **both** rows read that key. ✅ matches report #2. Cause: shared name keys + email attribution in the client — **not** shared Apex state, caching, or batch state (the Apex is stateless per call).

**Ticket screenshots cross-check (user-provided, 2026-10-23):**
1. Review screen for the single-row file shows BRM candidate = **exact-name "Patti Harris" (Mayor, City of Barrington)** only — Patricia absent → matches the predicted drop.
2. Two-row file (`Patti Harris` ×2; row 2 email `patti@bloomberg.org.invalid`).
3. "Select a duplicate" modal from the two-row file lists **"Patricia E. Harris" (Preferred First Name `Patti`, CEO, Bloomberg Philanthropies, `patti@bloomberg.org.invalid`)** + **"Patti Harris" (Mayor)** for the blank-email row → confirms the email-attribution path, and confirms `Preferred_First_Name__c` is already in the `getDupes` SELECT (the modal's Preferred First Name column is populated) → no SOQL change needed.
4. Single-row file (`Patti Harris`, all else blank).

Secondary latent issue (out of scope, noted): `DITCmpController.getContactMap` (line 1379, Review Errors stage auto-link) queries `Preferred_First_Name__c IN :firstNames` but keys results by `Converted_FirstName__c`, so a preferred-name match is keyed under the wrong name there too. Compare stage does not use it.

## 6. Proposed changes (Phase 2 — smallest justified fix)

### DIT component touch map (full inventory per user's deploy screenshot 2026-10-23)

| Component | Type | Touched? | Why |
|---|---|---|---|
| `DITStareCompareCmp` | AuraDefinitionBundle | **YES** | `prepareResult` preferred-name keying fix (helper JS only) |
| `DITCmpControllerTest` | ApexClass | **YES** | New regression tests pinning the `getDupes` retrieval contract |
| `DITCmpController` | ApexClass | No | Retrieval SOQL already matches `Preferred_First_Name__c` (verified live) |
| `DITWorker` | StaticResource | No | Row keys already correct (`pattiharris`-style); no change needed |
| `DITCmp` / `DITLoadCmp` / `DITSetupCmp` / `DITValidationCmp` / `DITConfirmRecords` / `DITConfirmValue` / `DITCreateCmp` | AuraDefinitionBundle | No | Upload/mapping/preview/review/import stages unaffected |

### Change detail

**File: `force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js`, method `prepareResult`** — replace the dead preferred-name block (lines 820–834) with logic that:

1. Skips when `Preferred_First_Name__c` is blank, when `FirstName == Preferred_First_Name__c` (already covered by the exact path), or when the candidate was already filed (`isDuplicateFound`) — same guards as today.
2. Computes the key with the **worker's normalization**: `(Preferred_First_Name__c + LastName)` lowercased, all whitespace stripped → e.g. `pattibrme7012test`.
3. Looks up `contactMap[thatKey]`; on hit, files the candidate under the **row's real lookup keys** — `firstLastNameKey` (trim-concat-lowercase of the matched row's `First_Name__c`/`Last_Name__c`) and `fullNameKey` (trimmed lowercase `Converted_Full_Name__c`) — deduped by Contact Id.
4. Concise comment referencing **BRME-7012** explaining the business reason (preferred name is an alternate first name for matching).

**No Apex changes required for retrieval** — the SOQL already matches `Preferred_First_Name__c` (both raw and converted branches).

**No `filterDup` change required** — verified permissive: clause 1 passes all candidates when UUID is unmapped/blank; clause 3 (`rec.Converted_Full_Name__c && excelCont.Converted_Full_Name__c`, truthy) passes otherwise. Will be validated manually in before/after checks.

## 7. Candidate retrieval vs row-level matching considerations

- Retrieval is **batch-wide by design** (sets unioned across rows); row-level precision happens in `prepareResult`/`setContactList`. The fix keeps this design — preferred-name candidates are *retrieved* batch-wide but *filed per matching row key*, so a row only sees candidates whose preferred-name+last-name pair matches **its own** first+last name.
- Same-name rows share lookup keys (existing behavior; the two-row clue). After the fix, identical-name rows each see the preferred-name candidate — consistent with the ticket (both rows should see Patricia) and with today's email behavior.
- "Return all valid candidates without duplicate Contact IDs": `setContactList` already unions both key lists and dedups by Id (line ~365); the fix preserves that.
- No auto-merge/auto-select changes: single-candidate auto-select (`showDupTable`/`filterRecords.length == 1`) behaves as before; with multiple candidates the modal lists all.

## 8. Preservation of existing behavior

- Email matching: untouched (SOQL email branches + email-attribution loop unchanged). Regression workbook row R4 proves `Alternate_Email__c` matching still works.
- Exact first-name matching: untouched; covered by regression rows R1/R5 and new Apex tests.
- Sharing/security: `getDupes` runs in the `with sharing` class without `WITH SYSTEM_MODE` on this query — unchanged. No new fields exposed; `Preferred_First_Name__c` is already selected by `getDupeContactList`? — verified: it is referenced in WHERE but **not** in the SELECT field list; the fix needs the value client-side, so the SELECT must include it. **Check in Phase 2:** `getDupeContactList` builds SELECT from `columnMap` values + a hardcoded set; `Preferred_First_Name__c` is added to `fields` only if the column map contains it (`DITStareCompareCmpController.columnMap` includes `Preferred_First_Name__c: "Preferred_First_Name__c"` — columnMap keys are DLR apis; `columnMap.keySet()` values are Contact fields, and `Preferred_First_Name__c` IS among the values). Verified present → no SOQL change needed. (Will re-verify in Phase 2 tests.)
- The review/import workflow, validation stage, and Review Errors stage are untouched.

## 9. Bulk processing and governor limits

- Fix is client-side JS only: **zero** new SOQL/DML. Compare stage today: 1 candidate SOQL (LIMIT 10000) per load + row CRUD as before.
- `prepareResult` loops candidates × row-keys; with ≤10000 candidates and typical ≤200-row files (DIT's own guidance), worst case ~2M cheap key comparisons client-side — same order as today's email loop. No new complexity class introduced.
- `createNewExcelRows`/`updateRecords` batch at 50 rows server-side — unchanged.

## 10. Test-data inventory and baseline instructions

See [README.md](BRME-7012/README.md) for full steps. Summary:

- **Baseline Contacts created in dev2** (synthetic, `.invalid` emails, marked `Description = 'BRME-7012 synthetic test data'`): IDs and values in [setup/record-manifest.md](BRME-7012/setup/record-manifest.md). Creation script: [setup/brme7012-create-baseline-contacts.apex](BRME-7012/setup/brme7012-create-baseline-contacts.apex). Cleanup: [setup/brme7012-cleanup.apex](BRME-7012/setup/brme7012-cleanup.apex) (deletes only those 4 IDs).
- **DIT upload workbooks** (real `.xlsx`, sheet `Sheet1`, 32-column template mirrored from the user's real upload file `C:\Users\Hardik\Downloads\Preferred First Name DIT Test.xlsx`; headers auto-map by field label): [test-data/](BRME-7012/test-data/)
  1. `BRME-7012-single-row-preferred-name.xlsx` — single-row repro.
  2. `BRME-7012-two-row-email-clue.xlsx` — two-row clue repro.
  3. `BRME-7012-regression.xlsx` — 6 rows: preferred+exact multi-candidate, uppercase first name (case), no-match last name (negative), email-regression via Alternate Email, exact-name with blank preferred on the existing Contact, trailing-space first name (whitespace).
- Existing real Contacts `Patricia Harris` (003bc000014Q78UAAS), `Patti Harris` (003bc000018J8PlAAK / …8PmAAK) left untouched; synthetic data uses `BRME7012Test`/`BRME7012Email` last names to avoid collision.
- Rows are **not** pre-inserted as Contacts — the user uploads them through DIT.
- DIT accepts `.xlsx/.xlsm/.csv` (SheetJS/PapaParse), first sheet only; fully-empty rows skipped, **no dedup of identical rows**; auto-mapping matches Excel headers to DLR field labels case-insensitively; only `Last Name` is required.

## 11. Proposed automated tests and manual checks (Phase 2)

**Apex (`DITCmpControllerTest`)** — new methods with correctly-constructed data (existing `tesgetDupes` passes shifted args to `createContact(title, firstName, lastName, email, …)` and asserts 0 — too weak to catch regressions):

1. `testGetDupesPreferredFirstName` — row (Patti/X, no email) vs Contact (Patricia, pref Patti, X) → candidate list contains Patricia. *(Would also pass pre-fix: retrieval already works — it guards against SOQL regressions.)*
2. `testGetDupesExactFirstNamePreserved` — row (Patti/X) vs Contact (Patti/X).
3. `testGetDupesMultipleCandidates` — both Contacts returned for one row.
4. `testGetDupesDifferentLastNameNegative` — no match without email.
5. `testGetDupesEmailMatchingPreserved` — row email vs Contact `Alternate_Email__c`.
6. `testGetDupesBlankPreferredName` — blank preferred never matches/never errors.

> Note: the actual bug lives in Aura JS (`prepareResult`); Apex tests can only pin the retrieval contract. The repo's Jest setup (`sfdx-lwc-jest`) covers `lwc/**` only — no Aura harness. Row-assignment verification is manual (below) unless we add a one-off Jest config (open question §12).

**Manual before/after (dev2):**

| Workbook | Before fix (baseline) | After fix |
|---|---|---|
| single-row | Patricia **absent**; Patti BRME7012Test present | Patricia **present** + Patti present |
| two-row | both rows flag Patricia + Patti (via email bleed) | same display — mechanism now independent per row |
| regression R1 | only Patti | Patricia + Patti |
| R2 `PATTI` | only Patti (case-insensitive) | Patricia + Patti |
| R3 `BRME7012Nomatch` | none | none |
| R4 email→Alternate | Randy flagged | unchanged |
| R5 Bob exact | Bob only | unchanged |
| R6 `Patti ` trailing space | Patti only | Patricia + Patti |

Also: confirm candidates deduped by Id; confirm single-candidate auto-confirm path unchanged; confirm Confirm/Import completes.

## 12. Deployment and rollback (Phase 2)

- Per repo practice: `sf project deploy start --source-dir force-app/main/default/aura/DITStareCompareCmp --dry-run -o dev2Current` first; then real deploy of the Aura bundle (+ test class) with `--test-level RunSpecifiedTests -t DITCmpControllerTest`; verify via org `DeployRequest` (CLI exit code/output not trusted — known cosmetic `locale en_US` failure).
- No production deploy.
- Rollback: workspace is **not under git**; the pristine deployed copies retrieved 2026-10-23 live in `other-org/retrieve-brme7012/unpackaged/` and can be redeployed to revert.

## 14. Final implementation (Phase 2 — completed 2026-10-23)

**Changed files**

1. [DITStareCompareCmpHelper.js](force-app/main/default/aura/DITStareCompareCmp/DITStareCompareCmpHelper.js#L826-L855) — `prepareResult`: replaced the dead hyphen-key preferred-name block with logic that keys by the worker's normalization `(pref+last).toLowerCase().replace(/\s+/g,'')` and files the candidate under the matching row's real lookup keys (`firstLastNameKey` + `fullNameKey`), deduped by Contact Id. Includes a BRME-7012 comment explaining the business reason (Preferred First Name is an alternate first name for matching).
2. [DITCmpControllerTest.cls](force-app/main/default/classes/DITCmpControllerTest.cls#L296-L417) — 6 new tests + 2 helpers pinning the `getDupes` retrieval contract: preferred-first-name match, exact-name preserved, multiple candidates (no replacement, no duplicate IDs), different-last-name negative, email matching preserved (via `Alternate_Email__c`), blank preferred name never matches.

**No changes** to `DITCmpController` (SOQL already matched preferred names), `DITWorker`, or any other DIT stage component.

**Deployment & tests**

- Dry-run validated clean, then deployed `DITStareCompareCmp` + `DITCmpControllerTest` with `RunSpecifiedTests -t DITCmpControllerTest`.
- Verified via org `DeployRequest` `0Afbc00000DEKaTCAX`: **Succeeded, 0 component errors, 2 components, 18/18 tests passed, 0 test errors**.

**Validation**

- Server-side pre-fix evidence: [setup/brme7012-baseline-evidence.apex](BRME-7012/setup/brme7012-baseline-evidence.apex) — retrieval already returned Patricia for the single-row file (2 rows).
- Post-fix logic verification (executed the deployed `prepareResult` keying against live data shapes in the browser): single-row visible candidates = **Patricia (pref=Patti) + Patti**; two-row → both rows = **Patricia + Patti**, deduped by Id.
- UI: automated browser hit an LWS/static-resource wall driving the duplicates modal; final visual confirmation is the user's (see README §5).

**Remaining limitations**

- The exact-name candidate is listed first (existing ordering unchanged); the user picks between candidates in the modal — no auto-merge, as required.
- Same-name rows share worker keys, so identical-name rows each see the same candidate set (pre-existing design; unchanged).
- Review Errors stage contact auto-link gap left out of scope (verified unused by that stage's UI).

## 13. Open questions and assumptions

**Resolved with the user (2026-10-23)**

1. **Review Errors stage scope** — user asked about the impact of NOT fixing it. Verified: the `contacts` map produced by `getContactMap` ([DITCmpController.cls](force-app/main/default/classes/DITCmpController.cls#L1379)) is **never consumed** by the Review Errors UI — `DITConfirmRecords` only uses `result.orgs` for organization resolution ([DITConfirmRecordsHelper.js](force-app/main/default/aura/DITConfirmRecords/DITConfirmRecordsHelper.js#L57-L117)); `contacts` appears only in a `console.log`. So skipping it has **no user-facing impact today**; Compare Potential Duplicates is the only place contact candidates are shown. **Decision: out of scope** (no behavior change there; can be cleaned up separately later).
2. **Version control** — none. Local VS Code workspace + the dev2 org only. Proceed with local edits; rollback = redeploy the pristine retrieved copies in `other-org/retrieve-brme7012/unpackaged/` (§12).
3. **Test strategy** — after changes: run Apex tests; attempt browser-driven UI testing with Playwright; if file upload / multi-stage navigation proves unreliable, hand over to the user for manual testing while I inspect logs. No new Jest harness for Aura.
4. **DIT navigation** — confirmed: `https://bbrm--dev2.sandbox.lightning.force.com/lightning/n/Data_Import2`.

**Two-row display note (business confirmation still welcome)**

5. Two-row post-fix display will look identical to pre-fix (both rows show both candidates) — the change is the *mechanism* (row 1 matches via preferred name, independent of row 2's email). Assumed acceptable per ticket text ("both matching Contacts should remain available as candidates").

**Assumptions**

- "Business Email" = standard `Contact.Email` / DLR `Business_Email__c` (label-verified).
- Matching remains case-insensitive exact (LIKE semantics); no fuzzy matching introduced.
- Sandbox `dev2Current` is the correct test org (ticket's dev sandbox).
- Observed during baseline Contact creation: `ContactTriggerHandler` after-insert logged one non-blocking error event via `BBApps_ErrorHandler` (inserts succeeded, all fields populated). Pre-existing trigger noise — no action unless the user objects.
