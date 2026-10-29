/**
* FieldHistoryService
* 
* This service class tracks changes to specified fields on sObjects based on configuration
* defined in the History_Setting__mdt custom metadata type. It compares old and new values
* during insert and update operations and logs history records in the Custom_History__c object.
* 
* Author : Ravi Bheemreddy
* Jira   : BRME-5387
* Test   : FieldHistoryServiceTest
*/
public without sharing class FieldHistoryService { 
    
    private static final String ERR_TRACK = 'FIELD_HISTORY_SERVICE_TRACK_FAILED';
    private static final String ERR_PROCESS_FIELDS_TO_TRACK = 'FIELD_HISTORY_SERVICE_PROCESS_FIELDS_TO_TRACK_FAILED';

    @TestVisible
    private static List<History_Setting__mdt> testFieldsToTrackOverride;
    
    public static void track(Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        try{
            if (newMap == null || newMap.isEmpty()) {
                return;
            }
            
            String objectType = newMap.values().get(0).getSObjectType().getDescribe().getName();
            List<History_Setting__mdt> fieldsToTrack = getFieldsToTrack(objectType);
            
            if (fieldsToTrack.isEmpty()) {
                return;
            }
            
            List<Custom_History__c> historyRecords = new List<Custom_History__c>();
            
            for (Id recordId : newMap.keySet()) {
                sObject oldRecord = (oldMap != null && oldMap.containsKey(recordId)) ? oldMap.get(recordId) : null;
                sObject newRecord = newMap.get(recordId);
                
                processFieldsToTrack(oldRecord, newRecord, fieldsToTrack, historyRecords, objectType);
            }
            
            if (!historyRecords.isEmpty()) {
                insert historyRecords;
                System.enqueueJob(new CustomHistoryRecordUpdatesQueueable(historyRecords));
            }
            
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_TRACK)); 
        } 
    }
    
    private static void processFieldsToTrack(sObject oldRecord, sObject newRecord, List<History_Setting__mdt> fieldsToTrack, List<Custom_History__c> historyRecords, String objectType) {
        try{
            if (newRecord == null) {
                return;
            }

            Map<String, Schema.SObjectField> fieldMap = newRecord.getSObjectType().getDescribe().fields.getMap();

            for (History_Setting__mdt setting : fieldsToTrack) {
                if (setting == null || String.isBlank(setting.Field__c)) {
                    continue;
                }

                Schema.SObjectField fieldToken = fieldMap.get(setting.Field__c);
                if (fieldToken == null) {
                    continue;
                }

                Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                if (fieldDescribe == null || !fieldDescribe.isAccessible()) {
                    continue;
                }

                String field = setting.Field__c;
                Object oldValue = (oldRecord != null) ? oldRecord.get(field) : null;
                Object newValue = newRecord.get(field);
                
                if ((oldValue == null && newValue != null) || (oldValue != null && !oldValue.equals(newValue))) {
                    String oldValString = formatHistoryValue(oldValue);
                    String newValString = formatHistoryValue(newValue);
                    
                    Custom_History__c historyRecord = createHistoryRecord(objectType, newRecord.Id, field, oldValString, newValString);
                    historyRecords.add(historyRecord);
                }
            }
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_PROCESS_FIELDS_TO_TRACK)); 
        } 
    }
    
    private static Custom_History__c createHistoryRecord(String objectType, Id recordId, String field, String oldValue, String newValue) {
        Custom_History__c historyRecord = new Custom_History__c();
        historyRecord.Object_API_Name__c = objectType;
        historyRecord.Record_ID__c = recordId;
        historyRecord.Field_API_Name__c = field;
        historyRecord.Old_Value__c = oldValue;
        historyRecord.New_Value__c = newValue;
        return historyRecord;
    }

    @TestVisible
    private static String formatHistoryValue(Object value) {
        if (value == null) {
            return null;
        }

        if (value instanceof Datetime) {
            Datetime dtValue = (Datetime)value;
            return dtValue.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        return String.valueOf(value);
    }
    
    @testVisible
    private static List<History_Setting__mdt> getFieldsToTrack(String objectType) {
        if (Test.isRunningTest() && testFieldsToTrackOverride != null) {
            return testFieldsToTrackOverride;
        }

        List<History_Setting__mdt> configuredFields = [
            SELECT Id, Field__c
            FROM History_Setting__mdt
            WHERE Object__c = :objectType AND Field__c != null
        ];

        if (String.isBlank(objectType)) {
            return new List<History_Setting__mdt>();
        }

        Schema.SObjectType objectToken = Schema.getGlobalDescribe().get(objectType);
        if (objectToken == null) {
            return new List<History_Setting__mdt>();
        }

        Map<String, Schema.SObjectField> fieldMap = objectToken.getDescribe().fields.getMap();
        List<History_Setting__mdt> validFields = new List<History_Setting__mdt>();
        for (History_Setting__mdt setting : configuredFields) {
            if (setting == null || String.isBlank(setting.Field__c)) {
                continue;
            }
            if (fieldMap.containsKey(setting.Field__c)) {
                validFields.add(setting);
            }
        }
        return validFields;
    }
}