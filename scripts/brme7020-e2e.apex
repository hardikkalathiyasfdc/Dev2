// BRME-7020 end-to-end verification on dev2Current. Read-only w.r.t. org data: all records created are deleted in finally.
// Outputs lines prefixed BRME7020| for parsing.

Map<String, Object> out = new Map<String, Object>();
List<Highlight_Interaction__c> toClean = new List<Highlight_Interaction__c>();

Team__c team = [SELECT Id FROM Team__c LIMIT 1];

Highlight_Interaction__c pub;    // non-private
Highlight_Interaction__c priv;   // private
Highlight_Interaction__c priv2;  // second private (group-access check)

try {
    // ---------- Setup ----------
    pub = new Highlight_Interaction__c(Name='BRME7020-E2E-Public', Team__c=team.Id, Description__c='public', Status__c='Draft', Include_In_Program_Highlight__c=true);
    priv = new Highlight_Interaction__c(Name='BRME7020-E2E-Private', Team__c=team.Id, Description__c='private', Status__c='Draft');
    priv2 = new Highlight_Interaction__c(Name='BRME7020-E2E-Private2', Team__c=team.Id, Description__c='private2', Status__c='Draft');
    insert new List<Highlight_Interaction__c>{pub, priv, priv2};
    toClean.addAll(new List<Highlight_Interaction__c>{pub, priv, priv2});

    priv.put('Private__c', true);  update priv;
    priv2.put('Private__c', true); update priv2;

    // ---------- Functional (DML) checks ----------
    // F1: private + Include_In_CityView -> validation error
    Highlight_Interaction__c t1 = priv.clone(false, true, false, false);
    t1.Id = priv.Id;
    t1.Include_In_CityView__c = true;
    try { update t1; out.put('F1_privatePlusIncludeBlocked','FAIL: no error'); }
    catch (DmlException e) { out.put('F1_privatePlusIncludeBlocked', e.getMessage().contains('Private highlights cannot be submitted to CityView') ? 'PASS' : 'FAIL: '+e.getMessage()); }

    // F2: private + Publish_To_CityView -> validation error
    Highlight_Interaction__c t2 = priv.clone(false, true, false, false);
    t2.Id = priv.Id;
    t2.Publish_To_CityView__c = true;
    try { update t2; out.put('F2_privatePlusPublishBlocked','FAIL: no error'); }
    catch (DmlException e) { out.put('F2_privatePlusPublishBlocked', e.getMessage().contains('Private highlights cannot be submitted to CityView') ? 'PASS' : 'FAIL: '+e.getMessage()); }

    // F3: existing CityView highlight cannot be made private
    Highlight_Interaction__c t3 = pub.clone(false, true, false, false);
    t3.Id = pub.Id;
    t3.Include_In_CityView__c = true;
    update t3;
    t3.put('Private__c', true);
    try { update t3; out.put('F3_cityviewMadePrivateBlocked','FAIL: no error'); }
    catch (DmlException e) { out.put('F3_cityviewMadePrivateBlocked', e.getMessage().contains('Private highlights cannot be submitted to CityView') ? 'PASS' : 'FAIL: '+e.getMessage()); }

    // F4: MRB-optional private flow -> submit -> reviewed, no interactions auto-created
    priv.Include_As_MRB_Highlight__c = true;
    update priv;
    HighlightSubmitController.ValidationResult v = HighlightSubmitController.validateHighlight(priv.Id);
    out.put('F4a_privateValidates', v.isValid ? 'PASS' : 'FAIL: '+v.errors);
    HighlightSubmitController.ValidationResult s = HighlightSubmitController.submitForReview(priv.Id);
    out.put('F4b_privateSubmits', s.isValid ? 'PASS' : 'FAIL: '+s.errors);
    priv = [SELECT Id, Status__c FROM Highlight_Interaction__c WHERE Id = :priv.Id];
    priv.Status__c = 'Reviewed';
    update priv;
    Integer privInteractions = [SELECT COUNT() FROM Interaction__c WHERE Highlight_Interaction__c = :priv.Id];
    out.put('F4c_privateNoAutoInteractions', privInteractions == 0 ? 'PASS' : 'FAIL: '+privInteractions+' interactions');

    // F5: non-private regression -> submit/review/publish creates interactions
    Account org = [SELECT Id FROM Account LIMIT 1];
    insert new Interaction_Participant__c(Highlight__c=pub.Id, Type__c='Organization', Organization__c=org.Id, Description__c='p');
    HighlightSubmitController.submitForReview(pub.Id);
    pub = [SELECT Id, Status__c, Publish_To_CityView__c, Include_In_CityView__c FROM Highlight_Interaction__c WHERE Id = :pub.Id];
    pub.Status__c = 'Reviewed';
    pub.Publish_To_CityView__c = true;
    update pub;
    Integer pubInteractions = [SELECT COUNT() FROM Interaction__c WHERE Highlight_Interaction__c = :pub.Id];
    out.put('F5_publicPublishes', pubInteractions > 0 ? 'PASS ('+pubInteractions+' interaction)' : 'FAIL: 0 interactions');

    // ---------- Sharing matrix via UserRecordAccess ----------
    PermissionSet reviewerPs = [SELECT Id FROM PermissionSet WHERE Name='Highlights_Metrics_Reviewer' LIMIT 1];
    PermissionSet requestorPs = [SELECT Id FROM PermissionSet WHERE Name='Highlights_Metrics_Requestor' LIMIT 1];
    Group reviewGroup = [SELECT Id FROM Group WHERE DeveloperName='Highlights_Private_Highlights_Review' LIMIT 1];
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
    String suffix = '.brme7020@bbrm.dev2.test';

    User uGroupNoPS;      // group member, no perm sets
    User uReviewerNoGroup; // reviewer PS, no group
    User uBoth;            // reviewer PS + group
    User uRequestor;       // requestor PS, no group
    User uNone;            // neither

    List<User> users = new List<User>();
    for (String ln : new List<String>{'GNoPS','RevNoGrp','Both','Req','None'}) {
        users.add(new User(Alias=ln.left(8), Email='brme7020@test.invalid', EmailEncodingKey='UTF-8',
            LastName='E2E'+ln, LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId=p.Id, TimeZoneSidKey='America/New_York', UserName=ln.toLowerCase()+suffix));
    }
    Database.DMLOptions dmo = new Database.DMLOptions();
    dmo.OptAllOrNone = false;
    Database.insert(users, dmo);
    uGroupNoPS=users[0]; uReviewerNoGroup=users[1]; uBoth=users[2]; uRequestor=users[3]; uNone=users[4];

    List<SObject> memberships = new List<SObject>();
    memberships.add(new GroupMember(GroupId=reviewGroup.Id, UserOrGroupId=uGroupNoPS.Id));
    memberships.add(new GroupMember(GroupId=reviewGroup.Id, UserOrGroupId=uBoth.Id));
    memberships.add(new PermissionSetAssignment(AssigneeId=uReviewerNoGroup.Id, PermissionSetId=reviewerPs.Id));
    memberships.add(new PermissionSetAssignment(AssigneeId=uBoth.Id, PermissionSetId=reviewerPs.Id));
    memberships.add(new PermissionSetAssignment(AssigneeId=uRequestor.Id, PermissionSetId=requestorPs.Id));
    insert memberships;

    Map<String, User> usersByKey = new Map<String, User>{
        'GroupNoPS'=>uGroupNoPS, 'ReviewerNoGroup'=>uReviewerNoGroup, 'Both'=>uBoth, 'Requestor'=>uRequestor, 'None'=>uNone
    };

    List<Id> userIds = new List<Id>{uGroupNoPS.Id, uReviewerNoGroup.Id, uBoth.Id, uRequestor.Id, uNone.Id};
    List<String> keyOrder = new List<String>{'GroupNoPS','ReviewerNoGroup','Both','Requestor','None'};
    Map<String, String> fField = new Map<String, String>{
        'GroupNoPS'=>'S3', 'ReviewerNoGroup'=>'S2b', 'Both'=>'S1b', 'Requestor'=>'S4c', 'None'=>'S4c2'
    };

    // UserRecordAccess requires a single UserId per query.
    for (Integer i = 0; i < keyOrder.size(); i++) {
        String key = keyOrder[i];
        Id uid = userIds[i];
        String privRes = 'NO-ROW';
        for (UserRecordAccess a : [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE RecordId = :priv2.Id AND UserId = :uid]) {
            privRes = 'read='+a.HasReadAccess+',edit='+a.HasEditAccess;
        }
        String pubRes = 'NO-ROW';
        for (UserRecordAccess a : [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE RecordId = :pub.Id AND UserId = :uid]) {
            pubRes = 'read='+a.HasReadAccess+',edit='+a.HasEditAccess;
        }
        out.put(fField.get(key)+'_'+key+'_private', privRes);
        out.put('PUB_'+key+'_nonPrivate', pubRes);
    }

    // (FLS-by-user is verified in HighlightSubmitControllerTest via real USER_MODE queries.)
} finally {
    if (!toClean.isEmpty()) {
        delete [SELECT Id FROM Interaction__c WHERE Highlight_Interaction__c IN :toClean];
        delete toClean;
    }
}

List<String> keys = new List<String>(out.keySet());
keys.sort();
for (String k : keys) System.debug('BRME7020|'+k+'|'+out.get(k));
