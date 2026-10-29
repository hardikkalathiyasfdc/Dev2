Id budgetId = 'a0fbc000006WeIDAA0';
IM_Budget_Grant__c bg = new IM_Budget_Grant__c();
bg.Budget__c = budgetId;
insert bg;
IM_Budget_Row__c brow = [SELECT Id, Budget_Grant__c FROM IM_Budget_Row__c WHERE Budget__c = :budgetId LIMIT 1];
brow.Budget_Grant__c = bg.Id;
update brow;
System.debug('BudgetGrant: ' + bg.Id + ' linked to row ' + brow.Id);
