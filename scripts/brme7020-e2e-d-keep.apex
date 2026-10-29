// BRME-7020 E2E Part D: create persistent test records (not cleaned) so sharing can be re-checked after recalc completes.
Team__c team = [SELECT Id FROM Team__c LIMIT 1];
List<Highlight_Interaction__c> existing = [SELECT Id, Name FROM Highlight_Interaction__c WHERE Name IN ('BRME7020-Keep-Public','BRME7020-Keep-Private')];
if (existing.isEmpty()) {
    Highlight_Interaction__c pub = new Highlight_Interaction__c(Name='BRME7020-Keep-Public', Team__c=team.Id, Description__c='public', Status__c='Draft', Include_In_Program_Highlight__c=true);
    Highlight_Interaction__c priv = new Highlight_Interaction__c(Name='BRME7020-Keep-Private', Team__c=team.Id, Description__c='private', Status__c='Draft');
    insert new List<Highlight_Interaction__c>{pub, priv};
    priv.put('Private__c', true); update priv;
}
for (Highlight_Interaction__c h : [SELECT Id, Name FROM Highlight_Interaction__c WHERE Name IN ('BRME7020-Keep-Public','BRME7020-Keep-Private')]) System.debug('BRME7020|KEEP|'+h.Name+'|'+h.Id);
