@isTest
public with sharing class BlinkOrganizationControllerTest {

    private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c'});

    private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
    private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));

    private static String columns = '["id","name","acronym","legal_name","tax_class",'
                                    + '"tax_id","brm_id","contig_id","street_address","city","url"]';
    private static String cols = EncodingUtil.urlEncode(columns, 'UTF-8');

    @testSetup static void setup() {
        Account acct = TestDataFactory.createOrg('Testing');
    }

    @isTest
    public static void testSearchOrganization() {

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
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }]';
        mockResponseBody += '    }';
        mockResponseBody += '    }';

        String name = 'Testing';
        String filter = EncodingUtil.urlEncode(BLinkUtil.getOrgSearchFilter(name, null), 'UTF-8');

        HttpMockRegistry.mockCallout(
            'callout:'+FLUXX_NAMED_CRED,
            '/api/rest/v2/organization?page=1&per_page=20&cols='+cols+'&filter='+filter,
            HttpMockRegistry.createSuccessResponse(mockResponseBody)
        );

        Test.startTest();
            Map<String, Object> searchResults = BlinkOrganizationController.searchOrganization('Testing', null);
            List<Account> accts = (List<Account>)searchResults.get('brmOrgs');
            Assert.areEqual('Testing', accts[0].Name);
        Test.stopTest();
    }

    @isTest
    public static void testLink() {
        Account acct = [SELECT Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                                FROM Account WHERE NAME = 'Testing' WITH SYSTEM_MODE];

        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Testing",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"' + acct.Id + '",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');
        BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
        bgiveorg.id = '123456';
        bgiveorg.name = 'Testing';
        bgiveorg.legal_name = 'Testing';
        bgiveorg.tax_class = '501(c)(3)';
        bgiveorg.tax_id = '54-098523';
        bgiveorg.brm_id = acct.Id;
        bgiveorg.contig_id = '98765';
        Map<String,Object> data = new Map<String,Object>();
        data.put('brm_id', acct.id);
        data.put('brm_sync_hash', BLinkUtil.getOrgBRMHash(acct, bgiveorg, syncFieldMappings));
        data.put('updated_by_id', FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

        Test.startTest();

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?data=' + dataMap + '&cols=' + cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );

            BlinkOrganizationController.brmLink(acct, JSON.serialize(bgiveorg));
            Account updatedAcct = [SELECT Bgive_Id__c FROM Account WHERE NAME = 'Testing'];

            Assert.areEqual('123456', updatedAcct.Bgive_Id__c);
        Test.stopTest();
    }

    @isTest
    public static void testGetBgiveOrg() {
        BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Testing",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing Ltd",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';
        Test.startTest();
            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?' + 'cols=' + cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            bgiveorg.id = '123456';
            bgiveorg.name = 'Testing';
            bgiveorg = BlinkOrganizationController.getBgiveOrg(bgiveorg.id);

            Assert.areEqual('Testing', bgiveorg.name);
        Test.stopTest();
    }

    @isTest
    public static void testGetOrganization() {
        Account acct = [SELECT Name FROM Account WHERE NAME = 'Testing' WITH SYSTEM_MODE];
        Test.startTest();
            Account org = BlinkOrganizationController.getOrganization(acct.id);
            Assert.areEqual(org.Name, acct.Name);
        Test.stopTest();
    }

    @isTest
    public static void testUnlink() {
        Account acct = [SELECT Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                                FROM Account WHERE NAME = 'Testing' WITH SYSTEM_MODE];
        acct.Bgive_Id__c = '123456';
        update acct;

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
                '/api/rest/v2/organization/123456?data=' + dataMap + '&cols=' + cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
            BlinkOrganizationController.brmUnlink(acct);
            Account updatedAcct = [SELECT Bgive_Id__c FROM Account WHERE NAME = 'Testing' WITH SYSTEM_MODE];

            Assert.areEqual(null, updatedAcct.Bgive_Id__c);
        Test.stopTest();
    }

    @isTest
    public static void testCreateInBrmAndLink() {
        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"BrmOrg",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"BrmOrg",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');
        BLinkOrgService.BGiveOrg bgiveorg = new BLinkOrgService.BGiveOrg();
        bgiveorg.id = '123456';
        bgiveorg.name = 'BrmOrg';
        bgiveorg.legal_name = 'BrmOrg';
        bgiveorg.tax_class = '501(c)(3)';
        bgiveorg.tax_id = '54-098523';
        bgiveorg.contig_id = '98765';
        Map<String,Object> data = new Map<String,Object>();
        data.put('updated_by_id', FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

        Test.startTest();

            HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/123456?data=' + dataMap + '&cols=' + cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );

            BlinkOrganizationController.createInBrmAndLink(JSON.serialize(bgiveorg));
            Account updatedAcct = [SELECT Bgive_Id__c FROM Account WHERE NAME = 'BrmOrg' WITH SYSTEM_MODE];

            Assert.areEqual('123456', updatedAcct.Bgive_Id__c);
        Test.stopTest();
    }

    @isTest
    public static void testCreateInBgiveAndLink() {
        Account acct = [SELECT Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c, Restricted__c
                                FROM Account WHERE NAME = 'Testing' WITH SYSTEM_MODE];

        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"123456",';
        mockResponseBody += '    "name":"Testing",';
        mockResponseBody += '    "acronym":"null",';
        mockResponseBody += '    "legal_name":"Testing",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"' + acct.Id + '",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';

        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappings = BLinkUtil.getSyncFields('Account');
        List<BLink_Sync_Field_Mapping__mdt> syncFieldMappingsForHash = BLinkUtil.getSyncFieldsForHash('Account');

        Map<String,Object> data = BLinkUtil.formOrgSyncPayload(acct, null, syncFieldMappings);
        data.put('name', acct.Name);
        data.put('tax_class', acct.Tax_ID__c);
        data.put('legal_name', acct.Legal_Name__c);
        data.put('brm_id', acct.id);
        data.put('acronym', acct.AKA__c);
        data.put('brm_sync_hash', BLinkUtil.getOrgBRMHash(acct, null, syncFieldMappingsForHash));
        data.put('updated_by_id', FLUXX_USER_ID);
        data.put('created_by_id', FLUXX_USER_ID);
        String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
		HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization?data='+dataMap+'&cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
            );
        Test.startTest();
            System.debug('here acc: '+acct);
        try{
            Account updatedAcct = BlinkOrganizationController.createInBgiveAndLink(acct);
            Assert.areNotEqual(null, updatedAcct, 'Account should be returned');
            Assert.areEqual('123456', updatedAcct.Bgive_Id__c, 'BGive ID should be set');
        }catch(Exception ex){}
            

        Test.stopTest();
    }
    
    @isTest
    public static void testIsBgiveOrgCreationEnabled() {
        User brmUser = TestDatafactory.createUser();
        Test.startTest();
        	System.runAs(brmUser) {
        		Boolean isBgiveOrgCreationEnabled = BlinkOrganizationController.isBgiveOrgCreationEnabled();
                Assert.isFalse(isBgiveOrgCreationEnabled);
            }
        Test.stopTest();
    }
}