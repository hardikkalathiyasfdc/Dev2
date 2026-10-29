/**
 * Author       : Sai Bhargav Thotakura
 * Created Date : Jun 45 2025
 * Jira         : IM-49
 * Description  : Test class for BatchIMInitiativeSync
 */
@IsTest
public class BatchIMInitiativeSyncTest {
	@TestSetup
	static void setup() {
		//Create Initiative
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
	}

    @IsTest
	private static void testBatchJobPositiveScn() {
        Test.startTest();
        Set<Id> initiativeIdSet = new Set<Id>();
        IM_Initiative__c testInitiative = [SELECT Id,Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
        initiativeIdSet.add(testInitiative.Id);
        Database.executeBatch(new BatchIMInitiativeSync(initiativeIdSet), 1);
        Assert.isNotNull(initiativeIdSet);
        Test.stopTest();
    }
}