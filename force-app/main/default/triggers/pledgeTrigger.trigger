trigger pledgeTrigger on Pledge__c (after update, before update, before insert, after insert, before delete, after delete) {
   
    TriggerFactory.createAndExecuteHandler(pledgeTriggerHandler.class);
    
}