@isTest
public with sharing class IMBudgetPeriodControllerTest {
    @testSetup static void setup() {
        TestDataFactory.createInitiativeBaseData();
        
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
        
        IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
    }

    @isTest
    public static void testGetBudgetPeriods() {
        IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        List<IM_Budget_Period__c> budetPeriods = [SELECT Id, Name, Period_Label__c
                                                  FROM IM_Budget_Period__c
                                                  WHERE Budget__c = :budget.Id
                                                  WITH SYSTEM_MODE];
        Test.startTest();
            List<IM_Budget_Period__c> periodList = IMBudgetPeriodController.getBudgetPeriods(String.valueOf(budget.Id));
        Test.stopTest();
        Assert.areEqual(budetPeriods.size(), periodList.size());
    }

    @isTest
    public static void testUpdateBudgetPeriods() {
        IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        List<IM_Budget_Period__c> budetPeriods = [SELECT Id, Name, Period_Label__c
                                                  FROM IM_Budget_Period__c
                                                  WHERE Budget__c = :budget.Id
                                                  WITH SYSTEM_MODE];
        for(IM_Budget_Period__c bp: budetPeriods){
            bp.Period_Label__c = 'Test';
        }
        Test.startTest();
            IMBudgetPeriodController.updateBudgetPeriods(budetPeriods);
        Test.stopTest();
        List<IM_Budget_Period__c> updatedPeriods = [SELECT Id, Name, Period_Label__c
                                                    FROM IM_Budget_Period__c
                                                    WHERE Budget__c = :budget.Id
                                                    WITH SYSTEM_MODE];
        Assert.areEqual('Test', updatedPeriods[0].Period_Label__c);
    }

    @isTest
    public static void testUpdateBudgetPeriodsException() {
        IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        List<IM_Budget_Period__c> budetPeriods = [SELECT Id, Name, Period_Label__c
                                                  FROM IM_Budget_Period__c
                                                  WHERE Budget__c = :budget.Id
                                                  WITH SYSTEM_MODE];
        for(IM_Budget_Period__c bp: budetPeriods){
            bp.Period_Label__c = 'Test';
        }
        Test.startTest();
        	try {
            	IMBudgetPeriodController.updateBudgetPeriods(null);
            } catch (Exception e) {
				Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
			}
        Test.stopTest();
    }
}