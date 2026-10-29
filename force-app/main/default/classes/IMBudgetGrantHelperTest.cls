/**
* Author      : Paddy
* Date        : 5/19/2025
* Jira        : IM-203
* Description : Test class for IMBudgetGrantHelper.
* ChangeLog   :  
*/
@isTest
public with sharing class IMBudgetGrantHelperTest {
    
    @TestSetup
    static void setup() {
        TestDataFactory.createInitiativeBaseData();
        
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');

        Account testAcc = TestDataFactory.createOrg('test');
        
        IM_Budget_Row__c budRow = TestDataFactory.createBudgetRow(budget.Id);
        IM_Budget_Org__c budgetOrg = TestDataFactory.createBudgetOrg(budget.Id, testAcc.Id);
        IM_Grant__c imGrant = TestDataFactory.createIMGrant();
        IM_Budget_Grant__c budgetGrant = TestDataFactory.createBudgetGrant(budget.Id, budgetOrg.Id, imGrant.Id);
    }

    @isTest
    public static void testGetBudgetGrants() {
        IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        List<IM_Budget_Row__c> budgetRows = [SELECT Id, Budget__c, Partner__c, Unique_Identifier__c, Total_Amount__c, Partner__r.Organization__c FROM IM_Budget_Row__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
        List<IM_Budget_Org__c> budgetOrgs = [SELECT Id FROM IM_Budget_Org__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
        Map<String, IM_Budget_Grant__c> existingBudgetGrantMap = IMBudgetGrantHelper.getExistingBudgetGrants(new Set<Id>{budget.Id});
        Map<String, IM_Grant__c> imGrants = new Map<String, IM_Grant__c>();
        Map<String, IM_Budget_Grant__c> grantsToUpdate = new Map<String, IM_Budget_Grant__c>();

        Test.startTest();
            Map<String, IM_Budget_Grant__c> budgetGrants = IMBudgetGrantHelper.getBudgetGrants(budgetRows, existingBudgetGrantMap, imGrants, grantsToUpdate);
            Assert.areEqual(budgetGrants.size(), existingBudgetGrantMap.size());
        Test.stopTest();
    }

    @isTest
    public static void testGetExistingBudgetGrants() {
        IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];

        Test.startTest();
            Map<String, IM_Budget_Grant__c> existingBudgetGrants = IMBudgetGrantHelper.getExistingBudgetGrants(new Set<Id>{budget.Id});
            Assert.areEqual(budgetGrants.size(), existingBudgetGrants.size());
        Test.stopTest();
    }

    @isTest
    public static void testFormatUniqueKey() {
        IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
        IM_Budget_Grant__c budgetGrant = [SELECT Id, Budget__c, Budget_Org__c, Unique_Identifier__c 
            FROM IM_Budget_Grant__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE LIMIT 1];
        String uniqueIdentifier = budgetGrant.Unique_Identifier__c == null ? '' : budgetGrant.Unique_Identifier__c;
        String key = String.valueOf(budgetGrant.Budget__c) + budgetGrant.Budget_Org__c + uniqueIdentifier;
        Test.startTest();
            String uniqueKey = IMBudgetGrantHelper.formatUniqueKey(budgetGrant.Budget__c, budgetGrant.Budget_Org__c, budgetGrant.Unique_Identifier__c);
            Assert.areEqual(key, uniqueKey);
        Test.stopTest();
    }
}