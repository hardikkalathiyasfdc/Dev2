// BRME-7020 E2E Part A: create 5 test users + group/permset membership (setup objects only).
Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
String suffix = '.brme7020@bbrm.dev2.test';
Set<String> existing = new Set<String>();
for (User u : [SELECT UserName FROM User WHERE UserName LIKE '%.brme7020@bbrm.dev2.test']) existing.add(u.UserName);
List<User> users = new List<User>();
for (String ln : new List<String>{'GNoPS','RevNoGrp','Both','Req','None'}) {
    String un = ln.toLowerCase()+suffix;
    if (existing.contains(un)) continue;
    users.add(new User(Alias=ln.left(8), Email='brme7020@test.invalid', EmailEncodingKey='UTF-8',
        LastName='E2E'+ln, LanguageLocaleKey='en_US', LocaleSidKey='en_US',
        ProfileId=p.Id, TimeZoneSidKey='America/New_York', UserName=un, IsActive=true, Sharing_Team__c='Events'));
}
if (!users.isEmpty()) insert users;

Map<String, Id> idByLast = new Map<String, Id>();
for (User u : [SELECT Id, LastName FROM User WHERE LastName IN ('E2EGNoPS','E2ERevNoGrp','E2EBoth','E2EReq','E2ENone')]) idByLast.put(u.LastName, u.Id);

PermissionSet reviewerPs = [SELECT Id FROM PermissionSet WHERE Name='Highlights_Metrics_Reviewer' LIMIT 1];
PermissionSet requestorPs = [SELECT Id FROM PermissionSet WHERE Name='Highlights_Metrics_Requestor' LIMIT 1];
Group reviewGroup = [SELECT Id FROM Group WHERE DeveloperName='Highlights_Private_Highlights_Review' LIMIT 1];

List<SObject> m = new List<SObject>();
m.add(new GroupMember(GroupId=reviewGroup.Id, UserOrGroupId=idByLast.get('E2EGNoPS')));
m.add(new GroupMember(GroupId=reviewGroup.Id, UserOrGroupId=idByLast.get('E2EBoth')));
m.add(new PermissionSetAssignment(AssigneeId=idByLast.get('E2ERevNoGrp'), PermissionSetId=reviewerPs.Id));
m.add(new PermissionSetAssignment(AssigneeId=idByLast.get('E2EBoth'), PermissionSetId=reviewerPs.Id));
m.add(new PermissionSetAssignment(AssigneeId=idByLast.get('E2EReq'), PermissionSetId=requestorPs.Id));
Database.SaveResult[] sr = Database.insert(m, false);
for (Database.SaveResult r : sr) if (!r.isSuccess()) System.debug('BRME7020|MEMBERSHIP_ERR|'+r.getErrors());
System.debug('BRME7020|PARTA|users ready: '+idByLast.keySet());
