/**
 * Author            : Paddy
 * Date              : 05/21/2025
 * Jira              : IM-203
 * Description       : Test class for IMGeographyTriggerHandler.
 */

@isTest
public with sharing class IMGeographyTriggerHandlerTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
	}

	@isTest
	public static void testExternalId() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0'];

		Test.startTest();
		IM_Geography__c geography = new IM_Geography__c(Name = 'Boston, MA', Budget__c = budget.Id);
		insert geography;

		IM_Geography__c insertedGeography = [SELECT External_Id__c FROM IM_Geography__c WHERE Id = :geography.Id];
		Assert.areEqual(geography.Budget__c + geography.Name, insertedGeography.External_Id__c);
		Test.stopTest();
	}

	@isTest
	public static void testExternalIdForUpdate() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0'];
		IM_Geography__c geography = new IM_Geography__c(Name = 'Boston, MA', Budget__c = budget.Id);
		insert geography;

		Test.startTest();
		geography.Name = 'Amherst, NY';
		update geography;

		IM_Geography__c updatedGeography = [SELECT External_Id__c FROM IM_Geography__c WHERE Id = :geography.Id];
		Assert.areEqual(geography.Budget__c + geography.Name, updatedGeography.External_Id__c);
		Test.stopTest();
	}
}