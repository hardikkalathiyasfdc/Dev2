trigger IMReviewTrigger on IM_Review__c (after update, before update, before insert, after insert, before delete, after delete) {
    TriggerFactory.createAndExecuteHandler(IMReviewTriggerHandler.class);
}