// BRME-7020 FG E2E: sharing matrix for File_Group__c private vs non-private.
Map<String, Id> u = new Map<String, Id>();
for (User x : [SELECT Id, LastName FROM User WHERE LastName IN ('E2EGNoPS','E2ERevNoGrp','E2EBoth','E2EReq','E2ENone')]) u.put(x.LastName, x.Id);
Team__c t = [SELECT Id FROM Team__c LIMIT 1];
Highlight_Interaction__c pubH = new Highlight_Interaction__c(Name='FG-E2E-Pub', Team__c=t.Id, Description__c='d', Status__c='Draft', Include_In_Program_Highlight__c=true);
Highlight_Interaction__c privH = new Highlight_Interaction__c(Name='FG-E2E-Priv', Team__c=t.Id, Description__c='d', Status__c='Draft');
insert new List<Highlight_Interaction__c>{pubH, privH};
privH.put('Private__c', true); update privH; // trigger syncs file group private
File_Group__c pubFG = [SELECT Id, Private__c FROM File_Group__c WHERE Highlight__c=:pubH.Id LIMIT 1];
File_Group__c privFG = [SELECT Id, Private__c FROM File_Group__c WHERE Highlight__c=:privH.Id LIMIT 1];
System.debug('BRME7020|FG_FLAG_pub|' + pubFG.Private__c);
System.debug('BRME7020|FG_FLAG_priv|' + privFG.Private__c);
for (String ln : new List<String>{'E2EGNoPS','E2ERevNoGrp','E2EBoth','E2EReq','E2ENone'}) {
    Id uid = u.get(ln);
    String privRes='NO-ROW'; String pubRes='NO-ROW';
    for (UserRecordAccess a : [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE RecordId=:privFG.Id AND UserId=:uid]) privRes='r='+a.HasReadAccess+',e='+a.HasEditAccess;
    for (UserRecordAccess a : [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE RecordId=:pubFG.Id AND UserId=:uid]) pubRes='r='+a.HasReadAccess+',e='+a.HasEditAccess;
    System.debug('BRME7020|FGSHARE_'+ln+'_private|'+privRes);
    System.debug('BRME7020|FGSHARE_'+ln+'_nonPrivate|'+pubRes);
}
