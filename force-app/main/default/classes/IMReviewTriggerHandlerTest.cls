/**
 * Author      : Paddy
 * Date        : 11/19/2024
 * Jira        : IM-57
 * Description : Test class for IMReviewTriggerHandler.
 * Modified By :
 */
@isTest
public with sharing class IMReviewTriggerHandlerTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		Map<Id, File_Group__c> fileGroups = new Map<Id, File_Group__c>(
			[SELECT Name, Category__c, Parent_Initiative__r.name FROM File_Group__c WHERE Parent_Initiative__c = :initiative.Id]
		);
		List<File_Link__c> fileLinks = new List<File_Link__c>();
		for (File_Group__c fg : fileGroups.values()) {
			fileLinks.add(TestDataFactory.createFileLink('Test File Link', 'http://testfilelink.com', fg.Id));
		}
	}

	@isTest
	public static void testReviewName() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0'];
		User reviewer = TestDataFactory.createUser('Test', 'User');
		IM_Review__c strategyReview = TestDataFactory.createReview('Strategy');
		strategyReview.Reviewer__c = reviewer.Id;
		strategyReview.Initiative__c = initiative.Id;

		Test.startTest();
		insert strategyReview;
		IM_Review__c updatedReview = [SELECT Name FROM IM_Review__c WHERE Id = :strategyReview.Id];
		Assert.areEqual('Test User', updatedReview.Name);
		Test.stopTest();
	}

	@isTest
	public static void testInitiativeReview() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0'];
		User reviewer = TestDataFactory.createUser('Test', 'User');
		IM_Review__c budgetReview = TestDataFactory.createReview('Budget');
		budgetReview.Reviewer__c = reviewer.Id;
		budgetReview.Initiative__c = initiative.Id;
		Test.startTest();
		insert budgetReview;
		IM_Initiative__c updatedInitiative = [SELECT Name, Budget_Current_Reviewer__c FROM IM_Initiative__c WHERE Id = :initiative.Id];
		Assert.areEqual(reviewer.Id, updatedInitiative.Budget_Current_Reviewer__c);
		Test.stopTest();
	}

	@isTest
	public static void testInitiativeReviewAfterUpdate() {
		IM_Initiative__c initiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0'];
		User reviewer = TestDataFactory.createUser('Test', 'User');
		IM_Review__c budgetReview = TestDataFactory.createReview('Budget');
		budgetReview.Reviewer__c = reviewer.Id;
		budgetReview.Initiative__c = initiative.Id;
		insert budgetReview;
		Test.startTest();
		budgetReview.Review_Completed__c = System.today();
		update budgetReview;
		IM_Initiative__c updatedInitiative = [SELECT Name, Budget_Current_Reviewer__c FROM IM_Initiative__c WHERE Id = :initiative.Id];
		Assert.areEqual(reviewer.Id, updatedInitiative.Budget_Current_Reviewer__c);
		Test.stopTest();
	}
}