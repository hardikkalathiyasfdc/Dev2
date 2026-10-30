// BRME-7020 FG E2E setup: grant File_Group__c object Read to E2E users (record sharing tested separately).
Map<String, Id> u = new Map<String, Id>();
for (User x : [SELECT Id, LastName FROM User WHERE LastName IN ('E2EGNoPS','E2ERevNoGrp','E2EBoth','E2EReq','E2ENone')]) u.put(x.LastName, x.Id);
// Reuse requestor PS (grants object read on Highlight; check File_Group object read separately via reviewer). Use a permissive read-only PS for File_Group object access.
PermissionSet requestorPs = [SELECT Id FROM PermissionSet WHERE Name='Highlights_Metrics_Requestor' LIMIT 1];
List<SObject> m = new List<SObject>();
for (String ln : new List<String>{'E2EGNoPS','E2ENone'}) m.add(new PermissionSetAssignment(AssigneeId=u.get(ln), PermissionSetId=requestorPs.Id));
Database.SaveResult[] sr = Database.insert(m, false);
for (Database.SaveResult r : sr) if (!r.isSuccess()) System.debug('BRME7020|FG_SETUP_ERR|'+r.getErrors()[0].getStatusCode());
System.debug('BRME7020|FG_SETUP|done');
