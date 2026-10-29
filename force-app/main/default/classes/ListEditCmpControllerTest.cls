@isTest
public without sharing class ListEditCmpControllerTest {
  private final static String CAMP_REC = 'Events';
  private final static String EVENT_TIER = 'EventTier__c';
 
  @isTest
  public static void validateGetListMembers() {
    
    Test.starttest();
            Account a = TestDataFactory.getOrg('test');
            insert a;
            
            List<Contact> contactList = new List<Contact>();
            Contact con1 = new Contact(FirstName='test1', LastName='test1', AccountId = a.Id, Bio_Photo__c = 'Bio Photo', Bio_Confidential_Notes__c = 'Bio Confidential Notes', 
                                       Bio_Description__c = 'Bio Description', Team_s__c = 'IT',Categories__c = 'Education;Nonprofit', Office_Phone_Country_Code__c='United States(+1)', Phone='2121231234');
            contactList.add(con1);
            Contact con2 = new Contact(FirstName='test2', Significant_Other__c=con1.Id, LastName='test2', AccountId = a.Id, Bio_Photo__c = 'Bio Photo', Bio_Confidential_Notes__c = 'Bio Confidential Notes', 
                                       Bio_Description__c = 'Bio Description', Team_s__c = 'IT',Categories__c = 'Education;Nonprofit', Office_Phone_Country_Code__c='United States(+1)', Phone='212123123');
            contactList.add(con2);
            insert contactList;
            
            Tag__c t = TestDataFactory.getTag('test');
            insert t;
            Tag_Junction__c j = TestDataFactory.getTagJunc(t,con1);
            insert j;
            
            Campaign testCamp = TestDataFactory.getList('test list', CAMP_REC);
          insert testCamp;
          
          CampaignMember testMem = TestDataFactory.getListMember(
              testCamp.Id,
              con1.Id
          );
          insert testMem;
          testMem = TestDataFactory.getListMember(
              testCamp.Id,
              con2.Id
          );
          insert testMem;     
 	Test.stopTest();
    List<String> fieldsList = new List<String>{'Assistant__c','UB_FirstName__c','UB_LastName__c','RSVPStatus__c','RSVPNotes__c','RSVP_Event_Note_Complete__c','AttendedStatus__c','Table__c,Seat__c','EventEmailBody__c','Last_Email_Status__c','Last_Email_Sent_Errors__c','Source__c','UB_Notes__c','GuestOf__c','Full_Name__c','Contact_Title__c','Organization_Company__c','Guest_Email__c','Guest_Email_Type__c','Latest_Email_Subject__c','Business_Phone__c','Mobile_Phone__c','CC_Assistant__c','AssistantName__c','Assistant_Email__c','Assistant_Business_Phone__c','Spouse_Link__c','SpouseInvited__c','Significant_Other_Title__c','RSVPUpdateDate__c'};
      Map<String, Object> testObj = (Map<String, Object>) ListEditCmpController.getListMembers(
              testCamp.Id,
              fieldsList,
              fieldsList,
              0,
              null,
              null,
              null,
              true
      );
      System.assert(testObj.get('data') != null, 'failed to get list member data.');
  }

    @isTest static void testGetUserInfo() {
        Test.startTest();
            ListEditCmpController.getMyDomain();
            Boolean result = ListEditCmpController.getUserInfo();
            System.assertEquals(true, result);
            ListEditCmpController.getFieldsList(null,'Pre_Event', 'defaultHeaders');
        Test.stopTest();
    }
    
  @isTest 
    static void testGenerals () {
        ListEditCmpController.getEmailCol();
        Campaign testCamp = [Select Id from Campaign where name = 'test list' WITH SYSTEM_MODE limit 1];
        CampaignMember testMem = [Select Id from CampaignMember where CampaignId = :testCamp.Id WITH SYSTEM_MODE limit 1];
        Map<String, Object> emails = ListEditCmpController.getEmailBody(testMem.Id, 'Title');
        List<String> memIds = new List<String>{testMem.Id};
        List<String> listIds = new List<String>{testCamp.Id};

        ListEditCmpController.updateRSVPStatus(JSON.serialize(memIds), 'Attended',null);
        ListEditCmpController.updateGuestInfo(JSON.serialize(memIds), EVENT_TIER, 'Tier 1');
        ListEditCmpController.getUpdateFieldList('Pre_Event');
        ListEditCmpController.addSignificantOther(testCamp.Id, memIds);
        ListEditCmpController.getFilterQuery(new List<String>{'Name'},'test');
        ListEditCmpController.getPageSize('Pre_Event');
        ListEditCmpController.fetchStaffContacts(testMem.Id);
        ListEditCmpController.getCampaignMembers(testCamp.Id);
    }

    @testSetup
    private static void makeData() {
        Campaign testCamp = new Campaign(Name='test list');
        insert testCamp;
        Contact testCon = TestDataFactory.getContact('test');
        Contact testSignCon = TestDataFactory.getContact('Sig');
        insert testSignCon;
        testCon.Significant_Other__c = testSignCon.Id;
        insert testCon;
        CampaignMember testMem = TestDataFactory.getListMember(
        testCamp.Id,
        testCon.Id
        );
        insert testMem;
    }
    
    
    @isTest
    static void testUpdateListView() {
        Custom_List_View__c rec = new Custom_List_View__c(Name='Test View');
        insert rec;
        String cols = 'Additional_Email__c,Assistant__c,AssistantEmail__c';
        Test.startTest();
        ListEditCmpController.updateListView(rec.Id, cols);
        Test.stopTest();
        rec = [SELECT Column__c FROM Custom_List_View__c WHERE Id=:rec.Id];
        System.assertEquals(cols, rec.Column__c);
    }
    
    @isTest
    static void testGetFormattedSubject() {
        Campaign camp = new Campaign(Name='Test Campaign');
        insert camp;
        
        Contact con = TestDataFactory.getContact('Test12');
        insert con;
        
        CampaignMember cm = TestDataFactory.getListMember(camp.Id, con.Id);
        insert cm;
        
        Test.startTest();
        String result = ListEditCmpController.getFormattedSubject(cm.Id, 'Description');
        Test.stopTest();

    }
    
    @isTest
    static void testInvalidField() {
        Campaign camp = new Campaign(Name='Test Campaign');
        insert camp;
        
        Contact con = TestDataFactory.getContact('Test123');
        insert con; 
        
        CampaignMember cm = TestDataFactory.getListMember(camp.Id, con.Id);
        cm.EmailSubjectLine__c = 'Test';
        insert cm;
        
        Test.startTest();
            ListEditCmpController.getFormattedSubject(cm.Id, 'EmailSubjectLine__c');

        Test.stopTest();
    }
    
    @isTest
    static void testNullSubject() {
        Campaign camp = new Campaign(Name='Test Campaign');
        insert camp;
        
        Contact con = TestDataFactory.getContact('Test1234');
        insert con;
        
        CampaignMember cm = TestDataFactory.getListMember(camp.Id, con.Id);
        insert cm;
        
        Test.startTest();
        String result = ListEditCmpController.getFormattedSubject(cm.Id, 'Description');
        Test.stopTest();
        
        System.assertEquals('', result);
    }
    
}