/********************************************************************************
* Trigger Name : RelatedContactTrigger
* Object       : Related_Contact__c
* Description  :
* This trigger routes Related_Contact__c DML events to the corresponding trigger
* handler (RelatedContactTriggerHandler) using the TriggerFactory / TriggerHandler
* framework.
********************************************************************************/
trigger RelatedContactTrigger on Related_Contact__c (
    before insert,
    before update,
    after insert,
    after update,
    after delete
) {
    TriggerFactory.createAndExecuteHandler(RelatedContactTriggerHandler.class);
}