/**
* Author      : Sai Bhargav Thotakura
* Date        : 04/25/2025
* Jira        : IM-168
*/
trigger IMGrantTrigger on IM_Grant__c (after update, before delete) {
    TriggerFactory.createAndExecuteHandler(IMGrantTriggerHandler.class);
}