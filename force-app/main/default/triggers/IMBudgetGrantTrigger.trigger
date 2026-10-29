/**
* Author : Paddy
* Date   : 04/14/2025
* Jira   : IM-148
* Description : This is a trigger on the IM_Budget_Grant__c object.
*/
trigger IMBudgetGrantTrigger on IM_Budget_Grant__c (before insert, before delete) {
    TriggerFactory.createAndExecuteHandler(IMBudgetGrantTriggerHandler.class);
}