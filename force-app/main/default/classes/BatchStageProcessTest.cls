@isTest
private class BatchStageProcessTest {
    @isTest
    static void BatchExecution_Test() {
        // Create test data
        List<Staging_Area__c> testRecords = new List<Staging_Area__c>();
        for (Integer i = 0; i < 5; i++) {
            testRecords.add(new Staging_Area__c(
                Email_Subject__c = 'Test Subject ' + i,
                Email_Reply_To__c = 'test@example.com',
                Email_Body__c = 'Test Email Body ' + i,
                Processed__c = false
            ));
        }
        insert testRecords;

        // Start the batch job
        Test.startTest();
        BatchStageProcess batchJob = new BatchStageProcess();
        Database.executeBatch(batchJob);
        Test.stopTest();

        // Verify that records have been processed
        List<Staging_Area__c> processedRecords = [SELECT Id, Processed__c FROM Staging_Area__c WHERE Processed__c = true with SYSTEM_MODE];
        System.assertEquals(testRecords.size(), processedRecords.size(), 'All records should be processed');
    }

    @isTest
    static void errorHandling_Test () {
        Integer addTime = Integer.valueOf(5);
		DateTime now =  System.now().addMinutes(addTime);
		String day = string.valueOf(now.day());
		String month = string.valueOf(now.month());
		String hour = string.valueOf(now.hour());
		String minute = string.valueOf(now.minute());
		String second = string.valueOf(now.second());
		String year = string.valueOf(now.year());

		String strJobName = 'StageProcessBatch Job : ' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
		String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.schedule(strJobName, strSchedule, new BatchStageProcess());
    }
}