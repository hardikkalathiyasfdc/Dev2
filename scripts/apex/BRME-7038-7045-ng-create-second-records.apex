// Create a second record for BRME-7038 (Final Docs) and a second for BRME-7045 (Request Revisions).
String teamName = 'Arts';

List<User> userMatches = [SELECT Id, Email FROM User WHERE Email = 'ng.grant.contact@bimtest.example' LIMIT 1];
if (userMatches.isEmpty()) {
    throw new AuraHandledException('NG grants user not found. Run ng-request-revisions-create-user.apex first.');
}
User grantsUser = userMatches[0];

List<Team__c> teams = [SELECT Id, Name FROM Team__c WHERE Name = :teamName LIMIT 1];
if (teams.isEmpty()) {
    throw new AuraHandledException('Team not found: ' + teamName);
}
Team__c team = teams[0];

Id parentRecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Parent Initiative').getRecordTypeId();
Id budgetedRecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Budgeted Initiative').getRecordTypeId();

List<IM_Initiative__c> toInsert = new List<IM_Initiative__c>();

// ---------- BRME-7038: second Final Docs record ----------
IM_Initiative__c fdParent = new IM_Initiative__c(
    Name = 'NG Final Docs Demo 2 BRME-7038',
    Initiative_Type__c = 'Parent',
    Team__c = team.Id,
    RecordTypeId = parentRecordTypeId
);
insert fdParent;
toInsert.add(new IM_Initiative__c(
    Name = 'NG Final Docs Demo 2.0 BRME-7038',
    Initiative_Type__c = 'New',
    Status__c = 'In Development',
    Team__c = team.Id,
    Parent_Initiative__c = fdParent.Id,
    Grants_Team_Contact__c = grantsUser.Id,
    Start_Date__c = Date.today(),
    End_Date__c = Date.today().addMonths(12),
    RecordTypeId = budgetedRecordTypeId,
    Final_Memo_Link__c = 'https://bloomberg.example.com/final-memo/ng-final-docs-demo-2.pdf',
    Budget_Narrative_Link__c = 'https://bloomberg.example.com/budget-narrative/ng-final-docs-demo-2.pdf',
    Approval_Email_Link__c = 'https://bloomberg.example.com/approval-email/ng-final-docs-demo-2'
));

// ---------- BRME-7045: second Request Revisions record ----------
IM_Initiative__c rrParent = new IM_Initiative__c(
    Name = 'NG Request Revisions Demo 2 BRME-7045',
    Initiative_Type__c = 'Parent',
    Team__c = team.Id,
    RecordTypeId = parentRecordTypeId
);
insert rrParent;
toInsert.add(new IM_Initiative__c(
    Name = 'NG Request Revisions Demo 2.0 BRME-7045',
    Initiative_Type__c = 'New',
    Status__c = 'Ready for Approval',
    Team__c = team.Id,
    Parent_Initiative__c = rrParent.Id,
    Grants_Team_Contact__c = grantsUser.Id,
    Start_Date__c = Date.today(),
    End_Date__c = Date.today().addMonths(12),
    RecordTypeId = budgetedRecordTypeId
));

insert toInsert;

for (IM_Initiative__c r : [SELECT Id, Name, Status__c, View_Required_Docs__c FROM IM_Initiative__c WHERE Id IN :toInsert]) {
    System.debug('CREATED>>> ' + r.Id + ' | ' + r.Name + ' | ' + r.Status__c);
}
