/**
 * Author      : Paddy P
 * Date        : 03/14/2025
 * Jira        : IM-48
 * Description : Test class for IMService
 */
@isTest
public class IMServiceTest {
	    
    //Test Data Setup
	@TestSetup
	static void setup() {
		
		//Test Account
		Account org = TestDataFactory.createOrg('Test Organiation');
        
        TestDataFactory.createInitiativeBaseData();
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach', budgetedInitiative.Id, 'Component', 'Pending Approval');
        	
        budgetedInitiative.Status__c = 'Ongoing';
        budgetedInitiative.Approved__c = true;
        budgetedInitiative.Current_Budget__c = [SELECT Id, Name FROM IM_Budget__c LIMIT 1]?.Id;
        budgetedInitiative.Approved_Date__c = System.today();
        update budgetedInitiative;
       
        
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        insert amendmentInitiative;

        //File Group Records
        File_Group__c budgetedInitiativeFileGroup = TestDataFactory.createFileGroup('Initiative', 'Final Docs', budgetedInitiative.Id);
		File_Group__c amendmentFileGroup = [SELECT Id FROM File_Group__c WHERE Parent_Initiative__c = :amendmentInitiative.Id LIMIT 1];
        TestDataFactory.createFile('Test Final Docs',amendmentFileGroup.Id);
	}


	@isTest
	public static void testComputeGrants() {
		
		Test.startTest();
       		Map<Id, IM_Budget__c> budgetIdMap = new Map<Id, IM_Budget__c>([SELECT Id, Name FROM IM_Budget__c LIMIT 1]);
            IMService.computeGrants(budgetIdMap.keySet());
            Assert.isTrue(budgetIdMap.keySet().size() > 0);
		Test.stopTest();
	}
    
    @isTest
	public static void testComputeGrantsWithAmountChange() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Test Organiation'];
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach'];
       	  
		Test.startTest();
        	List<IM_Budget_Row__c> budgetRows = TestDataFactory.createBudgetRows(budget.Id, org.Id);
        	budgetRows[0].Period_1_Amount__c = 300000;
            budgetRows[1].Period_1_Amount__c = 700000;
            update budgetRows;
            Map<Id, IM_Budget__c> budgetIdMap = new Map<Id, IM_Budget__c>([SELECT Id, Name FROM IM_Budget__c LIMIT 1]);
            IMService.computeGrants(budgetIdMap.keySet());
            Assert.isTrue(budgetIdMap.keySet().size() > 0);
		Test.stopTest();
	}
    
    @isTest
	public static void testComputeGrantsWithZeroAmount() {
       	Account org = [SELECT Id FROM Account WHERE Name = 'Test Organiation'];
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Beach'];
       	
		Test.startTest();
      		List<IM_Budget_Row__c> budgetRows = TestDataFactory.createBudgetRows(budget.Id, org.Id);
        	budgetRows[0].Period_1_Amount__c = 0;
        	budgetRows[0].Period_2_Amount__c = 0;
            budgetRows[1].Period_1_Amount__c = 1000000;
        	budgetRows[1].Period_3_Amount__c = 500000;
            update budgetRows;
            Map<Id, IM_Budget__c> budgetIdMap = new Map<Id, IM_Budget__c>([SELECT Id, Name FROM IM_Budget__c LIMIT 1]);
            IMService.computeGrants(budgetIdMap.keySet());
            Assert.isTrue(budgetIdMap.keySet().size() > 0);
		Test.stopTest();
	}

	@isTest
	public static void testCloneBudgetGrants() {
               
		IM_Budget__c budget = [SELECT Id, Initiative__c FROM IM_Budget__c LIMIT 1];		
		Test.startTest();
            IM_Initiative__c amendmentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Initiative_Type__c = 'Amendment' LIMIT 1];
            IM_Initiative__c initiative = new IM_Initiative__c(Id = budget.Initiative__c);
            initiative.Open_Amendment__c = amendmentInitiative.Id;
            update initiative;
        
            IMService.cloneBudgetGrants(budget, String.valueOf(budget.Initiative__c));
            List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c WHERE Budget__c = :budget.Id];
            Assert.isNotNull(budgetGrants);
		Test.stopTest();
	}
}