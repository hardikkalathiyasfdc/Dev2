# BRME-5632 — Setup-record manifest

Synthetic records created in **dev2Current** sandbox on 2026-10-23 via [brme5632-create-baseline.apex](brme5632-create-baseline.apex). All marked `Description='BRME-5632 synthetic test data'`; emails use `.invalid`. No real records modified.

## Records (recreated 2026-10-23 after cleanup)

| Salesforce ID | Type | Name | Purpose |
|---|---|---|---|
| `001bc00000kljURAAY` | Account | BRME5632 Org | Org to link uploaded contacts |
| `003bc000018Lmm5AAC` | Contact | Owen BRME5632Update | Existing contact for the update-blocked scenario |
| `701bc00000kljUSAAY` | Campaign | BRME5632 List | Existing list for list-member scenarios |

_(Prior IDs `001bc00000klnxKAAQ` / `003bc000018Lgf3AAC` / `701bc00000klnxLAAQ` were deleted during the reset.)_

## The reproducible failure (no setup record needed)

A Contact save that fails the **active** validation rule `Office_Phone_Country_Code` ("Business Phone (Country Code) must be populated."): upload a row with **Business Phone populated but Business Phone (Country Code) blank**. Verified via [brme5632-probe.apex](brme5632-probe.apex): `FIELD_CUSTOM_VALIDATION_EXCEPTION: Business Phone (Country Code) must be populated.`

## DIT upload rows (NOT created as records)

`.xlsx` files in [../test-data/](../test-data/) are uploaded through the DIT UI by the tester. Data_Load__c / Data_Load_Record__c are load artifacts — delete the load (cascades) after testing. Any Contacts/CampaignMembers created by an Import run during testing should also be deleted.

| Artifact | IDs |
|---|---|
| BRME-5632 DIT load(s) | _(to be filled in after baseline repro runs)_ |

## Cleanup

Run [brme5632-cleanup.apex](brme5632-cleanup.apex) (deletes only BRME5632-named records), then delete test Data_Load__c records and any DIT-created Contacts/CampaignMembers. See [README](../README.md).
