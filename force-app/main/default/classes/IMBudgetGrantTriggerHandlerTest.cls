/**
 * Author            : Paddy
 * Date              : 05/22/2025
 * Jira              : IM-203
 * Description       : Test class for IMBudgetGrantTriggerHandler.
 */

@isTest
public with sharing class IMBudgetGrantTriggerHandlerTest {
	@TestSetup
	static void setup() {
		Account testAcc = TestDataFactory.createOrg('test');

		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Draft');
		
        IM_Budget_Org__c budgetOrg = TestDataFactory.createBudgetOrg(budget.Id, testAcc.Id);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
		IM_Grant__c imGrant = TestDataFactory.createIMGrant();
		IM_Budget_Grant__c budgetGrant = TestDataFactory.createBudgetGrant(budget.Id, budgetOrg.Id, imGrant.Id);
		IM_Budget_Row__c budetRow = TestDataFactory.createBudgetRow(budget.Id, budgetGrant.Id);
		IM_Budget_Grant_Period__c budgetGrantPeriod = TestDataFactory.createBudgetGrantPeriod(budgetPeriod.Id, budgetGrant.Id);
	}

	@isTest
	public static void testDeleteSuccess() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Budget_Grant__c budgetGrant = [SELECT Id FROM IM_Budget_Grant__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
		Test.startTest();
		delete as system budgetGrant;
		List<IM_Budget_Row__c> budetRows = [SELECT Id FROM IM_Budget_Row__c WHERE Budget_Grant__c = :budgetGrant.Id WITH SYSTEM_MODE];
		List<IM_Budget_Grant_Period__c> budgetGrantPeriods = [SELECT Id FROM IM_Budget_Grant_Period__c WHERE Budget_Grant__c = :budgetGrant.Id WITH SYSTEM_MODE];

		Assert.isTrue(budetRows.isEmpty());
		Assert.isTrue(budgetGrantPeriods.isEmpty());
		Test.stopTest();
	}
}