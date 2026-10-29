@isTest
private class DeleteOldDataLoadsBatchTest {

    @testSetup
    static void setupData() {
        List<Data_Load__c> loads = new List<Data_Load__c>();
        loads.add(new Data_Load__c(Name__c = 'Old Load 1'));
        loads.add(new Data_Load__c(Name__c = 'Old Load 2'));
        loads.add(new Data_Load__c(Name__c = 'Recent Load 1'));
        insert loads;
        Test.setCreatedDate(loads[0].Id, System.now().addDays(-31));
        Test.setCreatedDate(loads[1].Id, System.now().addDays(-45));
        Test.setCreatedDate(loads[2].Id, System.now().addDays(-10));
    }

    @isTest
    static void testBatchDeletesOnlyOldRecords() {
        Integer beforeCount = [SELECT Count() FROM Data_Load__c];
        System.assertEquals(3, beforeCount, 'Expected seeded test records.');
        Test.startTest();
        Database.executeBatch(new DeleteOldDataLoadsBatch(), 200);
        Test.stopTest();
        List<Data_Load__c> remaining = [SELECT Id FROM Data_Load__c];
        System.assertEquals(1, remaining.size());
    }

    @isTest
    static void testSchedulerRunsBatch() {
        Test.startTest();
        String jobId = System.schedule(
            'DeleteOldDataLoadsBatchScheduler_Test',
            '0 0 2 * * ?',
            new DeleteOldDataLoadsBatchScheduler()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}