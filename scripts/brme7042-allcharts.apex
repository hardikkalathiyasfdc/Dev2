Id budgetId = 'a0fbc000006WeIDAA0';

// Create a Geography (none exist); Budget__c is required
IM_Geography__c geo = new IM_Geography__c();
geo.Name = 'Test Geography';
geo.Budget__c = budgetId;
insert geo;

// Flip the budget dimension flags on
IM_Budget__c budget = new IM_Budget__c(Id = budgetId);
budget.Geography__c = true;
budget.Type_of_Work__c = true;
update budget;

// Populate the row's Geography + Type of Work so the pies have data
IM_Budget_Row__c brow = [SELECT Id, Geography__c, Type_of_Work__c FROM IM_Budget_Row__c WHERE Budget__c = :budgetId LIMIT 1];
brow.Geography__c = geo.Id;
brow.Type_of_Work__c = 'Charitable';
update brow;
System.debug('OK: geo=' + geo.Id + ' budget flags on, row updated ' + brow.Id);
