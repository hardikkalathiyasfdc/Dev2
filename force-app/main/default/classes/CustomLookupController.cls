/*
 *  test class: CustomLookupControllerTest
 */
public with sharing class CustomLookupController {

	private static final String ERR_CLASS_FAILED = 'CustomLookupController_CLASS_FAILED';

    @AuraEnabled
    public static Object fetchLookUpValues(String searchKeyWord, String objectName, String whereClause, String searchId) {
		Map<String, Object> result = new Map<String, Object>();
		try {
			result.put('searchId', searchId);
			if('tag__c'.equalsIgnoreCase(objectName)) {
				result.put('list', getTags(searchKeyWord, whereClause));
				return result;
			}
			String searchKey = '%' + searchKeyWord + '%';
			List<sObject> returnList = new List<sObject>();
			String sQuery = getQuery(searchKey, objectName);
			List<sObject> lstOfRecords = Database.query(sQuery);
			for(sObject obj : lstOfRecords) {
				returnList.add(obj);
			}
			result.put('list', returnList);
		} catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
		return result;
	}
		
	private static String getQuery(String searchKey, String objectName) {
		String q = 'SELECT Id, Name';
		if ('account'.equalsIgnoreCase(objectName)) {
			q += ',AKA__c';
		}
		if ('contact'.equalsIgnoreCase(objectName)) {
			q += ',Account.Name,Email';
		}
		if ('account'.equalsIgnoreCase(objectName)) {
			q += ' FROM ' + objectName + ' WHERE  (Name LIKE: searchKey OR AKA__c LIKE: searchKey) WITH SYSTEM_MODE ';
		} else {
			q += ' FROM ' + objectName + ' WHERE Name LIKE: searchKey WITH SYSTEM_MODE';
		}
		if ('user'.equalsIgnoreCase(objectName)) {
			q += ' AND IsActive = true';
		}
		if (!'tag__c'.equalsIgnoreCase(objectName)) {
			q += ' ORDER BY LastModifiedDate DESC LIMIT 5';
		} else {
			q += ' ORDER BY Name ASC';
		}
		return q;
    }
    
    private static List<SObject> getAllPublicTags() {
		String q = 'SELECT Id, Name FROM Tag__c WHERE Private__c = false WITH SYSTEM_MODE ORDER BY Name ASC';
		return Database.query(q);
    }
    
    private static List<SObject> getTags(String searchKeyWord, String whereClause) {
		if(String.isBlank(searchKeyWord)) {
			String q = 'SELECT Id, Name FROM Tag__c WHERE Private__c = false WITH SYSTEM_MODE';
			if (String.isNotBlank(whereClause)) {
				q += ' AND ' + whereClause;
			}
			q += ' ORDER BY Name ASC';
			return Database.query(q);
		}
		searchKeyWord = '\'%' + searchKeyWord + '%\'';
		String q = 'SELECT Id, Name FROM Tag__c WHERE Name LIKE '+searchKeyWord;
		if (String.isNotBlank(whereClause)) {
			q += ' AND ' + whereClause;
		}
		q += ' WITH SYSTEM_MODE ORDER BY Name ASC';
		return Database.query(q);
    }
}