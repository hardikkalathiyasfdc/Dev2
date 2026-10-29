trigger ElectedOfficeTrigger on ElectedOffice__c(after insert, after update) {
    TriggerFactory.createAndExecuteHandler(ElectedOfficeTriggerHandler.class);
}