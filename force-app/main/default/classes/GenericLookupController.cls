/**
 * @description       : Controller class used for Generic Lookup custom component
 * @author            : Ravi Bheemreddy
 * @test class		  : GenericLookupControllerTest
 * @jira			  : BRME-6394
 **/
public with sharing class GenericLookupController {
    
    private static final String ERR_CLASS_FAILED = 'GenericLookupController_CLASS_FAILED';
    
    @AuraEnabled(cacheable=true)
    public static SearchResponse searchRecords(String request) {
        try {
            SearchRequest req = (SearchRequest) JSON.deserialize(request, SearchRequest.class);
            return GenericLookupService.searchRecords(req);
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error searching records: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<LookupRecord> getRecordsByIds(String request) {
        try {
            IdsRequest req = (IdsRequest) JSON.deserialize(request, IdsRequest.class);
            return GenericLookupService.getRecordsByIds(req);
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<LookupRecord> getRecentlyViewed(String request) {
        try {
            RecentRequest req = (RecentRequest) JSON.deserialize(request, RecentRequest.class);
            return GenericLookupService.getRecentlyViewed(req);
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error fetching recently viewed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static ObjectInfoResult getObjectInfo(String objectApiName) {
        ObjectInfoResult result = new ObjectInfoResult();
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType != null) {
                Schema.DescribeSObjectResult describe = sObjectType.getDescribe();
                result.label = describe.getLabel();
                result.labelPlural = describe.getLabelPlural();
                result.apiName = describe.getName();
            }
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(e, f);
        }
        return result;
    }
    
    public class SearchRequest {
        public String objectApiName;
        public String searchTerm;
        public List<String> searchFields;
        public List<String> displayFields;
        public String filterClause;
        public String orderByClause;
        public Integer maxResults;
        public String accessMode;
        public Boolean withoutSharing;
        public String customSearchClass;
        public String searchConfig;
    }
    
    public class IdsRequest {
        public String objectApiName;
        public List<String> recordIds;
        public List<String> displayFields;
        public String accessMode;
        public Boolean withoutSharing;
    }
    
    public class RecentRequest {
        public String objectApiName;
        public List<String> displayFields;
        public String filterClause;
        public Integer maxResults;
        public String accessMode;
        public Boolean withoutSharing;
    }
    
    public class SearchResponse {
        @AuraEnabled public List<LookupRecord> records;
        @AuraEnabled public Boolean hasMore;
        
        public SearchResponse() {
            this.records = new List<LookupRecord>();
            this.hasMore = false;
        }
    }
    
    public class LookupRecord {
        @AuraEnabled public String Id;
        @AuraEnabled public Map<String, Object> fields;
        
        public LookupRecord() {
            this.fields = new Map<String, Object>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldSetFields(String objectApiName, String fieldSetName) {
        try {
            return GenericLookupService.getFieldSetFields(objectApiName, fieldSetName);
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error fetching field set fields: ' + e.getMessage());
        }
    }
    
    public class ObjectInfoResult {
        @AuraEnabled public String label;
        @AuraEnabled public String labelPlural;
        @AuraEnabled public String apiName;
    }
}