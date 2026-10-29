/**
* Author      : Hardik Kalathiya
* Date        : 03/19/2025
* Jira        : BRME-5731
* Description : Provides search functionality for Geo Area records based on specific search terms and filter.
* Test        : CityViewGeoAreaSearchControllerTest
*/

public with sharing class CityViewGeoAreaSearchController {

    // ---- Error Codes ----
    private static final String ERR_FETCH_ALL = 'CITYVIEW_GEOAREA_SEARCH_FAILED';

    // ---- Error Messages ----
    private static final String MSG_FETCH_ALL = 'Unable to fetch geo area search results.';

    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> fetchAllRecords(String sObjectName, String field, String subField) {
        try {
            Map<String, LookupSearchResult> results = new Map<String, LookupSearchResult>();
            // List 1: If searchTerm starts with Geo Name, show result in ascending order
            String strQuery = 'SELECT Id, Short_Name__c, RecordType.DeveloperName, Coordinates__latitude__s, Coordinates__longitude__s, Has_GCOM_Association__c, ' +
                ' Cultural_Access_Count__c, Interaction_Count__c, Association_Count__c, Office_Count__c,AKA__c, ' + field +
                (String.isNotBlank(subField) ? ', ' + subField : '') +
                ' FROM ' + sObjectName +
                ' WHERE ' +
                'BP_Active__c = true ' +
                'AND Deleted__c = false ' +
                'AND Short_Name__c != NULL ' +
                'AND ( ' +
                '(RecordType.DeveloperName = \'' + Assets.GEOAREARECORDTYPECITY + '\' AND (Geo_Area_Focus_Area_Count__c > 0 OR Has_GCOM_Association__c = true)) ' +
                'OR ' +
                '(RecordType.DeveloperName = \'' + Assets.GEOAREARECORDTYPECOUNTRY + '\') ' +
                'OR ' +
                '(RecordType.DeveloperName = \'' + Assets.GEOAREARECORDTYPESTATE + '\') ' +
                ') ' +
                'ORDER BY RecordType.DeveloperName DESC, GAFA_weight__c DESC NULLS LAST, Geo_Name__c ASC';
            List<sObject> searchResults = Database.query(strQuery);
            // Process search results
            if (searchResults != null && !searchResults.isEmpty()) {
                for (sObject sObj : searchResults) {
                    LookupSearchResult res = new LookupSearchResult();
                    res.Id = sObj.Id;
                    res.title = String.valueOf(sObj.get('Short_Name__c'));
                    res.name = String.valueOf(sObj.get('Name'));
                    res.aka = String.valueOf(sObj.get('AKA__c'));
                    res.latitude = String.valueOf(sObj.get('Coordinates__latitude__s'));
                    res.longitude = String.valueOf(sObj.get('Coordinates__longitude__s'));
                    res.hasGcomData = (Boolean)sObj.get('Has_GCOM_Association__c');
                    res.culturalAccessCount = Integer.valueOf(sObj.get('Cultural_Access_Count__c'));
                    res.interactionCount = Integer.valueOf(sObj.get('Interaction_Count__c'));
                    res.associationCount = Integer.valueOf(sObj.get('Association_Count__c'));
                    res.officeCount = Integer.valueOf(sObj.get('Office_Count__c'));
                    res.recordType = (sObj.getSObject('RecordType') != null)
                        ? String.valueOf(sObj.getSObject('RecordType').get('DeveloperName'))
                        : '';
                    res.subtitle = (String.isNotBlank(subField) && sObj.get(subField) != null)
                        ? String.valueOf(sObj.get(subField))
                        : sObjectName;

                    if (!results.containsKey(res.Id)) results.put(res.Id, res);
                }
            }
            return results.values();
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FETCH_ALL));
            throw new AuraHandledException(MSG_FETCH_ALL);
        }
    }

    public class LookupSearchResult {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String aka { get; set; }
        @AuraEnabled public String subtitle { get; set; }
        @AuraEnabled public String recordType { get; set; }
        @AuraEnabled public String latitude { get; set; }
        @AuraEnabled public String longitude { get; set; }
        @AuraEnabled public Boolean hasGcomData { get; set; }
        @AuraEnabled public Integer culturalAccessCount { get; set; }
        @AuraEnabled public Integer interactionCount { get; set; }
        @AuraEnabled public Integer associationCount { get; set; }
        @AuraEnabled public Integer officeCount { get; set; }
    }
}