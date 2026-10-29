global class DeleteOldDataLoadsBatch implements Database.Batchable<SObject> {

    private static final String ERR_DELETE_FAILED = 'DeleteOldDataLoadsBatch_DELETE_FAILED';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Data_Load__c
            WHERE CreatedDate < LAST_N_DAYS:30
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Data_Load__c> scope) {
        BBApps_Crud.doDeleteWithHandling(scope, false, ERR_DELETE_FAILED);
    }

    global void finish(Database.BatchableContext bc) {}
}