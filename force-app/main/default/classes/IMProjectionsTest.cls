/**
 * Author            : Paddy
 * Date              : 12/01/2025
 * Jira              : IM-408
 * Description       : Test class for IMProjections class
 */
@isTest
private without sharing class IMProjectionsTest {

	@testSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
	}

	@isTest
	static void testCreateProjectionsForBudgetedInitiative() {
		// Create a budgeted initiative with specific dates and amount
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Test Initiative', 'New');
		budgetedInitiative.Start_Date__c = Date.newInstance(2025, 1, 1);
		budgetedInitiative.End_Date__c = Date.newInstance(2027, 12, 31);
		budgetedInitiative.Proposed_Amount__c = 300000; // 3 years, $100k per year
		update budgetedInitiative;

		Test.startTest();
			List<IM_Projections__c> projections = IMProjections.create(new List<IM_Initiative__c>{ budgetedInitiative });
        	System.assertEquals(3, projections.size(), 'Should create 3 projection records for 3 years');
        
            // Verify first year projection
            IM_Projections__c firstYear = projections[0];
            System.assertEquals(budgetedInitiative.Id, firstYear.Initiative__c, 'Initiative should match');
            System.assertEquals('2025', firstYear.Year__c, 'First year should be 2025');
            System.assertEquals(100000, firstYear.Amount__c, 'Amount should be 100000');
    
            // Verify second year projection
            IM_Projections__c secondYear = projections[1];
            System.assertEquals('2026', secondYear.Year__c, 'Second year should be 2026');
            System.assertEquals(100000, secondYear.Amount__c, 'Amount should be 100000');
    
            // Verify third year projection
            IM_Projections__c thirdYear = projections[2];
            System.assertEquals('2027', thirdYear.Year__c, 'Third year should be 2027');
            System.assertEquals(100000, thirdYear.Amount__c, 'Amount should be 100000');
		Test.stopTest();
	}
}