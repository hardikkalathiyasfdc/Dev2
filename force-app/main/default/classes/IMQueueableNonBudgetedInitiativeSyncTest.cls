@isTest
public with sharing class IMQueueableNonBudgetedInitiativeSyncTest {
	private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();

	private static final String NON_BUDGETED_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.MISC_INITIATIVE_TYPE)
		.getRecordTypeId();

	@testSetup
	static void setup() {

		Account org = TestDataFactory.createOrg('Test org');
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
	}

	@isTest
	public static void testIMQueueableNonBudgetedInitiative() {
		Test.startTest();
            List<IM_Initiative__c> parentInitiatives = [
                SELECT Id, Name, Team__c, Segment__c, Focus_Area__c, Foundation_Code__c
                FROM IM_Initiative__c
                WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
                LIMIT 1
            ];
            IM_Initiative__c parentInitiative = parentInitiatives[0];
            parentInitiative.Name = parentInitiative.Name + ' Renamed';
            update parentInitiative;
		Test.stopTest();
        List<IM_Initiative__c> nonBudgetedInitiatives = [
			SELECT Id, Name
			FROM IM_Initiative__c
			WHERE RecordTypeId = :NON_BUDGETED_INITIATIVE_RECORD_TYPE_ID
			LIMIT 1
		];
		Assert.areEqual('Clean Beach Renamed Miscellaneous', nonBudgetedInitiatives[0].Name);
	}
}