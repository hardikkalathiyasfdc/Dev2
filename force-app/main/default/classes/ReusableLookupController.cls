public with sharing class ReusableLookupController {

    private static final String ERR_CLASS_FAILED = 'ReusableLookupController_CLASS_FAILED';

    @AuraEnabled
    public static List<ResultWrapper> fetchRecords(SearchWrapper inputWrapper) {
        try {
            if(inputWrapper != null) {
                String searchKeyWord = inputWrapper.searchString;
                List<String> fieldsToSearch = new List<String> {'Name', 'Preferred_FirstName_LastName__c', 'Preferred_First_Name__c', 'MiddleName', 'Suffix', 'Salutation'};
                List<String> fieldClause = new List<String>();
                String cleanedSearch = '%' + searchKeyWord.trim().replaceAll('\\s+', '%') + '%';
                for (String field : fieldsToSearch) {
                    fieldClause.add(field + ' LIKE :cleanedSearch');
                }
                
                String sQuery = 'SELECT id, Preferred_First_Name__c, Name, Title, Account.Name, Email, Organization_Name_formula__c, Preferred_FirstName_LastName__c FROM Contact WHERE ';
                sQuery += String.join(fieldClause, ' OR ');
            	sQuery += ' ORDER BY Preferred_FirstName_LastName__c DESC limit 50';
            
                List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
                for(SObject s : Database.query(sQuery)) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = (String)s.get(inputWrapper.fieldApiName);
                    wrap.title = (String)s.get(inputWrapper.otherFieldApiName);
                    wrap.id = (String)s.get('id');
                    wrap.OrganizationName = (String)s.get('Organization_Name_formula__c');
                    wrap.Email = (String)s.get('Email');
                     wrap.Name = (String)s.get('Name');
                    returnWrapperList.add(wrap);
                }
                return returnWrapperList;
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return null;
    }

    public class ResultWrapper {
        @AuraEnabled public String mainField{get;set;}
        @AuraEnabled public String title{get;set;}
        @AuraEnabled public String id{get;set;}
         @AuraEnabled public String OrganizationName{get;set;}
        @AuraEnabled public String Email{get;set;}
        @AuraEnabled public String Name{get;set;}
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