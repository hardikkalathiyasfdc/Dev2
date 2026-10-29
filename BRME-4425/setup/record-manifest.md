# BRME-4425 — Setup-record manifest

Synthetic records created in **dev2Current** sandbox on 2026-10-23 via [brme4425-create-baseline-contacts.apex](brme4425-create-baseline-contacts.apex). All three have `Description = 'BRME-4425 synthetic test data'` and use the `.invalid` TLD. No real/existing Contacts were modified.

## Existing BRM Contacts (exact-match targets)

| # | Salesforce ID | FirstName | LastName | Email | Preferred_First_Name__c |
|---|---|---|---|---|---|
| C1 | `003bc000018J9ykAAC` | Alice | BRME4425Exact | alice.brme4425@brme4425.invalid | — |
| C2 | `003bc000018J9ylAAC` | Brendan | BRME4425Exact | brendan.brme4425@brme4425.invalid | — |
| C3 | `003bc000018J9ymAAC` | Carla | BRME4425Exact | carla.brme4425@brme4425.invalid | — |

Trigger-populated values verified after insert: `Converted_FirstName__c`/`Converted_LastName__c` set; `Converted_Full_Name__c` = space-less concatenation (e.g. `AliceBRME4425Exact`).

## Separation from BRME-7012

Distinct last names (`BRME4425Exact`, `BRME4425New`) — no overlap with BRME-7012's `BRME7012Test`/`BRME7012Email` data. BRME-7012 records and results are unaffected.

## DIT upload rows (NOT created as Contacts)

The `.xlsx` files in [../test-data/](../test-data/) are uploaded through the DIT UI by the tester. The Data_Load__c / Data_Load_Record__c rows produced are load artifacts — delete the Data_Load__c record (cascades) after testing; IDs appended below after runs.

| Artifact | IDs |
|---|---|
| BRME-4425 DIT load(s) | _(to be filled in after the user's test runs)_ |

## Cleanup

Run [brme4425-cleanup.apex](brme4425-cleanup.apex) (deletes only the 3 Contact IDs above), then delete any Data_Load__c records created during testing. See [README](../README.md#6-cleanup).
