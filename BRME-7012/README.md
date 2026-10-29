# BRME-7012 — DIT Compare Potential Duplicates: Preferred First Name matching

**Status: Phase 2 implemented & deployed to dev2Current (2026-10-23).** Final UI confirmation pending (see §5).

> **DIT: Compare Potential Duplicates should match imported First Name against existing First Name OR Preferred First Name, combined with Last Name.**

- Implementation plan (root cause + proposed fix): [BRME-7012-implementation-plan.md](BRME-7012-implementation-plan.md)
- Baseline record values + Salesforce IDs: [setup/record-manifest.md](setup/record-manifest.md)
- Org: **dev2Current** sandbox (`https://bbrm--dev2.sandbox.my.salesforce.com`) — confirmed sandbox.

## 1. Record setup (already done — 2026-10-23)

Four synthetic Contacts were created in the sandbox (script: [setup/brme7012-create-baseline-contacts.apex](setup/brme7012-create-baseline-contacts.apex)):

| ID | Name | Preferred First Name | Emails | Role |
|---|---|---|---|---|
| `003bc000018JAY2AAO` | Patricia BRME7012Test | **Patti** | patricia.brme7012@brme7012.invalid | preferred-name candidate |
| `003bc000018JAY3AAO` | Patti BRME7012Test | — | patti.brme7012@brme7012.invalid | exact-name candidate |
| `003bc000018JAY4AAO` | Bob BRME7012Test | — | bob.brme7012@brme7012.invalid | blank-preferred control |
| `003bc000018JAY5AAO` | Randy BRME7012Email | — | randy.brme7012@brme7012.invalid / alt: randy.alt.brme7012@brme7012.invalid | email regression |

To re-create them (e.g. after a sandbox refresh): `sf apex run -o dev2Current -f BRME-7012/setup/brme7012-create-baseline-contacts.apex` — then update the IDs in the manifest.

## 2. DIT upload files

In [test-data/](test-data/) — real `.xlsx`, first sheet `Contacts`, headers auto-map to DIT fields by label:

| File | Rows | Purpose |
|---|---|---|
| `BRME-7012-single-row-preferred-name.xlsx` | 1 | Single-row reproduction |
| `BRME-7012-two-row-email-clue.xlsx` | 2 | Two-row reproduction of the reported clue |
| `BRME-7012-regression.xlsx` | 6 | Regression scenarios R1–R6 |

Headers used: the exact 32-column DIT template mirrored from the real upload file `C:\Users\Hardik\Downloads\Preferred First Name DIT Test.xlsx` (2026-10-23): `Salutation, First Name, Middle Name, Last Name, Suffix, Preferred First Name, Title, Company, Business Email, Personal Email, Additional Email, Business Phone (Country Code), Business Phone, Mobile Phone (Country Code), Mobile Phone, Additional Phone (Country Code), Additional Phone, Business Street Address 1/2/3, Business City, Business State, Business Postal Code, Business Country, Home Street Line1/2/3, Home City, Home State, Home Postal Code, Home Country, Notes␣` (sheet `Sheet1`; only the First Name / Last Name / Preferred First Name / Business Email columns are populated; all other cells blank). Only `Last Name` is a required DIT column. Rows:

> The user's example file (`Patti Harris`, everything else blank) is itself the single-row repro against the **real** Harris contacts (`003bc000014Q78UAAS` Patricia / `003bc000018J8PlAAK` + `003bc000018J8PmAAK` Patti). The workbooks here reproduce the same scenarios against the **synthetic** `BRME7012Test` records so the real Contacts are never touched.

| File / row | First Name | Last Name | Preferred First Name | Business Email |
|---|---|---|---|---|
| single-row R1 | Patti | BRME7012Test | — | — |
| two-row R1 | Patti | BRME7012Test | — | — |
| two-row R2 | Patti | BRME7012Test | — | patricia.brme7012@brme7012.invalid |
| regression R1 | Patti | BRME7012Test | — | — |
| regression R2 | PATTI | BRME7012Test | — | — |
| regression R3 | Patti | BRME7012Nomatch | — | — |
| regression R4 | Randall | BRME7012Email | — | randy.alt.brme7012@brme7012.invalid |
| regression R5 | Bob | BRME7012Test | — | — |
| regression R6 | `Patti ` (trailing space) | BRME7012Test | — | — |

To regenerate: `cd BRME-7012/tooling && npm install && node make-xlsx.js`.

## 3. Upload / mapping steps (each workbook)

1. Open the **Data Import Tool** in the dev2 sandbox: `https://bbrm--dev2.sandbox.lightning.force.com/lightning/n/Data_Import2` (confirmed with the user 2026-10-23).
2. **Upload File** stage → choose the workbook → Next. (DIT accepts `.xlsx/.xlsm/.csv`; reads the first sheet; max ~200 rows recommended.)
3. **Map Columns** stage → headers auto-map by field label (`First Name`→First_Name__c, `Last Name`→Last_Name__c, `Preferred First Name`→Preferred_First_Name__c, `Business Email`→Business_Email__c). Verify all four are mapped; Next.
4. **Preview** stage → no errors expected (all values valid; only Last Name is required). Next.
5. **Review Errors** stage → no errors expected; Next.
6. **Compare Potential Duplicates** stage → observe the candidates each row flags. **This is the stage under test.**
7. Do **not** complete Import unless you intend to create contacts; to abandon, note the `Data_Load__c` record created (DIT lists previous loads) and delete it during cleanup.

## 4. Baseline reproduction (current, pre-fix behavior)

| Workbook | Expected baseline (bug) behavior |
|---|---|
| single-row | Row flags **only Patti BRME7012Test (C2)**. **Patricia (C1) is missing** — this is the bug. |
| two-row | **Both** rows flag Patricia (C1) + Patti (C2) — row 1 gets Patricia only via row 2's email through the shared name key (see plan §5). |
| regression | R1: C2 only. R2: C2 only (case-insensitive). R3: none. R4: C4 via email. R5: C3 only. R6: C2 only. |

## 5. Post-fix UI verification (please run — fix is deployed)

The fix is live in dev2Current. Please confirm visually in your browser:

1. **Single-row** (`BRME-7012-single-row-preferred-name.xlsx`, or the in-progress load `a06bc00000NiZOEAA3`): at Compare Potential Duplicates, click the row → the duplicates list must show **both** `Patricia BRME7012Test` (Preferred First Name `Patti`) **and** `Patti BRME7012Test`. Pre-fix only Patti appeared.
2. **Two-row** (`BRME-7012-two-row-email-clue.xlsx`): both rows list Patricia + Patti.
3. **Regression** (`BRME-7012-regression.xlsx`): R1/R2/R6 → Patricia + Patti; R3 (`BRME7012Nomatch`) → none; R4 → Randy via email; R5 → Bob only.

Expected candidate recap:

| Workbook / row | Expected candidates (post-fix) |
|---|---|
| single-row | **C1 (Patricia, via Preferred First Name) + C2 (Patti, exact)** — no email needed |
| two-row R1 & R2 | both rows: C1 + C2 (row 1 now matches independently of row 2's email) |
| regression R1 | C1 + C2 |
| regression R2 (`PATTI`) | C1 + C2 (case-insensitive) |
| regression R3 (`BRME7012Nomatch`) | none |
| regression R4 | C4 (email via Alternate Email) |
| regression R5 (Bob) | C3 only |
| regression R6 (`Patti ` + trailing space) | C1 + C2 |

In all cases: no duplicate Contact IDs, no auto-merge — multiple candidates remain selectable.

## 6. Cleanup

1. Delete any `Data_Load__c` records created by the test uploads (DIT "previous data loads" list; deleting the load cascades to its `Data_Load_Record__c` rows).
2. Delete the 4 baseline Contacts:
   `sf apex run -o dev2Current -f BRME-7012/setup/brme7012-cleanup.apex`
   (deletes only the IDs in the manifest; aborts on any unexpected record.)
3. Pre-existing real Contacts (Patricia/Patti Harris, manifest §"Pre-existing") are **not** part of cleanup.

## 7. Investigation artifacts

- Org-vs-repo retrieved copies (drift check): `other-org/retrieve-brme7012/`
- Read-only probes: `scripts/brme7012-probe.apex` (LIKE-set semantics + existing Harris records), `scripts/brme7012-probe2.apex` (Converted_Full_Name__c composition)
- Workbook generator: [tooling/make-xlsx.js](tooling/make-xlsx.js)
