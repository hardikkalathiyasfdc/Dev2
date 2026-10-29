Id budgetId = 'a0fbc000006WeIDAA0';

// Create 2 more Components (Budget__c required)
List<IM_Component__c> newComps = new List<IM_Component__c>();
for (String n : new List<String>{'Program Delivery', 'Capacity Building'}) {
    IM_Component__c c = new IM_Component__c();
    c.Name = n;
    c.Budget__c = budgetId;
    newComps.add(c);
}
insert newComps;

// Create 2 more Geographies (Budget__c required)
List<IM_Geography__c> newGeos = new List<IM_Geography__c>();
for (String n : new List<String>{'North America', 'Europe'}) {
    IM_Geography__c g = new IM_Geography__c();
    g.Name = n;
    g.Budget__c = budgetId;
    newGeos.add(g);
}
insert newGeos;

// Existing dimension ids
Id comp1 = 'a0jbc000007xyk5AAA';   // TBD
Id geo1  = 'a0lbc0000031Mb3AAE';   // Test Geography
Id comp2 = newComps[0].Id;         // Program Delivery
Id comp3 = newComps[1].Id;         // Capacity Building
Id geo2  = newGeos[0].Id;          // North America
Id geo3  = newGeos[1].Id;          // Europe

// Budget Grant for the inner join (reuse the one created earlier)
IM_Budget_Grant__c bg = [SELECT Id FROM IM_Budget_Grant__c WHERE Budget__c = :budgetId LIMIT 1];

// Add 3 varied rows so each pie has multiple slices
List<IM_Budget_Row__c> rows = new List<IM_Budget_Row__c>();
rows.add(new IM_Budget_Row__c(Budget__c=budgetId, Budget_Grant__c=bg.Id, Component__c=comp2, Geography__c=geo2, Type_of_Work__c='Service Provider', Description__c='Slice 2', Duration_months__c=12, Partner_Role__c='Evaluation', Sub_Partner_Type__c='SubContract', Unique_Identifier__c='SL2', Period_1_Amount__c=20000));
rows.add(new IM_Budget_Row__c(Budget__c=budgetId, Budget_Grant__c=bg.Id, Component__c=comp3, Geography__c=geo3, Type_of_Work__c='Advocacy', Description__c='Slice 3', Duration_months__c=12, Partner_Role__c='Evaluation', Sub_Partner_Type__c='SubContract', Unique_Identifier__c='SL3', Period_1_Amount__c=15000));
rows.add(new IM_Budget_Row__c(Budget__c=budgetId, Budget_Grant__c=bg.Id, Component__c=comp1, Geography__c=geo1, Type_of_Work__c='Electoral', Description__c='Slice 4', Duration_months__c=12, Partner_Role__c='Evaluation', Sub_Partner_Type__c='SubContract', Unique_Identifier__c='SL4', Period_1_Amount__c=25000));
insert rows;
System.debug('Created ' + newComps.size() + ' comps, ' + newGeos.size() + ' geos, ' + rows.size() + ' rows');
