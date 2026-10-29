@isTest
public class BGiveApiTest {

    @testSetup static void setup() {
        Map<String,Focus_Area__c> focusAreas = TestDataFactory.createFocusAreas(new List<String>{'Government Innovation'});

        Foundation_Code__c rootCode = TestDataFactory.createRootFoundationCode();
        rootCode.Last_Sync_All_Job_Id__c = '1234';
        update rootCode;

        Foundation_Code__c code = TestDataFactory.buildFoundationCode('Government Innovation','Focus Area',rootCode.Id,focusAreas.get('Government Innovation').Id);
        code.BGive_ID__c = '{"240765":"10259239","240763":"10259237"}';
        insert code;

        Foundation_Code__c childFC1 = TestDataFactory.buildFoundationCode('Clean Beach','Non Programmatic Initiative',code.Id,null );
        Foundation_Code__c childFC2 = TestDataFactory.buildFoundationCode('Clean Air','Non Programmatic Initiative',code.Id,null);
        List<Foundation_Code__c> childFcs = new List<Foundation_Code__c>{childFC1, childFC2};
        insert childFcs;
    }

    @isTest
    static void testGetCallout() {
        Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
        Foundation_Code__c foundationCode = [SELECT Id FROM Foundation_Code__c WHERE Name = 'Government Innovation' with SYSTEM_MODE];
        BGiveApiMav bgiveApi = new BGiveApiMav();
        Test.startTest();
            BGiveApi.BGiveAPIResponse bgiveResponse = (BGiveApi.BGiveAPIResponse)bgiveApi.fetch(foundationCode.Id, new List<String>{'model_attribute_id','value'});
            Object record = bgiveResponse.record;
            Assert.areEqual('Government Innovation', ((Map<String,Object>)record).get('value'));
        Test.stopTest();
    }

    @isTest
    static void testCreateCallout() {
        Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
        Foundation_Code__c foundationCode = [SELECT Id FROM Foundation_Code__c with SYSTEM_MODE LIMIT 1];
        Map<String,Object> data = new Map<String,Object>();
        data.put('id', foundationCode.Id);
        data.put('description', 'Government Innovation');
        data.put('value', 'Government Innovation');
        data.put('retired', 'false');
        data.put('model_attribute_id', '12345');
        BGiveApiMav bgiveApi = new BGiveApiMav();
        Test.startTest();
        	BGiveApi.BGiveAPIResponse bgiveResponse = (BGiveApi.BGiveAPIResponse)bgiveApi.fetch(foundationCode.Id, new List<String>{'model_attribute_id','value'});
            Object record = bgiveResponse.record;
            Assert.areEqual('Government Innovation', ((Map<String,Object>)record).get('value'));
        Test.stopTest();
    }

    @isTest
    static void testModifyCallout() {
        Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
        Foundation_Code__c foundationCode = [SELECT Id FROM Foundation_Code__c with SYSTEM_MODE LIMIT 1];
        Map<String,Object> data = new Map<String,Object>();
        data.put('id', foundationCode.Id);
        data.put('description', 'Government Innovation');
        data.put('value', 'Government Innovation');
        data.put('retired', 'true');
        data.put('model_attribute_id', '123456');
        BGiveApiMav bgiveApi = new BGiveApiMav();
        Test.startTest();
            BGiveApi.BGiveAPIResponse bgiveResponse = (BGiveApi.BGiveAPIResponse)bgiveApi.fetch(foundationCode.Id, new List<String>{'model_attribute_id','value'});
            Object record = bgiveResponse.record;
            Assert.areEqual(1, ((Map<String,Object>)record).get('retired'));
        Test.stopTest();
    }
}