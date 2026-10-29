# BRME-4425 — DIT "Require No Review" expandable table

**Status: Phase 2 implemented, deployed & user-verified in dev2Current (2026-10-23).** The collapsible no-review table renders correctly (mixed load: Alice/Brendan/Derek shown expanded, Carla in review).

> **Display contacts that require no review in an expandable/collapsible table at Compare Potential Duplicates.**

- Implementation plan: [BRME-4425-implementation-plan.md](BRME-4425-implementation-plan.md)
- Baseline record IDs: [setup/record-manifest.md](setup/record-manifest.md)
- Org: **dev2Current** sandbox (`https://bbrm--dev2.sandbox.lightning.force.com/lightning/n/Data_Import2`).

## 1. Record setup (already done — 2026-10-23)

Three synthetic Contacts created in the sandbox (script: [setup/brme4425-create-baseline-contacts.apex](setup/brme4425-create-baseline-contacts.apex)):

| ID | Name | Email | Role |
|---|---|---|---|
| `003bc000018J9ykAAC` | Alice BRME4425Exact | alice.brme4425@brme4425.invalid | exact-match target |
| `003bc000018J9ylAAC` | Brendan BRME4425Exact | brendan.brme4425@brme4425.invalid | exact-match target |
| `003bc000018J9ymAAC` | Carla BRME4425Exact | carla.brme4425@brme4425.invalid | exact-match / review target |

To re-create after a refresh: `sf apex run -o dev2Current -f BRME-4425/setup/brme4425-create-baseline-contacts.apex`, then update the IDs in the manifest.

## 2. DIT upload files

In [test-data/](test-data/) — real `.xlsx`, sheet `Sheet1`, 32-column DIT template (headers auto-map by field label). Only `First Name`, `Last Name`, `Business Email` are populated.

| File | Rows | Expected classification (verified vs live org data) |
|---|---|---|
| `BRME-4425-exact-matches.xlsx` | Alice / Brendan / Carla BRME4425Exact (matching emails) | 3 **no-review** (exact matches) |
| `BRME-4425-mixed.xlsx` | Alice + Brendan (exact) · Carla (email differs) · Derek BRME4425New | 3 **no-review** (2 exact + 1 new) + 1 **review** (Carla) |
| `BRME-4425-zero-no-review.xlsx` | Alice + Brendan (exact name, different emails) | 0 **no-review** + 2 **review** |

To regenerate: `node BRME-4425/tooling/make-xlsx.js`.

## 3. Upload / mapping steps (each workbook)

1. Open DIT: `https://bbrm--dev2.sandbox.lightning.force.com/lightning/n/Data_Import2`
2. **Upload File** → choose the workbook → Next.
3. **Map Columns** → headers auto-map; verify `First Name`, `Last Name`, `Business Email` mapped → Next (accept "Not all fields mapped" warning → Yes).
4. **Preview** → no errors (Last Name present on all rows) → Next.
5. **Review Errors** → no org/contact errors expected → Next.
6. **Compare Potential Duplicates** → observe the "**N Contact(s) Require No Review**" count and the review list. This is the stage under test.

## 4. Baseline (current, pre-change) behavior

- The no-review **count is shown but there is no way to see which contacts they are** — the rows never appear in the review list.
- exact-matches → count = 3, review list empty.
- mixed → count = 3, review list shows only **Carla BRME4425Exact**.
- zero-no-review → count = 0, review list shows **Alice + Brendan**.

## 5. Expected results after the change

- A collapsed "**N Contact(s) Require No Review**" section appears; expanding it lists exactly those contacts using the Compare duplicates table's 16 columns (Contact Alert Reason, First Name, …, UUID).
- exact-matches → expand shows Alice, Brendan, Carla.
- mixed → expand shows Alice, Brendan, Derek; Carla remains in the review list.
- zero-no-review → header shows 0, no rows.
- Count and table always agree; collapse hides it again.

## 6. Cleanup

1. Delete any `Data_Load__c` records created by the test uploads (DIT "Load an in progress file" list; deleting the load cascades to its rows).
2. Delete the 3 baseline Contacts: `sf apex run -o dev2Current -f BRME-4425/setup/brme4425-cleanup.apex` (deletes only the manifest IDs).
3. BRME-7012 synthetic records and real Contacts are **not** part of this cleanup.

## 7. Artifacts

- Workbook generator: [tooling/make-xlsx.js](tooling/make-xlsx.js)
- Classification evidence: [setup/brme4425-classification-precheck.apex](setup/brme4425-classification-precheck.apex)
