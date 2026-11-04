// Set Current_Budget__c on the two BRME-7039 checklist records so Term Alignment evaluates.
// Bypass the initiative handlers: a direct Current_Budget update fires a code path that throws
// an Aura-only exception in anonymous context.
TriggerFactory.setBypass('IMBudgetedInitiativeHandler');
TriggerFactory.setBypass('IMAmendmentInitiativeHandler');
TriggerFactory.setBypass('IMParentInitiativeHandler');
List<IM_Initiative__c> updates = new List<IM_Initiative__c>{
    new IM_Initiative__c(Id = 'a0r7x00002AmDcVAAV', Current_Budget__c = 'a0T7x00000XsJAsEAN'), // A: term 12 = budget 12 -> Yes
    new IM_Initiative__c(Id = 'a0r7x00002AmDcXAAV', Current_Budget__c = 'a0T7x00000XsJAtEAN')  // B: term 12 != budget 24 -> No
};
update updates;
TriggerFactory.removeBypass('IMBudgetedInitiativeHandler');
TriggerFactory.removeBypass('IMAmendmentInitiativeHandler');
TriggerFactory.removeBypass('IMParentInitiativeHandler');
for (IM_Initiative__c r : [
    SELECT Name, Term__c, Current_Budget__r.Budget_Term_months__c, Term_Alignment__c, Required_Approval_Docs__c
    FROM IM_Initiative__c WHERE Id IN ('a0r7x00002AmDcVAAV', 'a0r7x00002AmDcXAAV')
]) {
    System.debug('FIXED>>> ' + r.Name + ' | Term=' + r.Term__c + ' | BudgetTerm=' + r.Current_Budget__r.Budget_Term_months__c
        + ' | TermAlignment=' + r.Term_Alignment__c + ' | RequiredDocs=' + r.Required_Approval_Docs__c);
}
