Id budgetId = 'a0fbc000006WeIDAA0';
Account org = [SELECT Id FROM Account LIMIT 1];

IM_Grant__c grant = new IM_Grant__c();
grant.Deleted__c = false;
insert grant;

IM_Budget_Org__c budgetOrg = new IM_Budget_Org__c();
budgetOrg.Budget__c = budgetId;
budgetOrg.Organization__c = org.Id;
budgetOrg.Type__c = 'Partner';
insert budgetOrg;

IM_Budget_Grant__c budgetGrant = new IM_Budget_Grant__c();
budgetGrant.Budget__c = budgetId;
budgetGrant.Budget_Org__c = budgetOrg.Id;
budgetGrant.IM_Grant__c = grant.Id;
insert budgetGrant;

IM_Budget_Row__c brow = [SELECT Id, Budget_Grant__c FROM IM_Budget_Row__c WHERE Budget__c = :budgetId LIMIT 1];
brow.Budget_Grant__c = budgetGrant.Id;
update brow;
System.debug('OK: grant=' + grant.Id + ' budgetGrant=' + budgetGrant.Id + ' row=' + brow.Id);
