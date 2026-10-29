// BRME-7020 E2E Part E: re-check the sharing matrix against the persistent records.
Map<String, Id> idByLast = new Map<String, Id>();
for (User u : [SELECT Id, LastName FROM User WHERE LastName IN ('E2EGNoPS','E2ERevNoGrp','E2EBoth','E2EReq','E2ENone')]) idByLast.put(u.LastName, u.Id);
Map<String, Id> recByName = new Map<String, Id>();
for (Highlight_Interaction__c h : [SELECT Id, Name FROM Highlight_Interaction__c WHERE Name IN ('BRME7020-Keep-Public','BRME7020-Keep-Private')]) recByName.put(h.Name, h.Id);
List<String> keyOrder = new List<String>{'GNoPS','RevNoGrp','Both','Req','None'};
Map<String,String> lbl = new Map<String,String>{'GNoPS'=>'E2EGNoPS','RevNoGrp'=>'E2ERevNoGrp','Both'=>'E2EBoth','Req'=>'E2EReq','None'=>'E2ENone'};
for (String key : keyOrder) {
    Id uid = idByLast.get(lbl.get(key));
    String privRes='NO-USER'; String pubRes='NO-USER';
    if (uid != null) {
        privRes='NO-ROW';
        for (UserRecordAccess a : [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE RecordId=:recByName.get('BRME7020-Keep-Private') AND UserId=:uid]) privRes='read='+a.HasReadAccess+',edit='+a.HasEditAccess;
        pubRes='NO-ROW';
        for (UserRecordAccess a : [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE RecordId=:recByName.get('BRME7020-Keep-Public') AND UserId=:uid]) pubRes='read='+a.HasReadAccess+',edit='+a.HasEditAccess;
    }
    System.debug('BRME7020|SHARE_'+key+'_private|'+privRes);
    System.debug('BRME7020|SHARE_'+key+'_nonPrivate|'+pubRes);
}
