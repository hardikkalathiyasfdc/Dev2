/*
Author     : Sai Bhargav Thotakura
Date       : 06/30/2025
Jira       : IM-205
Description: Test Class for IMBudgetGrantListController
*/
@isTest
public class IMBudgetGrantListControllerTest {

    private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();

    private static final String BUDGETED_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.BUDGET_INITIATIVE)
		.getRecordTypeId();

    @TestSetup
    static void setup(){
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

    @IsTest
    private static void testGetRelatedBudgetGrants(){
        Test.startTest();
		List<IM_Initiative__c> parentInitiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
			LIMIT 1
		];
		List<IM_Initiative__c> initiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
			LIMIT 1
		];
		List<IM_Budget__c> budget = [
			SELECT Id
			FROM IM_Budget__c
			WHERE Initiative__c = :initiative[0].Id
			WITH SYSTEM_MODE
		];
		initiative[0].Approved__c = true;
		initiative[0].Approved_Date__c = System.today();
		initiative[0].Parent_Initiative__c = parentInitiative[0].Id;
		initiative[0].Status__c = 'Ongoing';
		initiative[0].Current_Budget__c = budget[0].Id;
		update as system initiative;
		IM_Grant__c imGrant = [SELECT Id FROM IM_Grant__c WITH SYSTEM_MODE LIMIT 1];
		Map<String, Object> relatedGrants = IMBudgetGrantListController.getRelatedBudgetGrants(imGrant.Id);
		Test.stopTest();
        Assert.areEqual(1, ((List<IM_Budget_Grant__c>)relatedGrants.get('budgetGrants')).size());
    }
}