/**
@Description: The batch is used daily to check Term End date, if the Term End date is reached, then 
the Elected Officed record should be inactive
@Author: Bloomberg
@Date: 12/07/2020
**/
global without sharing class InactiveElectedStatusBatch implements Database.Batchable<sObject> {

    public String query;
    private static final String ERR_UPDATE_FAILED = 'InactiveElectedStatusBatch_UPDATE_FAILED';
    private static final String ERR_CLASS_FAILED = 'InactiveElectedStatusBatch_CLASS_FAILED';

    public InactiveElectedStatusBatch(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query); 
    }

    global void execute(Database.BatchableContext BC, list<ElectedOffice__c> scope) {
        try {
            for(ElectedOffice__c eo : scope) {
                eo.ElectedStatus__c = 'Inactive';
            }
            BBApps_Crud.doUpdateWithHandling(scope, false, ERR_UPDATE_FAILED);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    global void finish(Database.BatchableContext BC) {}
}