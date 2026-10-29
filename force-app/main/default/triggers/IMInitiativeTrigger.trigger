/**
 * Author : Gauri Sagane
 * Date   : 11/13/2024
 * Jira   : IM-41
 * Description : This is a trigger on the Initiaitve object.
 * ChangeLog         :
 * Gauri on 08/18/2025: IM-312: Separated the trigger logic for different Initiative record types
 */

trigger IMInitiativeTrigger on IM_Initiative__c(after update, before update, before insert, after insert, before delete) {
    TriggerFactory.createAndExecuteHandler(IMParentInitiativeHandler.class);
	TriggerFactory.createAndExecuteHandler(IMBudgetedInitiativeHandler.class);
	TriggerFactory.createAndExecuteHandler(IMAmendmentInitiativeHandler.class);
}