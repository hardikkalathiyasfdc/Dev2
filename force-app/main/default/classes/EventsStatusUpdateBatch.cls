global without sharing class EventsStatusUpdateBatch implements Database.Batchable<sObject>, Schedulable {

    public final static String EVENT_RECORD_TYPE_ID = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
    public String query;
    private static final String ERR_CLASS_FAILED = 'EventsStatusUpdateBatch_CLASS_FAILED';
    private static final String ERR_DML_UPDATE = 'EventsStatusUpdateBatch_UPDATE_FAILED';

    global EventsStatusUpdateBatch() {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Campaign> scope) {
        try {
            for(Campaign cm: scope) {
                if(cm.End_Date_Time__c < Datetime.now()) {
                    cm.EventStatus__c = 'Complete';
                }
            }
            BBApps_Crud.doUpdateWithHandling(scope, false, new BBApps_ErrorCustomFields(ERR_DML_UPDATE));
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    global void finish(Database.BatchableContext BC) {}

    global void execute(System.SchedulableContext something) {
        String query = 'SELECT End_Date_Time__c, Id, EventStatus__c FROM Campaign WHERE EventStatus__c = \'Upcoming\' AND RecordTypeId = \''+EVENT_RECORD_TYPE_ID+'\'';
        EventsStatusUpdateBatch batch = new EventsStatusUpdateBatch();
        batch.query = query;
        Database.executeBatch(batch, 400);
    }
}