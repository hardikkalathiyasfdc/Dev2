// BRME-7039: test data scenarios for Approval Checklist fields.
// Scenario map:
//  1.0 (a0qbc00000HmnW5AAJ): aligned term (24 = 24) -> Term Alignment "Yes"
//  2.0 (a0qbc00000I0wsrAAB): misaligned term (24 vs 36) -> "No"; all 3 doc links -> Required Approval Docs "Yes"
//  3.0 (a0qbc00000I5Kq9AAF): no Current Budget -> "No"; partial links -> "No"

Id init1 = 'a0qbc00000HmnW5AAJ';
Id init2 = 'a0qbc00000I0wsrAAB';
Id init3 = 'a0qbc00000I5Kq9AAF';

// Bypass the Initiative trigger: IMBudgetHelper.updateActiveStatus (called on Current_Budget__c change)
// throws AuraHandledException, which cannot be thrown outside a Lightning context.
TriggerFactory.setBypass('IMBudgetedInitiativeHandler');

// Clean up budgets from any previous partial run
delete [SELECT Id FROM IM_Budget__c WHERE Name LIKE 'BRME7039%'];

// Budgets with matching/mismatching terms (Status must be Pending Approval/Approved for the Current_Budget__c lookup filter)
IM_Budget__c b1 = new IM_Budget__c(Name = 'BRME7039 Aligned Budget', Initiative__c = init1,
    Budget_Term_months__c = 24, Budget_Categories__c = 'Component', Status__c = 'Pending Approval',
    Proposed_Amount__c = 100000, Version__c = 1);
IM_Budget__c b2 = new IM_Budget__c(Name = 'BRME7039 Misaligned Budget', Initiative__c = init2,
    Budget_Term_months__c = 36, Budget_Categories__c = 'Component', Status__c = 'Pending Approval',
    Proposed_Amount__c = 100000, Version__c = 1);
insert new List<IM_Budget__c>{ b1, b2 };
System.debug('Budgets inserted: ' + b1.Id + ', ' + b2.Id);

// Link as Current Budget (init3 intentionally left without one)
update new IM_Initiative__c(Id = init1, Current_Budget__c = b1.Id);
update new IM_Initiative__c(Id = init2, Current_Budget__c = b2.Id);

// Checklist manual responses on init1: one "No" with Notes (validation passes)
update new IM_Initiative__c(Id = init1,
    Strategic_Locations_Aligned__c = 'No',
    Strategic_Locations_Aligned_Notes__c = 'One location outside strategic footprint; exception documented.',
    Budget_Aligns_with_Memo__c = 'Yes',
    Type_of_Work_Aligns_Memo__c = 'Yes',
    Initiative_Name_and_Budget_Name_Review__c = 'Yes',
    Approval_Notes__c = 'Checklist review completed by Grants.');

// init2: all "Yes"
update new IM_Initiative__c(Id = init2,
    Strategic_Locations_Aligned__c = 'Yes',
    Budget_Aligns_with_Memo__c = 'Yes',
    Type_of_Work_Aligns_Memo__c = 'Yes',
    Initiative_Name_and_Budget_Name_Review__c = 'Yes',
    Revisions_Reason__c = 'Budget re-uploaded after memo correction.');

// init3: partial links already set by BRME-7038 (Final Memo + Budget Narrative); leave as-is

List<IM_Initiative__c> results = [
    SELECT Name, Term__c, Current_Budget__r.Budget_Term_months__c, Term_Alignment__c, Required_Approval_Docs__c
    FROM IM_Initiative__c WHERE Id IN (:init1, :init2, :init3) ORDER BY Name];
for (IM_Initiative__c r : results) {
    System.debug(r.Name + ' | Term=' + r.Term__c + ' | BudgetTerm=' +
        r.Current_Budget__r.Budget_Term_months__c + ' | TermAlignment=' + r.Term_Alignment__c +
        ' | ReqDocs=' + r.Required_Approval_Docs__c);
}
