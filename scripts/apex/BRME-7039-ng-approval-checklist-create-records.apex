// BRME-7039: Create two NG Budgeted Initiatives that exercise the Approval Checklist.
// Record A: fully aligned  -> Term Alignment = Yes, Required Approval Docs = Yes, all checks = Yes.
// Record B: misaligned     -> Term Alignment = No (budget term differs), Required Approval Docs = No
//                             (only 2 of 3 links), one checklist response = No with its Notes filled.
String teamName = 'Arts';

List<User> userMatches = [SELECT Id FROM User WHERE Email = 'ng.grant.contact@bimtest.example' LIMIT 1];
if (userMatches.isEmpty()) {
    throw new AuraHandledException('NG grants user not found. Run ng-request-revisions-create-user.apex first.');
}
User grantsUser = userMatches[0];

Team__c team = [SELECT Id FROM Team__c WHERE Name = :teamName LIMIT 1];
Id parentRtId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Parent Initiative').getRecordTypeId();
Id budgetedRtId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get('Budgeted Initiative').getRecordTypeId();

// ---------- Record A: aligned ----------
IM_Initiative__c parentA = new IM_Initiative__c(
    Name = 'NG Approval Checklist A BRME-7039', Initiative_Type__c = 'Parent', Team__c = team.Id, RecordTypeId = parentRtId);
insert parentA;

IM_Initiative__c initA = new IM_Initiative__c(
    Name = 'NG Approval Checklist A 1.0 BRME-7039',
    Initiative_Type__c = 'New', Status__c = 'In Development', Team__c = team.Id,
    Parent_Initiative__c = parentA.Id, Grants_Team_Contact__c = grantsUser.Id,
    Start_Date__c = Date.today(), End_Date__c = Date.today().addMonths(12), // Term = 12 months
    RecordTypeId = budgetedRtId,
    Final_Memo_Link__c = 'https://bloomberg.example.com/final-memo/checklist-a.pdf',
    Budget_Narrative_Link__c = 'https://bloomberg.example.com/budget-narrative/checklist-a.pdf',
    Approval_Email_Link__c = 'https://bloomberg.example.com/approval-email/checklist-a',
    Initiative_Name_and_Budget_Name_Review__c = 'Yes',
    Strategic_Locations_Aligned__c = 'Yes',
    Budget_Aligns_with_Memo__c = 'Yes',
    Type_of_Work_Aligns_Memo__c = 'Yes',
    Approval_Notes__c = 'All manual checks passed.'
);
insert initA;

// Budget with matching term (12 months) -> Term Alignment = Yes. Pending Approval sets Current_Budget__c.
IM_Budget__c budgetA = new IM_Budget__c(
    Name = 'Checklist A Budget', Initiative__c = initA.Id, Budget_Term_months__c = 12,
    Budget_Categories__c = 'Component', Status__c = 'Pending Approval',
    Proposed_Amount__c = 20000, Version__c = 1, Type_of_Work__c = true
);
insert budgetA;

// ---------- Record B: misaligned + partial docs + a "No" check ----------
IM_Initiative__c parentB = new IM_Initiative__c(
    Name = 'NG Approval Checklist B BRME-7039', Initiative_Type__c = 'Parent', Team__c = team.Id, RecordTypeId = parentRtId);
insert parentB;

IM_Initiative__c initB = new IM_Initiative__c(
    Name = 'NG Approval Checklist B 1.0 BRME-7039',
    Initiative_Type__c = 'New', Status__c = 'In Development', Team__c = team.Id,
    Parent_Initiative__c = parentB.Id, Grants_Team_Contact__c = grantsUser.Id,
    Start_Date__c = Date.today(), End_Date__c = Date.today().addMonths(12), // Term = 12 months
    RecordTypeId = budgetedRtId,
    Final_Memo_Link__c = 'https://bloomberg.example.com/final-memo/checklist-b.pdf',
    Budget_Narrative_Link__c = 'https://bloomberg.example.com/budget-narrative/checklist-b.pdf',
    // Approval_Email_Link__c intentionally blank -> Required Approval Docs = No
    Initiative_Name_and_Budget_Name_Review__c = 'Yes',
    Strategic_Locations_Aligned__c = 'No',
    Strategic_Locations_Aligned_Notes__c = 'One location is outside the approved strategic geography; pending program confirmation.',
    Budget_Aligns_with_Memo__c = 'Yes',
    Type_of_Work_Aligns_Memo__c = 'Yes'
);
insert initB;

// Budget with mismatched term (24 months vs 12) -> Term Alignment = No.
IM_Budget__c budgetB = new IM_Budget__c(
    Name = 'Checklist B Budget', Initiative__c = initB.Id, Budget_Term_months__c = 24,
    Budget_Categories__c = 'Component', Status__c = 'Pending Approval',
    Proposed_Amount__c = 20000, Version__c = 1, Type_of_Work__c = true
);
insert budgetB;

// ---------- Verify ----------
for (IM_Initiative__c r : [
    SELECT Id, Name, Status__c, Term__c, Current_Budget__c, Current_Budget__r.Budget_Term_months__c,
           Term_Alignment__c, Required_Approval_Docs__c,
           Strategic_Locations_Aligned__c, Strategic_Locations_Aligned_Notes__c
    FROM IM_Initiative__c WHERE Id IN (:initA.Id, :initB.Id)
]) {
    System.debug('CHECK>>> ' + r.Name
        + ' | Term=' + r.Term__c + ' | BudgetTerm=' + (r.Current_Budget__r != null ? String.valueOf(r.Current_Budget__r.Budget_Term_months__c) : 'null')
        + ' | TermAlignment=' + r.Term_Alignment__c
        + ' | RequiredDocs=' + r.Required_Approval_Docs__c
        + ' | StratAligned=' + r.Strategic_Locations_Aligned__c);
}
