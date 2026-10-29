@isTest
public with sharing class BLinkOrgServiceTest {

    private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c'});

    private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
    private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));

    private static String columns = '["id","name","acronym","legal_name","tax_class",'
                                    + '"tax_id","brm_id","contig_id","street_address","city","url"]';
    private static String cols = EncodingUtil.urlEncode(columns, 'UTF-8');
    private static String relations = '{"geo_state_id":["name"],"geo_country_id":["name"]}';
    private static String relation = EncodingUtil.urlEncode(relations, 'UTF-8');

    @testSetup static void setup() {
        Account a = TestDataFactory.createOrg('Testing');
    }

    @isTest
    public static void testSearchBRM() {
        List<Account> org = [SELECT Id, Name, Bgive_Id__c, Bgive_Contig_Id__c FROM Account WITH SYSTEM_MODE LIMIT 1];
        org[0].Bgive_Contig_Id__c = '1234';
        update org[0];
        List<Account> orgList = new List<Account>();
        BLinkOrgService bos = new BLinkOrgService();
        Test.startTest();
            orgList = bos.searchBRM('Testing', '1234');
            Assert.areEqual(org[0].Name, orgList[0].Name);
        Test.stopTest();
    }

    @isTest
    public static void testSearchBgive() {
        List<BLinkOrgService.BGiveOrg> orgDet = new List<BLinkOrgService.BGiveOrg>();
        BLinkOrgService bos = new BLinkOrgService();
        String mockResponseBody = '{"records":';
        mockResponseBody += '{"organization":';
        mockResponseBody += '[{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Testing",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing Ltd",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"12345678",';
        mockResponseBody += '    "contig_id":"98765",';
        mockResponseBody += '    "street_address":"274 Lincoln Street",';
        mockResponseBody += '    "city":"Albertson",';
        mockResponseBody += '    "geo_state_id":[{"id":4014,"name":"New York"}],';
        mockResponseBody += '    "geo_country_id":[{"id":250,"name":"United States"}]';
        mockResponseBody += ' }]';
        mockResponseBody += '    }';
        mockResponseBody += '    }';

        String name = 'Testing';
        String filter = EncodingUtil.urlEncode(BLinkUtil.getOrgSearchFilter(name, null), 'UTF-8');

        Test.startTest();

        HttpMockRegistry.mockCallout(
            'callout:'+FLUXX_NAMED_CRED,
            '/api/rest/v2/organization?page=1&per_page=20&cols=' + cols + '&relation=' + relation + '&filter='+filter,
            HttpMockRegistry.createSuccessResponse(mockResponseBody)
        );
        orgDet = bos.searchBgive('Testing', null);

        Test.stopTest();
        Assert.areEqual('Testing', orgDet[0].name);
    }

    @isTest
    public static void testLinkWithBRMOrg() {
        Account org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                            FROM Account WHERE Name = 'Testing'
                      		WITH SYSTEM_MODE];

        BLinkOrgService bos = new BLinkOrgService();

        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Testing",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing Ltd",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"'+org.Id+'",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');

        BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
        bgiveorg.id = '123456';
        bgiveorg.name = 'Testing';
        bgiveorg.legal_name = 'Testing';
        bgiveorg.tax_class = 'City or Govt Agency';
        bgiveorg.tax_id = '27908661070';
        bgiveorg.brm_id = '';
        bgiveorg.contig_id = '';
        Map<String,Object> data = new Map<String,Object>();
        data.put('brm_id', org.id);
        data.put('brm_sync_hash',BLinkUtil.getOrgBRMHash(org, bgiveorg, syncFieldMappings));
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

        Test.startTest();

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );

            bos.brmLink(org, bgiveorg);
            Account updatedAcct = [SELECT Bgive_Id__c FROM Account WHERE Name = 'Testing' WITH SYSTEM_MODE];
            Assert.areEqual('123456', org.Bgive_Id__c);
        Test.stopTest();
       
    }
  
    
    @isTest
    public static void testLinkWithBRMOrgNegative() {
        Account org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                            FROM Account WHERE Name = 'Testing'
                      		WITH SYSTEM_MODE];

        BLinkOrgService bos = new BLinkOrgService();

        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Testing",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing Ltd",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"'+org.Id+'",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');

        BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
        bgiveorg.id = '123456';
        bgiveorg.name = 'Testing';
        bgiveorg.legal_name = 'Testing';
        bgiveorg.tax_class = 'Testing';
        bgiveorg.tax_id = '27908661070';
        bgiveorg.brm_id = '';
        bgiveorg.contig_id = '';
        Map<String,Object> data = new Map<String,Object>();
        data.put('brm_id', org.id);
        data.put('brm_sync_hash',BLinkUtil.getOrgBRMHash(org, bgiveorg, syncFieldMappings));
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

        Test.startTest();

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
        try{
            bos.brmLink(org, bgiveorg);  
        } catch (Exception ex){
             Assert.areEqual('Linking failed, could not update BRM record. Please contact Administrator for Help.', ex.getMessage());
        }
          
            Account updatedAcct = [SELECT Bgive_Id__c FROM Account WHERE Name = 'Testing' WITH SYSTEM_MODE];
            Assert.areEqual('123456', org.Bgive_Id__c);
        Test.stopTest();
       
    }
    @isTest
    public static void testLinkWithOrgLinked() {
        List<Account> org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                             FROM Account
                             WITH SYSTEM_MODE
                             LIMIT 1];
        org[0].Bgive_Id__c = '123456';
        update org[0];
        BLinkOrgService bos = new BLinkOrgService();
        Test.startTest();
            BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
            bgiveorg.id = '123456';
            bgiveorg.name = 'Testing';
            bgiveorg.brm_id = org[0].Id;
        	bgiveorg.get('brm_id');
        	bgiveorg.get('contig_id');
            try{
                bos.brmLink(org[0], bgiveorg);
            }catch(Exception e){
                System.debug(e);
            }
        Test.stopTest();
    }

    @isTest
    public static void testLinkWithoutBRMOrg() {
        BLinkOrgService bos = new BLinkOrgService();
        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"456789",';
        mockResponseBody += '    "name":"Test",';
        mockResponseBody += '    "acronym":"",';
        mockResponseBody += '    "legal_name":"Test",';
        mockResponseBody += '    "tax_class":"City or Govt Agency",';
        mockResponseBody += '    "tax_id":"27908661070",';
        mockResponseBody += '    "brm_id":"",';
        mockResponseBody += '    "contig_id":""';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');

        Test.startTest();
            BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
            bgiveorg.id = '456789';
            bgiveorg.name = 'Test';
            bgiveorg.legal_name = 'Test';
            bgiveorg.tax_class = 'City or Govt Agency';
            bgiveorg.tax_id = '27908661070';
            bgiveorg.brm_id = '';
            bgiveorg.contig_id = '';
            bos.createInBrmAndLink(bgiveorg);
            List<Account> org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                                 FROM Account
                                 WHERE Bgive_Id__c = :bgiveorg.id
                                 WITH SYSTEM_MODE
                                 LIMIT 1];
            bgiveorg.brm_id = org[0].Id;
            Map<String,Object> data = new Map<String, Object>();
            data.put('brm_id', org[0].id);
            data.put('name', org[0].Name);
            data.put('brm_sync_hash',BLinkUtil.getOrgBRMHash(org[0], bgiveOrg, syncFieldMappings));
            data.put('updated_by_id',FLUXX_USER_ID);

            String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/456789?cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/456789?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            List<Account> orgDet = [SELECT Name, Bgive_Id__c FROM Account WHERE Bgive_Id__c = :bgiveorg.id WITH SYSTEM_MODE LIMIT 1];
            Assert.areEqual(bgiveorg.name, orgDet[0].Name);
            Assert.areEqual(bgiveorg.brm_id, orgDet[0].Id);
        Test.stopTest();
    }

    @isTest
    public static void testUnlink() {
        List<Account> org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                             FROM Account
                             WITH SYSTEM_MODE
                             LIMIT 1];
        org[0].Bgive_Id__c = '123456';
        update org[0];
        BLinkOrgService bos = new BLinkOrgService();
        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Testing",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing Ltd",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        Map<String,Object> data = new Map<String,Object>();
        data.put('brm_id', '');
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            bos.brmUnlink(org[0]);
        try{
            bos.createInBgiveAndLink(org[0]);  
           String returnedData = BLinkOrgService.bgiveUnlink(null); 
        }catch(Exception ex){
            System.debug('Error occured');
        }
            Assert.areEqual(null, org[0].Bgive_Id__c);
        Test.stopTest();
    }
  
        @isTest
    public static void testBrmUnlink() {
         Account org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                             FROM Account
                        	 WITH SYSTEM_MODE
                             LIMIT 1];
        org.Bgive_Id__c = '';
            BLinkOrgService bos = new BLinkOrgService();
        Test.startTest();      
        try{
               update org;
                  bos.brmUnlink(org);
        }catch(Exception ex){
            System.debug('Error occured');
        }
        Test.stopTest();
    }
    @isTest
    public static void testGetBgiveOrg() {
        BLinkOrgService bos = new BLinkOrgService();
        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Testing",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing Ltd",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"",';
        mockResponseBody += '    "contig_id":"98765",';
        mockResponseBody += '    "street_address":"274 Lincoln Street",';
        mockResponseBody += '    "city":"Albertson",';
        mockResponseBody += '    "geo_state_id":[{"id":4014,"name":"New York"}],';
        mockResponseBody += '    "geo_country_id":[{"id":250,"name":"United States"}]';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?' + 'cols=' + cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
            bgiveorg.id = '123456';
            bgiveorg.name = 'Testing';
            BLinkOrgService.BGiveOrg orgDet = bos.getBgiveOrg(bgiveorg.id);
        	Assert.areEqual('Testing', orgDet.name);
        Test.stopTest();
    }

    @isTest
    public static void testSync() {
        List<Account> org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                             FROM Account
                             WITH SYSTEM_MODE
                             LIMIT 1];
        org[0].Bgive_Id__c = '123456';
        update org[0];
        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');
        BLinkOrgService bos = new BLinkOrgService();
        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Test",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing Ltd",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"'+org[0].Id+'",';
        mockResponseBody += '    "contig_id":"test"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
        bgiveorg.id = '123456';
        bgiveorg.name = 'Test';
        bgiveorg.brm_id = org[0].Id;

        Map<String,Object> data = new Map<String,Object>();

        data = BLinkUtil.formOrgSyncPayload(org[0] , bgiveorg , syncFieldMappings);
        data.put('update_brm_flag',false);
        data.put('brm_sync_hash',BLinkUtil.getOrgBRMHash(org[0], bgiveorg, syncFieldMappings));
        data.put('updated_by_id',FLUXX_USER_ID);

        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

        Test.startTest();

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            bos.sync(org[0]);
            Assert.areEqual('Test', bgiveorg.name);
        Test.stopTest();
    }

    @isTest
    public static void testBgiveLink() {
        Account org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                       FROM Account
                       WHERE Name = 'Testing'
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        // Create BGiveOrg object for linking
        BLinkOrgService.BGiveOrg bgiveOrg = new BLinkOrgService.BGiveOrg();
        bgiveOrg.id = '789012';
        bgiveOrg.name = 'Test BGive Org';
        bgiveOrg.legal_name = 'Test BGive Org Legal';
        bgiveOrg.tax_class = '501(c)(3)';
        bgiveOrg.tax_id = '12-3456789';
        bgiveOrg.brm_id = '';
        bgiveOrg.contig_id = '';
        
        // Convert to JSON string for bgiveLink method
        String bgiveOrgJson = JSON.serialize(bgiveOrg);
        
        // Mock response for modify call
        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"789012",';
        mockResponseBody += '    "name":"Test BGive Org",';
        mockResponseBody += '    "acronym":"TBO",';
        mockResponseBody += '    "legal_name":"Test BGive Org Legal",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"12-3456789",';
        mockResponseBody += '    "brm_id":"' + org.Id + '",';
        mockResponseBody += '    "contig_id":""';
        mockResponseBody += ' }';
        mockResponseBody += '    }';
        
        Map<String, Object> data = new Map<String, Object>();
        data.put('brm_id', org.Id);
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
        
        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/789012?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            
        try{
            String resultBrmId = BLinkOrgService.bgiveLink(org, bgiveOrgJson);
            Assert.areEqual(org.Id, resultBrmId, 'bgiveLink should return the BRM org ID');
        } catch (Exception ex){
            system.debug('Exception Occured');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testBgiveLinkAlreadyLinked() {
        
        Account org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                       FROM Account
                       WHERE Name = 'Testing'
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        org.Bgive_Id__c = '789012';
        update org;
        
        BLinkOrgService.BGiveOrg bgiveOrg = new BLinkOrgService.BGiveOrg();
        bgiveOrg.id = '789012';
        bgiveOrg.name = 'Test BGive Org';
        bgiveOrg.brm_id = org.Id; // Already linked
        
        String bgiveOrgJson = JSON.serialize(bgiveOrg);
        
        Test.startTest();
            try {
                BLinkOrgService.bgiveLink(org, bgiveOrgJson);
                Assert.fail('Should throw exception when org is already linked');
            } catch (Exception e) {
                Assert.isTrue(e.getMessage().contains('already linked'), 'Should throw exception for already linked org');
            }
        Test.stopTest();
    }
    
    @isTest
    public static void testBgiveUnlink() {
        Account org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                       FROM Account
                       WHERE Name = 'Testing'
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        org.Bgive_Id__c = '789012';
        update org;
        
        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"789012",';
        mockResponseBody += '    "name":"Test BGive Org",';
        mockResponseBody += '    "acronym":"TBO",';
        mockResponseBody += '    "legal_name":"Test BGive Org Legal",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"12-3456789",';
        mockResponseBody += '    "brm_id":"",';
        mockResponseBody += '    "contig_id":""';
        mockResponseBody += ' }';
        mockResponseBody += '    }';
        
        Map<String, Object> data = new Map<String, Object>();
        data.put('brm_id', '');
        data.put('updated_by_id',FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
        
        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/789012?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            
            String resultBrmId = BLinkOrgService.bgiveUnlink(org);
            Assert.areEqual('', resultBrmId, 'bgiveUnlink should return empty string for brm_id');
        Test.stopTest();
    }
    
    @isTest
    public static void testBgiveUnlinkNotLinked() {
        Account org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                       FROM Account
                       WHERE Name = 'Testing'
                       WITH SYSTEM_MODE
                       LIMIT 1];
        
        org.Bgive_Id__c = null;
        update org;
        
        Test.startTest();
            try {
                BLinkOrgService.bgiveUnlink(org);
                Assert.fail('Should throw exception when org is not linked');
            } catch (BLinkOrgService.BLinkException e) {
                Assert.isTrue(e.getMessage().contains('not linked'), 'Should throw exception for org not linked to BGive');
            }
        Test.stopTest();
    }
}