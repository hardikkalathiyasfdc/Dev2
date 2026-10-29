public with sharing class DITLookupController {

    private static final String ERR_FETCH_RECORDS  = 'DITLC_FETCH_RECORDS_FAILED';
    private static final String ERR_GET_PICKLISTS   = 'DITLC_GET_PICKLISTS_FAILED';
    
    @AuraEnabled
    public static List<ResultWrapper> fetchRecords(SearchWrapper inputWrapper) {
        try {
            if(inputWrapper != null){
                String fieldsToQuery = 'SELECT Id, ';
                if(string.isNotBlank(inputWrapper.fieldApiName)){
                    fieldsToQuery = fieldsToQuery + inputWrapper.fieldApiName;
                }
                if(string.isNotBlank(inputWrapper.otherFieldApiName)){
                    fieldsToQuery = fieldsToQuery + ', ' + inputWrapper.otherFieldApiName;
                } 
                if(inputWrapper.objectApiName =='Account'){
                    fieldsToQuery = fieldsToQuery + ',Legal_Name__c,AKA__c, Converted_AKA__c,Converted_Legal_Name__c,Website ';
                }
                String query = fieldsToQuery + ' FROM '+ inputWrapper.objectApiName;
                if(String.isNotBlank(inputWrapper.selectedRecordId)) {
                    query += ' WHERE Id = \''+ inputWrapper.selectedRecordId + '\'';
                }
                else if(String.isNotBlank(inputWrapper.searchString)) {
                    
                    inputWrapper.searchString = inputWrapper.searchString.replaceFirst('The ', '');
                    inputWrapper.searchString = SpecialCharactersHelper.convertSpecialCharToEnglish(inputWrapper.searchString);
                    String filterCriteria = inputWrapper.fieldApiName + ' LIKE \'%' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\'';
                    if(inputWrapper.objectApiName =='Account'){
                        filterCriteria += 'OR Converted_AKA__c  LIKE ' + '\'' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\'';
                        filterCriteria += 'OR Converted_Legal_Name__c  LIKE ' + '\'' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\'';
                          filterCriteria += 'OR Converted_Org_Name__c  LIKE ' + '\'' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%\'';
                    }
                    query += ' WHERE '+ filterCriteria;
                }
                if(inputWrapper.objectApiName =='Account'){
                    query += ' ORDER BY AKA__c DESC NULLS LAST,Converted_Legal_Name__c DESC NULLS LAST,Name ASC';
                }
                // if(inputWrapper.fieldApiName =='Significant_Other__c')
                //{
                //  query = query + ' AND Significant_Other__c =null ';
                // }
                List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
                system.debug('query:: '+query);
                for(SObject s : Database.query(query + ' LIMIT 200')) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = (String)s.get(inputWrapper.fieldApiName);
                    wrap.subField = (String)s.get(inputWrapper.otherFieldApiName);
                    wrap.id = (String)s.get('id');
                    if(inputWrapper.objectApiName =='Account'){
                        wrap.AKA = (String)s.get('AKA__c');
                        wrap.Legal_Name =(String)s.get('Legal_Name__c');
                        wrap.Website =(String)s.get('Website');
                    }
                    returnWrapperList.add(wrap);
                }
                return returnWrapperList;
            }
            return null;
        } catch (Exception err) {
            BBApps_ErrorHandler.logErrors(err, new BBApps_ErrorCustomFields(ERR_FETCH_RECORDS));
            throw new AuraHandledException(err.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPickLists(String objectType, String selectedField){
        try {
            Map<String, String> pickListValuesMap = new Map<String, String>();
            Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
            Schema.DescribeSObjectResult res = convertToObj.getDescribe();
            Schema.DescribeFieldResult fieldResult;
            fieldResult = res.fields.getMap().get(selectedField).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesMap.put(pickListVal.getValue(), pickListVal.getLabel());
            }     
            return pickListValuesMap;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_PICKLISTS));
            throw new AuraHandledException(ex.getMessage());
        }
    }
    public class ResultWrapper{
        @AuraEnabled public String mainField{get;set;}
        @AuraEnabled public String subField{get;set;}
        @AuraEnabled public String AKA{get;set;}
        @AuraEnabled public String Legal_Name{get;set;}
        @AuraEnabled public String Website{get;set;}
        @AuraEnabled public String id{get;set;}
    }
    
    public class SearchWrapper {
        @AuraEnabled public String objectApiName{get;set;}
        @AuraEnabled public String fieldApiName{get;set;}
        @AuraEnabled public String otherFieldApiName{get;set;}
        @AuraEnabled public String searchString{get;set;}
        @AuraEnabled public String selectedRecordId{get;set;}
        @AuraEnabled public String parentRecordId{get;set;}
        @AuraEnabled public String parentFieldApiName{get;set;}
    }
}