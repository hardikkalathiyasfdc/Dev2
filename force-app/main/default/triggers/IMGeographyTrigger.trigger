/**
* Author : Paddy
* Date   : 03/17/2025
* Jira   : IM-124
* Description : This is a trigger on the IM_Geography__c object.
*/
trigger IMGeographyTrigger on IM_Geography__c (before insert, before update) {
    TriggerFactory.createAndExecuteHandler(IMGeographyTriggerHandler.class);
}