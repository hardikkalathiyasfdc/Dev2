@isTest
public class PhotoBookControllerTest {
    @isTest
    public static void testGetContacts() {
        Account a = TestDataFactory.createOrg('Test Account');
        Photo_Book_Setting__c pbs = new Photo_Book_Setting__c(Account__c=a.Id, Type__c='BP Org', Order__c=1);
        insert pbs;
        Photo_Book_Setting__c pbs2 = new Photo_Book_Setting__c(Color__c='5D008D', Type__c='HR Dept Color');
        insert pbs2;
        Photo_Book_Setting__c pbs3 = new Photo_Book_Setting__c(Color__c='5D008D', Type__c='HR Org Color');
        insert pbs3;
        Photo_Book_Setting__c pbs4 = new Photo_Book_Setting__c(Department__c='BP Administration', Type__c='Org Department');
        insert pbs4;
        List<Campaign> cList = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, false);
        Campaign c = cList[0];
        c.Name = 'test list';
        insert c;
        Photo_Book_Setting__c pbs1 = new Photo_Book_Setting__c(Account__c=a.Id, List__c=c.Id, Type__c='Intern List', Order__c=1);
        insert pbs1;
        List<Contact> contacts = TestDataFactory.createMultipleContacts(a.Id, 5, true);
        TestDataFactory.createCampaignMembers(c, contacts, true);
        PhotoBookController.Criteria criteria = new PhotoBookController.Criteria();
        criteria.title1 = 'Bloomberg';
        criteria.title2 = 'Philanthropies';
        criteria.coverColor = '5D008D';
        criteria.groupByDepartment = true;
        criteria.orgIds = new List<Id>{a.Id};
        criteria.departments = new List<String>();
        PhotoBookController.Keyword kw = new PhotoBookController.Keyword();
        kw.field = 'Key_Projects__c';
        kw.value = 'special';
        criteria.keywords = new List<PhotoBookController.Keyword>();
        criteria.cardFields = new List<String>{
            'Key_Projects__c', 'Key_Contact__c', 'Started_In__c', 'Came_From__c'
        };
        Id requestId = PhotoBookBuilderController.createRequest(JSON.serialize(criteria));
        Test.startTest();
        PhotoBookController pbc = new PhotoBookController();
        pbc.criteria = criteria;
        pbc.loadFromRequest(requestId);
        List<List<PhotoBookController.PhotoBookContact>> contactRows = pbc.getContactRows();
        List<List<PhotoBookController.PhotoBookContact>> headerRows = pbc.getHeaderRows();
        List<PhotoBookController.PhotoBookContact> PhotoBookContactslist = pbc.getInternContacts();
        Integer countMatches = PhotoBookController.countMatches(JSON.serialize(criteria));
        PhotoBookController.PhotoBookContact hrc = new PhotoBookController.PhotoBookContact();
        Test.stopTest();
    }

    @isTest
    public static void testGetContactsWithException() {
        Account a = TestDataFactory.createOrg('Test Account');
        Photo_Book_Setting__c pbs = new Photo_Book_Setting__c(Account__c=a.Id, Type__c='BP Org', Order__c=1);
        insert pbs;
        List<Contact> contacts =  TestDataFactory.createMultipleContacts(a.Id, 5, true);
        List<Campaign> cList = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, false);
        Campaign c = cList[0];
        c.Name = 'test list';
        insert c;
        Photo_Book_Setting__c pbs1 = new Photo_Book_Setting__c(Account__c=a.Id, List__c=c.Id, Type__c='Intern List', Order__c=1);
        insert pbs1;
        TestDataFactory.createCampaignMembers(c, contacts, true);
        PhotoBookController.Criteria criteria = new PhotoBookController.Criteria();
        criteria.groupByDepartment = true;
        criteria.orgIds = new List<Id>{a.Id};
        criteria.departments = new List<String>();
        criteria.keywords = new List<PhotoBookController.Keyword>();
        criteria.cardFields = new List<String>();
        Test.startTest();
        PhotoBookController.forceException = true;
        PhotoBookController pbc = new PhotoBookController();
        pbc.criteria = criteria;
        List<List<PhotoBookController.PhotoBookContact>> contactRows = pbc.getContactRows();
        List<PhotoBookController.PhotoBookContact> PhotoBookContactslist = pbc.getInternContacts();
        PhotoBookController.PhotoBookContact hrc = new PhotoBookController.PhotoBookContact();
        PhotoBookController.forceException = false;
        Test.stopTest();
        System.assertEquals(0, contactRows.size());
        System.assertEquals(null, PhotoBookContactslist);
    }

    @isTest
    public static void testGetFilterOptions() {
        Test.startTest();
        PhotoBookBuilderController.FilterOptions options = PhotoBookBuilderController.getFilterOptions();
        Test.stopTest();
        System.assertNotEquals(null, options);
        System.assertNotEquals(null, options.departments);
        System.assertNotEquals(null, options.cardFields);
        System.assertNotEquals(null, options.defaultCardFields);
        System.assertNotEquals(null, options.keywordFields);
        System.assert(options.defaultCardFields.size() <= 4);
    }

    @isTest
    public static void testBuilderCountMatches() {
        Account a = TestDataFactory.createOrg('Test Account');
        Photo_Book_Setting__c pbs = new Photo_Book_Setting__c(Account__c=a.Id, Type__c='BP Org', Order__c=1);
        insert pbs;
        List<Contact> contacts = TestDataFactory.createMultipleContacts(a.Id, 5, true);
        PhotoBookController.Criteria criteria = new PhotoBookController.Criteria();
        criteria.title1 = 'Bloomberg';
        criteria.title2 = 'Philanthropies';
        criteria.coverColor = '5D008D';
        criteria.groupByDepartment = true;
        criteria.orgIds = new List<Id>{a.Id};
        criteria.departments = new List<String>();
        criteria.keywords = new List<PhotoBookController.Keyword>();
        criteria.cardFields = new List<String>();
        Test.startTest();
        Integer blankCount = PhotoBookController.countMatches(null);
        Integer countMatches = PhotoBookController.countMatches(JSON.serialize(criteria));
        Test.stopTest();
        System.assertEquals(5, countMatches);
    }

    @isTest
    public static void testCreateRequest() {
        Account a = TestDataFactory.createOrg('Test Account');
        PhotoBookController.Criteria criteria = new PhotoBookController.Criteria();
        criteria.title1 = 'Bloomberg';
        criteria.title2 = 'Philanthropies';
        criteria.coverColor = '5D008D';
        criteria.groupByDepartment = true;
        criteria.orgIds = new List<Id>{a.Id};
        criteria.departments = new List<String>();
        criteria.keywords = new List<PhotoBookController.Keyword>();
        criteria.cardFields = new List<String>{'Key_Projects__c', 'SkillKnowledgeArea__c'};
        Test.startTest();
        Id requestId = PhotoBookBuilderController.createRequest(JSON.serialize(criteria));
        Test.stopTest();
        PhotoBook_Request__c request = [SELECT Id, Filter_Criteria_JSON__c FROM PhotoBook_Request__c WHERE Id=:requestId WITH SYSTEM_MODE];
        PhotoBookController.Criteria savedCriteria = (PhotoBookController.Criteria) JSON.deserialize(request.Filter_Criteria_JSON__c, PhotoBookController.Criteria.class);
        System.assertNotEquals(null, requestId);
        System.assertEquals('Bloomberg', savedCriteria.title1);
        System.assertEquals('Philanthropies', savedCriteria.title2);
        System.assertEquals('5D008D', savedCriteria.coverColor);
        System.assertEquals(true, savedCriteria.groupByDepartment);
        System.assertEquals(a.Id, savedCriteria.orgIds[0]);
        System.assertEquals(2, savedCriteria.cardFields.size());
    }

    @isTest
    public static void testCreateRequestWithException() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PhotoBookBuilderController.createRequest('Invalid JSON');
        } catch(AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown);
    }

    @isTest
    public static void testBuilderCountMatchesWithException() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PhotoBookController.countMatches('Invalid JSON');
        } catch(AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown);
    }
}