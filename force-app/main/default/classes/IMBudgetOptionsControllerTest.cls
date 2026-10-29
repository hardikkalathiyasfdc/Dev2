@isTest
public with sharing class IMBudgetOptionsControllerTest {
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
	}

	@isTest
	public static void testGetBudget() {
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		Test.startTest();
			IM_Budget__c newBudget = IMBudgetOptionsController.getBudget(budget[0].Id);
		Test.stopTest();
		Assert.areEqual(budget[0].Id, newBudget.Id);
	}

	@isTest
	public static void testGetBudgetException() {
		try {
			List<IM_Initiative__c> initiative = [SELECT Id FROM IM_Initiative__c WITH SYSTEM_MODE LIMIT 1];
			Test.startTest();
				IM_Budget__c newBudget = IMBudgetOptionsController.getBudget(initiative[0].Id);
			Test.stopTest();
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
	}

	@isTest
	public static void testUpdateBudget() {
		List<IM_Budget__c> budget = [SELECT Id, Unique_Identifier__c FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		Test.startTest();
            budget[0].Unique_Identifier__c = true;
            IMBudgetOptionsController.updateBudget(budget[0]);
            IM_Budget__c updatedBudget = [SELECT Id, Unique_Identifier__c FROM IM_Budget__c WHERE Id = :budget[0].Id WITH SYSTEM_MODE];
		Test.stopTest();
		Assert.areEqual(budget[0].Unique_Identifier__c, updatedBudget.Unique_Identifier__c);
	}

	@isTest
	public static void testUpdateBudgetException() {
		try {
			List<IM_Budget__c> budget = [SELECT Id, Budget_Categories__c FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
			Test.startTest();
                budget[0].Budget_Categories__c = '';
                IMBudgetOptionsController.updateBudget(budget[0]);
			Test.stopTest();
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
	}

	@isTest
	public static void testGetBudgetRows() {
		List<IM_Budget__c> budget = [SELECT Id, Unique_Identifier__c FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Budget_Row__c> rows = [SELECT Id, Component__c FROM IM_Budget_Row__c WHERE Budget__c = :budget[0].Id WITH SYSTEM_MODE];
		Test.startTest();
            List<IM_Budget_Row__c> budgetRows = IMBudgetOptionsController.getBudgetRows(budget[0].Id);
		Test.stopTest();
		Assert.areEqual(rows[0].Component__c, budgetRows[0].Component__c);
	}

	@isTest
	public static void testUpdateBudgetRows() {
		List<IM_Budget__c> budget = [SELECT Id, Unique_Identifier__c FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		List<IM_Budget_Row__c> rows = [
			SELECT
				Id,
				Component__c,
				SubComponent__c,
				Geography__c,
				Partner__c,
				Partner_Role__c,
				Unique_Identifier__c,
				Payee_Fiscal_Sponsor__c,
				Sub_Partner__c,
				Sub_Partner_Type__c,
				Duration_months__c,
				Type_of_Work__c,
				Partner_Fund__c,
				Description__c
			FROM IM_Budget_Row__c
			WHERE Budget__c = :budget[0].Id
			WITH SYSTEM_MODE
		];
		Map<String, Boolean> fieldValMap = new Map<String, Boolean>();
		fieldValMap.put('Component__c', false);
		fieldValMap.put('SubComponent__c', false);
		fieldValMap.put('Geography__c', false);
		fieldValMap.put('Partner__c', false);
		fieldValMap.put('Partner_Role__c', false);
		fieldValMap.put('Unique_Identifier__c', true);
		fieldValMap.put('Payee_Fiscal_Sponsor__c', true);
		fieldValMap.put('Sub_Partner__c', true);
		fieldValMap.put('Sub_Partner_Type__c', true);
		fieldValMap.put('Duration_months__c', true);
		fieldValMap.put('Type_of_Work__c', true);
		fieldValMap.put('Partner_Fund__c', true);
		Test.startTest();
            IMBudgetOptionsController.updateBudgetRows(budget[0], rows, fieldValMap);
            List<IM_Budget_Row__c> budgetRows = [SELECT Id FROM IM_Budget_Row__c WHERE Budget__c = :budget[0].Id WITH SYSTEM_MODE];
		Test.stopTest();
		Assert.areEqual(2, budgetRows.size());
	}

	@isTest
	public static void testUpdateBudgetRowsException() {
		try{
			List<IM_Budget__c> budget = [SELECT Id, Unique_Identifier__c FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
			List<IM_Budget_Row__c> rows = [
				SELECT
					Id,
					Duration_months__c
				FROM IM_Budget_Row__c
				WHERE Budget__c = :budget[0].Id
				WITH SYSTEM_MODE
			];
			Map<String, Boolean> fieldValMap = new Map<String, Boolean>();
			fieldValMap.put('Duration_months__c', false);
			Test.startTest();
				IMBudgetOptionsController.updateBudgetRows(budget[0], rows, fieldValMap);
			Test.stopTest();
		} catch(Exception e){
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
	}

	@isTest
	public static void testDeleteChildRecords() {
		List<IM_Budget__c> budget = [SELECT Id, Geography__c, Partner_Fund__c FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];

		Map<String, Boolean> fieldValMap = new Map<String, Boolean>();
		fieldValMap.put('Component__c', true);
		fieldValMap.put('SubComponent__c', true);
		fieldValMap.put('Geography__c', true);
		fieldValMap.put('Partner__c', false);
		fieldValMap.put('Partner_Role__c', false);
		fieldValMap.put('Unique_Identifier__c', false);
		fieldValMap.put('Payee_Fiscal_Sponsor__c', false);
		fieldValMap.put('Sub_Partner__c', false);
		fieldValMap.put('Sub_Partner_Type__c', false);
		fieldValMap.put('Duration_months__c', false);
		fieldValMap.put('Type_of_Work__c', false);
		fieldValMap.put('Partner_Fund__c', false);
		Test.startTest();
            IMBudgetOptionsController.deleteBudgetChildRecords(budget[0], fieldValMap);
            List<IM_Component__c> components = [SELECT Id FROM IM_Component__c WHERE Budget__c = :budget[0].Id WITH SYSTEM_MODE];
            List<IM_Geography__c> geographies = [SELECT Id FROM IM_Geography__c WHERE Budget__c = :budget[0].Id WITH SYSTEM_MODE];
            Assert.isTrue(components.isEmpty());
            Assert.isTrue(geographies.isEmpty());
		Test.stopTest();
	}
}