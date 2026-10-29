global without sharing class BatchToUpdatePayamentsStatus implements Database.Batchable<sObject>, Schedulable  {
    private static final String ERR_BATCH_JOB_FAILED   = 'BATCH_UPDATE_PAYMENTS_STATUS_FAILED';
    private static final String ERR_UPDATE_FAILED      = 'BATCH_UPDATE_PAYMENTS_STATUS_UPDATE_FAILED';

    private static final String MSG_BATCH_JOB_FAILED   = 'BatchToUpdatePayamentsStatus job failed.';
    private static final String MSG_UPDATE_FAILED      = 'Failed while updating Payment status.';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        try { 
            string query='select id,name,Status__c,Scheduled_Date__c from Payment__c where Scheduled_Date__c <TODAY and Status__c =\'Scheduled\'';
            return Database.getQueryLocator(query);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
            return Database.getQueryLocator('SELECT Id FROM Payment__c WHERE Id = null');
        }
    }
    
    global void execute(Database.BatchableContext BC, list<Payment__c> scope) {
        try {
            List<Payment__c> finalList = new List<Payment__c>();
            if(scope.size()>0){
                for(Payment__c eachPayment:scope){ 
                    eachPayment.Status__c='Past Due';  
                    finalList.add(eachPayment);
                }
            }
            if(finalList.size()>0){
                BBApps_Crud.doUpdateWithHandling(finalList, false, ERR_UPDATE_FAILED);
            }  
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
    global void execute(SchedulableContext sc ) {
        BatchToUpdatePayamentsStatus batch = new BatchToUpdatePayamentsStatus();
        Database.executeBatch(batch);
    }
}