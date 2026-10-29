/**
 * @description       : Service class used for Generic Lookup custom component
 * @author            : Ravi Bheemreddy
 * @test class		  : GenericLookupControllerTest
 * @jira			  : BRME-6394
 **/
public class GenericLookupService {
    
    private static final String ERR_CLASS_FAILED = 'GenericLookupService_CLASS_FAILED';
    
    public static GenericLookupController.SearchResponse searchRecords(GenericLookupController.SearchRequest req) {
        GenericLookupController.SearchResponse response = new GenericLookupController.SearchResponse();
         
        try {
            if (String.isNotBlank(req.customSearchClass)) {
                Type customType = Type.forName(req.customSearchClass);
                if (customType != null) {
                    IGenericLookupSearch customSearch = (IGenericLookupSearch) customType.newInstance();
                    response.records = customSearch.search(req);
                    return response;
                }
            }
            String objectApiName = String.escapeSingleQuotes(req.objectApiName);
            String searchTerm = String.escapeSingleQuotes(req.searchTerm);
            Integer maxResults = req.maxResults != null ? req.maxResults : 10;
            
            Set<String> fieldsToQuery = new Set<String>{'Id', 'Name'};
            if (req.displayFields != null) {
                for (String field : req.displayFields) {
                    fieldsToQuery.add(String.escapeSingleQuotes(field));
                }
            }
            
            if (req.searchFields != null) {
                for (String field : req.searchFields) {
                    fieldsToQuery.add(String.escapeSingleQuotes(field));
                }
            }
            
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ');
            query += ' FROM ' + objectApiName;
            
            List<String> keywords = searchTerm.trim().split('\\s+');
            List<String> fieldConditions = new List<String>();
            List<String> searchFieldList = (req.searchFields != null && !req.searchFields.isEmpty())
                ? req.searchFields
                : new List<String>{ 'Name' };
            for (String field : searchFieldList) {
                List<String> keywordConditions = new List<String>();
                for (String keyword : keywords) {
                    keywordConditions.add(String.escapeSingleQuotes(field) + ' LIKE \'%' + String.escapeSingleQuotes(keyword) + '%\'');
                }
                fieldConditions.add('(' + String.join(keywordConditions, ' AND ') + ')');
            }
            
            query += ' WHERE (' + String.join(fieldConditions, ' OR ') + ')';
            
            if (String.isNotBlank(req.filterClause)) {
                query += ' AND (' + req.filterClause + ')';
            }
            
            if (String.isNotBlank(req.orderByClause)) {
                query += ' ORDER BY ' + req.orderByClause;
            } else {
                query += ' ORDER BY Name ASC';
            }
            
            query += ' LIMIT ' + (maxResults + 1);
            
            List<SObject> results = executeQuery(query, req.accessMode, req.withoutSharing);
            
            response.hasMore = results.size() > maxResults;
            
            Integer recordCount = Math.min(results.size(), maxResults);
            for (Integer i = 0; i < recordCount; i++) {
                response.records.add(mapSObjectToLookupRecord(results[i], req.displayFields));
            }
            
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error searching records: ' + e.getMessage());
        }
        
        return response;
    }
    
    public static List<GenericLookupController.LookupRecord> getRecordsByIds(GenericLookupController.IdsRequest req) {
        List<GenericLookupController.LookupRecord> records = new List<GenericLookupController.LookupRecord>();
        
        try {
            if (req.recordIds == null || req.recordIds.isEmpty()) {
                return records;
            }
            
            String objectApiName = String.escapeSingleQuotes(req.objectApiName);
            
            Set<String> fieldsToQuery = new Set<String>{'Id', 'Name'};
            if (req.displayFields != null) {
                for (String field : req.displayFields) {
                    fieldsToQuery.add(String.escapeSingleQuotes(field));
                }
            }
            
            Set<Id> recordIds = new Set<Id>();
            for (String recordId : req.recordIds) {
                recordIds.add(Id.valueOf(recordId));
            }
            
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ');
            query += ' FROM ' + objectApiName;
            query += ' WHERE Id IN (';
            
            List<String> idStrings = new List<String>();
            for (Id recId : recordIds) {
                idStrings.add('\'' + recId + '\'');
            }
            query += String.join(idStrings, ',') + ')';
            
            List<SObject> results = executeQuery(query, req.accessMode, req.withoutSharing);
            
            for (SObject record : results) {
                records.add(mapSObjectToLookupRecord(record, req.displayFields));
            }
            
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
        
        return records;
    }
    
    public static List<GenericLookupController.LookupRecord> getRecentlyViewed(GenericLookupController.RecentRequest req) {
        List<GenericLookupController.LookupRecord> records = new List<GenericLookupController.LookupRecord>();
        
        try {
            String objectApiName = String.escapeSingleQuotes(req.objectApiName);
            Integer maxResults = 5;
            
            Set<String> fieldsToQuery = new Set<String>{'Id', 'Name'};
            if (req.displayFields != null) {
                for (String field : req.displayFields) {
                    fieldsToQuery.add(String.escapeSingleQuotes(field));
                }
            }
            
            String recentQuery = 'SELECT Id FROM RecentlyViewed WHERE Type = \'' + objectApiName + '\' ORDER BY LastViewedDate DESC LIMIT ' + (maxResults * 2);
            
            List<SObject> recentlyViewed = executeQuery(recentQuery, req.accessMode, req.withoutSharing);
            
            if (recentlyViewed.isEmpty()) {
                return records;
            }
            
            List<Id> orderedIds = new List<Id>();
            List<String> idStrings = new List<String>();
            for (SObject rv : recentlyViewed) {
                Id recId = (Id) rv.get('Id');
                orderedIds.add(recId);
                idStrings.add('\'' + recId + '\'');
            }
            
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ');
            query += ' FROM ' + objectApiName;
            query += ' WHERE Id IN (' + String.join(idStrings, ',') + ')';
            
            if (String.isNotBlank(req.filterClause)) {
                query += ' AND (' + req.filterClause + ')';
            }
            
            List<SObject> results = executeQuery(query, req.accessMode, req.withoutSharing);
            
            Map<Id, SObject> recordMap = new Map<Id, SObject>();
            for (SObject record : results) {
                recordMap.put((Id) record.get('Id'), record);
            }
            
            for (Id recordId : orderedIds) {
                if (recordMap.containsKey(recordId)) {
                    records.add(mapSObjectToLookupRecord(recordMap.get(recordId), req.displayFields));
                    if (records.size() >= maxResults) {
                        break;
                    }
                }
            }
            
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error fetching recently viewed: ' + e.getMessage());
        }
        
        return records;
    }
    
    public static List<String> getFieldSetFields(String objectApiName, String fieldSetName) {
        List<String> fields = new List<String>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType == null) {
            return fields;
        }
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = objDescribe.fieldSets.getMap();
        if (!fieldSetMap.containsKey(fieldSetName)) {
            return fields;
        }
        Schema.FieldSet fs = fieldSetMap.get(fieldSetName);
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        for (Schema.FieldSetMember f : fs.getFields()) {
            String fieldPath = f.getFieldPath();
            if (fieldMap.containsKey(fieldPath) && fieldMap.get(fieldPath).getDescribe().isAccessible()) {
                fields.add(fieldPath);
            }
        }
        return fields;
    }

    private static List<SObject> executeQuery(String query, String accessMode, Boolean withoutSharing) {
        if (withoutSharing) {
            return new WithoutSharingExecutor().execute(query, accessMode);
        } else {
            return new WithSharingExecutor().execute(query, accessMode);
        }
    }
    
    public static GenericLookupController.LookupRecord mapToLookupRecord(SObject record, List<String> displayFields) {
        return mapSObjectToLookupRecord(record, displayFields);
    }

    private static GenericLookupController.LookupRecord mapSObjectToLookupRecord(SObject record, List<String> displayFields) {
        GenericLookupController.LookupRecord lookupRecord = new GenericLookupController.LookupRecord();
        lookupRecord.Id = (String) record.get('Id');
        
        if (displayFields != null) {
            for (String field : displayFields) {
                Object fieldValue = getFieldValue(record, field);
                if (fieldValue != null) {
                    lookupRecord.fields.put(field, fieldValue);
                }
            }
        }
        
        return lookupRecord;
    }
    
    private static Object getFieldValue(SObject record, String fieldPath) {
        if (String.isBlank(fieldPath)) {
            return null;
        }
        
        List<String> parts = fieldPath.split('\\.');
        SObject currentSObject = record;
        
        for (Integer i = 0; i < parts.size(); i++) {
            if (currentSObject == null) {
                return null;
            }
            if (i < parts.size() - 1) {
                currentSObject = currentSObject.getSObject(parts[i]);
            } else {
                return currentSObject.get(parts[i]);
            }
        }
        
        return null;
    }
    
    private with sharing class WithSharingExecutor {
        public List<SObject> execute(String query, String accessMode) {
            if (accessMode == 'SYSTEM_MODE') {
                return Database.query(query, AccessLevel.SYSTEM_MODE);
            }
            return Database.query(query, AccessLevel.USER_MODE);
        }
    }
    
    private without sharing class WithoutSharingExecutor {
        public List<SObject> execute(String query, String accessMode) {
            if (accessMode == 'SYSTEM_MODE') {
                return Database.query(query, AccessLevel.SYSTEM_MODE);
            }
            return Database.query(query, AccessLevel.USER_MODE);
        }
    }
}