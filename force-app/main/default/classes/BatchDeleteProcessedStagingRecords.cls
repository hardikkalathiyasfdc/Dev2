global class BatchDeleteProcessedStagingRecords implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {
    
    private static final String ERR_EXECUTE = 'BDPSR_EXECUTE_FAILED';

    global void execute(SchedulableContext sc) {
        Database.executeBatch(this,200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator([SELECT Id FROM Staging_Area__c WHERE Processed__c = true ]); 
        }
        return Database.getQueryLocator([SELECT Id FROM Staging_Area__c WHERE Processed__c = true AND CreatedDate < LAST_N_DAYS:30]);
    }

    global void execute(Database.BatchableContext BC, List<Staging_Area__c> scope) {
        BBApps_Crud.doDeleteWithHandling(scope, false, ERR_EXECUTE);
    }

    global void finish(Database.BatchableContext BC) {
        // Add any post-processing logic if needed
    }
}