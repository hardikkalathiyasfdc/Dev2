/**
 * Author            : Gauri Sagane
 * Date              : 12/19/2025
 * Description       : Test class for BatchIMNonBudgetGrantDeletion
 */
@isTest
public with sharing class BatchIMNonBudgetGrantDeletionTest {
    private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
        .get(Assets.PARENT_INITIATIVE).getRecordTypeId();

    @TestSetup
    static void setup() {
        Account org = TestDataFactory.createOrg('Test org');

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
    public static void testDeleteNonBudgetGrants() {
        Test.startTest();
            List<IM_Initiative__c> parentInitiative = [
                SELECT Id
                FROM IM_Initiative__c
                WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
                WITH SYSTEM_MODE
                LIMIT 1
            ];

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

            initiative.Approved__c = true;
            initiative.Parent_Initiative__c = parentInitiative[0].Id;
            initiative.Status__c = 'Ongoing';
            initiative.Current_Budget__c = budget[0].Id;
            initiative.Approved_Date__c = System.today();
            update as system initiative;

            List<IM_Initiative__c> initiatives = [
                SELECT Id, Name
                FROM IM_Initiative__c
                WHERE Name = 'Clean Beach Miscellaneous'
                WITH SYSTEM_MODE
                LIMIT 1
            ];

            List<IM_Grant__c> imGrants = [SELECT Id, Deleted__c FROM IM_Grant__c WITH SYSTEM_MODE LIMIT 1];
            IM_Non_Budget_Grant__c nonBg = TestDataFactory.createNonBudgetGrant(initiatives[0].Id, imGrants[0].Id);

            BatchIMNonBudgetGrantDeletion batchGrantDeletion = new BatchIMNonBudgetGrantDeletion();
            new BatchIMNonBudgetGrantDeletion().execute(null);
        Test.stopTest();

        List<IM_Non_Budget_Grant__c> nonBudgetGrantsDeleted = [
            SELECT Id
            FROM IM_Non_Budget_Grant__c
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        Assert.areEqual(true, nonBudgetGrantsDeleted.isEmpty());
    }
}