public class CustomSingleSelectLookupLwcController {

    private static final String ERR_CLASS_FAILED = 'CustomSingleSelectLookupLwcController_CLASS_FAILED';

    @AuraEnabled(cacheable=true)
    public static list<sObject> fetchLookupData(String searchKey, String sObjectApiName) {    
        List<sObject> returnList = new List<sObject>();
        try {
            if(String.isNotBlank(searchKey)) {
                String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
                String sQuery = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(sObjectApiName) + 
                               ' WHERE Name LIKE : sWildCardText ORDER BY createdDate DESC LIMIT 5';
                for(sObject obj : database.query(sQuery)) {
                    returnList.add(obj);
                }  
            }       
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return returnList;
    }

    // Method to fetch lookup search result   
    @AuraEnabled(cacheable=true)
    public static list<sObject> fetchLookupDataFilter(String searchKey, String sObjectApiName, String parentfieldApiName, String pRecordId, Boolean isParentRequired) {    
        List<sObject> returnList = new List<sObject>();
        try {
            String sWildCardText = String.isNotBlank(searchKey) ? '%' + String.escapeSingleQuotes(searchKey) + '%' :'%';
            //String filterLogic = String.isEmpty(filterData) ? '' : String.escapeSingleQuotes(filterData); //
            String parentField = String.isNotBlank(parentfieldApiName) ? String.escapeSingleQuotes(parentfieldApiName) : '';
            String parentId = String.isNotBlank(pRecordId) ? String.escapeSingleQuotes(pRecordId) : '';
            String filterLogic = String.isEmpty(parentfieldApiName) ? '' : ' AND '+ parentField +'='+ '\'' + parentId + '\'' ;
            String sQuery = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(sObjectApiName) +  
                           ' WHERE Name Like :sWildCardText ' + filterLogic + ' ORDER BY createdDate DESC LIMIT 5';
            if(isParentRequired && (String.isBlank(parentField) || String.isBlank(parentId))) {
            } else {
                for(sObject obj: database.query(sQuery)) {
                    returnList.add(obj);
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return returnList;
    }

    // Method to fetch lookup default value 
    @AuraEnabled(cacheable=true)
    public static sObject fetchDefaultRecord(String recordId, String sObjectApiName) {   
        try {    
            if(String.isNotBlank(recordId)){
                String sRecId = String.escapeSingleQuotes(recordId);
                String sQuery = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(sObjectApiName) + 
                               ' WHERE Id = :sRecId LIMIT 1';
                for(sObject obj: database.query(sQuery)) {
                    return obj;
                } 
            }         
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return null;
    }
}