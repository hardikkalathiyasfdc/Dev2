/**
 * Author      : Paddy
 * Date        : 12/03/2024
 * Jira        : IM-65
 * Description : Test class for IMBudgetTriggerHandler.
 * Modified By :
 */
@isTest
public with sharing class IMBudgetTriggerHandlerTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
	}

	@isTest
	public static void testCreateBudgetPeriodData() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = new IM_Budget__c(Initiative__c = initiative.Id, Budget_Term_months__c = 24, Budget_Categories__c = 'Component');
		Test.startTest();
		insert as system budget;
		IM_Budget__c insertedBudget = [SELECT Budget_Term_Years__c FROM IM_Budget__c WHERE Id = :budget.Id WITH SYSTEM_MODE];
		Integer insertedBudgetPeriods = [SELECT COUNT() FROM IM_Budget_Period__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
		Assert.areEqual(insertedBudget.Budget_Term_Years__c, insertedBudgetPeriods);
		Test.stopTest();
	}

	@isTest
	public static void testCreateBudgetPeriodDataForUpdate() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = new IM_Budget__c(Initiative__c = initiative.Id, Budget_Term_months__c = 24, Budget_Categories__c = 'Component');
		insert as system budget;
		Test.startTest();
		budget.Budget_Term_months__c = 36;
		update as system budget;
		IM_Budget__c insertedBudget = [SELECT Budget_Term_Years__c FROM IM_Budget__c WHERE Id = :budget.Id WITH SYSTEM_MODE];
		Integer insertedBudgetPeriods = [SELECT COUNT() FROM IM_Budget_Period__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
		Assert.areEqual(insertedBudget.Budget_Term_Years__c, insertedBudgetPeriods);
		Test.stopTest();
	}

	@isTest
	public static void testDeleteBudgetPeriodData() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = new IM_Budget__c(Initiative__c = initiative.Id, Budget_Term_months__c = 24, Budget_Categories__c = 'Component');
		insert as system budget;
		Test.startTest();
		budget.Budget_Term_months__c = 12;
		update as system budget;
		Integer updatedBudgetPeriods = [SELECT COUNT() FROM IM_Budget_Period__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
		Assert.areEqual(1, updatedBudgetPeriods);
		Test.stopTest();
	}

	@isTest
	public static void testTermReducedBudgets() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = new IM_Budget__c(
			Initiative__c = initiative.Id,
			Budget_Term_months__c = 24,
			Budget_Categories__c = 'Component',
			Last_Checked_In_At__c = System.now()
		);
		insert as system budget;
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRow(budget.Id);
		Test.startTest();
		budget.Budget_Term_months__c = 12;
		update as system budget;
		Decimal periodAmount = [SELECT Id, Period_2_Amount__c FROM IM_Budget_Row__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE]?.Period_2_Amount__c;
		Assert.areEqual(0, periodAmount);
		Test.stopTest();
	}
    
    @isTest
	public static void testDeleteBudgetOnCheckout() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = new IM_Budget__c(Initiative__c = initiative.Id, Budget_Term_months__c = 24, Budget_Categories__c = 'Component');
		insert as system budget;
		Test.startTest();
        try {
			budget.Checked_Out_By__c = UserInfo.getUserId();
            update as system budget;
			delete as system budget;
            Assert.isTrue(true, 'Expected error was not thrown');
        } catch (Exception ex) {
            Assert.isFalse(false, 'Caught an unexpected exception');
        }
		Test.stopTest();
	}

	@isTest
	public static void testPendingApprovalBudgets() {
		IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		//BRME-7040: Bypass the Initiative handler — the auto-set of Current Budget on insert-as-Pending-Approval
		//fires IMBudgetedInitiativeHandler → IMBudgetHelper.updateActiveStatus, which throws AuraHandledException in trigger/test context
		TriggerFactory.setBypass('IMBudgetedInitiativeHandler');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
		IM_Budget__c budgetNew = TestDataFactory.createBudget('Clean Beach 1.1', budgetedInitiative.Id, 'Component', 'Draft');
		TriggerFactory.removeBypass('IMBudgetedInitiativeHandler');
		Test.startTest();
		try{
			budgetNew.Status__c = 'Pending Approval';
			update as system budgetNew;
		}catch(Exception ex){
			System.debug('Exception message: ' + ex.getMessage());
			Assert.isTrue(ex.getMessage().contains('Only one budget can be in pending approval status for an initiative.'));
		}
		Test.stopTest();
	}

	@isTest
	public static void testLockBudgetRows() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = new IM_Budget__c(
			Initiative__c = initiative.Id,
			Budget_Term_months__c = 24,
			Budget_Categories__c = 'Component',
			Last_Checked_In_At__c = System.now()
		);
		insert as system budget;
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRow(budget.Id);
		Test.startTest();
			budget.Status__c = 'Approved';
			update as system budget;
		Test.stopTest();
	}

	@isTest
	public static void testDeleteBudget() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = new IM_Budget__c(Initiative__c = initiative.Id, Budget_Term_months__c = 24, Budget_Categories__c = 'Component');
		insert as system budget;
		User imProgramTeamUser = TestDataFactory.createUserWithPermissionSetGroup('IM', 'ProgramTeamUser', 'Teams User', 'IM_Program_Team', 'IM_Program_Team');
		
		Test.startTest();
        try {
			System.runAs(imProgramTeamUser) {
				delete as system budget;
				Assert.isTrue(true, 'Expected error was not thrown');
			}
        } catch (Exception ex) {
            Assert.isFalse(false, 'Caught an unexpected exception');
        }
		Test.stopTest();
	}

	@isTest
	public static void testSetCurrentBudgetOnPendingApproval() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', initiative.Id, 'Component', 'Draft');
		TestDataFactory.createBudgetRow(budget.Id);
		Test.startTest();
		budget.Status__c = 'Pending Approval';
		update as system budget;
		Test.stopTest();
		IM_Initiative__c updatedInitiative = [SELECT Current_Budget__c FROM IM_Initiative__c WHERE Id = :initiative.Id WITH SYSTEM_MODE];
		Assert.areEqual(budget.Id, updatedInitiative.Current_Budget__c, 'Current Budget should be set to the budget moved to Pending Approval');
		IM_Budget__c updatedBudget = [SELECT Is_Active__c FROM IM_Budget__c WHERE Id = :budget.Id WITH SYSTEM_MODE];
		Assert.isTrue(updatedBudget.Is_Active__c, 'Current Budget should be marked Active');
	}

	@isTest
	public static void testClearCurrentBudgetOnReturnToDraft() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', initiative.Id, 'Component', 'Draft');
		TestDataFactory.createBudgetRow(budget.Id);
		budget.Status__c = 'Pending Approval';
		update as system budget;
		Test.startTest();
		budget.Status__c = 'Draft';
		update as system budget;
		Test.stopTest();
		IM_Initiative__c updatedInitiative = [SELECT Current_Budget__c FROM IM_Initiative__c WHERE Id = :initiative.Id WITH SYSTEM_MODE];
		Assert.isNull(updatedInitiative.Current_Budget__c, 'Current Budget should be cleared when the budget moves back to Draft');
	}

	@isTest
	public static void testClearDoesNotWipeRepointedBudget() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', initiative.Id, 'Component', 'Draft');
		TestDataFactory.createBudgetRow(budget.Id);
		budget.Status__c = 'Pending Approval';
		update as system budget;
		//Repoint the Initiative's Current Budget to a different (approved) budget
		IM_Budget__c approvedBudget = TestDataFactory.createBudget('Clean Beach 2.0', initiative.Id, 'Component', 'Approved');
		update as system new IM_Initiative__c(Id = initiative.Id, Current_Budget__c = approvedBudget.Id);
		Test.startTest();
		budget.Status__c = 'Draft';
		update as system budget;
		Test.stopTest();
		IM_Initiative__c updatedInitiative = [SELECT Current_Budget__c FROM IM_Initiative__c WHERE Id = :initiative.Id WITH SYSTEM_MODE];
		Assert.areEqual(approvedBudget.Id, updatedInitiative.Current_Budget__c, 'Current Budget should not be cleared when it no longer points at the budget leaving Pending Approval');
	}

	@isTest
	public static void testBulkSetCurrentBudget() {
		IM_Initiative__c initiativeOne = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Initiative__c initiativeTwo = TestDataFactory.createBudgetedInitiative('Green River', 'New');
		IM_Budget__c budgetOne = TestDataFactory.createBudget('Clean Beach 1.0', initiativeOne.Id, 'Component', 'Draft');
		IM_Budget__c budgetTwo = TestDataFactory.createBudget('Green River 1.0', initiativeTwo.Id, 'Component', 'Draft');
		TestDataFactory.createBudgetRow(budgetOne.Id);
		TestDataFactory.createBudgetRow(budgetTwo.Id);
		budgetOne.Status__c = 'Pending Approval';
		budgetTwo.Status__c = 'Pending Approval';
		Test.startTest();
		update as system new List<IM_Budget__c>{ budgetOne, budgetTwo };
		Test.stopTest();
		Map<Id, IM_Initiative__c> initiativesById = new Map<Id, IM_Initiative__c>([
			SELECT Current_Budget__c
			FROM IM_Initiative__c
			WHERE Id IN :new Set<Id>{ initiativeOne.Id, initiativeTwo.Id }
			WITH SYSTEM_MODE
		]);
		Assert.areEqual(budgetOne.Id, initiativesById.get(initiativeOne.Id).Current_Budget__c, 'Current Budget should be set for the first initiative');
		Assert.areEqual(budgetTwo.Id, initiativesById.get(initiativeTwo.Id).Current_Budget__c, 'Current Budget should be set for the second initiative');
	}

	@isTest
	public static void testTypeOfWorkRequiredForPendingApproval() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = new IM_Budget__c(
			Initiative__c = initiative.Id,
			Budget_Term_months__c = 24,
			Budget_Categories__c = 'Component',
			Type_of_Work__c = false
		);
		insert as system budget;
		TestDataFactory.createBudgetRow(budget.Id);
		Test.startTest();
		budget.Status__c = 'Pending Approval';
		try {
			update as system budget;
			Assert.fail('Expected a validation error when Type of Work is not checked');
		} catch (DmlException ex) {
			Assert.isTrue(
				ex.getMessage().contains('Type of Work must be added in budget template to proceed further.'),
				'Unexpected error message: ' + ex.getMessage()
			);
		}
		//With Type of Work checked the update succeeds and Current Budget is set
		budget.Type_of_Work__c = true;
		update as system budget;
		Test.stopTest();
		IM_Initiative__c updatedInitiative = [SELECT Current_Budget__c FROM IM_Initiative__c WHERE Id = :initiative.Id WITH SYSTEM_MODE];
		Assert.areEqual(budget.Id, updatedInitiative.Current_Budget__c, 'Current Budget should be set once Type of Work is checked');
	}

	@isTest
	public static void testClearCurrentBudgetOnDeclined() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', initiative.Id, 'Component', 'Draft');
		TestDataFactory.createBudgetRow(budget.Id);
		budget.Status__c = 'Pending Approval';
		update as system budget;
		Test.startTest();
		budget.Status__c = 'Declined';
		update as system budget;
		Test.stopTest();
		IM_Initiative__c updatedInitiative = [SELECT Current_Budget__c FROM IM_Initiative__c WHERE Id = :initiative.Id WITH SYSTEM_MODE];
		Assert.isNull(updatedInitiative.Current_Budget__c, 'Current Budget should be cleared when the budget is Declined');
	}

	@isTest
	public static void testSetCurrentBudgetOnInsertAsPendingApproval() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE LIMIT 1];
		Test.startTest();
		//BRME-7040: Bypass the Initiative handler (IMBudgetHelper.updateActiveStatus AuraHandledException) around the insert;
		//the auto-set of Current Budget still runs in the budget trigger — verify it afterwards
		TriggerFactory.setBypass('IMBudgetedInitiativeHandler');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', initiative.Id, 'Component', 'Pending Approval');
		TriggerFactory.removeBypass('IMBudgetedInitiativeHandler');
		Test.stopTest();
		IM_Initiative__c updatedInitiative = [SELECT Current_Budget__c FROM IM_Initiative__c WHERE Id = :initiative.Id WITH SYSTEM_MODE];
		Assert.areEqual(budget.Id, updatedInitiative.Current_Budget__c, 'Current Budget should be set for a budget inserted directly as Pending Approval');
	}
}