# BRME-7012 — Setup-record manifest

All synthetic records created in **dev2Current** sandbox (`https://bbrm--dev2.sandbox.my.salesforce.com`) on 2026-10-23 via [brme7012-create-baseline-contacts.apex](brme7012-create-baseline-contacts.apex). All four have `Description = 'BRME-7012 synthetic test data'` and use the `.invalid` TLD. No real/existing Contacts were modified.

## Existing BRM Contacts (baseline for DIT matching)

| # | Salesforce ID | FirstName | LastName | Preferred_First_Name__c | Email (Business Email) | Alternate_Email__c | Purpose |
|---|---|---|---|---|---|---|---|
| C1 | `003bc000018JAY2AAO` | Patricia | BRME7012Test | Patti | patricia.brme7012@brme7012.invalid | — | Preferred-name candidate (the "Patricia Harris" analog) |
| C2 | `003bc000018JAY3AAO` | Patti | BRME7012Test | — | patti.brme7012@brme7012.invalid | — | Exact first-name candidate (multiple-candidates check) |
| C3 | `003bc000018JAY4AAO` | Bob | BRME7012Test | — | bob.brme7012@brme7012.invalid | — | Blank-preferred control; must never appear for Patti rows |
| C4 | `003bc000018JAY5AAO` | Randy | BRME7012Email | — | randy.brme7012@brme7012.invalid | randy.alt.brme7012@brme7012.invalid | Email-matching regression target (matched via Alternate Email) |

Trigger-populated values verified after insert: `Converted_FirstName__c`/`Converted_LastName__c` set; `Converted_Full_Name__c` = space-less concatenation (e.g. `PatriciaBRME7012Test`).

## Pre-existing org data referenced (NOT created by BRME-7012 — do not delete)

| Salesforce ID | Name | Notes |
|---|---|---|
| `003bc000014Q78UAAS` | Patricia Harris (Preferred First Name = Patti, Email = patti@bloomberg.org.invalid) | Original reported record |
| `003bc000018J8PlAAK` | Patti Harris (no email) | Pre-existing |
| `003bc000018J8PmAAK` | Patti Harris (Email = patti@bloomberg.org) | Pre-existing |

## DIT upload rows (intentionally NOT created as Contacts)

The `.xlsx` files in [../test-data/](../test-data/) are uploaded through the DIT UI by the tester. Data_Load__c / Data_Load_Record__c records produced by those uploads are load artifacts — delete the Data_Load__c record (cascades) after testing; its IDs will be appended below after the baseline run.

| Artifact | IDs |
|---|---|
| Baseline DIT load (single-row, pre-fix) | `a06bc00000NiZOEAA3` (`BRME-7012-single-row-preferred-name.xlsx`, stage `preview`, created 2026-10-23; child row `a05bc00000Yn0eTAAR`) |
| Baseline DIT load(s) (post-fix runs) | _(to be filled in after Phase 2 test runs)_ |

## Cleanup

Run [brme7012-cleanup.apex](brme7012-cleanup.apex) (deletes only the 4 Contact IDs above), then delete any Data_Load__c records created during testing. Both steps are also described in the [README](../README.md#cleanup).
