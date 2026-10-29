trigger DonorTrigger on Donor__c (after update, before update, before insert, after insert, before delete, after delete) {
   
    TriggerFactory.createAndExecuteHandler(DonorTriggerHandler.class);
}