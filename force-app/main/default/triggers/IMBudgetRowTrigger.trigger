/**
* Author : Gauri Sagane
* Date   : 02/21/2025
* Jira   : IM-113
* Description : This is a trigger on the Budget Rows object.
*/

trigger IMBudgetRowTrigger on IM_Budget_Row__c (before insert, after insert, before update, after update, after delete) {
    TriggerFactory.createAndExecuteHandler(IMBudgetRowTriggerHandler.class);
}