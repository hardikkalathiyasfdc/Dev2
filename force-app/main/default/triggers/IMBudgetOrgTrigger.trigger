/**
* Author : Paddy
* Date   : 03/17/2025
* Jira   : IM-124
* Description : This is a trigger on the IM_Budget_Org__c object.
*/
trigger IMBudgetOrgTrigger on IM_Budget_Org__c (before insert, before update) {
    TriggerFactory.createAndExecuteHandler(IMBudgetOrgTriggerHandler.class);
}