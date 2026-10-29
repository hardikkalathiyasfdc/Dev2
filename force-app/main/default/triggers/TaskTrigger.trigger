trigger TaskTrigger on Task (before insert, before update, after insert, after update, before delete, after delete) {
    if(TaskTriggerHandler.isFirstTime) {
        TriggerFactory.createAndExecuteHandler(TaskTriggerHandler.class);
    }
}