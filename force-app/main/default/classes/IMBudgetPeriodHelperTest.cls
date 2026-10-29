/**
 * Author            : Paddy
 * Date              : 05/28/2025
 * Jira              : IM-203
 * Description       : Test class for IMBudgetPeriodHelper.
 */

@isTest
public with sharing class IMBudgetPeriodHelperTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');

		TestDataFactory.createBudgetPeriods(budget.Id, 3);
	}

	@isTest
	public static void testSetDates() {
		IM_Initiative__c initiative = [
			SELECT Id, Start_Date__c, End_Date__c, Parent_Initiative__c, Status__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Beach 1.0'
			WITH SYSTEM_MODE
		];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Beach' WITH SYSTEM_MODE];

		Test.startTest();
		initiative.Current_Budget__c = budget.Id;
		initiative.Approved__c = true;
		initiative.Start_Date__c = System.today().addMonths(10);
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Approved_Date__c = System.today();
		update as system initiative;

		IM_Budget_Period__c period1 = [
			SELECT Period__c, Period_Start_Date__c, Period_End_Date__c
			FROM IM_Budget_Period__c
			WHERE Budget__c = :budget.Id AND Period__c = 1
			WITH SYSTEM_MODE
			LIMIT 1
		];

		Assert.areEqual(initiative.Start_Date__c, period1.Period_Start_Date__c);
		Test.stopTest();
	}
}