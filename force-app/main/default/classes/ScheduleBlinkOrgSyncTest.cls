@isTest
public with sharing class ScheduleBlinkOrgSyncTest {

    private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c'});

    private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
    private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));

    private static String columns = '["id","name","acronym","legal_name","tax_class",'
                                    + '"tax_id","brm_id","contig_id","street_address","city","url"]';
    private static String cols = EncodingUtil.urlEncode(columns, 'UTF-8');

    @testSetup static void setup() {
        Account a = TestDataFactory.createOrg('Testing');
    }

    @isTest
    public static void ScheduleBlinkOrgSyncTest() {
        List<Account> org = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                            FROM Account
                            WITH SYSTEM_MODE
                            LIMIT 1];
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
        mockResponseBody += '    "brm_id":"'+org[0].Id+'",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }]';
        mockResponseBody += '    }';
        mockResponseBody += '    }';

        String filter = EncodingUtil.urlEncode('{"group_type":"and","conditions":[["update_brm_flag","eq","true"],["brm_id","not-null","-"]]}', 'UTF-8');
        Test.startTest();

        HttpMockRegistry.mockCallout(
            'callout:'+FLUXX_NAMED_CRED,
            '/api/rest/v2/organization?page=1&per_page=10000&cols='+cols+'&filter='+filter,
            HttpMockRegistry.createSuccessResponse(mockResponseBody)
        );
        new ScheduleBlinkOrgSync().execute(null);
        Test.stopTest();
        Assert.areEqual('Testing Ltd', [SELECT Id, Legal_Name__c FROM Account WHERE Id = :org[0].Id WITH SYSTEM_MODE].Legal_Name__c);

    }
}