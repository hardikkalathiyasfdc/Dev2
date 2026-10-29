trigger InteractionTrigger on Interaction__c (before insert, before update, after insert, after update, after delete) {

    TriggerFactory.createAndExecuteHandler(InteractionTriggerHandler.class);
    
}