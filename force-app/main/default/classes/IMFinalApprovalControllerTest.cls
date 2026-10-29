/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 05/22/2025
 * Jira        : IM-
 * Description : Test class for IMFinalApprovalController
 */
@isTest
public class IMFinalApprovalControllerTest {
	private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();

	private static final String BUDGETED_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.BUDGET_INITIATIVE)
		.getRecordTypeId();

	@TestSetup
	static void setup() {
		Account org = TestDataFactory.createOrg('Test org');

		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
	}

	@isTest
	public static void testGetBudgetData() {
		Test.startTest();
            IM_Budget__c budget = [
                SELECT Id, Name, Budget_Amount__c
                FROM IM_Budget__c
                WHERE Name = 'Clean Beach 1.0'
                LIMIT 1
            ];
            List<IM_Budget__c> result = IMFinalApprovalController.getBudgetData(budget.Id);
		Test.stopTest();
		Assert.areEqual(budget.Id, result[0].Id);
		Assert.areEqual(budget.Budget_Amount__c, result[0].Budget_Amount__c);
	}

	@isTest
	public static void testGetTeamFocusArea() {
		Test.startTest();
            Team__c testTeam = [SELECT Id, Name, Focus_Area__c FROM Team__c WHERE Name = 'Arts' LIMIT 1];
            List<Team__c> result = IMFinalApprovalController.getTeamFocusArea(testTeam.Id);
		Test.stopTest();
		Assert.areEqual(testTeam.Id, result[0].Id);
		Assert.areEqual(testTeam.Focus_Area__c, result[0].Focus_Area__c);
	}

	@isTest
	public static void testGetPendingApprovalBudgets() {
		Test.startTest();
            IM_Initiative__c testInitiative = [SELECT Id, Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0'];
            IM_Budget__c testBudget = [SELECT Id, Name, Budget_Amount__c FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0'];
            List<IM_Budget__c> result = IMFinalApprovalController.getPendingApprovalBudgets(testInitiative.Id);
		Test.stopTest();
		Assert.areEqual(testBudget.Id, result[0].Id);
		Assert.areEqual(testBudget.Name, result[0].Name);
	}
    
    @isTest
	public static void testUpdateBudgetStatus() {
        IM_Budget__c budget = [
                SELECT Id, Name, Budget_Amount__c
                FROM IM_Budget__c
                WHERE Name = 'Clean Beach 1.0'
                LIMIT 1
            ];
        Test.startTest();
        	IMFinalApprovalController.updateBudgetStatus(budget.Id);
        Test.stopTest();
        IM_Budget__c updatedBudget = [
                SELECT Status__c
                FROM IM_Budget__c
                WHERE Id = :budget.Id
            ];
        Assert.areEqual(updatedBudget.Status__c, 'Approved');
    }
}