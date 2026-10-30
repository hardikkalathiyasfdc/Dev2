// BIM Requested Amount fix — E2E step B (dev2Current): change amounts 100,000 -> 120,000
// DML-only script (callouts and DML cannot share one anonymous transaction).
IM_Budget_Grant__c bg = [
	SELECT Id, Budget_Amount_Local__c, Confirmed_Budget_Amount_Local__c
	FROM IM_Budget_Grant__c
	WHERE IM_Grant__c = 'a0obc000003FE49AAG'
	LIMIT 1
];
bg.Budget_Amount_Local__c = 120000;
bg.Confirmed_Budget_Amount_Local__c = 120000;
update bg;

IM_Grant__c g = [
	SELECT Id, Total_Amount_Local__c, Budget_Amount_Local__c
	FROM IM_Grant__c
	WHERE Id = 'a0obc000003FE49AAG'
];
System.debug('AMOUNTS CHANGED: Total_Amount_Local__c=' + g.Total_Amount_Local__c
	+ ' Budget_Amount_Local__c=' + g.Budget_Amount_Local__c);
