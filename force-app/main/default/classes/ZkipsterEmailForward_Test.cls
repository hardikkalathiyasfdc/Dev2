@isTest
private class ZkipsterEmailForward_Test {
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            String response = '{"links": {"self": "/v1/guests/117907580"}, "data": {"type_Z": "guests", "id": "117907580", "relationships": {"custom_fields": {"links": {"self": "/v1/guests/117907580/relationships/custom_fields", "related": "/v1/guests/117907580/custom_fields"}, "data": [{"type_Z": "custom_fields", "id": "279417"}, {"type_Z": "custom_fields", "id": "279418"}, {"type_Z": "custom_fields", "id": "279419"}, {"type_Z": "custom_fields", "id": "279420"}, {"type_Z": "custom_fields", "id": "279421"}, {"type_Z": "custom_fields", "id": "279422"}, {"type_Z": "custom_fields", "id": "279423"}, {"type_Z": "custom_fields", "id": "279424"}, {"type_Z": "custom_fields", "id": "279425"}, {"type_Z": "custom_fields", "id": "279426"}]}, "sessions": {"links": {"self": "/v1/guests/117907580/relationships/sessions", "related": "/v1/guests/117907580/sessions"}, "data": []}, "guest_list": {"links": {"self": "/v1/guests/117907580/relationships/guest_list", "related": "/v1/guests/117907580/guest_list"}, "data": {"type_Z": "guest_lists", "id": "509960"}}}, "attributes": {"contact_details": {"phone_number": "2126174384", "organization": "Bloomberg L.P.", "country_code": "US", "email": "forwardtestbg@gmail.com"}, "notification_emails": null, "checkin_date": null, "updated_date_utc": "2021-06-09T20:55:56Z", "plus_ones_checked": 0, "total_guests": 2, "status": "Confirmed", "custom_field_values": [{"field_name": "Guest Info", "selected_values": null, "value": "----509960---zchen@bloomberg.org----", "custom_field_id": 279417}, {"field_name": "Greeting Info", "selected_values": null, "value": "Dear Zelong,", "custom_field_id": 279418}, {"field_name": "Guest 1", "selected_values": null, "value": "Zelong Chen", "custom_field_id": 279419}, {"field_name": "Party Size", "selected_values": null, "value": "2", "custom_field_id": 279423}, {"field_name": "Guest 2", "selected_values": null, "value": "", "custom_field_id": 279421}, {"field_name": "Additional Notes", "selected_values": null, "value": "", "custom_field_id": 279424}, {"field_name": "Guest 1 Response", "selected_values": [{"option_id": 91951, "color": null, "color_rgb": null, "value": "Yes - In Person"}], "value": null, "custom_field_id": 279425}, {"field_name": "Guest 1 Attending", "selected_values": [{"option_id": 91951, "color": null, "color_rgb": null, "value": "Yes"}], "value": null, "custom_field_id": 279425}, {"field_name": "Guest 2 Response", "selected_values": [{"option_id": 91955, "color": null, "color_rgb": null, "value": "No"}], "value": null, "custom_field_id": 279426}], "qr_code_url": "https://qrcodes.zkipster.com/qr/generate?c=zid_c1e6f741-dc40-4d09-b0b1-a4ad57eb6abf&sig=1a0a11d89d7d29ad9b37db6fa6c469466cbc5cfa2408d66b2863d3154ef69a3f", "notification_phone_numbers": null, "main_guest_checked": false, "picture-url": null, "seating_map_details": {"seating_color": "RED", "seating_color_rgb": "#e6194b", "seat_label": null, "table_label": null}, "created_date_utc": "2021-06-09T14:46:37Z", "last_name": "Chen", "first_name": "Zelong", "note": null, "session-details": [], "changed_by": {"username": null, "device_id": null}}}}';
            res.setHeader('Content-Type', 'application/json');
            res.setBody(response);
            res.setStatusCode(200);
            
            return res;
        }
    }

    public class MockHttpResponseDeclineGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            String response = '{"links": {"self": "/v1/guests/117907580"}, "data": {"type_Z": "guests", "id": "117907580", "relationships": {"custom_fields": {"links": {"self": "/v1/guests/117907580/relationships/custom_fields", "related": "/v1/guests/117907580/custom_fields"}, "data": [{"type_Z": "custom_fields", "id": "279417"}, {"type_Z": "custom_fields", "id": "279418"}, {"type_Z": "custom_fields", "id": "279419"}, {"type_Z": "custom_fields", "id": "279420"}, {"type_Z": "custom_fields", "id": "279421"}, {"type_Z": "custom_fields", "id": "279422"}, {"type_Z": "custom_fields", "id": "279423"}, {"type_Z": "custom_fields", "id": "279424"}, {"type_Z": "custom_fields", "id": "279425"}, {"type_Z": "custom_fields", "id": "279426"}]}, "sessions": {"links": {"self": "/v1/guests/117907580/relationships/sessions", "related": "/v1/guests/117907580/sessions"}, "data": []}, "guest_list": {"links": {"self": "/v1/guests/117907580/relationships/guest_list", "related": "/v1/guests/117907580/guest_list"}, "data": {"type_Z": "guest_lists", "id": "509960"}}}, "attributes": {"contact_details": {"phone_number": "2126174384", "organization": "Bloomberg L.P.", "country_code": "US", "email": "forwardtestbg@gmail.com"}, "notification_emails": null, "checkin_date": null, "updated_date_utc": "2021-06-09T20:55:56Z", "plus_ones_checked": 0, "total_guests": 2, "status": "Confirmed", "custom_field_values": [{"field_name": "Guest Info", "selected_values": null, "value": "----509960---zchen@bloomberg.org----", "custom_field_id": 279417}, {"field_name": "Greeting Info", "selected_values": null, "value": "Dear Zelong,", "custom_field_id": 279418}, {"field_name": "Guest 1", "selected_values": null, "value": "Zelong Chen", "custom_field_id": 279419}, {"field_name": "Party Size", "selected_values": null, "value": "2", "custom_field_id": 279423}, {"field_name": "Guest 2", "selected_values": null, "value": "", "custom_field_id": 279421}, {"field_name": "Additional Notes", "selected_values": null, "value": "", "custom_field_id": 279424}, {"field_name": "Guest 1 Response", "selected_values": [{"option_id": 91951, "color": null, "color_rgb": null, "value": "No"}], "value": null, "custom_field_id": 279425}, {"field_name": "Guest 1 Attending", "selected_values": [{"option_id": 91951, "color": null, "color_rgb": null, "value": "No"}], "value": null, "custom_field_id": 279425}, {"field_name": "Guest 2 Response", "selected_values": [{"option_id": 91955, "color": null, "color_rgb": null, "value": "No"}], "value": null, "custom_field_id": 279426}], "qr_code_url": "https://qrcodes.zkipster.com/qr/generate?c=zid_c1e6f741-dc40-4d09-b0b1-a4ad57eb6abf&sig=1a0a11d89d7d29ad9b37db6fa6c469466cbc5cfa2408d66b2863d3154ef69a3f", "notification_phone_numbers": null, "main_guest_checked": false, "picture-url": null, "seating_map_details": {"seating_color": "RED", "seating_color_rgb": "#e6194b", "seat_label": null, "table_label": null}, "created_date_utc": "2021-06-09T14:46:37Z", "last_name": "Chen", "first_name": "Zelong", "note": null, "session-details": [], "changed_by": {"username": null, "device_id": null}}}}';
            res.setHeader('Content-Type', 'application/json');
            res.setBody(response);
            res.setStatusCode(200);
            
            return res;
        }
    }

    @testSetup
    static void dataPrep() {

        Contact cnt = new Contact(FirstName='test', LastName='test', Email='test@test1.com', DoNotCall=false);
        Contact cnt1 = new Contact(FirstName='test1', LastName='test1', Email='test1@test1.com', DoNotCall=false);
        Contact cnt2 = new Contact(FirstName='test2', LastName='test2', DoNotCall=false);

        insert new List<Contact>{cnt, cnt1, cnt2};

        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
        cm.InvitationFromEmail__c = [SELECT Address FROM OrgWideEmailAddress][0].Address;
        cm.LocationName__c = 'location Name';
        cm.LocationDetail__c = 'second floor';
        cm.City__c = 'ny';
        cm.State__c = 'NY';
        cm.AddressLine__c = ' address line';
        insert cm;

        CampaignMember member = new CampaignMember();
        member.ContactId = cnt.Id;
        member.CampaignId = cm.Id;

        CampaignMember member1 = new CampaignMember();
        member1.ContactId = cnt2.Id;
        member1.CampaignId = cm.Id;

        CampaignMember member2 = new CampaignMember();
        member2.ContactId = cnt1.Id;
        member2.CampaignId = cm.Id;
        insert new List<CampaignMember>{member, member1, member2};

    }

    @isTest
    static void testEmailNotification() {

     CampaignMember member = [SELECT Id FROM CampaignMember LIMIT 1];

    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
        email.htmlBody = '<td><p>----'+member.Id+'----</p></td><p>===EventLocation===</p>****{"eventType":"confirmation"}****';
    email.subject = 'CONFIRMATION for someone';

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    // create an instance of the EmailToSalesForce class and test it with the data in the testMethod
    ZkipsterEmailForward emailServiceObj = new ZkipsterEmailForward();
    //emailServiceObj.handleInboundEmail(email, env ); 
        ZkipsterEmailForward.processEmailBody(email.htmlBody,email.subject,'populated_by_event_details_in_@brm.com');
           email.htmlBody = '<td><p>----'+member.Id+'----</p></td><p>===EventLocation===</p>****{"eventType":"unconfirm"}****';
 //emailServiceObj.handleInboundEmail(email, env );  
        ZkipsterEmailForward.processEmailBody(email.htmlBody,email.subject,'populated_by_event_details_in_@brm.com');
    Test.stopTest();

    }

    @isTest
    static void testEmailNotificationDeline() {

     CampaignMember member = [SELECT Id FROM CampaignMember LIMIT 1];

    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
    email.htmlBody = '<td><p>----'+member.Id+'----</p></td><p>===EventLocation===</p>****{"eventType":"confirmation"}****';
    email.subject = 'CONFIRMATION for someone';

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseDeclineGenerator());
    // create an instance of the EmailToSalesForce class and test it with the data in the testMethod
    ZkipsterEmailForward emailServiceObj = new ZkipsterEmailForward();
   // emailServiceObj.handleInboundEmail(email, env );  
        ZkipsterEmailForward.processEmailBody(email.htmlBody,email.subject,'populated_by_event_details_in_@brm.com');
 email.htmlBody = '<td><p>----'+member.Id+'----</p></td><p>===EventLocation===</p>****{"eventType":"unconfirm"}****';
 //emailServiceObj.handleInboundEmail(email, env ); 
        ZkipsterEmailForward.processEmailBody(email.htmlBody,email.subject,'populated_by_event_details_in_@brm.com');
    Test.stopTest();

    }
     @isTest
    static void testEmailNotification2() {

     CampaignMember member = [SELECT Id FROM CampaignMember LIMIT 1];

    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
    email.htmlBody = '<td><p>----'+member.Id+'----</p></td><p>===EventLocation===</p>****{"eventType":"confirmation"}****';
    email.subject = 'CONFIRMATION for someone';

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseDeclineGenerator());
    // create an instance of the EmailToSalesForce class and test it with the data in the testMethod
    ZkipsterEmailForward emailServiceObj = new ZkipsterEmailForward();
   // emailServiceObj.handleInboundEmail(email, env );  
        ZkipsterEmailForward.processEmailBody(email.htmlBody,email.subject,'populated_by_event_details_in_@brm.com');
     email.htmlBody = '<td><p>----'+member.Id+'----</p></td><p>===EventLocation===</p>****{"eventType":"unconfirm"}****';
     emailServiceObj.handleInboundEmail(email, env ); 
        ZkipsterEmailForward.processEmailBody(email.htmlBody,email.subject,'populated_by_event_details_in_@brm.com');
    Test.stopTest();

    }
}