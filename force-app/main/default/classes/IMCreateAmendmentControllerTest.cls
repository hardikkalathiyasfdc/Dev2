/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 05/22/2025
 * Jira        : IM-
 * Description : Test class for IMCreateAmendmentController
 */
@isTest
public with sharing class IMCreateAmendmentControllerTest {
	private static final String AMENDMENT_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.AMENDMENT)
		.getRecordTypeId();

	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
	}

	@isTest
	public static void createAmendment() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Initiative__c testInitiative = [SELECT Id, Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Initiative__c testParentInitiative = [SELECT Id, Name FROM IM_Initiative__c WHERE Name = 'Clean Beach' WITH SYSTEM_MODE];
		testInitiative.Status__c = 'Ongoing';
		testInitiative.Approved__c = true;
		testInitiative.Approved_Date__c = System.today();
		testInitiative.Parent_Initiative__c = testParentInitiative.Id;
		testInitiative.Current_Budget__c = testBudget.Id;
		update as system testInitiative;
		String result = IMCreateAmendmentController.createAmendment(testInitiative.Id);
		Test.stopTest();
		List<IM_Initiative__c> amendmentInitiatives = [SELECT Id, Name FROM IM_Initiative__c WHERE RecordTypeId = :AMENDMENT_RECORD_TYPE_ID WITH SYSTEM_MODE LIMIT 1];
		Assert.areEqual(amendmentInitiatives[0].Id, result);
	}
}