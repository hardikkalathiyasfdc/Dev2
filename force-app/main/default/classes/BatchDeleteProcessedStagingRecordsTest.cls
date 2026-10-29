@isTest
private class BatchDeleteProcessedStagingRecordsTest {
    @isTest
    static void testBatchJob() {
        // Create test data
        List<Staging_Area__c> stagingRecords = new List<Staging_Area__c>();
        for(Integer i = 0; i < 200; i++) { // Create more records than the batch size (200)
            stagingRecords.add(new Staging_Area__c(Processed__c = true));
        }
        insert stagingRecords;

        // Start the batch job
        Test.startTest();
        BatchDeleteProcessedStagingRecords batchJob = new BatchDeleteProcessedStagingRecords();
        Database.executeBatch(batchJob);
        Test.stopTest();

        // Verify that all processed staging records have been deleted
        Integer remainingRecords = [SELECT COUNT() FROM Staging_Area__c WHERE Processed__c = true with SYSTEM_MODE];
        System.assertEquals(0, remainingRecords, 'All processed staging records should have been deleted');
    }
        @isTest
    static void testScheduledBatchJob() {
        // Create test data
        List<Staging_Area__c> stagingRecords = new List<Staging_Area__c>();
        for(Integer i = 0; i < 200; i++) { // Create more records than the batch size (200)
            stagingRecords.add(new Staging_Area__c(Processed__c = true));
        }
        insert stagingRecords;

        // Start the batch job
        Test.startTest();
	Integer addTime = Integer.valueOf(1);
		DateTime now =  System.now().addMinutes(addTime);
		String day = string.valueOf(now.day());
		String month = string.valueOf(now.month());
		String hour = string.valueOf(now.hour());
		String minute = string.valueOf(now.minute());
		String second = string.valueOf(now.second());
		String year = string.valueOf(now.year());

		String strJobName = 'StageProcessBatch Job : ' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
		String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;

		System.schedule(strJobName, strSchedule, new BatchDeleteProcessedStagingRecords());

        Test.stopTest();


    }
}