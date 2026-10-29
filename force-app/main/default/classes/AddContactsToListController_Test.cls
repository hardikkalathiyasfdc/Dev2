@isTest
public class AddContactsToListController_Test {
    private final static String CAMP_REC = 'Contact List (Leadership)';
    
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
        
        Campaign testCamp = TestDataFactory.getList('test list', CAMP_REC);
        insert as system testCamp;

        CampaignMember testMem = TestDataFactory.getListMember(
          testCamp.Id,
          c.Id
        );
        insert as system testMem;
        
    }
       @isTest
    static void selectedTagsTest () {
        List<Tag__c> tags = [Select Id from Tag__c WITH SYSTEM_MODE];
        ApexPages.StandardSetController standardController = new ApexPages.StandardSetController(tags);
        standardController.setSelected(tags);
        
		AddContactsToListController extension = new AddContactsToListController(standardController);
        
        System.assertEquals(true, extension.tagIdsString != null);
    }
    
    
     @isTest
    static void getContactsTest () {
        List<Tag__c> tags = [Select Id from Tag__c WITH SYSTEM_MODE];
        ApexPages.StandardSetController standardController = new ApexPages.StandardSetController(tags);
        standardController.setSelected(tags);
        Test.startTest();
        AddContactsToListController extension = new AddContactsToListController(standardController);
        Contact c =[Select Id from Contact where Name= 'test' WITH SYSTEM_MODE];
        c.DoNotCall = true;
        update as system c;
        Test.stopTest();
         Campaign c2 = [Select Id from Campaign WITH SYSTEM_MODE LIMIT 1];
        AddContactsToListController.addContactsToListfromTag(c2.Id,'New List',true);
    }
    
    
    @isTest
    static void addContactsToListTest () 
    {
        Test.startTest();
        Campaign c = [Select Id from Campaign WITH SYSTEM_MODE LIMIT 1];
         c.recordTypeId= Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Events').getRecordTypeId();
        update as system c;
        AddContactsToListController.addContactsToList(c.Id,'New List',true);
        test.stopTest();
        List<Campaign> lstcamp= [Select Id from Campaign WITH SYSTEM_MODE];
        System.assertEquals(2, lstcamp.size());
          AddContactsToListController.addContactsToList(c.Id,lstcamp[1].Id,false);
        // AddContactsToListController.asyncAddContactsToList(c.Id,'New List',true);
       // AddContactsToListController.asyncAddContactsToList(c.Id,lstcamp[1].Id,false);
    }
}