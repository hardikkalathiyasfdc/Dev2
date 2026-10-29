/**
* Author      : Paddy
* Date        : 12/03/2024
* Jira        : IM-65
* Description : Trigger for IM_Budget__c.
* Modified By : 
* Test        : BudgetTriggerHandlerTest
*/
trigger IMBudgetTrigger on IM_Budget__c (before insert, after insert, before update, after update,before delete) {
    TriggerFactory.createAndExecuteHandler(IMBudgetTriggerHandler.class);
}