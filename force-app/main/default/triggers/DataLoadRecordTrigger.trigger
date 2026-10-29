trigger DataLoadRecordTrigger on Data_Load_Record__c ( before update, before insert) {      
    TriggerFactory.createAndExecuteHandler(DataLoadRecordTriggerHandler.class);
}