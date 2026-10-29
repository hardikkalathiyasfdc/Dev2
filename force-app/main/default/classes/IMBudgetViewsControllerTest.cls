@isTest
public with sharing class IMBudgetViewsControllerTest {
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
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
		ContentVersion contentVersion = TestDataFactory.createContentVersion();
		ContentVersion cv = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id WITH SYSTEM_MODE LIMIT 1];
		Template__c template = TestDataFactory.createTemplateForViews(cv.ContentDocumentId);
	}

	@isTest
	public static void testGetBudget() {
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		Test.startTest();
		IM_Budget__c newBudget = IMBudgetViewsController.getBudget(budget[0].Id);
		Test.stopTest();
		Assert.areEqual(budget[0].Id, newBudget.Id);
	}

	@isTest
	public static void testGetBudgetTemplate() {
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		Template__c template = [SELECT Id, Metadata__c FROM Template__c WITH SYSTEM_MODE LIMIT 1];
		Test.startTest();
		IMBudgetViewsController.TemplateWrapper templateWrapper = IMBudgetViewsController.getBudgetTemplate(budget[0].Id);
		Test.stopTest();
		Assert.areEqual(template.Metadata__c, templateWrapper.metadata);
	}

	@isTest
	public static void testGetData() {
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		Map<String, List<String>> tabData = new Map<String, List<String>>();
		List<String> tab1 = new List<String>{ 'Component__c', 'SubComponent__c' };
		List<String> tab2 = new List<String>{ 'Partner__c', 'Partner_Role__c' };
		tabData.put('compTab', tab1);
		tabData.put('partnerTab', tab2);
		String tabToColsMapping = JSON.serialize(tabData);
		Test.startTest();
		IMBudgetViewsController.BudgetWrapper budgetWrapper = IMBudgetViewsController.getData(budget[0].Id, tabToColsMapping);
		Map<String, List<AggregateResult>> dataMap = budgetWrapper.aggregateDataMap;
		Set<String> outputTabs = dataMap.keySet();
		Set<String> inputTabs = tabData.keySet();
		Test.stopTest();
		Assert.areEqual(inputTabs, outputTabs);
	}
}