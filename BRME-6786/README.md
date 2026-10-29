# BRME-6786 — DIT Review Errors: organization error messages

Phase 1 package: investigation, synthetic baseline Accounts, DIT upload workbooks, and reproduction steps for the ticket

> **Align organization error messages at Review Errors with the row's actual resolution flow.**

- Implementation plan (root cause + proposed fix): [BRME-6786-implementation-plan.md](BRME-6786-implementation-plan.md)
- Baseline record IDs: [setup/record-manifest.md](setup/record-manifest.md)
- Org: **dev2Current** sandbox — DIT at `https://bbrm--dev2.sandbox.lightning.force.com/lightning/n/Data_Import2`.

## 1. Record setup (already done — 2026-10-23)

Four synthetic Accounts created (script: [setup/brme6786-create-baseline-orgs.apex](setup/brme6786-create-baseline-orgs.apex)):

| ID | Name | Role |
|---|---|---|
| `001bc00000kjz4sAAA` | BRME6786 Holdings Group | Scenario 1 candidate |
| `001bc00000kjz4tAAA` | BRME6786 City Foundation | Scenario 3 candidate A |
| `001bc00000kjz4uAAA` | BRME6786 City Foundation | Scenario 3 candidate B (same name) |
| `001bc00000kjz4vAAA` | BRME6786 Exact Org | Exact-match control |

Scenario 2 needs no record — "BRME6786 Nonexistent Foundation" is genuinely absent.

To re-create after a refresh: `sf apex run -o dev2Current -f BRME-6786/setup/brme6786-create-baseline-orgs.apex`, then update the manifest IDs.

## 2. DIT upload files

In [test-data/](test-data/) — real `.xlsx`, sheet `Sheet1`, 32-column template. Populated columns: `First Name`, `Last Name`, **`Organization Name`** (auto-maps to the Organization Name field; the legacy "Company" header does not auto-map).

| File | Org value(s) | Current message (baseline) | Duplicate modal |
|---|---|---|---|
| `BRME-6786-scenario1-similar-records.xlsx` | BRME6786 Holdings | "BRME6786 Holdings not found in BRM" | 1 candidate (Holdings Group) |
| `BRME-6786-scenario2-create-org.xlsx` | BRME6786 Nonexistent Foundation | "…not found in BRM" | none → Create Organization |
| `BRME-6786-scenario3-multiple.xlsx` | BRME6786 City Foundation | "Multiple BRME6786 City Foundation found in BRM. Please search for correct one." | 2 candidates |
| `BRME-6786-mixed.xlsx` | all three + BRME6786 Exact Org | per-row | per-row; control row auto-links (no error row) |

To regenerate: `node BRME-6786/tooling/make-xlsx.js`.

## 3. Upload / mapping steps (each workbook)

1. Open DIT → **Upload File** → choose the workbook → Next.
2. **Map Columns** → verify `First Name`, `Last Name`, `Organization Name` are mapped → Next (accept partial-mapping warning → Yes).
3. **Preview** → no errors expected → Next.
4. **Review Errors** → observe the Organization Name cell error message on each row, and click the **+** button (or the cell) to see which modal opens (Potential Duplicate Records vs Create Organization).
5. Do **not** complete Import; note the Data_Load__c created for cleanup.

## 4. Baseline reproduction (current behavior)

| Scenario | What you see today |
|---|---|
| 1 | Red "BRME6786 Holdings not found in BRM" — yet + opens Potential Duplicate Records with BRME6786 Holdings Group |
| 2 | Red "BRME6786 Nonexistent Foundation not found in BRM" — + opens Create Organization |
| 3 | Red "Multiple BRME6786 City Foundation found in BRM. Please search for correct one." — + opens Potential Duplicate Records with 2 rows |
| control | Exact Org row auto-links; never appears in Review Errors |

## 5. Expected messages after the fix

| Scenario | New message |
|---|---|
| 1 | **Similar records exist in BRM. Please review potential duplicates.** |
| 2 | **Org not found in BRM. Please create new Organization.** |
| 3 | **Similar records exist in BRM. Please review potential duplicates.** |

Selecting a candidate (Use Existing) or creating an org still clears the error; Cancel changes nothing; each row's message is independent in mixed uploads.

## 6. Cleanup

1. Delete Data_Load__c records created by the test uploads (DIT "Load an in progress file" list; cascades to rows).
2. Delete any Contacts/Accounts created via DIT during testing.
3. Delete the 4 baseline Accounts: `sf apex run -o dev2Current -f BRME-6786/setup/brme6786-cleanup.apex` (deletes only the manifest IDs).
4. BRME-7012 / BRME-4425 records are untouched.

## 7. Artifacts

- Workbook generator: [tooling/make-xlsx.js](tooling/make-xlsx.js)
- Classification evidence: [setup/brme6786-classification-precheck.apex](setup/brme6786-classification-precheck.apex)
