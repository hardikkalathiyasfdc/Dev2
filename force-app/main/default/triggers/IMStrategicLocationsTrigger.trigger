/**
 * Author : Gauri Sagane
 * Date   : 11/13/2024
 * Jira   : IM-87
 * Description : This is a trigger on the Strategic Locations object.
 */

trigger IMStrategicLocationsTrigger on IM_Strategic_Locations__c(before insert, after insert, after update, after delete) {
    TriggerFactory.createAndExecuteHandler(IMStrategicLocationsTriggerHandler.class);
}