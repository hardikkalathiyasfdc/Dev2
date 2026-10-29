# BRME-6786 — Setup-record manifest

Synthetic records created in **dev2Current** sandbox on 2026-10-23 via [brme6786-create-baseline-orgs.apex](brme6786-create-baseline-orgs.apex). All four have `Description = 'BRME-6786 synthetic test data'`. No real/existing Accounts were modified.

## Existing BRM Accounts (baseline for Review Errors org matching)

| # | Salesforce ID | Name | Converted_Org_Name__c | Scenario role |
|---|---|---|---|---|
| O1 | `001bc00000kjz4sAAA` | BRME6786 Holdings Group | BRME6786HoldingsGroup | Scenario 1 candidate (upload "BRME6786 Holdings" is not an exact normalized match → "not found" today, but the duplicate modal offers this record) |
| O2 | `001bc00000kjz4tAAA` | BRME6786 City Foundation | BRME6786CityFoundation | Scenario 3 candidate A (identical name) |
| O3 | `001bc00000kjz4uAAA` | BRME6786 City Foundation | BRME6786CityFoundation | Scenario 3 candidate B (identical name) |
| O4 | `001bc00000kjz4vAAA` | BRME6786 Exact Org | BRME6786ExactOrg | Exact-match regression control |

Scenario 2 uses **no** setup record: the uploaded org "BRME6786 Nonexistent Foundation" is genuinely absent from BRM.

## DIT upload rows (NOT created as records)

The `.xlsx` files in [../test-data/](../test-data/) are uploaded through the DIT UI by the tester. Data_Load__c / Data_Load_Record__c rows produced are load artifacts — delete the Data_Load__c record (cascades) after testing. Any Contact/Account created through the DIT import flow during testing should also be deleted.

| Artifact | IDs |
|---|---|
| BRME-6786 DIT load(s) | _(to be filled in after the user's baseline repro runs)_ |

## Classification evidence

[brme6786-classification-precheck.apex](brme6786-classification-precheck.apex) (run 2026-10-23) verified against live org data:

| Upload value | Initial message today | Duplicate-modal candidates |
|---|---|---|
| BRME6786 Holdings | "BRME6786 Holdings not found in BRM" | 1 (Holdings Group) |
| BRME6786 Nonexistent Foundation | "... not found in BRM" | 0 → Create Organization |
| BRME6786 City Foundation | "Multiple BRME6786 City Foundation found in BRM. Please search for correct one." | 2 |
| BRME6786 Exact Org | none (auto-links) | n/a |

## Cleanup

Run [brme6786-cleanup.apex](brme6786-cleanup.apex) (deletes only the 4 Account IDs above), then delete any Data_Load__c records and any DIT-created Contacts/Accounts from testing. See [README](../README.md).
