trigger PaymentTrigger on Payment__c (before update, before insert) {
    TriggerFactory.createAndExecuteHandler(PaymentTriggerHandler.class);
}