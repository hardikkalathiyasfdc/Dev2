trigger RecipientOrganizationTrigger on Recipient_Organization__c (after update, before update, before insert, after insert, before delete, after delete, after undelete) {
    TriggerFactory.createAndExecuteHandler(RecipientOrganizationTriggerHandler.class);
}