@isTest
public class BatchContactRollupRecordsTest {
    @testSetup
    static void setupdata() {
        List<Contact> contacts = new List<Contact> ();
        Contact ct = TestDataFactory.getContact('contact one');
        contacts.add(ct);
        
        Contact ct2 = TestDataFactory.getContact('contact two');
        contacts.add(ct2);
        
        insert as system contacts;
        
        List<Campaign> lists = new List<Campaign> ();
        Campaign cList = TestDataFactory.getList('Contact List One', 'Contact List');
        lists.add(cList);
        
        Campaign eventList = TestDataFactory.getList('Contact List One', 'Events');
        lists.add(eventList);
        
        insert as system lists;
        
        List<CampaignMember> campaignMembers = new List<CampaignMember> ();
        CampaignMember member1 = TestDataFactory.getListMember(cList.Id, ct.Id);
        campaignMembers.add(member1);
        
        CampaignMember member2 = TestDataFactory.getListMember(cList.Id, ct2.Id);
        campaignMembers.add(member2);
        
        CampaignMember member3 = TestDataFactory.getListMember(eventList.Id, ct2.Id);
        campaignMembers.add(member3);
        
        insert as system campaignMembers;
    }
    
    @isTest 
    static void testRollUpCounts () {
        Test.startTest();
		BatchContactRollupRecords batchRollup = new BatchContactRollupRecords();
        Database.executebatch(batchRollup);        
        Test.stopTest();
        
        Contact contactOne = [Select Id, Touchpoint_sum__c, Event_Count__c from Contact where LastName = 'contact one' WITH SYSTEM_MODE];
        Contact contactTwo = [Select Id, Touchpoint_sum__c, Event_Count__c from Contact where LastName = 'contact two' WITH SYSTEM_MODE];
		
        System.assertEquals (1, contactOne.Touchpoint_sum__c);
		System.assertEquals (0, contactOne.Event_Count__c);
        System.assertEquals (2, contactTwo.Touchpoint_sum__c);
		System.assertEquals (1, contactTwo.Event_Count__c);
    }
}