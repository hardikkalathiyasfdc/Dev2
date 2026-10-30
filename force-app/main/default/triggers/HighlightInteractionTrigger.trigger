trigger HighlightInteractionTrigger on Highlight_Interaction__c (after insert, before update, after update, after delete) {
    TriggerFactory.createAndExecuteHandler(HighlightInteractionTriggerHandler.class);
}