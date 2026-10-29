trigger UserTrigger on User (after update, before update, before insert, after insert, before delete, after delete) {
    TriggerFactory.createAndExecuteHandler(UserTriggerHandler.class);
}