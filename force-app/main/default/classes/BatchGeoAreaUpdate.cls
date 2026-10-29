global without sharing class BatchGeoAreaUpdate implements Database.Batchable<sObject>  {
    private static final String ERR_START   = 'BGAU_START_FAILED';
    private static final String ERR_EXECUTE = 'BGAU_EXECUTE_FAILED';
    BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_START);

    private Set<Id> gaSet;
    private Set<Id> stateCitySet;
    
    global BatchGeoAreaUpdate(Set<Id> gaSet){
        this.gaSet = gaSet;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            string query='Select Id from Geo_Area__c where Parent__c IN :gaSet OR Parent__r.Parent__c IN :gaSet';
            System.debug('Query is - ' + query);
            return Database.getQueryLocator(query);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, f);
            return null;
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Geo_Area__c> scope) {
        BBApps_Crud.doUpdateWithHandling(scope, false, ERR_EXECUTE);
    }
    
    global void finish(Database.BatchableContext BC) {
    }    
}