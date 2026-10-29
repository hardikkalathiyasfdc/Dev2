/**
 * Author      : Paddy
 * Date        : 12/31/2024
 * Jira        : IM-84
 * Description : Test class for IMCloneBudgetController.
 * Modified By :
 */
@isTest
public with sharing class IMCloneBudgetControllerTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
	}

	@isTest
	public static void testCloneBudget() {
		IM_Initiative__c newInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
		IM_Initiative__c initiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE LIMIT 1];

		Test.startTest();
			String clonedBudgetId = IMCloneBudgetController.cloneBudget(budget.Id, newInitiative.Id, 'ClonedBudget');
			IM_Budget__c clonedBudget = [SELECT Id, Cloned_From__c FROM IM_Budget__c WHERE Id = :clonedBudgetId WITH SYSTEM_MODE LIMIT 1];
			Assert.areEqual(clonedBudget.Cloned_From__c, budget.Id);
		Test.stopTest();
	}

	@isTest
	public static void testGetTeamValue() {
		IM_Initiative__c newInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
		IM_Initiative__c initiative = [SELECT Id, Team__r.Id FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE LIMIT 1];
		Test.startTest();
            String teamId = IMCloneBudgetController.getTeamValue(budget.Id);
            Assert.areEqual(teamId, initiative.Team__r.Id);
		Test.stopTest();
	}

	@isTest
	public static void testCloneBudgetException() {
		Test.startTest();
		try {
			IM_Initiative__c newInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
			IM_Initiative__c initiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
			IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE LIMIT 1];
			String clonedBudgetId = IMCloneBudgetController.cloneBudget(budget.Id, 'InitiativeId', 'ClonedBudgetName');
		} catch (Exception e) {
			Assert.isTrue(String.valueOf(e).contains('Exception'));
		}
		Test.stopTest();
	}
}