/**
 * Author            : Paddy
 * Date              : 05/21/2025
 * Jira              : IM-203
 * Description       : Test class for IMComponentTriggerHandler.
 */

@isTest
public with sharing class IMComponentTriggerHandlerTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
	}

	@isTest
	public static void testComponentExternalId() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];

		Test.startTest();
		IM_Component__c component = new IM_Component__c(Name = 'Research', Budget__c = budget.Id, Type__c = 'Component');
		insert as system component;

		IM_Component__c insertedComponent = [SELECT External_Id__c FROM IM_Component__c WHERE Id = :component.Id WITH SYSTEM_MODE];
		Assert.areEqual(component.Budget__c + component.Name, insertedComponent.External_Id__c);
		Test.stopTest();
	}

	@isTest
	public static void testSubComponentExternalId() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];

		Test.startTest();
		IM_Component__c component = new IM_Component__c(Name = 'Research', Budget__c = budget.Id, Type__c = 'Component');
		insert as system component;

		IM_Component__c subComponent = new IM_Component__c(
			Name = 'Training',
			Budget__c = budget.Id,
			Parent_Component__c = component.Id,
			Type__c = 'SubComponent'
		);
		insert as system subComponent;

		IM_Component__c insertedSubComponent = [SELECT External_Id__c FROM IM_Component__c WHERE Parent_Component__c = :component.Id WITH SYSTEM_MODE];
		String externalId = (String) subComponent.Budget__c + subComponent.Parent_Component__c + subComponent.Name;
		Assert.areEqual(externalId, insertedSubComponent.External_Id__c);
		Test.stopTest();
	}

	@isTest
	public static void testExternalIdForUpdate() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Component__c component = new IM_Component__c(Name = 'Research', Budget__c = budget.Id, Type__c = 'Component');
		insert as system component;

		Test.startTest();
        component.Name = 'Research and Development';
		update as system component;


		IM_Component__c updatedComponent = [SELECT External_Id__c FROM IM_Component__c WHERE Id = :component.Id WITH SYSTEM_MODE];
		Assert.areEqual(component.Budget__c + component.Name, updatedComponent.External_Id__c);
		Test.stopTest();
	}
}