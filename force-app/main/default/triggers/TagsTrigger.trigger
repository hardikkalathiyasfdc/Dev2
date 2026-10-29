/*
*  test class: TagsCmpControllerTest
*/
trigger TagsTrigger on Tag_Junction__c(
    before insert,
    before update,
    after insert,
    after update, 
    before delete,
    after delete
) {
    TriggerFactory.createAndExecuteHandler(TagsTriggerHandler.class);
}