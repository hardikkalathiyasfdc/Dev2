@isTest
public class ManageFoundationCodesCntrlTest {

    @testSetup static void setup() {
		Map<String, Focus_Area__c> focusAreas = TestDataFactory.createFocusAreas(new List<String>{ 'Government Innovation' });

		Foundation_Code__c rootCode = TestDataFactory.createRootFoundationCode();
		rootCode.Last_Sync_All_Job_Id__c = '1234';
		update rootCode;

        Foundation_Code__c code = TestDataFactory.buildFoundationCode('Government Innovation','Focus Area',rootCode.Id,focusAreas.get('Government Innovation').Id);
		insert code;

		Foundation_Code__c childFC1 = TestDataFactory.buildFoundationCode('Clean Beach', 'Non Programmatic Initiative', code.Id, null);
		Foundation_Code__c childFC2 = TestDataFactory.buildFoundationCode('Clean Air', 'Non Programmatic Initiative', code.Id, null);
		List<Foundation_Code__c> childFcs = new List<Foundation_Code__c>{ childFC1, childFC2 };
		insert childFcs;
	}

	@isTest
	static void testGetFoundationCodes() {
		List<Foundation_Code__c> foundationCodes = ManageFoundationCodesCntrl.getFoundationCodes();
		Assert.isTrue(!foundationCodes.isEmpty(), 'Foundation Codes not returned');
	}

	@isTest
	static void testSync() {
		Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
		Foundation_Code__c foundationCode = [SELECT Id FROM Foundation_Code__c WHERE Name = 'Government Innovation' with SYSTEM_MODE];
		Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
		Test.startTest();
		ManageFoundationCodesCntrl.syncCode(foundationCode.Id);
		Test.stopTest();
		BGiveApiMav bgiveApi = new BGiveApiMav();
        BGiveApi.BGiveAPIResponse bgiveResponse = (BGiveApi.BGiveAPIResponse)bgiveApi.fetch(foundationCode.Id, new List<String>{'model_attribute_id','value'});
		Object record = bgiveResponse.record;
		Assert.areEqual('Government Innovation', ((Map<String, Object>) record).get('value'));
	}

	@isTest
	static void testSyncAll() {
		Test.setMock(HttpCalloutMock.class, new FoundationCodeCalloutMock());
		Foundation_Code__c foundationCode = [SELECT Id FROM Foundation_Code__c WHERE Name = 'Government Innovation' with SYSTEM_MODE];
		Test.startTest();
		ManageFoundationCodesCntrl.syncAll();
		Test.stopTest();
		BGiveApiMav bgiveApi = new BGiveApiMav();
        BGiveApi.BGiveAPIResponse bgiveResponse = (BGiveApi.BGiveAPIResponse)bgiveApi.fetch(foundationCode.Id, new List<String>{'model_attribute_id','value'});
		Object record = bgiveResponse.record;
		Assert.areEqual('Government Innovation', ((Map<String, Object>) record).get('value'));
	}

	@isTest
	static void testLastSyncStatus() {

		Foundation_Code__c foundationCode = [SELECT Id FROM Foundation_Code__c WHERE Name = 'Government Innovation' with SYSTEM_MODE];
		Test.startTest();
		Object result = ManageFoundationCodesCntrl.syncLastSyncJobStatus();
		Assert.areEqual(null, result);
		Test.stopTest();
	}

	@isTest
	static void testLastSyncStatusException() {
		Test.startTest();
		try {
			Foundation_Code__c initiativeCode = [
				SELECT Id, Last_Sync_All_Job_Id__c
				FROM Foundation_Code__c
				WHERE Foundation_Code__c = :Assets.INITIATIVES
				WITH SYSTEM_MODE
				LIMIT 1
			];
			delete initiativeCode;
			Object result = ManageFoundationCodesCntrl.syncLastSyncJobStatus();
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
		Test.stopTest();
	}
}