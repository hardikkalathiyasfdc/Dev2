// BRME-7020 E2E Part B: functional DML checks + sharing matrix. Cleans up created highlights/interactions.
Map<String, Object> out = new Map<String, Object>();
List<Highlight_Interaction__c> toClean = new List<Highlight_Interaction__c>();

Team__c team = [SELECT Id FROM Team__c LIMIT 1];
Highlight_Interaction__c pub; Highlight_Interaction__c priv; Highlight_Interaction__c priv2;

try {
    pub = new Highlight_Interaction__c(Name='BRME7020-E2E-Public', Team__c=team.Id, Description__c='public', Status__c='Draft', Include_In_Program_Highlight__c=true);
    priv = new Highlight_Interaction__c(Name='BRME7020-E2E-Private', Team__c=team.Id, Description__c='private', Status__c='Draft');
    priv2 = new Highlight_Interaction__c(Name='BRME7020-E2E-Private2', Team__c=team.Id, Description__c='private2', Status__c='Draft');
    insert new List<Highlight_Interaction__c>{pub, priv, priv2};
    toClean.addAll(new List<Highlight_Interaction__c>{pub, priv, priv2});

    priv.put('Private__c', true);  update priv;
    priv2.put('Private__c', true); update priv2;

    Highlight_Interaction__c t1 = priv.clone(false, true, false, false); t1.Id=priv.Id; t1.Include_In_CityView__c=true;
    try { update t1; out.put('F1_privatePlusIncludeBlocked','FAIL: no error'); }
    catch (DmlException e) { out.put('F1_privatePlusIncludeBlocked', e.getMessage().contains('Private highlights cannot be submitted to CityView') ? 'PASS' : 'FAIL: '+e.getMessage()); }

    Highlight_Interaction__c t2 = priv.clone(false, true, false, false); t2.Id=priv.Id; t2.Publish_To_CityView__c=true;
    try { update t2; out.put('F2_privatePlusPublishBlocked','FAIL: no error'); }
    catch (DmlException e) { out.put('F2_privatePlusPublishBlocked', e.getMessage().contains('Private highlights cannot be submitted to CityView') ? 'PASS' : 'FAIL: '+e.getMessage()); }

    Highlight_Interaction__c t3 = pub.clone(false, true, false, false); t3.Id=pub.Id; t3.Include_In_CityView__c=true; update t3;
    t3.put('Private__c', true);
    try { update t3; out.put('F3_cityviewMadePrivateBlocked','FAIL: no error'); }
    catch (DmlException e) { out.put('F3_cityviewMadePrivateBlocked', e.getMessage().contains('Private highlights cannot be submitted to CityView') ? 'PASS' : 'FAIL: '+e.getMessage()); }

    priv.Include_As_MRB_Highlight__c = true; update priv;
    HighlightSubmitController.ValidationResult v = HighlightSubmitController.validateHighlight(priv.Id);
    out.put('F4a_privateValidates', v.isValid ? 'PASS' : 'FAIL: '+v.errors);
    HighlightSubmitController.ValidationResult s = HighlightSubmitController.submitForReview(priv.Id);
    out.put('F4b_privateSubmits', s.isValid ? 'PASS' : 'FAIL: '+s.errors);
    priv = [SELECT Id, Status__c FROM Highlight_Interaction__c WHERE Id=:priv.Id];
    priv.Status__c='Reviewed'; update priv;
    Integer privI = [SELECT COUNT() FROM Interaction__c WHERE Highlight_Interaction__c=:priv.Id];
    out.put('F4c_privateNoAutoInteractions', privI==0 ? 'PASS' : 'FAIL: '+privI+' interactions');

    Account org = [SELECT Id FROM Account LIMIT 1];
    insert new Interaction_Participant__c(Highlight__c=pub.Id, Type__c='Organization', Organization__c=org.Id, Description__c='p');
    HighlightSubmitController.submitForReview(pub.Id);
    pub = [SELECT Id, Status__c, Publish_To_CityView__c, Include_In_CityView__c FROM Highlight_Interaction__c WHERE Id=:pub.Id];
    pub.Status__c='Reviewed'; pub.Publish_To_CityView__c=true; update pub;
    Integer pubI = [SELECT COUNT() FROM Interaction__c WHERE Highlight_Interaction__c=:pub.Id];
    out.put('F5_publicPublishes', pubI>0 ? 'PASS ('+pubI+' interaction)' : 'FAIL: 0 interactions');

    Map<String, Id> idByLast = new Map<String, Id>();
    for (User u : [SELECT Id, LastName FROM User WHERE LastName IN ('E2EGNoPS','E2ERevNoGrp','E2EBoth','E2EReq','E2ENone')]) idByLast.put(u.LastName, u.Id);
    List<String> keyOrder = new List<String>{'GNoPS','RevNoGrp','Both','Req','None'};
    Map<String,String> lbl = new Map<String,String>{'GNoPS'=>'E2EGNoPS','RevNoGrp'=>'E2ERevNoGrp','Both'=>'E2EBoth','Req'=>'E2EReq','None'=>'E2ENone'};

    for (String key : keyOrder) {
        Id uid = idByLast.get(lbl.get(key));
        String privRes='NO-USER'; String pubRes='NO-USER';
        if (uid != null) {
            privRes='NO-ROW';
            for (UserRecordAccess a : [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE RecordId=:priv2.Id AND UserId=:uid]) privRes='read='+a.HasReadAccess+',edit='+a.HasEditAccess;
            pubRes='NO-ROW';
            for (UserRecordAccess a : [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE RecordId=:pub.Id AND UserId=:uid]) pubRes='read='+a.HasReadAccess+',edit='+a.HasEditAccess;
        }
        out.put('SHARE_'+key+'_private', privRes);
        out.put('SHARE_'+key+'_nonPrivate', pubRes);
    }
} finally {
    if (!toClean.isEmpty()) {
        delete [SELECT Id FROM Interaction__c WHERE Highlight_Interaction__c IN :toClean];
        delete toClean;
    }
}

List<String> keys = new List<String>(out.keySet()); keys.sort();
for (String k : keys) System.debug('BRME7020|'+k+'|'+out.get(k));
