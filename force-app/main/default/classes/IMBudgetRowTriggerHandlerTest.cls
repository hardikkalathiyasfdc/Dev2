@isTest
public with sharing class IMBudgetRowTriggerHandlerTest {
	@testSetup
	static void setup() {
		Account org = TestDataFactory.createOrg('Test org');
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
		IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
		IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
		IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
        IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, partner.Id, geography.Id);
		IM_Funding_Source__c partnerFund = TestDataFactory.createFundingPartner(budget.Id);
	}

	@isTest
	public static void testBudgetRowInsert() {
		Test.startTest();
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Component__c> component = [SELECT Id FROM IM_Component__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Component__c> subComponent = [SELECT Id FROM IM_Component__c WHERE Type__c = 'SubComponent' WITH SYSTEM_MODE LIMIT 1];
		List<IM_Geography__c> geography = [SELECT Id FROM IM_Geography__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Budget_Org__c> partner = [SELECT Id FROM IM_Budget_Org__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Funding_Source__c> partnerFund = [SELECT Id FROM IM_Funding_Source__c WITH SYSTEM_MODE LIMIT 1];
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget[0].Id, component[0].Id, subComponent[0].Id, partner[0].Id, geography[0].Id);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget[0].Id);
		IM_Budget_Row__c budgetRow1 = TestDataFactory.createBudgetRowWithData(
			budget[0].Id,
			component[0].Id,
			subComponent[0].Id,
			partner[0].Id,
			geography[0].Id
		);
		budgetRow1.Unique_Identifier__c = '6789';
		budgetRow1.Partner_Fund__c = partnerFund[0].Id;
		update as system budgetRow1;
		List<IM_Budget_Row__c> budgetRows = [SELECT Id FROM IM_Budget_Row__c WHERE Budget__c = :budget[0].Id WITH SYSTEM_MODE];
		Test.stopTest();
		Assert.areEqual(3, budgetRows.size());
	}

	@isTest
	public static void testBudgetRowDelete() {
		Test.startTest();
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Component__c> component = [SELECT Id FROM IM_Component__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Component__c> subComponent = [SELECT Id FROM IM_Component__c WHERE Type__c = 'SubComponent' WITH SYSTEM_MODE LIMIT 1];
		List<IM_Geography__c> geography = [SELECT Id FROM IM_Geography__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Budget_Org__c> partner = [SELECT Id FROM IM_Budget_Org__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Funding_Source__c> partnerFund = [SELECT Id FROM IM_Funding_Source__c WITH SYSTEM_MODE LIMIT 1];
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget[0].Id, component[0].Id, subComponent[0].Id, partner[0].Id, geography[0].Id);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget[0].Id);
		IM_Budget_Row__c budgetRow1 = TestDataFactory.createBudgetRowWithData(
			budget[0].Id,
			component[0].Id,
			subComponent[0].Id,
			partner[0].Id,
			geography[0].Id
		);
		budgetRow1.Unique_Identifier__c = '6789';
		budgetRow1.Partner_Fund__c = partnerFund[0].Id;
		update as system budgetRow1;
		delete as system budgetRow1;
		List<IM_Budget_Row__c> budgetRows = [SELECT Id FROM IM_Budget_Row__c WHERE Budget__c = :budget[0].Id WITH SYSTEM_MODE LIMIT 1];
		Test.stopTest();
		Assert.areEqual(1, budgetRows.size());
	}
}