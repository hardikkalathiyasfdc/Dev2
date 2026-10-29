public with sharing class reUsableMultiSelectLookupCtrl {

    private static final String ERR_CLASS_FAILED = 'reUsableMultiSelectLookupCtrl_CLASS_FAILED';

    @AuraEnabled
    public static List<sObject> fetchLookUpValues(String searchKeyWord, String ObjectName, List<sObject> ExcludeitemsList) {
        List<sObject> returnList = new List<sObject> ();
        try {
            List<String> lstSearchWordsSplit = new List<String>();
            for(String str : searchKeyWord.split(' ')) {
                String wordStr = '%' + str + '%';
                lstSearchWordsSplit.add(wordStr);
            }
            String searchKey = '%' + searchKeyWord + '%';
            List<string> lstExcludeitems = new List<string>();
            for(sObject item : ExcludeitemsList) {
                lstExcludeitems.add(item.id);
            }
            String sQuery;
            // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 and exclude already selected records  
            if(ObjectName != null && ObjectName == 'Contact') {
                if(lstSearchWordsSplit != null && lstSearchWordsSplit.size()>1) {
                    sQuery = 'SELECT id, FirstName, LastName, Preferred_First_Name__c,Name,Title,Account.Name,Email FROM ' + 
                              ObjectName + ' WHERE LastName LIKE: lstSearchWordsSplit AND (Preferred_First_Name__c LIKE: lstSearchWordsSplit OR FirstName LIKE: lstSearchWordsSplit) AND Id NOT IN : lstExcludeitems order by createdDate DESC limit 10';
                } else {
                    sQuery = 'SELECT id, FirstName, LastName, Preferred_First_Name__c,Name,Title,Account.Name,Email FROM ' + 
                             ObjectName + ' WHERE (Name LIKE: searchKey OR Preferred_First_Name__c LIKE: searchKey) AND Id NOT IN : lstExcludeitems order by createdDate DESC limit 10';
                }
            } else {
                sQuery =  'SELECT id, Name,Title,Account.Name,Email FROM ' + ObjectName + ' WHERE Name LIKE: searchKey AND Id NOT IN : lstExcludeitems order by createdDate DESC limit 10';
            }
            List<sObject> lstOfRecords = Database.query(sQuery);
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return returnList;
    }

    @AuraEnabled(cacheable=true)
    public static String fetchAccountsByKeyword(String searchKeyWord) {
        try {
            String searchKey = '%' + String.escapeSingleQuotes(searchKeyWord) + '%';
            String sQuery = ' SELECT Id, Name, AKA__c FROM Account WHERE Name LIKE: searchKey ORDER BY Name ASC LIMIT 30';
            return JSON.serialize(Database.query(sQuery));
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return '';
    }
}