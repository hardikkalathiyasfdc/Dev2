@isTest

public with sharing class BlinkContactControllerTest {

    private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c'});
    private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
    private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));
    private static String columns = '["id","first_name","preferred_first_name","last_name","maiden_name","email","salutation","prefix",'
                                    + '"middle_initial","title","primary_org_sort_name","brm_id","contig_id"]';
    private static String cols = EncodingUtil.urlEncode(columns, 'UTF-8');
    
    @testSetup static void setup() {
        Account acct = TestDataFactory.createOrg('Test Account');
        Contact contact = TestDataFactory.createContact(acct.Id, 'Testing');
    }

    @isTest
    public static void testSearchContacts() {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Bgive_Id__c FROM Contact WITH SYSTEM_MODE LIMIT 1];
        Map<String, Object> searchResulst = new Map<String, Object>();
        
        Test.startTest();
            searchResulst = BlinkContactController.searchContacts('Testing', 'Contact');
        Test.stopTest();
        List<Contact> searchResultsContacts = (List<Contact>)searchResulst.get('brmContacts');
        Assert.areEqual(contacts[0].FirstName, searchResultsContacts[0].firstName);
    }

    @isTest
    public static void testGetBgiveContact() {
        BLinkContactService.BGiveContact bgiveContact = new BLinkContactService.BGiveContact();
        String mockResponseBody = '{"user":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "first_name":"Testing",';
        mockResponseBody += '    "last_name":"Contact",';
        mockResponseBody += '    "preferred_first_name":"test",';
        mockResponseBody += '    "title":"test",';
        mockResponseBody += '    "brm_id":"",';
        mockResponseBody += '    "email":"test@test.com",';
        mockResponseBody += '    "salutation":"test",';
        mockResponseBody += '    "middle_initial":"A"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';
        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/123456?'+'cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            bgiveContact.id = '123456';
            bgiveContact.first_name = 'Testing';
            bgiveContact.last_name = 'Contact';
            bgiveContact.brm_id = '12345678';
            bgiveContact = BlinkContactController.getBgiveContact(bgiveContact.id);
        Test.stopTest();
        Assert.areEqual('Testing', bgiveContact.first_name);
    }

    @isTest
    public static void testLink() {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, MiddleName, title, Phone, Restricted__c,
                                AccountId, Bgive_Contig_Id__c, Bgive_Id__c, Solicitor_History_Status__c, Account.Name
                                FROM Contact
                                WITH SYSTEM_MODE
                                LIMIT 1];
        Contact brmContactDetails = contacts[0];
        Contact contact = null;
        String mockResponseBody = '{"user":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "first_name":"Testing",';
        mockResponseBody += '    "last_name":"Contact",';
        mockResponseBody += '    "preferred_first_name":"test",';
        mockResponseBody += '    "title":"test",';
        mockResponseBody += '    "brm_id":"' + brmContactDetails.Id + '",';
        mockResponseBody += '    "email":"test@test.com",';
        mockResponseBody += '    "salutation":"test",';
        mockResponseBody += '    "middle_initial":"A"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        Map<String,Object> data = new Map<String,Object>();
        data.put('brm_id', brmContactDetails.id);
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

        Test.startTest();
        HttpMockRegistry.mockCallout(
            'callout:'+FLUXX_NAMED_CRED,
            '/api/rest/v2/user/123456?data='+dataMap+'&cols='+cols,
            HttpMockRegistry.createSuccessResponse(mockResponseBody));
            //BlinkContactController.ContactWrapper brmContact = new BlinkContactController.ContactWrapper(brmContactDetails.Id, brmContactDetails.FirstName, brmContactDetails.MiddleName, brmContactDetails.Lastname, brmContactDetails.Preferred_First_Name__c,
            //brmContactDetails.Email, brmContactDetails.Phone, brmContactDetails.Account.Name, brmContactDetails.Title, brmContactDetails.Bgive_Id__c, brmContactDetails.Id, brmContactDetails.Bgive_Contig_Id__c);
            
            BLinkContactService.BGiveContact bgiveContact = new BLinkContactService.BGiveContact();
            bgiveContact.id = '123456';
            bgiveContact.first_name = 'Testing';
            bgiveContact.last_name = 'Contact';
            bgiveContact.brm_id = '12345678';

            contact = BlinkContactController.brmLink(brmContactDetails, JSON.serialize(bgiveContact), 'Enabled');
        Test.stopTest();
        Contact updatedContact = [Select Id, Bgive_Id__c from Contact where Id = :brmContactDetails.Id WITH SYSTEM_MODE];
        Assert.areEqual('123456', updatedContact.Bgive_Id__c);
    }

    @isTest
    public static void testUnlink() {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, MiddleName, title, Phone, Restricted__c,
                                    AccountId, Bgive_Contig_Id__c, Bgive_Id__c, Solicitor_History_Status__c, Account.Name
                                    FROM Contact
                                  	WITH SYSTEM_MODE
                                    LIMIT 1];
        Contact brmContactDetails = contacts[0];
        brmContactDetails.Bgive_Id__c = '123456';
        update brmContactDetails;

        String mockResponseBody = '{"user":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "first_name":"Testing",';
        mockResponseBody += '    "last_name":"Contact",';
        mockResponseBody += '    "preferred_first_name":"test",';
        mockResponseBody += '    "title":"test",';
        mockResponseBody += '    "brm_id":"",';
        mockResponseBody += '    "email":"test@test.com",';
        mockResponseBody += '    "salutation":"test",';
        mockResponseBody += '    "middle_initial":"A"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        Map<String,Object> data = new Map<String,Object>();
        data.put('brm_id', '');
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

        Test.startTest();

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/123456?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
        
            BlinkContactController.brmUnlink(brmContactDetails, 'Enabled');
        Test.stopTest();
        Contact updatedContact = [Select Id, Bgive_Id__c from Contact where Id = :brmContactDetails.Id WITH SYSTEM_MODE];
        Assert.areEqual(null, updatedContact.Bgive_Id__c);
    }

    @isTest
    public static void testGetContact() {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Bgive_Id__c FROM Contact WITH SYSTEM_MODE LIMIT 1];
        
        Test.startTest();
            Contact contactDetails= BlinkContactController.getContact(contacts[0].Id);
            Assert.areEqual(contacts[0].FirstName, contactDetails.FirstName);
        Test.stopTest();
    }
}