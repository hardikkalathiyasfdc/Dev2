@isTest
public class ContactListWithTagsReportControllerTest {

    @testSetup
    static void dataSetup() {
        Account a = TestDataFactory.getOrg('test');
        insert as system a;
        Contact c = TestDataFactory.getContact('test');
        c.AccountId = a.Id;
        insert as system c;
        Tag__c t = TestDataFactory.getTag('test');
        insert as system t;
        Tag_Junction__c j = TestDataFactory.getTagJunc(t,c);
        insert as system j;
        
        Campaign testCamp = new Campaign(Name = 'test list');
        insert as system testCamp;

        CampaignMember testMem = TestDataFactory.getListMember(
            testCamp.Id,
            c.Id
        );
        insert as system testMem;
    }
    
    @isTest
    static void getAllContactListTags() {
        Contact contact = [Select Id from Contact WITH SYSTEM_MODE limit 1];
        Campaign campaign = [Select Id from Campaign WITH SYSTEM_MODE limit 1];
        Tag__c tag = [Select Id from Tag__c WITH SYSTEM_MODE limit 1];
        ContactListWithTagsReportController.getAllContactListTags(campaign.Id,tag.Id,contact.Id);
        List<String> contactIds = new List<String>{contact.Id};
        List<String> campaignIds = new List<String>{campaign.Id};
        List<String> tagIds = new List<String>{tag.Id};
        ContactListWithTagsReportController.ContactListTagDataWrapper wrapper = new ContactListWithTagsReportController.ContactListTagDataWrapper('firstName', 'firstPreferredName', 'lastName', 'title', 'organization');
        List<ContactListWithTagsReportController.ContactListTagDataWrapper> dataWrapper = ContactListWithTagsReportController.getContactListTagData(contactIds, campaignIds, tagIds);
        System.assert(!dataWrapper.isEmpty());
        List<String> orderedList = new List<String>{campaign.Id};
        List<ContactListWithTagsReportController.ContactListTagDataWrapper> updatedData = ContactListWithTagsReportController.getUpdatedData(JSON.serialize(dataWrapper), orderedList, false);
        List<ContactListWithTagsReportController.ContactListTagDataWrapper> updatedData1 = ContactListWithTagsReportController.getUpdatedData(JSON.serialize(dataWrapper), orderedList, true);
        List<String> contactFieldAPINames = new List<String>{'DoNotCall'};
        List<String> listMemberFieldAPINames = new List<String>{'RSVPStatus__c'};
        List<String> contactIds1 = new List<String>{contact.Id};
        ContactListWithTagsReportController.getMemberList(campaignIds, contactIds, tagIds, contactIds1, 'Executive', listMemberFieldAPINames, listMemberFieldAPINames, contactFieldAPINames, false);
        ContactListWithTagsReportController.getMemberList(contactIds, campaignIds, tagIds, contactIds1, 'Standard', listMemberFieldAPINames, listMemberFieldAPINames, contactFieldAPINames,false);
        ContactListWithTagsReportController.ContactListTagDataWrapper wrapper1 = new ContactListWithTagsReportController.ContactListTagDataWrapper();
    }
    
    @isTest
    static void addToExistingList() {
        Campaign campaign = [Select Id from Campaign WITH SYSTEM_MODE limit 1];
        Contact contact = [Select Id from Contact WITH SYSTEM_MODE limit 1];
        List<String> contactIds = new List<String>{contact.Id};
        List<String> campaignIds = new List<String>{campaign.Id};
    	AddListTagResultsToListController.getRecentlyViewed();
        Map<String, String> contactSourceMap = new Map<String, String>();
        contactSourceMap.put('test', 'test');
        AddListTagResultsToListController.addToExistingListAsync(campaign.Id, 'Sent', false, contactIds, contactSourceMap);
        AddListTagResultsToListController.search('test', campaignIds);
    }			
}