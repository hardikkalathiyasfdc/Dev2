@isTest
public with sharing class BatchIMBudgetOrgDeletionTest {
    @TestSetup
    static void setup() {
        Account org = TestDataFactory.createOrg('Test org');
        Account newOrg = TestDataFactory.createOrg('Test New org');

        TestDataFactory.createInitiativeBaseData();
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
        IM_Component__c component = TestDataFactory.createComponent(budget.Id);
        IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
        IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
        IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
        IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, partner.Id, geography.Id);
        IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
        Currency__c usdCurrency = TestDataFactory.createCurrency('USD');
        Fund__c fund = TestDataFactory.createFund('Personal');
    }

    @isTest
    public static void testDeleteBudgetOrgs() {
        Test.startTest();
        IM_Initiative__c initiative = [
            SELECT Id
            FROM IM_Initiative__c
            WHERE Name = 'Clean Beach 1.0'
            WITH SYSTEM_MODE
            LIMIT 1
            ];
        List<IM_Budget__c> budget = [
            SELECT Id
            FROM IM_Budget__c
            WHERE Initiative__c = :initiative.Id
            WITH SYSTEM_MODE
            ];

        List<IM_Budget_Org__c> budgetOrgs = [
            SELECT Id, Deleted__c
            FROM IM_Budget_Org__c
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        budgetOrgs[0].Deleted__c = true;
        update as system budgetOrgs;

        new BatchIMBudgetOrgDeletion().execute(null);
        Test.stopTest();
        List<IM_Budget_Org__c> budgetOrgsDeleted = [
        SELECT Id
        FROM IM_Budget_Org__c
        WITH SYSTEM_MODE
        LIMIT 1
        ];
        Assert.areEqual(true, budgetOrgsDeleted.isEmpty());
    }
}