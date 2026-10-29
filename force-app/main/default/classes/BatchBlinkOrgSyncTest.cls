@isTest
public with sharing class BatchBlinkOrgSyncTest {
    private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c'});

     private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
     private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));
     private static String columns = '["id","name","acronym","legal_name","tax_class",'
                                    + '"tax_id","brm_id","contig_id"]';
     private static String cols = EncodingUtil.urlEncode(columns, 'UTF-8');

     @testSetup static void setup() {
        Account a = TestDataFactory.createOrg('Test Bloomberg LP');
    }

    @isTest
    static void syncOrgTest() {
         List<Account> orgList = [SELECT Id, Name, AKA__c, Legal_Name__c, Tax_ID__c, Tax_Status__c, Bgive_Contig_Id__c, Bgive_Id__c
                                  FROM Account
                                  WITH SYSTEM_MODE
                                  LIMIT 1];


        String mockResponseBody = '{"organization":';
        mockResponseBody += '{';
        mockResponseBody += '    "id":"432123",';
        mockResponseBody += '    "name":"Test",';
        mockResponseBody += '    "acronym":"TST",';
        mockResponseBody += '    "legal_name":"Testing Ltd",';
        mockResponseBody += '    "tax_class":"501(c)(3)",';
        mockResponseBody += '    "tax_id":"54-098523",';
        mockResponseBody += '    "brm_id":"'+orgList[0].Id+'",';
        mockResponseBody += '    "contig_id":"98765"';
        mockResponseBody += ' }';
        mockResponseBody += '    }';


        HttpMockRegistry.mockCallout(
            'callout:'+FLUXX_NAMED_CRED,
            '/api/rest/v2/organization/432123',
            HttpMockRegistry.createSuccessResponse(mockResponseBody)
        );

        HttpMockRegistry.mockCallout(
                'callout:'+FLUXX_NAMED_CRED,
                '/api/rest/v2/organization/432123?'+'cols='+cols,
                HttpMockRegistry.createSuccessResponse(mockResponseBody)
        );


        Test.startTest();
        	Database.executeBatch(new BatchBlinkOrgSync(new List<Id>{orgList[0].Id}),1);
        Test.stopTest();
    }
}