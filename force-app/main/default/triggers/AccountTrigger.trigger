//jlu scan for special characters in names added all conditions for triggers
trigger AccountTrigger on Account (after update, before update, before insert, after insert, before delete, after delete) {
    TriggerFactory.createAndExecuteHandler(AccountTriggerHandler.class);
}