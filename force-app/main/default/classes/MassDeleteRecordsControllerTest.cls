/**
 * Author      : Sai Bhargav
 * Date        : 08/08/2025
 * Jira        : IM-309
 * Description : Test class for MassDeleteRecordsController
 */
@isTest
public class MassDeleteRecordsControllerTest {
	@TestSetup
	static void setup() {
		Account org = TestDataFactory.createOrg('Test Organiation');
	}

	@isTest
	public static void hasDeleteAccess() {
		Account acc = [SELECT Id FROM Account WHERE Name = 'Test Organiation' WITH SYSTEM_MODE LIMIT 1];
		Test.startTest();
		MassDeleteRecordsController.InputWrapper input = new MassDeleteRecordsController.InputWrapper();
		input.ids = new List<Id>{ acc.Id };
		List<MassDeleteRecordsController.OutputWrapper> result = MassDeleteRecordsController.deleteRecords(
			new List<MassDeleteRecordsController.InputWrapper>{ input }
		);
		Test.stopTest();
		Assert.areEqual(0, new List<Account>([SELECT Id FROM Account WHERE Name = 'Test Organiation' WITH SYSTEM_MODE]).size());
		Assert.isFalse(result[0].hasError, 'Expected no error');
		Assert.areEqual('', result[0].errorMessage);
	}

	@isTest
	public static void noAccess() {
		Account acc = [SELECT Id,Name FROM Account WHERE Name = 'Test Organiation' WITH SYSTEM_MODE LIMIT 1];
		Test.startTest();
		MassDeleteRecordsController.InputWrapper input = new MassDeleteRecordsController.InputWrapper();
		input.ids = new List<Id>{ acc.Id };
		String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' WITH SYSTEM_MODE];
		User u = new User(
			Alias = 'standt',
			Email = 'standarduser@testorg.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'Testing',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = p.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			Sharing_Team__c = 'System Administration',
			UserName = uniqueUserName
		);
		System.runAs(u) {
			List<MassDeleteRecordsController.OutputWrapper> result = MassDeleteRecordsController.deleteRecords(
				new List<MassDeleteRecordsController.InputWrapper>{ input }
			);
			Test.stopTest();
			Assert.areEqual(1, result.size(), 'Should return exactly one output wrapper');
			Assert.isTrue(result[0].hasError);
			Assert.areEqual(Assets.NO_DELETE_ACCESS+ ': ('+acc.Name+')', result[0].errorMessage);
		}
	}

	@isTest
	public static void emptyInput() {
		Test.startTest();
		MassDeleteRecordsController.InputWrapper input = new MassDeleteRecordsController.InputWrapper();
		input.ids = new List<Id>();
		List<MassDeleteRecordsController.OutputWrapper> result = MassDeleteRecordsController.deleteRecords(
			new List<MassDeleteRecordsController.InputWrapper>{ input }
		);
		Test.stopTest();
		Assert.areEqual(1, result.size(), 'Should return exactly one output wrapper');
		Assert.isTrue(result[0].hasError);
		Assert.areEqual(Assets.NO_RECORDS_SELECTED, result[0].errorMessage);
	}
}