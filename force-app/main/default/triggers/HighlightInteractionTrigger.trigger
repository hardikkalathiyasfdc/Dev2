trigger HighlightInteractionTrigger on Highlight_Interaction__c (after insert, before update, after update) {
    TriggerFactory.createAndExecuteHandler(HighlightInteractionTriggerHandler.class);
}