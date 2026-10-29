trigger FoundationCodeTrigger on Foundation_Code__c (after update, before update, before insert, after insert) {
    TriggerFactory.createAndExecuteHandler(FoundationCodeHandler.class);
}