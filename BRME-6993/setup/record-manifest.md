# BRME-6993 — Setup-record manifest

Synthetic records created in **dev2Current** sandbox on 2026-10-23 via [brme6993-create-baseline.apex](brme6993-create-baseline.apex) + [brme6993-create-missing.apex](brme6993-create-missing.apex). All marked `Description='BRME-6993 synthetic test data'`; emails use `.invalid`. No real records modified.

## Accounts (organizations)

| Salesforce ID | Name | Billing address | Role |
|---|---|---|---|
| `001bc00000kkfowAAA` | BRME6993 Org A | 100 Alpha Way, New York NY 10001 US | **BRM org** — assigned to the baseline contacts |
| `001bc00000kkfoxAAA` | BRME6993 Org B | 200 Beta Blvd, Chicago IL 60601 US | **Excel org** — the "different" org referenced by uploads |

## Contacts (BRM side, all on Org A)

| Salesforce ID | Name | Email | Phone | Address | Use_Same_Address_as_Organization__c | Covers |
|---|---|---|---|---|---|---|
| `003bc000018L8YYAA0` | Fiona BRME6993Full | fiona.brme6993@brme6993.invalid | +1 212-555-0101 | 100 Alpha Way, New York | **false** | S1 (all highlights) |
| `003bc000018L8YZAA0` | Theo BRME6993ChkTrue | theo.brme6993@brme6993.invalid | +1 212-555-0102 | 100 Alpha Way, New York | **true** | S2 (address suppressed) |
| `003bc000018KoOdAAK` | Paula BRME6993Partial | paula.brme6993@brme6993.invalid | — | — | false | S3 (email only) |
| `003bc000018KoOeAAK` | Adam BRME6993AddrOnly | — | — | 100 Alpha Way, New York | false | S3 (address only) |
| `003bc000018KoOfAAK` | Bianca BRME6993Bare | — | — | — | false | S3 (none) |

**Setup note:** inserting a Contact with Business Phone requires `Office_Phone_Country_Code__c` (validation rule `Office_Phone_Country_Code`) — hence the country code on Fiona/Theo.

## DIT upload rows (NOT created as records)

`.xlsx` files in [../test-data/](../test-data/) are uploaded through the DIT UI by the tester. Data_Load__c / Data_Load_Record__c are load artifacts — delete the load (cascades) after testing; also delete any Contacts updated/created by an Import run if you go that far.

| Artifact | IDs |
|---|---|
| BRME-6993 DIT load(s) | _(to be filled in after baseline repro runs)_ |

## Cleanup

Run [brme6993-cleanup.apex](brme6993-cleanup.apex) (deletes only the IDs above), then delete test Data_Load__c records. See [README](../README.md).
