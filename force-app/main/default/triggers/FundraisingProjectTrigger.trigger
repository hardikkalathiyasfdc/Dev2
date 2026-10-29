trigger FundraisingProjectTrigger on Fundraising_Project__c (before insert, after delete, after insert, after update) {
       
    TriggerFactory.createAndExecuteHandler(FundraisingProjectTriggerHandler.class);
}