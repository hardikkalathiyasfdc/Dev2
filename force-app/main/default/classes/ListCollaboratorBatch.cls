global class ListCollaboratorBatch implements Database.Batchable<sObject> {

    private static final String ERR_DELETE_COLLABORATORS = 'DELETE_ListCollaboratorBatch_FAILED';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Integer threshold = Integer.valueOf(Application_Properties__mdt.getInstance('List_Collaborator_Batch_Threshold_Days').Value__c);
        DateTime thresholdDate = System.now().addDays(-threshold);

        return Database.getQueryLocator([
            SELECT Id 
            FROM Collaborator__c 
            WHERE List__r.End_Date_Time__c < :thresholdDate
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Collaborator__c> collaboratorList) {
        BBApps_Crud.doDeleteWithHandling(collaboratorList, false, new BBApps_ErrorCustomFields(ERR_DELETE_COLLABORATORS));
    }

    global void finish(Database.BatchableContext BC) {}
}