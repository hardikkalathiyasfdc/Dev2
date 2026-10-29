/**
* Author      : Ravi
* Date        : 09/09/2026
* Jira        : BRME-6951
* Description : Trigger for Metric_Value__c object.
*/
trigger MetricValueTrigger on Metric_Value__c (after insert, after update) {
	TriggerFactory.createAndExecuteHandler(MetricValueTriggerHandler.class); 
}