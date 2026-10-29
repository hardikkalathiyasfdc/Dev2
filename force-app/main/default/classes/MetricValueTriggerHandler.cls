/**
* Author      : Ravi
* Date        : 09/09/2026
* Jira        : BRME-6951
* Description : This class is the handler class for MetricValueTrigger.
* Test        : MetricValueTriggerHandlerTest
*/
public without sharing class MetricValueTriggerHandler extends TriggerHandler {
	public List<Metric_Value__c> newMetricValues;
    public List<Metric_Value__c> oldMetricValues; 
    public Map<Id, Metric_Value__c> newMap;
    public Map<Id, Metric_Value__c> oldMap;
    public Boolean isUpdateTrigger;
    public Boolean isInsertTrigger;
    public Boolean isDeleteTrigger;
    public Boolean isAfterTrigger;
    private static final String ERR_BULK_AFTER= 'METRIC_VALUE_TRIGGER_HANDLER_BULK_AFTER_FAILED';
    
    public MetricValueTriggerHandler() {
        newMetricValues = Trigger.new;
        oldMetricValues = Trigger.old;
        newMap = (Map<Id, Metric_Value__c>) Trigger.newMap;
        oldMap = (Map<Id, Metric_Value__c>) Trigger.oldMap;
        isUpdateTrigger = Trigger.isUpdate;
        isInsertTrigger = Trigger.isInsert;
        isAfterTrigger = Trigger.isAfter;
        isDeleteTrigger = Trigger.isDelete;
    }
    
    public override void bulkAfter() {
        try{
            if(!isDeleteTrigger) {
                FieldHistoryService.track(oldMap, newMap);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_BULK_AFTER) );
        }
    }
}