/**
* Author            : Paddy
* Date              : 05/22/2025
* Jira              : IM-203
* Description       : Test class for IMBudgetHelper.
*/

@isTest
public with sharing class IMBudgetHelperTest {
    
    @TestSetup
    static void setup() {
        //Bypass Automation
		Bypass_Automation_Setting__c bypassSetting = new Bypass_Automation_Setting__c();
		bypassSetting.IM_Initiative_Validation__c = true;
		bypassSetting.IM_Initiative_Trigger__c = true;
        bypassSetting.IM_Budget_Validation__c = true;
		insert as system  bypassSetting;
        
        TestDataFactory.createInitiativeBaseData();
        
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
        IM_Budget__c newBudget = TestDataFactory.createBudget('Clean Air 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');

        Account testAcc = TestDataFactory.createOrg('test');

        IM_Budget_Org__c budgetOrg = TestDataFactory.createBudgetOrg(budget.Id, testAcc.Id);
        IM_Grant__c imGrant = TestDataFactory.createIMGrant();
        IM_Budget_Grant__c budgetGrant = TestDataFactory.createBudgetGrant(budget.Id, budgetOrg.Id, imGrant.Id);
        IM_Budget_Grant__c newBudgetGrant = TestDataFactory.createBudgetGrant(newBudget.Id, budgetOrg.Id, imGrant.Id);
       
        budgetedInitiative.Current_Budget__c = budget.Id;
        update as system budgetedInitiative;
    }

    @isTest
    public static void testUpdateActiveStatus() {

        IM_Initiative__c initiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air 1.0' WITH SYSTEM_MODE];
        IM_Budget__c oldBudget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        IM_Budget__c newBudget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air 1.0' WITH SYSTEM_MODE];

        Test.startTest();
            newBudget.Status__c = 'Pending Approval';
            update as system newBudget;
            initiative.Current_Budget__c = newBudget.Id;
            update as system initiative;

            IM_Budget__c oldUpdatedBudget = [SELECT Is_Active__c FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
            IM_Budget__c newUpdatedBudget = [SELECT Is_Active__c FROM IM_Budget__c WHERE Name = 'Clean Air 1.0' WITH SYSTEM_MODE];

            IM_Budget_Grant__c oldBudgetGrant = [SELECT Is_Active__c FROM IM_Budget_Grant__c WHERE Budget__c = :oldBudget.Id WITH SYSTEM_MODE];
            IM_Budget_Grant__c newBudgetGrant = [SELECT Is_Active__c FROM IM_Budget_Grant__c WHERE Budget__c = :newBudget.Id WITH SYSTEM_MODE];
            
            Assert.isFalse(oldUpdatedBudget.Is_Active__c);
            Assert.isFalse(oldBudgetGrant.Is_Active__c);
        Test.stopTest();
    }
}