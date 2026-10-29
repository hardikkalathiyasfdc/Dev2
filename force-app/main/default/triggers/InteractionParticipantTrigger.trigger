trigger InteractionParticipantTrigger on Interaction_Participant__c (after insert, after update, before delete) {
    TriggerFactory.createAndExecuteHandler(InteractionParticipantTriggerHandler.class);
}