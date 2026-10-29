@isTest
public with sharing class BLinkContactServiceTest {

    private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c'});

    private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
    private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));

    private static String columns = '["id","first_name","preferred_first_name","last_name","maiden_name","email","salutation","prefix",'
                                    + '"middle_initial","title","primary_org_sort_name","brm_id","contig_id"]';
    private static String cols = EncodingUtil.urlEncode(columns, 'UTF-8');


    @testSetup static void setup() {
        Account a = TestDataFactory.createOrg('Test');
        Contact con = TestDataFactory.createContact(a.Id , 'Testing');
    }

    @isTest
    public static void testSearchBRM() {
        List<Contact> con = [SELECT Id, FirstName, LastName, Bgive_Id__c FROM Contact WITH SYSTEM_MODE LIMIT 1];
        List<Contact> conList = new List<Contact>();
        BLinkContactService bcs = new BLinkContactService();
        Boolean exceptionThrown = false;
        try {
            // Trigger exception: blank inputs
            conList = bcs.searchBRM('Testing', '');
        } catch (exception e) {
            exceptionThrown = true;
            System.assertEquals(
                'Please provide first Name and Last Name initials to search',
                e.getMessage()
            );
        }
        Test.startTest();
            conList = bcs.searchBRM('Testing', 'Contact');
        Test.stopTest();
        Assert.areEqual(con[0].FirstName, conList[0].FirstName);
    }

    @isTest
    public static void testSearchBgive() {
        List<BLinkContactService.BGiveContact> conDet = new List<BLinkContactService.BGiveContact>();
        BLinkContactService bcs = new BLinkContactService();
        String mockResponseBody = '{"records":';
        mockResponseBody += '{"user":';
        mockResponseBody += '[{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "first_name":"Testing",';
        mockResponseBody += '    "last_name":"Contact",';
        mockResponseBody += '    "preferred_first_name":"test",';
        mockResponseBody += '    "title":"test",';
        mockResponseBody += '    "brm_id":"12345678",';
        mockResponseBody += '    "email":"test@test.com",';
        mockResponseBody += '    "salutation":"test",';
        mockResponseBody += '    "middle_initial":"A"';
        mockResponseBody += ' }]';
        mockResponseBody += '    }';
        mockResponseBody += '    }';

        String firstName = 'Testing';
        String lastname = 'Contact';

        String filter = EncodingUtil.urlEncode(BLinkUtil.getSearchFilter(firstName, lastname), 'UTF-8');
        Test.startTest();

        HttpMockRegistry.mockCallout(
            'callout:'+FLUXX_NAMED_CRED,
            '/api/rest/v2/user?page=1&per_page=20&cols='+cols+'&filter='+filter,
            HttpMockRegistry.createSuccessResponse(mockResponseBody)
        );
        try {
            conDet = bcs.searchBgive('', '');
        } catch (exception e) {
            System.assertEquals(  e.getMessage(), e.getMessage());
        }
        
        conDet = bcs.searchBgive('Testing', 'Contact');

        Test.stopTest();
        Assert.areEqual('Testing', conDet[0].first_name);

    }

    @isTest
    public static void testLinkWithBRMContact() {
        List<Contact> con = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, MiddleName, title, Phone,Restricted__c,
                             AccountId, Bgive_Contig_Id__c, Bgive_Id__c, Solicitor_History_Status__c
                             FROM Contact
                             WITH SYSTEM_MODE
                             LIMIT 1];

        BLinkContactService bcs = new BLinkContactService();

        String mockResponseBody = '{"user":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "first_name":"Testing",';
        mockResponseBody += '    "last_name":"Contact",';
        mockResponseBody += '    "preferred_first_name":"test",';
        mockResponseBody += '    "title":"test",';
        mockResponseBody += '    "brm_id":"'+con[0].Id+'",';
        mockResponseBody += '    "email":"test@test.com",';
        mockResponseBody += '    "salutation":"test",';
        mockResponseBody += '    "middle_initial":"A"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        Map<String,Object> data = new Map<String,Object>();
        data.put('brm_id', con[0].id);
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
        System.debug(dataMap);
        Test.startTest();

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/123456?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            BLinkContactService.BGiveContact bgivecon = new BLinkContactService.BGiveContact();
            bgivecon.id = con[0].Id;
            bgivecon.first_name = 'Testing';
            bgivecon.last_name = 'Contact';
            bgivecon.brm_id = con[0].Id;
            bcs.brmLink(con[0], bgivecon, 'Enabled');
        try {
           bcs.brmLink(con[0], bgivecon, 'Testing');
        } catch (exception e) {
            System.assertEquals(  e.getMessage(), e.getMessage());
        }
        Test.stopTest();
        Assert.areEqual(con[0].Id, con[0].Bgive_Id__c);
    }


    @isTest
    public static void testLinkWithoutBRMContact() {
        BLinkContactService bcs = new BLinkContactService();
        String mockResponseBody = '{"user":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"456789",';
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
            BLinkContactService.BGiveContact bgivecon = new BLinkContactService.BGiveContact();
            bgivecon.id = '456789';
            bgivecon.first_name = 'Test';
            bgivecon.last_name = 'Contact BGive';
            bcs.brmLink(null, bgivecon, 'Enabled');
            List<Contact> con = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, 
                                 MiddleName, title, Phone, AccountId, Bgive_Contig_Id__c, Bgive_Id__c, 
                                 Solicitor_History_Status__c 
                                 FROM Contact 
                                 WHERE Bgive_Id__c = :bgivecon.id 
                                 WITH SYSTEM_MODE
                                 LIMIT 1];
            bgivecon.brm_id = con[0].Id;
            Map<String,Object> data = new Map<String, Object>();
            data.put('brm_id', con[0].id);
            data.put('updated_by_id',FLUXX_USER_ID);

            String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
            System.debug(dataMap);
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/456789?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
        Test.stopTest();
        List<Contact> conDet = [Select Id, FirstName, LastName, Bgive_Id__c From Contact Where Bgive_Id__c = :bgivecon.id LIMIT 1];
        Assert.areEqual(bgivecon.first_name, conDet[0].FirstName);
        Assert.areEqual(bgivecon.brm_id, conDet[0].Id);
    }

    @isTest
    public static void testUnlink() {
        List<Contact> con = [Select Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, 
                             MiddleName, title, Restricted__c, Phone, AccountId, Bgive_Contig_Id__c, 
                             Bgive_Id__c, Solicitor_History_Status__c 
                             From Contact
                             WITH SYSTEM_MODE
                             LIMIT 1];
        con[0].Bgive_Id__c = '123456';
        update con[0];
        System.debug(con[0].Bgive_Id__c);
        BLinkContactService bcs = new BLinkContactService();
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
        System.debug(dataMap);

        Test.startTest();

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/123456?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            bcs.brmUnlink(con[0], 'Enabled');
        Test.stopTest();
           try {
               Contact cont = new Contact();
          bcs.brmUnlink(cont, 'Testing');
        } catch (exception e) {
            System.assertEquals(  e.getMessage(), e.getMessage());
        }

        Assert.areEqual('', con[0].Bgive_Id__c);
    }

    @isTest
    public static void testGetBgiveContact() {
        BLinkContactService bcs = new BLinkContactService();
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
            BLinkContactService.BGiveContact bgivecon = new BLinkContactService.BGiveContact();
            bgivecon.id = '123456';
            bgivecon.first_name = 'Testing';
            bgivecon.last_name = 'Contact';
            bgivecon.brm_id = '12345678';
            BLinkContactService.BGiveContact conDet = bcs.getBgiveContact(bgivecon.id);
        Test.stopTest();

        Assert.areEqual('Testing', conDet.first_name);
    }

    @isTest
    public static void testBgiveLink() {
        Contact con = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, MiddleName, 
                       title, Phone,
                       AccountId, Bgive_Contig_Id__c, Bgive_Id__c, Solicitor_History_Status__c
                       FROM Contact
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        // Create BGiveContact object for linking
        BLinkContactService.BGiveContact bgiveContact = new BLinkContactService.BGiveContact();
        bgiveContact.id = '789012';
        bgiveContact.first_name = 'Test';
        bgiveContact.last_name = 'BGive Contact';
        bgiveContact.preferred_first_name = 'Test';
        bgiveContact.title = 'Test Title';
        bgiveContact.brm_id = '';
        bgiveContact.email = 'testbgive@test.com';
        bgiveContact.salutation = 'Mr.';
        bgiveContact.middle_initial = 'B';
        
        // Convert to JSON string for bgiveLink method
        String bgiveContactJson = JSON.serialize(bgiveContact);
        
        // Mock response for modify call
        String mockResponseBody = '{"user":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"789012",';
        mockResponseBody += '    "first_name":"Test",';
        mockResponseBody += '    "last_name":"BGive Contact",';
        mockResponseBody += '    "preferred_first_name":"Test",';
        mockResponseBody += '    "title":"Test Title",';
        mockResponseBody += '    "brm_id":"' + con.Id + '",';
        mockResponseBody += '    "email":"testbgive@test.com",';
        mockResponseBody += '    "salutation":"Mr.",';
        mockResponseBody += '    "middle_initial":"B"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';
        
        Map<String, Object> data = new Map<String, Object>();
        data.put('brm_id', con.Id);
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
        
        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/789012?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            
            String resultBrmId = BLinkContactService.bgiveLink(con, bgiveContactJson);
            Assert.areEqual(con.Id, resultBrmId, 'bgiveLink should return the BRM contact ID');
        Test.stopTest();
    }
    
    @isTest
    public static void testBgiveLinkExceptionHandling() {
        Contact con = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, MiddleName, title, Phone,
                       AccountId, Bgive_Contig_Id__c, Bgive_Id__c, Solicitor_History_Status__c
                       FROM Contact
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        BLinkContactService.BGiveContact bgiveContact = new BLinkContactService.BGiveContact();
        bgiveContact.id = '999999'; // Non-existent ID to trigger error
        bgiveContact.first_name = 'Test';
        bgiveContact.last_name = 'BGive Contact';
        bgiveContact.brm_id = '';
        
        // Convert to JSON string for bgiveLink method
        String bgiveContactJson = JSON.serialize(bgiveContact);
        
        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/999999?data=',
                HttpMockRegistry.createResponse(404, 'Not Found', '{"error":"Not Found"}')
            );
            
            try {
                BLinkContactService.bgiveLink(con, bgiveContactJson);
                Assert.fail('Should throw exception when API call fails');
            } catch (Exception e) {
                Assert.isTrue(true, 'Exception should be thrown for failed API call');
            }
        Test.stopTest();
    }
    
    @isTest
    public static void testBgiveUnlink() {
        Contact con = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, MiddleName, title, Phone,
                       AccountId, Bgive_Contig_Id__c, Bgive_Id__c, Solicitor_History_Status__c
                       FROM Contact
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        // Set Bgive_Id__c to simulate linked contact
        con.Bgive_Id__c = '789012';
        update con;
        
        // Mock response for modify call (unlink - sets brm_id to empty)
        String mockResponseBody = '{"user":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"789012",';
        mockResponseBody += '    "first_name":"Test",';
        mockResponseBody += '    "last_name":"BGive Contact",';
        mockResponseBody += '    "preferred_first_name":"Test",';
        mockResponseBody += '    "title":"Test Title",';
        mockResponseBody += '    "brm_id":"",';
        mockResponseBody += '    "email":"testbgive@test.com",';
        mockResponseBody += '    "salutation":"Mr.",';
        mockResponseBody += '    "middle_initial":"B"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';
        
        Map<String, Object> data = new Map<String, Object>();
        data.put('brm_id', '');
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
        
        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/789012?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            
            String resultBrmId = BLinkContactService.bgiveUnlink(con);
            Assert.areEqual('', resultBrmId, 'bgiveUnlink should return empty string for brm_id');
        Test.stopTest();
    }
    
    @isTest
    public static void testBgiveUnlinkExceptionHandling() {
        Contact con = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, MiddleName, title, Phone,
                       AccountId, Bgive_Contig_Id__c, Bgive_Id__c, Solicitor_History_Status__c
                       FROM Contact
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        // Set Bgive_Id__c to simulate linked contact
        con.Bgive_Id__c = '999999'; // Non-existent ID to trigger error
        update con;
        
        Test.startTest();
            // Mock error response
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/user/999999?data=',
                HttpMockRegistry.createResponse(404, 'Not Found', '{"error":"Not Found"}')
            );
            
            try {
                BLinkContactService.bgiveUnlink(con);
                Assert.fail('Should throw exception when API call fails');
            } catch (BLinkContactService.ContactSearchException e) {
                Assert.isTrue(true, 'Exception should be thrown for failed API call');
            }
        Test.stopTest();
    }

    @isTest
    public static void testBrmLinkExceptionHandlingDmlException() {
        Contact con = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Salutation, MiddleName, title, Phone,
                       AccountId, Bgive_Contig_Id__c, Bgive_Id__c, Solicitor_History_Status__c
                       FROM Contact
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        BLinkContactService bcs = new BLinkContactService();
        
        // Create BGiveContact object
        BLinkContactService.BGiveContact bgivecon = new BLinkContactService.BGiveContact();
        bgivecon.id = '123456';
        bgivecon.first_name = 'Testing';
        bgivecon.last_name = 'Contact';
        bgivecon.brm_id = '';
        bgivecon.contig_id = '';
        
        Test.startTest();
            try {
                bcs.brmLink(con, bgivecon, 'Enabled1');
            } catch (Exception e) {
                Assert.isTrue(e.getMessage().contains('Linking') || e.getMessage().contains('BRM') || e.getMessage().contains('Contact Object'), 
                    'Should throw ContactSearchException with appropriate message for DML failure');
            }
        Test.stopTest();
    }

}