/**
 * Author            : Paddy
 * Date              : 12/26/2025
 * Description       : Test class for BatchIMNonBudgetGrantPeriodDeletion
 */
@isTest
public class BatchIMNonBudgetGrantPeriodDeletionTest {
    
    // Store grant ID to avoid querying in test method because of Too Many SOQL error
    private static Id grantId;
    
    @testSetup
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
        
        IM_Grant__c imGrant = TestDataFactory.createIMGrant();
        grantId = imGrant.Id;
    }
        
    @isTest
    static void testExecuteDeletesZeroAmountPeriods() {
        
        Test.startTest();
        
            IM_Initiative__c budgetedInitiative = [
                SELECT Id
                FROM IM_Initiative__c
                WHERE Name = 'Clean Beach 1.0'
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            IM_Budget__c budget = [
                SELECT Id
                FROM IM_Budget__c
                WHERE Initiative__c = :budgetedInitiative.Id
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            List<IM_Initiative__c> initiatives = [
                    SELECT Id, Name
                    FROM IM_Initiative__c
                    WHERE Name = 'Clean Beach Miscellaneous'
                    WITH SYSTEM_MODE
                    LIMIT 1
                ];
            
            // Use stored grant ID from @testSetup to avoid query, fallback to query if needed
            Id imGrantId = grantId;
            if (imGrantId == null) {
                IM_Grant__c imGrant = [SELECT Id FROM IM_Grant__c WITH SYSTEM_MODE LIMIT 1];
                imGrantId = imGrant.Id;
            }
        
            budgetedInitiative.Approved__c = true;
            budgetedInitiative.Status__c = 'Ongoing';
            budgetedInitiative.Current_Budget__c = budget.Id;
            budgetedInitiative.Approved_Date__c = System.today();
            update as system budgetedInitiative;
        
        	IM_Non_Budget_Grant__c nonBudgetGrant = TestDataFactory.createNonBudgetGrant(initiatives[0].Id, imGrantId);
        
            // Create periods with zero amounts (to be deleted)
            List<IM_Non_Budget_Grant_Period__c> periodsToDelete = new List<IM_Non_Budget_Grant_Period__c>();
            for (Integer i = 0; i < 5; i++) {
                periodsToDelete.add(new IM_Non_Budget_Grant_Period__c(
                    Non_Budget_Grant__c = nonBudgetGrant.Id,
                    Total_Paid_Amount_Local__c = 0,
                    Total_Scheduled_Amount_Local__c = 0
                ));
            }
            insert as system periodsToDelete;
        
            // Create periods with non-zero amounts (should not be deleted)
            List<IM_Non_Budget_Grant_Period__c> periodsToKeep = new List<IM_Non_Budget_Grant_Period__c>();
            periodsToKeep.add(new IM_Non_Budget_Grant_Period__c(
                Non_Budget_Grant__c = nonBudgetGrant.Id,
                Total_Paid_Amount_Local__c = 100,
                Total_Scheduled_Amount_Local__c = 0
            ));
            periodsToKeep.add(new IM_Non_Budget_Grant_Period__c(
                Non_Budget_Grant__c = nonBudgetGrant.Id,
                Total_Paid_Amount_Local__c = 0,
                Total_Scheduled_Amount_Local__c = 200
            ));
            insert as system periodsToKeep;
        
            BatchIMNonBudgetGrantPeriodDeletion batch = new BatchIMNonBudgetGrantPeriodDeletion();
            batch.execute(null, periodsToDelete);
        
        Test.stopTest();
        
        // Verify records were deleted - single query to get all periods
        List<IM_Non_Budget_Grant_Period__c> allPeriods = [
            SELECT Id, Total_Paid_Amount_Local__c, Total_Scheduled_Amount_Local__c
            FROM IM_Non_Budget_Grant_Period__c
            WHERE Non_Budget_Grant__c = :nonBudgetGrant.Id
            WITH SYSTEM_MODE
        ];
        
        // Verify zero amount periods were deleted
        List<IM_Non_Budget_Grant_Period__c> remainingZeroPeriods = new List<IM_Non_Budget_Grant_Period__c>();
        List<IM_Non_Budget_Grant_Period__c> keptPeriods = new List<IM_Non_Budget_Grant_Period__c>();
        
        for (IM_Non_Budget_Grant_Period__c period : allPeriods) {
            if (period.Total_Paid_Amount_Local__c == 0 && period.Total_Scheduled_Amount_Local__c == 0) {
                remainingZeroPeriods.add(period);
            } else {
                keptPeriods.add(period);
            }
        }
        
        Assert.areEqual(0, remainingZeroPeriods.size(), 
            'All zero amount periods should be deleted. Remaining: ' + remainingZeroPeriods.size());
        
        // Verify non-zero amount periods are still present
        Assert.areEqual(2, keptPeriods.size(), 
            'Non-zero amount periods should still exist');
        
        // Verify kept periods have at least one non-zero amount
        for (IM_Non_Budget_Grant_Period__c period : keptPeriods) {
            Boolean hasNonZeroAmount = period.Total_Paid_Amount_Local__c != 0 || 
                                     period.Total_Scheduled_Amount_Local__c != 0;
            Assert.isTrue(hasNonZeroAmount, 
                'Kept period should have at least one non-zero amount');
        }
    }
    
    @isTest
    static void testExecuteEmptyList() {
        BatchIMNonBudgetGrantPeriodDeletion batch = new BatchIMNonBudgetGrantPeriodDeletion();
        
        Test.startTest();
        try {
            batch.execute(null, new List<IM_Non_Budget_Grant_Period__c>());
            Assert.isTrue(true, 'Should execute without error for empty list');
        } catch (Exception e) {
            Assert.fail('Should not throw exception for empty list: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteSchedulableContext() {
        BatchIMNonBudgetGrantPeriodDeletion batch = new BatchIMNonBudgetGrantPeriodDeletion();
        
        Test.startTest();
        String cronExp = '0 0 0 * * ?'; // Daily at midnight
        String jobId = System.schedule('Test Batch', cronExp, batch);
        Test.stopTest();
        
        // Verify the scheduled job was created
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
            WITH SYSTEM_MODE
        ];
        
        Assert.isNotNull(ct, 'Scheduled job should be created');
        Assert.areEqual(cronExp, ct.CronExpression, 
            'Cron expression should match');
    }
}