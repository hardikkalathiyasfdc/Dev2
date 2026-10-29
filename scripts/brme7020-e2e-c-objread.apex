// BRME-7020 E2E Part C: grant object-level Read on Highlight_Interaction__c to the test users that need it.
Map<String, Id> idByLast = new Map<String, Id>();
for (User u : [SELECT Id, LastName FROM User WHERE LastName IN ('E2EGNoPS','E2ENone')]) idByLast.put(u.LastName, u.Id);
PermissionSet requestorPs = [SELECT Id FROM PermissionSet WHERE Name='Highlights_Metrics_Requestor' LIMIT 1];
List<SObject> m = new List<SObject>();
m.add(new PermissionSetAssignment(AssigneeId=idByLast.get('E2EGNoPS'), PermissionSetId=requestorPs.Id));
m.add(new PermissionSetAssignment(AssigneeId=idByLast.get('E2ENone'), PermissionSetId=requestorPs.Id));
Database.SaveResult[] sr = Database.insert(m, false);
for (Database.SaveResult r : sr) if (!r.isSuccess()) System.debug('BRME7020|ERR|'+r.getErrors());
System.debug('BRME7020|PARTC|granted requestor object-read to GNoPS + None');
