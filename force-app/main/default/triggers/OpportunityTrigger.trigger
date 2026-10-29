trigger OpportunityTrigger on Opportunity (after update, before update, before insert, after insert, before delete, after delete) {
    TriggerFactory.createAndExecuteHandler(OpportunityTriggerHandler.class);
}