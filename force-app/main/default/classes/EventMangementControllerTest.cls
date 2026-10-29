@isTest
public class EventMangementControllerTest {

    @testSetup
    static void setupData() {
        Contact cnt = new Contact(FirstName='test', LastName='test', Email='test@test1.com', DoNotCall=false);
        Contact cnt1 = new Contact(FirstName='test1', LastName='test1', Email='test1@test1.com', DoNotCall=false);
        Contact cnt2 = new Contact(FirstName='test2', LastName='test2', DoNotCall=false);

        insert new List<Contact>{cnt, cnt1, cnt2};
            
        User user = TestDataFactory.createUser();
        
        Related_Contact__c relatedContact = new Related_Contact__c();
        relatedContact.Main_Contact__c = cnt.Id;
        relatedContact.Related_Contact__c = cnt1.Id;

        Related_Contact__c relatedContact1 = new Related_Contact__c();
        relatedContact1.Main_Contact__c = cnt1.Id;
        relatedContact1.Related_Contact__c = cnt.Id;

        insert new List<Related_Contact__c>{relatedContact, relatedContact1};

        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
        cm.TimeZone__c = 'America/Chicago';
        cm.EventCoordinator__c = user.Id;
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

        UnplannedGuest__c unplannedGuest = new UnplannedGuest__c();
        unplannedGuest.Event__c = cm.Id;
        unplannedGuest.FirstName__c = 'test1';
        unplannedGuest.LastName__c = 'test2';
        unplannedGuest.ZkipserGuestId__c = '232323';

        insert unplannedGuest;
    }
    
    @isTest
    static void testSearch() {
        String eventsString = EventMangementController.getEvents('Name', 'Contains', 'test', '', false, true);
        List<EventMangementController.Event> events = (List<EventMangementController.Event>)JSON.deserialize(eventsString, List<EventMangementController.Event>.class);
        Assert.isFalse(events.isEmpty()); 
    }
    
    @isTest
    static void testSearchByEventDate() {
         Datetime currentDateTime = Datetime.now().addDays(-2);
        String eventsString = EventMangementController.getEvents('Event_Start_Date_Time__c', '>', currentDateTime.format('yyy-MM-dd'), '',false, true);
        List<EventMangementController.Event> events = (List<EventMangementController.Event>)JSON.deserialize(eventsString, List<EventMangementController.Event>.class);
        Assert.isFalse(events.isEmpty());  
    }
}