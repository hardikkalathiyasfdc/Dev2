# other-org/

Everything in this folder is **local-only working material** for getting the Zkipster changes working in the **other org** (the target environment where `Contact.LP_London_Dear_Line__c` exists and `Contact.CorrespondenceDearLine__c` does not).

Nothing here is deployed by the normal `sf project deploy start --source-dir force-app/...` flow.

## Contents

- `zkipster-test-query-fix.txt` — the field-mismatch analysis + fix options (Option A: align fields across orgs; Option B: dynamic reads) + the definitive stale-class fix for the `SObjectException: Contact.LP_London_Dear_Line__c` test failure.

## Plan once the other org is authorized

1. `sf org list` → confirm the other org's alias.
2. Verify which Dear Line field(s) exist there:
   `sf data query -q "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName='Contact' AND QualifiedApiName IN ('LP_London_Dear_Line__c','CorrespondenceDearLine__c')" -o <OTHER_ORG_ALIAS> --result-format human`
3. Confirm the stale class: query the other org's `ZkipsterIntegration` body (Tooling API `ApexClass`) and check whether it references `LP_London_Dear_Line__c`.
4. Apply the chosen option from `zkipster-test-query-fix.txt`.
5. Deploy + run `EventMangementAuraCtrl_Test` in the other org.

## Org facts so far

| Field | dev2Current | other org |
|---|---|---|
| `CorrespondenceDearLine__c` | ✅ exists (verified via FieldDefinition query 2026-10-17) | ❓ (user: other org has `LP_London_Dear_Line__c` instead) |
| `LP_London_Dear_Line__c` | ❌ not deployed (verified 2026-10-17; metadata file exists in repo but not in org) | ✅ exists (per user) |
