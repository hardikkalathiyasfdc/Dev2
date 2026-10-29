/**
* Author : Paddy
* Date   : 03/17/2025
* Jira   : IM-124
* Description : This is a trigger on the IM_Component object.
*/
trigger IMComponentTrigger on IM_Component__c (before insert, after insert, before update, after update) {
    TriggerFactory.createAndExecuteHandler(IMComponentTriggerHandler.class);
}