/**
* Author            : Paddy
* Date              : 05/22/2025
* Jira              : IM-203
* Description       : Test class for IMBudgetOrgTriggerHandler.
*/

@isTest
public with sharing class IMBudgetOrgTriggerHandlerTest {
    
    @TestSetup
    static void setup() {
        TestDataFactory.createInitiativeBaseData();
        
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
        Account testAcct = TestDataFactory.createOrg('Test Account');
    }

    @isTest
    public static void testExternalId() {
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        Account testAcct = [SELECT Id FROM Account WHERE Name = 'Test Account' WITH SYSTEM_MODE];

        Test.startTest();
            IM_Budget_Org__c budgetOrg = new IM_Budget_Org__c(Budget__c = budget.Id, Organization__c = testAcct.Id, Type__c = 'Partner');
            insert as system budgetOrg;

            IM_Budget_Org__c insertedBudgetOrg = [SELECT External_Id__c FROM IM_Budget_Org__c WHERE Id = :budgetOrg.Id WITH SYSTEM_MODE];
            Assert.areEqual(budgetOrg.Budget__c + budgetOrg.Type__c + budgetOrg.Organization__c, insertedBudgetOrg.External_Id__c);
        Test.stopTest();
    }

    @isTest
    public static void testExternalIdforUpdate() {
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        Account testAcct = [SELECT Id FROM Account WHERE Name = 'Test Account' WITH SYSTEM_MODE];
        IM_Budget_Org__c budgetOrg = new IM_Budget_Org__c(Budget__c = budget.Id, Organization__c = testAcct.Id, Type__c = 'Partner');
        
        insert as system budgetOrg;

        Test.startTest();
            budgetOrg.Type__c = 'SubPartner';
            update as system budgetOrg;

            IM_Budget_Org__c updatedBudgetOrg = [SELECT External_Id__c FROM IM_Budget_Org__c WHERE Id = :budgetOrg.Id WITH SYSTEM_MODE];
            Assert.areEqual(budgetOrg.Budget__c + budgetOrg.Type__c + budgetOrg.Organization__c, updatedBudgetOrg.External_Id__c);
        Test.stopTest();
    }
}