/**
 * CustomHistoryRecordUpdatesQueueable
 * 
 * This queueable class tracks changes to specified fields on sObjects based on configuration
 * defined in the History_Setting__mdt custom metadata type. This class is used to handle 'REFERENCE'
 * fields since it involves querying relationship data using the parent relationship.
 * 
 * Author : Ravi Bheemreddy
 * Jira   : BRME-5387
 * Test   : CustomHistoryRecordUpdatesQueueableTest
 */

public with sharing class CustomHistoryRecordUpdatesQueueable implements Queueable {
    
    private List<Custom_History__c> recordsToUpdate;
    private static final String ERR_EXECUTE  = 'HISTORY_RECORD_UPDATE_QUEUEABLE_EXECUTE_FAILED';
    private static final String ERR_FETCH_RELATED_RECORD_NAMES  = 'HISTORY_RECORD_UPDATE_QUEUEABLE_FETCH_RELATED_RECORD_NAMES_FAILED';
    
    public CustomHistoryRecordUpdatesQueueable(List<Custom_History__c> recordsToUpdate) {
        this.recordsToUpdate = recordsToUpdate;
    }
    
    public void execute(QueueableContext context) {
        try{ 
            Map<Id, String> relatedRecordNames = fetchRelatedRecordNames(recordsToUpdate);
            
            for (Custom_History__c record : recordsToUpdate) {
                String objectApiName = (String) record.get('Object_API_Name__c');
                String fieldApiName = (String) record.get('Field_API_Name__c');
                
                if (isReferenceField(fieldApiName, objectApiName)) {
                    if (relatedRecordNames.containsKey((Id)record.get('Old_Value__c'))) {
                        record.put('Old_Value__c', relatedRecordNames.get((Id)record.get('Old_Value__c')));
                    }
                    if (relatedRecordNames.containsKey((Id)record.get('New_Value__c'))) {
                        record.put('New_Value__c', relatedRecordNames.get((Id)record.get('New_Value__c')));
                    }
                }
            }
            
            if (!recordsToUpdate.isEmpty()) {
                List<MB_Error__c> errs = new List<MB_Error__c>();
                List<Database.SaveResult> results = Database.update(recordsToUpdate, false);
                for( Integer i=0;i<results.size();i++ ) {
                    if( !results[i].isSuccess() ) {
                        for(Database.Error err : results[i].getErrors()) {
                            errs.add(new MB_Error__c( Description__c='CustomHistoryRecordUpdatesQueueable Failure '+JSON.serialize(recordsToUpdate[i]), Type__c='CustomHistoryRecordUpdatesQueueable Failure'));
                        }
                    }
                }
                if( errs.size() > 0 ) {
                    insert errs;
                } 
            }
            
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_EXECUTE)); 
        }
    }
    
    private Map<Id, String> fetchRelatedRecordNames(List<Custom_History__c> records) {
        try{ 
            Set<Id> relatedIds = new Set<Id>();
            Map<Id, String> relatedRecordNames = new Map<Id, String>();
            Map<String, Set<Id>> objectToIdsMap = new Map<String, Set<Id>>();
            
            for (Custom_History__c record : records) {
                String objectApiName = (String) record.get('Object_API_Name__c');
                String fieldApiName = (String) record.get('Field_API_Name__c');
                
                if (isReferenceField(fieldApiName, objectApiName)) {
                    if (record.get('Old_Value__c') != null) {
                        addRelatedId((Id) record.get('Old_Value__c'), fieldApiName, objectApiName, objectToIdsMap);
                    }
                    if (record.get('New_Value__c') != null) {
                        addRelatedId((Id) record.get('New_Value__c'), fieldApiName, objectApiName, objectToIdsMap);
                    }
                }
            }
            
            // Fetch related record names
            for (String objType : objectToIdsMap.keySet()) {
                Set<Id> ids = objectToIdsMap.get(objType);
                String query = 'SELECT Id, Name FROM ' + objType + ' WHERE Id IN :ids';
                try {
                    List<SObject> recordsFetched = Database.query(query);
                    for (SObject recordFetched : recordsFetched) {
                        relatedRecordNames.put(recordFetched.Id, (String) recordFetched.get('Name'));
                    }
                } catch (Exception e) {
                    insert new MB_Error__c( 
                        Description__c = e.getMessage(), 
                        Type__c='CustomHistoryRecordUpdatesQueueable Failure'
                    );
                }
            }
            
            return relatedRecordNames;
            
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_FETCH_RELATED_RECORD_NAMES)); 
            return null;
        }
    }
    
    private Boolean isReferenceField(String fieldApiName, String objectApiName) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType != null) {
            Schema.DescribeSObjectResult describeResult = objType.getDescribe();
            Schema.SObjectField field = describeResult.fields.getMap().get(fieldApiName);
            if (field != null) {
                Schema.DescribeFieldResult fieldResult = field.getDescribe();
                return fieldResult.getType() == Schema.DisplayType.REFERENCE;
            }
        }
        return false;
    }
    
    private void addRelatedId(Id relatedId, String fieldApiName, String objectApiName, Map<String, Set<Id>> objectToIdsMap) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.SObjectField field = describeResult.fields.getMap().get(fieldApiName);
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        String referenceTo = fieldResult.getReferenceTo()[0].getDescribe().getName();
        
        if (!objectToIdsMap.containsKey(referenceTo)) {
            objectToIdsMap.put(referenceTo, new Set<Id>());
        }
        objectToIdsMap.get(referenceTo).add(relatedId);
    }
}