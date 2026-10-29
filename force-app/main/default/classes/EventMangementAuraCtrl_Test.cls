@isTest
private class EventMangementAuraCtrl_Test {
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if( req.getEndpoint().contains('/events')) {
                // Create a fake response
                
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"links": {"self": "/v1/events/170273"},"data": {"type": "events","id": "170273","attributes": {},"relationships": {}}}');
                res.setStatusCode(201);
                
            } else if ( req.getEndpoint().contains('/events/')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"links": {"self": "/v1/events/170273"},"data": {"type": "events","id": "170273","attributes": {},"relationships": {}}}');
                res.setStatusCode(200);
            } else if( req.getEndpoint().contains('/guest-lists/123/guests')) {
                String response = '{"links":{"self":"/v1/guests/117907580"},"data":[{"type_Z":"guests","id":"117907580","attributes":{"first_name":"Zelong","last_name":"Chen","contact_details":{"organization":"Bloomberg L.P.","salutation": "test","country_code":"US","phone_number":"2126174384","email":"forwardtestbg@gmail.com"},"notification_emails":null,"notification_phone_numbers":null,"note":null,"total_guests":2,"plus_ones_checked":0,"main_guest_checked":false,"checkin_date":null,"status":"CheckedIn","seating_map_details":{"seating_color":"RED","seating_color_rgb":"#e6194b","table_label":null,"seat_label":null},"created_date_utc":"2021-06-09T14:46:37Z","updated_date_utc":"2021-06-09T20:55:56Z","changed_by":{"username":null,"device_id":null},"custom_field_values":[{"custom_field_id":279417,"field_name":"Guest Info","value":"----509960---zchen@bloomberg.org----","selected_values":null},{"custom_field_id":279418,"field_name":"Greeting Info","value":"Dear Zelong,","selected_values":null},{"custom_field_id":279419,"field_name":"Guest 1","value":"Zelong Chen","selected_values":null},{"custom_field_id":279423,"field_name":"Party Size","value":"2","selected_values":null},{"custom_field_id":279421,"field_name":"Guest 2","value":"","selected_values":null},{"custom_field_id":279424,"field_name":"Additional Notes","value":"","selected_values":null},{"custom_field_id":279425,"field_name":"Guest 1 Response","value":null,"selected_values":[{"option_id":91951,"color":null,"color_rgb":null,"value":"Yes - Virtual"}]},{"custom_field_id":279426,"field_name":"Guest 2 Response","value":null,"selected_values":[{"option_id":91955,"color":null,"color_rgb":null,"value":"No"}]}],"qr_code_url":"https://qrcodes.zkipster.com/qr/generate?c=zid_c1e6f741-dc40-4d09-b0b1-a4ad57eb6abf&sig=1a0a11d89d7d29ad9b37db6fa6c469466cbc5cfa2408d66b2863d3154ef69a3f","session-details":[],"picture-url":null},"relationships":{"guest_list":{"links":{"self":"/v1/guests/117907580/relationships/guest_list","related":"/v1/guests/117907580/guest_list"},"data":{"type_Z":"guest_lists","id":"509960"}},"custom_fields":{"links":{"self":"/v1/guests/117907580/relationships/custom_fields","related":"/v1/guests/117907580/custom_fields"},"data":[{"type_Z":"custom_fields","id":"279417"},{"type_Z":"custom_fields","id":"279418"},{"type_Z":"custom_fields","id":"279419"},{"type_Z":"custom_fields","id":"279420"},{"type_Z":"custom_fields","id":"279421"},{"type_Z":"custom_fields","id":"279422"},{"type_Z":"custom_fields","id":"279423"},{"type_Z":"custom_fields","id":"279424"},{"type_Z":"custom_fields","id":"279425"},{"type_Z":"custom_fields","id":"279426"}]},"sessions":{"links":{"self":"/v1/guests/117907580/relationships/sessions","related":"/v1/guests/117907580/sessions"},"data":[]}}}],"included":[{"type_Z":"custom_fields","id":"279417","attributes":{"name":"Guest Info","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279417/relationships/event","related":"/v1/custom_fields/279417/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279417"}},{"type_Z":"custom_fields","id":"279418","attributes":{"name":"Greeting Info","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279418/relationships/event","related":"/v1/custom_fields/279418/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279418"}},{"type_Z":"custom_fields","id":"279419","attributes":{"name":"Guest 1","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279419/relationships/event","related":"/v1/custom_fields/279419/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279419"}},{"type_Z":"custom_fields","id":"279420","attributes":{"name":"Guest 1 Attending","field-type":"DropDown","field_options":[{"option_id":91946,"color":null,"color_rgb":null,"value":"Yes","order":1},{"option_id":91947,"color":null,"color_rgb":null,"value":"No","order":2}],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279420/relationships/event","related":"/v1/custom_fields/279420/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279420"}},{"type_Z":"custom_fields","id":"279421","attributes":{"name":"Guest 2","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279421/relationships/event","related":"/v1/custom_fields/279421/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279421"}},{"type_Z":"custom_fields","id":"279422","attributes":{"name":"Guest 2 Attending","field-type":"DropDown","field_options":[{"option_id":91948,"color":null,"color_rgb":null,"value":"Yes","order":1},{"option_id":91949,"color":null,"color_rgb":null,"value":"No","order":2}],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279422/relationships/event","related":"/v1/custom_fields/279422/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279422"}},{"type_Z":"custom_fields","id":"279423","attributes":{"name":"Party Size","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279423/relationships/event","related":"/v1/custom_fields/279423/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279423"}},{"type_Z":"custom_fields","id":"279424","attributes":{"name":"Additional Notes","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279424/relationships/event","related":"/v1/custom_fields/279424/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279424"}},{"type_Z":"custom_fields","id":"279425","attributes":{"name":"Guest 1 Response","field-type":"DropDown","field_options":[{"option_id":91950,"color":null,"color_rgb":null,"value":"Yes - In Person","order":1},{"option_id":91951,"color":null,"color_rgb":null,"value":"Yes - Virtual","order":2},{"option_id":91952,"color":null,"color_rgb":null,"value":"No","order":3}],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279425/relationships/event","related":"/v1/custom_fields/279425/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279425"}},{"type_Z":"custom_fields","id":"279426","attributes":{"name":"Guest 2 Response","field-type":"DropDown","field_options":[{"option_id":91953,"color":null,"color_rgb":null,"value":"Yes - In Person","order":1},{"option_id":91954,"color":null,"color_rgb":null,"value":"Yes - Virtual","order":2},{"option_id":91955,"color":null,"color_rgb":null,"value":"No","order":3}],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279426/relationships/event","related":"/v1/custom_fields/279426/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279426"}}]}';
                res.setHeader('Content-Type', 'application/json');
                res.setBody(response);
                res.setStatusCode(200);
            } else if( req.getEndpoint().contains('/guests/1234')) {
                String response = '{"links":{"self":"/v1/guests/117907580"},"data":{"type_Z":"guests","id":"117907580","attributes":{"first_name":"Zelong","last_name":"Chen","contact_details":{"organization":"Bloomberg L.P.","salutation": "test","country_code":"US","phone_number":"2126174384","email":"forwardtestbg@gmail.com"},"notification_emails":null,"notification_phone_numbers":null,"note":null,"total_guests":2,"plus_ones_checked":0,"main_guest_checked":false,"checkin_date":null,"status":"Confirmed","seating_map_details":{"seating_color":"RED","seating_color_rgb":"#e6194b","table_label":null,"seat_label":null},"created_date_utc":"2021-06-09T14:46:37Z","updated_date_utc":"2021-06-09T20:55:56Z","changed_by":{"username":null,"device_id":null},"custom_field_values":[{"custom_field_id":279417,"field_name":"Guest Info","value":"----509960---zchen@bloomberg.org----","selected_values":null},{"custom_field_id":279418,"field_name":"Greeting Info","value":"Dear Zelong,","selected_values":null},{"custom_field_id":279419,"field_name":"Guest 1","value":"Zelong Chen","selected_values":null},{"custom_field_id":279423,"field_name":"Party Size","value":"2","selected_values":null},{"custom_field_id":279421,"field_name":"Guest 2","value":"","selected_values":null},{"custom_field_id":279424,"field_name":"Additional Notes","value":"","selected_values":null},{"custom_field_id":279425,"field_name":"Guest 1 Response","value":null,"selected_values":[{"option_id":91951,"color":null,"color_rgb":null,"value":"Yes - Virtual"}]},{"custom_field_id":279426,"field_name":"Guest 2 Response","value":null,"selected_values":[{"option_id":91955,"color":null,"color_rgb":null,"value":"No"}]}],"qr_code_url":"https://qrcodes.zkipster.com/qr/generate?c=zid_c1e6f741-dc40-4d09-b0b1-a4ad57eb6abf&sig=1a0a11d89d7d29ad9b37db6fa6c469466cbc5cfa2408d66b2863d3154ef69a3f","session-details":[],"picture-url":null},"relationships":{"guest_list":{"links":{"self":"/v1/guests/117907580/relationships/guest_list","related":"/v1/guests/117907580/guest_list"},"data":{"type_Z":"guest_lists","id":"509960"}},"custom_fields":{"links":{"self":"/v1/guests/117907580/relationships/custom_fields","related":"/v1/guests/117907580/custom_fields"},"data":[{"type_Z":"custom_fields","id":"279417"},{"type_Z":"custom_fields","id":"279418"},{"type_Z":"custom_fields","id":"279419"},{"type_Z":"custom_fields","id":"279420"},{"type_Z":"custom_fields","id":"279421"},{"type_Z":"custom_fields","id":"279422"},{"type_Z":"custom_fields","id":"279423"},{"type_Z":"custom_fields","id":"279424"},{"type_Z":"custom_fields","id":"279425"},{"type_Z":"custom_fields","id":"279426"}]},"sessions":{"links":{"self":"/v1/guests/117907580/relationships/sessions","related":"/v1/guests/117907580/sessions"},"data":[]}}},"included":[{"type_Z":"custom_fields","id":"279417","attributes":{"name":"Guest Info","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279417/relationships/event","related":"/v1/custom_fields/279417/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279417"}},{"type_Z":"custom_fields","id":"279418","attributes":{"name":"Greeting Info","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279418/relationships/event","related":"/v1/custom_fields/279418/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279418"}},{"type_Z":"custom_fields","id":"279419","attributes":{"name":"Guest 1","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279419/relationships/event","related":"/v1/custom_fields/279419/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279419"}},{"type_Z":"custom_fields","id":"279420","attributes":{"name":"Guest 1 Attending","field-type":"DropDown","field_options":[{"option_id":91946,"color":null,"color_rgb":null,"value":"Yes","order":1},{"option_id":91947,"color":null,"color_rgb":null,"value":"No","order":2}],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279420/relationships/event","related":"/v1/custom_fields/279420/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279420"}},{"type_Z":"custom_fields","id":"279421","attributes":{"name":"Guest 2","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279421/relationships/event","related":"/v1/custom_fields/279421/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279421"}},{"type_Z":"custom_fields","id":"279422","attributes":{"name":"Guest 2 Attending","field-type":"DropDown","field_options":[{"option_id":91948,"color":null,"color_rgb":null,"value":"Yes","order":1},{"option_id":91949,"color":null,"color_rgb":null,"value":"No","order":2}],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279422/relationships/event","related":"/v1/custom_fields/279422/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279422"}},{"type_Z":"custom_fields","id":"279423","attributes":{"name":"Party Size","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279423/relationships/event","related":"/v1/custom_fields/279423/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279423"}},{"type_Z":"custom_fields","id":"279424","attributes":{"name":"Additional Notes","field-type":"TextField","field_options":[],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279424/relationships/event","related":"/v1/custom_fields/279424/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279424"}},{"type_Z":"custom_fields","id":"279425","attributes":{"name":"Guest 1 Response","field-type":"DropDown","field_options":[{"option_id":91950,"color":null,"color_rgb":null,"value":"Yes - In Person","order":1},{"option_id":91951,"color":null,"color_rgb":null,"value":"Yes - Virtual","order":2},{"option_id":91952,"color":null,"color_rgb":null,"value":"No","order":3}],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279425/relationships/event","related":"/v1/custom_fields/279425/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279425"}},{"type_Z":"custom_fields","id":"279426","attributes":{"name":"Guest 2 Response","field-type":"DropDown","field_options":[{"option_id":91953,"color":null,"color_rgb":null,"value":"Yes - In Person","order":1},{"option_id":91954,"color":null,"color_rgb":null,"value":"Yes - Virtual","order":2},{"option_id":91955,"color":null,"color_rgb":null,"value":"No","order":3}],"hidden-from-apps":false},"relationships":{"event":{"links":{"self":"/v1/custom_fields/279426/relationships/event","related":"/v1/custom_fields/279426/event"},"data":{"type_Z":"events","id":"261005"}}},"links":{"self":"/v1/custom_fields/279426"}}]}';
                res.setHeader('Content-Type', 'application/json');
                res.setBody(response);
                res.setStatusCode(200);
            }else if ( req.getEndpoint().contains('/guest-lists') ) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"links": {"self": "/guest-lists/123"},"data": {"type": "guest-lists","id": "123","attributes": {},"relationships": {}}}');
                res.setStatusCode(201);
            } else if ( req.getEndpoint().contains('/guests')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"links": {"self": "/guests/123"},"data": {"type": "guests","id": "123","attributes": {},"relationships": {}}}');
                res.setStatusCode(201);
            } else if(req.getEndpoint().contains('/guests/') && req.getMethod() == 'DELETE') {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"links": {"self": "/guests/123"},"data": {"type": "guests","id": "123","attributes": {},"relationships": {}}}');
                res.setStatusCode(204);
            } 
            
            return res;
        }
    }
    
    @testSetup
    static void dataPrep() {
        Contact cnt = new Contact(FirstName='test', LastName='test', Email='test@test1.com', DoNotCall=false);
        Contact cnt1 = new Contact(FirstName='test1', LastName='test1', Email='test1@test1.com', DoNotCall=false);
        Contact cnt2 = new Contact(FirstName='test2', LastName='test2', DoNotCall=false);
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(new List<Contact>{cnt, cnt1, cnt2}, dml, AccessLevel.SYSTEM_MODE);
        
        cnt1.Significant_Other__c = cnt.Id;
        cnt.Significant_Other__c = cnt1.Id;
        Database.update(new List<Contact>{cnt, cnt1}, dml, AccessLevel.SYSTEM_MODE);
        
        Related_Contact__c relatedContact = new Related_Contact__c();
        relatedContact.Main_Contact__c = cnt.Id;
        relatedContact.Related_Contact__c = cnt1.Id;
        
        Related_Contact__c relatedContact1 = new Related_Contact__c();
        relatedContact1.Main_Contact__c = cnt1.Id;
        relatedContact1.Related_Contact__c = cnt.Id;
        
        insert as system new List<Related_Contact__c>{relatedContact, relatedContact1};
            
        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
        insert as system cm;
        
        CampaignMember member = new CampaignMember();
        member.ContactId = cnt.Id;
        member.CampaignId = cm.Id;
        
        CampaignMember member1 = new CampaignMember();
        member1.ContactId = cnt2.Id;
        member1.CampaignId = cm.Id;
        
        CampaignMember member2 = new CampaignMember();
        member2.ContactId = cnt1.Id;
        member2.CampaignId = cm.Id;
        insert as system new List<CampaignMember>{member, member1, member2};
            
        UnplannedGuest__c unplannedGuest = new UnplannedGuest__c();
        unplannedGuest.Event__c = cm.Id;
        unplannedGuest.FirstName__c = 'test1';
        unplannedGuest.LastName__c = 'test2';
        unplannedGuest.ZkipserGuestId__c = '232323';
        
        insert as system unplannedGuest;
    }
    
    @isTest
    static void testGenerals() {
        Test.startTest();
        List<CampaignMember> members = [SELECT Id, ContactId FROM CampaignMember WITH SYSTEM_MODE];
        Contact c = [Select Id from Contact where Id =: members[0].ContactId WITH SYSTEM_MODE];
        System.debug('members ::::: '+members.size());
        List<UnplannedGuest__c> guest = [SELECT Id FROM UnplannedGuest__c WITH SYSTEM_MODE];
        
        // Pre-existing broken call: updateAssistants signature is (List<Id>, Boolean, List<String>, List<String>, Boolean)
        // EventMangementAuraCtrl.updateAssistants(new List<Id> {members[0].Id}, 'true', true);
        String contInfo = EventMangementAuraCtrl.getContactInfo(members[0].Id);
        String currentUser = EventMangementAuraCtrl.getCurrentUser('');
        String timeZone = EventMangementAuraCtrl.getCurrentTiemZone();
        String orgEmails = EventMangementAuraCtrl.getOrgEmails();
        EventMangementAuraCtrl.deleteGuests(JSON.serialize(new List<String>{members[0].Id}));
        Object result = EventMangementAuraCtrl.searchList('test', 'test');
        Object conts = EventMangementAuraCtrl.searchContact('test test');
        Object conts1 = EventMangementAuraCtrl.searchContact('test');
        String recordId = EventMangementAuraCtrl.getEventRecordTypeId();
        EventMangementAuraCtrl.deleteUnplannedGuest(guest[0].Id);
        EventMangementAuraCtrl.getContacts(new List<String> {c.Id});
        EventMangementAuraCtrl.getCountryStateCodes();
        EventMangementAuraCtrl.getCountryPickLists('Contact', 'MailingCountry');
        EventMangementAuraCtrl.getStatePickLists('Contact', 'MailingCountry', 'MailingState');
        try{
            EventMangementAuraCtrl.findDuplicates(c);
        }catch(Exception ex){}
        Test.stopTest();
    }
    
    @isTest
    static void testGuestEventSync() {
        Test.startTest();
        Campaign cam = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        EventMangementAuraCtrl.syncEvent(cam.Id);
        Boolean isEventList = EventMangementAuraCtrl.checkEventList(cam.Id);
        String result = EventMangementAuraCtrl.getUnplannedGuests(cam.Id);
        Test.stopTest();
        System.assertEquals(true, isEventList);
    }

    @isTest
    static void testCancelledGuestEventSync() {
        Test.startTest();
        Campaign cam = [SELECT Id,EventStatus__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        cam.EventStatus__c = 'Cancelled';
        update as system cam;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        EventMangementAuraCtrl.syncEvent(cam.Id);
        Boolean isEventList = EventMangementAuraCtrl.checkEventList(cam.Id);
        String result = EventMangementAuraCtrl.getUnplannedGuests(cam.Id);
        Test.stopTest();
        System.assertEquals(true, isEventList);
    }

    @isTest
    static void testFromEventSync() {
        Test.startTest();
        Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        cam.ZkipsterGuestListId__c = '123';
        update as system cam;
        
        List<CampaignMember> members = [SELECT Id, ZkipsterGuestId__c FROM CampaignMember WITH SYSTEM_MODE];
        members[0].ZkipsterGuestId__c = '117907580';
        update as system members;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        EventMangementAuraCtrl.startSyncFromZkipster(cam.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testFromEventSyncMore() {
        Test.startTest();
        Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        cam.ZkipsterGuestListId__c = '123';
        update as system cam;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        EventMangementAuraCtrl.startSyncFromZkipster(cam.Id);
        
        String orgEmailUpdate = EventMangementAuraCtrl.getOrgEmailsByEvent(cam.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateOrgEmail() {
        Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        cam.ZkipsterGuestListId__c = '123';
        update as system cam;
        
        List<OrgWideEmailAddress> addresses = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WITH SYSTEM_MODE];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        String result = EventMangementAuraCtrl.updateOrgEmails(JSON.serialize(addresses[0]), cam.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSaveListGuests() {
        Test.startTest();
        Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        cam.ZkipsterGuestListId__c = '123';
        update as system cam;
        
        Contact cnt = new Contact(FirstName='te1st', LastName='t12est', Email='te2st@test11.com', DoNotCall=false);
        Contact cnt1 = new Contact(FirstName='tes2fst1', LastName='te32st1', Email='te13st1@te2st1.com', DoNotCall=false);
        Contact cnt2 = new Contact(FirstName='tes3232t2', LastName='te1sdst2', DoNotCall=false);
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(new List<Contact>{cnt, cnt1, cnt2}, dml, AccessLevel.SYSTEM_MODE);
        
        Campaign cm = new Campaign();
        cm.Name = 'test campaign1';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;        
        User u = [select Id from User where User.Name = 'Diana Meyer' WITH SYSTEM_MODE];
        
        System.runAs(u) {
            insert as system cm;
        }
        
        CampaignMember member = new CampaignMember();
        member.ContactId = cnt.Id;
        member.CampaignId = cm.Id;
        
        CampaignMember member1 = new CampaignMember();
        member1.ContactId = cnt2.Id;
        member1.CampaignId = cm.Id;
        
        CampaignMember member2 = new CampaignMember();
        member2.ContactId = cnt1.Id;
        member2.CampaignId = cm.Id;
        insert as system new List<CampaignMember>{member, member1, member2};
            
        EventMangementAuraCtrl.saveListGuests(JSON.serialize(new List<Campaign>{cm}), cam.Id, 'as', '', '');
        Test.stopTest();
    }
    
    @isTest
    static void testSaveContactGuests() {
        Test.startTest();
        Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        update as system cam;
        
        Contact cnt = new Contact(FirstName='te1st', LastName='t12est', Email='te2st@test11.com', DoNotCall=false);
        Contact cnt1 = new Contact(FirstName='tes2fst1', LastName='te32st1', Email='te13st1@te2st1.com', DoNotCall=false);
        Contact cnt2 = new Contact(FirstName='tes3232t2', LastName='te1sdst2', DoNotCall=false);
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(new List<Contact>{cnt, cnt1, cnt2}, dml, AccessLevel.SYSTEM_MODE);
        String cntIds = cnt.Id+','+cnt1.Id+','+cnt2.Id;
        
        Object result = EventMangementAuraCtrl.saveContactGuests(cam.Id, cntIds, 'waitingList', 'recommendedBy', '', '');
        Object result1 = EventMangementAuraCtrl.saveContactGuests(cam.Id, cntIds, 'as', 'recommendedBy', 'Yes', 'Did Not Attend');
        Test.stopTest();
    }
    
    @isTest
    static void testSyncToZkipsterBatch() {
        Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        cam.ZkipsterGuestListId__c = '123';
        update as system cam;
        
        List<CampaignMember> members = [SELECT Id, ZkipsterGuestId__c FROM CampaignMember WITH SYSTEM_MODE];
        members[0].ZkipsterGuestId__c = '123232';
        update as system members;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        String query = 'SELECT Id,CreatedBy.Email, UB_FirstName__c, Table__c, Seat__c, Guest_Email__c, First_Preferred_First_Name__c, SpouseInvited__c, RSVPNotes__c, UB_LastName__c, Contact.Full_Name__c, Contact.CorrespondenceDearLine__c, Contact.Account.Name, EventEmail__c, RSVPStatus__c, ZkipsterGuestId__c, PartySize__c, Phone, Contact.Significant_Other__r.Full_Name__c, Campaign.ZkipsterGuestListId__c, Contact.Restricted__c, Contact.RestrictedFirstName__c, Contact.RestrictedLastName__c, Contact.Account.Restricted_Org_Name__c ' ;
        query += ' FROM CampaignMember WHERE CampaignId =\''+cam.Id+'\'';
        SyncGuestsToZkipster sync = new SyncGuestsToZkipster();
        sync.campId= cam.Id;
        sync.query = query;
        Database.executeBatch(sync, 100); 
        Test.stopTest();
    }
    
    @isTest
    static void testSyncToGetGuestInfo() {
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ZkipsterIntegration.getZkipsterGuestInfo('1234');
        
        Test.stopTest();
    }

    @isTest
    static void ZkipsterGetAllGuestsAsyncEmailTest(){
        Campaign cam = [SELECT Id, Name, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        
        // Set up the user context
        User u = TestDataFactory.createUser();
        System.runAs(u) {
            Test.startTest();
            ZkipsterGetAllGuestsAsync.sendEmailAlerts('success',cam.Name);
            Test.stopTest();
        }
    }

    @isTest
    static void SyncGuestsToZkipsterEmailTest(){
        Campaign cam = [SELECT Id, Name FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        
        // Set up the user context
        User u = TestDataFactory.createUser();
        System.runAs(u) {
            Test.startTest();
            SyncGuestsToZkipster.sendEmailAlerts('success', cam);
            SyncGuestsToZkipster.sendEmailAlerts('failed', cam);
            Test.stopTest();
        }
    }

    @isTest
    static void testSyncToZkipsterFailureSetsFailed() {
        Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        cam.ZkipsterGuestListId__c = '123';
        update as system cam;
        
        List<CampaignMember> members = [SELECT Id, ZkipsterGuestId__c, Synced_With_Zkipster__c FROM CampaignMember WITH SYSTEM_MODE];
        members[0].ZkipsterGuestId__c = '123232';
        update as system members;
        
        // Mock that fails every callout (500) so zkipsterCallout returns 'error'
        Test.setMock(HttpCalloutMock.class, new MockHttpFailureGenerator());
        String query = 'SELECT Id, CreatedBy.Email, UB_FirstName__c, Table__c, Seat__c, Guest_Email__c, First_Preferred_First_Name__c, Last_Preferred_Last_Name__c, SpouseInvited__c, RSVPNotes__c, UB_LastName__c, Title, Dietary__c, Contact.Full_Name__c, Contact.FirstName, Contact.LastName, Contact.Salutation, Contact.RestrictedSalutation__c, Contact.CorrespondenceDearLine__c, Contact.Account.Name, EventEmail__c, RSVPStatus__c, ZkipsterGuestId__c, PartySize__c, Phone, Contact.Significant_Other__r.Full_Name__c, Campaign.ZkipsterGuestListId__c, Contact.Restricted__c, Contact.RestrictedFirstName__c, Contact.RestrictedLastName__c, Contact.Account.Restricted_Org_Name__c, Synced_With_Zkipster__c ' ;
        query += ' FROM CampaignMember WHERE CampaignId =\''+cam.Id+'\'';
        
        SyncGuestsToZkipster sync = new SyncGuestsToZkipster();
        sync.campId = cam.Id;
        sync.query = query;
        // Full-field scope so Contact reads in the dedup guard don't throw SObjectException
        List<CampaignMember> scope = (List<CampaignMember>) Database.query(query);
        
        Test.startTest();
        // Call execute directly to avoid chaining the retry batch (test context allows only one async execution)
        sync.execute(null, scope);
        Test.stopTest();
        
        System.assertEquals(true, sync.isFailed, 'A failed callout must flag the batch as failed');
        System.assertEquals(members.size(), sync.failedRecordIds.size(), 'Every failed guest should be tracked for retry');
        
        List<CampaignMember> after = [SELECT Id, Synced_With_Zkipster__c FROM CampaignMember WHERE Id IN :members WITH SYSTEM_MODE];
        for (CampaignMember m : after) {
            System.assertEquals(false, m.Synced_With_Zkipster__c, 'Failed guests must not be marked as synced');
        }
    }

    public class MockHttpFailureGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"Internal Server Error"}');
            res.setStatusCode(500);
            return res;
        }
    }

    public class MockZkipsterDedupGenerator implements HttpCalloutMock {
        private Integer createCount = 0;
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String ep = req.getEndpoint();
            String method = req.getMethod();
            if (method == 'GET' && ep.contains('/guest-lists/') && ep.contains('/guests')) {
                // Guest-list lookup: return an existing guest named "test test" to force a dedup match
                res.setBody('{"data":[{"type":"guests","id":"999888","attributes":{"first-name":"test","last-name":"test"}}]}');
                res.setStatusCode(200);
            } else if (method == 'PATCH') {
                res.setBody('{"data":{"type":"guests","id":"999888","attributes":{}}}');
                res.setStatusCode(200);
            } else if (method == 'POST' && ep.contains('/guests')) {
                // Unique id per create: ZkipsterGuestId__c has a unique constraint, a repeated id fails DML
                createCount++;
                res.setBody('{"data":{"type":"guests","id":"ZK' + createCount + '","attributes":{}}}');
                res.setStatusCode(201);
            } else {
                res.setBody('{"data":{"id":"123","attributes":{}}}');
                res.setStatusCode(200);
            }
            return res;
        }
    }

    @isTest
    static void testSyncToZkipsterDedupLinksExistingGuest() {
        Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        cam.ZkipsterGuestListId__c = '123';
        update as system cam;
        
        List<CampaignMember> members = [SELECT Id, ZkipsterGuestId__c FROM CampaignMember WITH SYSTEM_MODE];
        for (CampaignMember m : members) { m.PartySize__c = 1; }
        update as system members;
        
        Test.setMock(HttpCalloutMock.class, new MockZkipsterDedupGenerator());
        String query = 'SELECT Id, CreatedBy.Email, UB_FirstName__c, Table__c, Seat__c, Guest_Email__c, First_Preferred_First_Name__c, Last_Preferred_Last_Name__c, SpouseInvited__c, RSVPNotes__c, UB_LastName__c, Title, Dietary__c, Contact.Full_Name__c, Contact.FirstName, Contact.LastName, Contact.Salutation, Contact.RestrictedSalutation__c, Contact.CorrespondenceDearLine__c, Contact.Account.Name, EventEmail__c, RSVPStatus__c, ZkipsterGuestId__c, PartySize__c, Phone, Contact.Significant_Other__r.Full_Name__c, Campaign.ZkipsterGuestListId__c, Contact.Restricted__c, Contact.RestrictedFirstName__c, Contact.RestrictedLastName__c, Contact.Account.Restricted_Org_Name__c, Synced_With_Zkipster__c ' ;
        query += ' FROM CampaignMember WHERE CampaignId =\''+cam.Id+'\'';
        
        SyncGuestsToZkipster sync = new SyncGuestsToZkipster();
        sync.campId = cam.Id;
        sync.query = query;
        // Query with full field set (incl. Campaign.ZkipsterGuestListId__c) as the real batch would
        List<CampaignMember> scope = (List<CampaignMember>) Database.query(query);
        
        Test.startTest();
        sync.execute(null, scope);
            Test.stopTest();
        
        // Diagnose: report member sync state + any BBApps error log (callout errors are logged via BBApps_ErrorHandler)
        List<BBApps_Error_Log__c> errs = [SELECT Id, Error_Details__c FROM BBApps_Error_Log__c WITH SYSTEM_MODE ORDER BY CreatedDate DESC LIMIT 3];
        String errMsg = errs.isEmpty() ? 'noErr' : errs[0].Error_Details__c;
        List<CampaignMember> after = [SELECT ZkipsterGuestId__c, Synced_With_Zkipster__c FROM CampaignMember WHERE Id IN :members WITH SYSTEM_MODE];
        String state = '';
        for (CampaignMember m : after) { state += '[' + m.ZkipsterGuestId__c + '/' + m.Synced_With_Zkipster__c + ']'; }
        System.assertEquals(false, sync.isFailed, 'failedIds=' + sync.failedRecordIds.size() + ' state=' + state + ' err=' + errMsg);
        }

    @isTest
    static void testGetAllZkipsterGuestIdsByName() {
        Test.setMock(HttpCalloutMock.class, new MockZkipsterDedupGenerator());
        Test.startTest();
        Map<String, String> result = ZkipsterIntegration.getAllZkipsterGuestIdsByName('123');
        Test.stopTest();
        System.assertEquals('999888', result.get('test|test'), 'Lookup should map name to zkipster guest id');
    }

    @isTest
    static void testSaveContactWithoutDuplicate() {
        Test.startTest();
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com'
        );
        
        EventMangementAuraCtrl.saveContact(testContact, false);
        Test.stopTest(); 
    }
    
    @isTest
    static void testSaveContactWithDuplicateAllowed() {
        Test.startTest();
        // Create a contact first
        Contact existingContact = new Contact(
            FirstName = 'Duplicate',
            LastName = 'User',
            Email = 'duplicate@example.com'
        );
        insert as system existingContact;
        
        // Try to insert a duplicate
        Contact duplicateContact = new Contact(
            FirstName = 'Duplicate',
            LastName = 'User',
            Email = 'duplicate@example.com'
        );
        
        EventMangementAuraCtrl.saveContact(duplicateContact, true);
        Test.stopTest();
    }
    
    @isTest
    static void testGetContacts() {
        Test.startTest();
        Contact contact1 = new Contact(FirstName = 'Alice', LastName = 'Smith', Email = 'alice@example.com');
        Contact contact2 = new Contact(FirstName = 'Bob', LastName = 'Jones', Email = 'bob@example.com');
        insert as system new List<Contact>{contact1, contact2};
        List<String> contactIds = new List<String>{contact1.Id, contact2.Id};   
        List<Contact> contacts = EventMangementAuraCtrl.getContacts(contactIds);
        Test.stopTest();
    }
    
    @isTest
    static void testCreateEvent() {
        Test.startTest();
        
        Campaign testEvent = new Campaign(
            Name = 'Test Event',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1)
        );
        
        EventMangementAuraCtrl.createEvent(testEvent);
        Test.stopTest();
    }
    
    @isTest
    static void testGetSearchContactInfo() {
        Test.startTest();
        // Create and insert a test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert as system testContact;
        
        Contact result = EventMangementAuraCtrl.getSearchContactInfo(testContact.Id);
        Test.stopTest();
    }
    
    @isTest
    static void errorBlockTest () {
        try {
            Campaign cam = [SELECT Id, ZkipsterGuestListId__c FROM Campaign WITH SYSTEM_MODE LIMIT 1];
            cam.ZkipsterGuestListId__c = '123';
            update as system cam;
            
            List<CampaignMember> members = [SELECT Id, ZkipsterGuestId__c FROM CampaignMember WITH SYSTEM_MODE];
            members[0].ZkipsterGuestId__c = '123232';
            update as system members;
            
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            String query = 'SELECT Id, CreatedBy.Email, UB_FirstName__c, Table__c, Seat__c, Guest_Email__c, First_Preferred_First_Name__c, SpouseInvited__c, RSVPNotes__c, UB_LastName__c, Contact.Full_Name__c, Contact.Account.Name, EventEmail__c, RSVPStatus__c, ZkipsterGuestId__c, PartySize__c, Phone, Contact.Significant_Other__r.Full_Name__c, Campaign.ZkipsterGuestListId__c, Contact.Restricted__c, Contact.RestrictedFirstName__c, Contact.RestrictedLastName__c, Contact.Account.Restricted_Org_Name__c ' ;
            query += ' FROM CampaignMember WHERE CampaignId =\''+cam.Id+'\'';
            SyncGuestsToZkipster sync = new SyncGuestsToZkipster(new List<Id> {cam.Id});
            sync.campId= cam.Id;
            sync.query = query;
            Database.executeBatch(sync, 100); 
            
            Test.stopTest();
        } catch (Exception e) {
            
        }
    }
    
    @isTest
    static void testGetContactIdsByTagIds() {
        Test.startTest();
        Contact testContact = new Contact(
            FirstName = 'Test2',
            LastName = 'User2',
            Email = 'testuser2@example.com'
        );
        insert as system testContact;
        Tag__c tagRec = TestDataFactory.getTag('Arts');
        insert as system tagRec;
        Tag_Junction__c tagJnRec = TestDataFactory.getTagJunc(tagRec,testContact);
        system.debug(tagJnRec);
        insert as system tagJnRec;
        system.debug(tagJnRec);
        
        List<Id> result = EventMangementAuraCtrl.getContactIdsByTagIds(
            new List<String>{tagRec.Id}
        );
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return 1 unique contact Ids');
        System.assert(result.contains(testContact.Id));
    }
}