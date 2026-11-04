// BRME-7038: Create a brand-new NG Budgeted Initiative with the three Final Document
// URL fields populated so QA can open the Final Docs tab and verify the
// View Required Docs combined-hyperlink formula.
String ticketTag = ' BRME-7038';
String baseName = 'NG Final Docs Demo';
String parentName = baseName + ticketTag;
String budgetedName = baseName + ' 1.0' + ticketTag;
String teamName = 'Arts';

// Reuse the NG grants user created for the revisions demo.
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

// Parent initiative.
Id parentRecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Parent Initiative').getRecordTypeId();
IM_Initiative__c parentInitiative = new IM_Initiative__c(
    Name = parentName,
    Initiative_Type__c = 'Parent',
    Team__c = team.Id,
    RecordTypeId = parentRecordTypeId
);
insert parentInitiative;

// Budgeted initiative with the three Final Document links populated.
Id budgetedRecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Budgeted Initiative').getRecordTypeId();
IM_Initiative__c initiative = new IM_Initiative__c(
    Name = budgetedName,
    Initiative_Type__c = 'New',
    Status__c = 'In Development',
    Team__c = team.Id,
    Parent_Initiative__c = parentInitiative.Id,
    Grants_Team_Contact__c = grantsUser.Id,
    Start_Date__c = Date.today(),
    End_Date__c = Date.today().addMonths(12),
    RecordTypeId = budgetedRecordTypeId,
    Final_Memo_Link__c = 'https://bloomberg.example.com/final-memo/ng-final-docs-demo.pdf',
    Budget_Narrative_Link__c = 'https://bloomberg.example.com/budget-narrative/ng-final-docs-demo.pdf',
    Approval_Email_Link__c = 'https://bloomberg.example.com/approval-email/ng-final-docs-demo'
);
insert initiative;

IM_Initiative__c result = [
    SELECT Id, Name, Status__c, Final_Memo_Link__c, Budget_Narrative_Link__c, Approval_Email_Link__c, View_Required_Docs__c
    FROM IM_Initiative__c WHERE Id = :initiative.Id
];
System.debug('BRME-7038 initiative: ' + result.Id + ' | ' + result.Name);
System.debug('Final Memo: ' + result.Final_Memo_Link__c);
System.debug('Budget Narrative: ' + result.Budget_Narrative_Link__c);
System.debug('Approval Email: ' + result.Approval_Email_Link__c);
System.debug('View Required Docs formula: ' + result.View_Required_Docs__c);
