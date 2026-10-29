public with sharing class AddListTagResultsToListController {
    
    @AuraEnabled(cacheable=true scope='global')
    public static List<LookupSearchResult> getRecentlyViewed() {
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        List<Campaign> recentRecords = [SELECT Id, Name, Event_Start_Date_Time__c 
                                        FROM Campaign 
                                        WHERE LastViewedDate != null 
                                        ORDER BY LastViewedDate DESC LIMIT 5];
        for(Campaign recentRecord : recentRecords) {
            results.add(new LookupSearchResult(recentRecord.Id, 'Campaign', 'standard:campaign', 
                        recentRecord.Name, recentRecord.Event_Start_Date_Time__c));
        }
        return results; 
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {
        searchTerm = '%' + searchTerm + '%';
        List<Campaign> campaignRecords = [SELECT Id, Name, Event_Start_Date_Time__c 
                                          FROM Campaign 
                                          WHERE Name like :searchTerm 
                                          ORDER BY LastViewedDate DESC LIMIT 5];
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        String campaignIcon = 'standard:campaign';
        for(Campaign campaignRecord : campaignRecords) {
            results.add(new LookupSearchResult(campaignRecord.Id, 'Campaign', 'standard:campaign', 
                        campaignRecord.Name, campaignRecord.Event_Start_Date_Time__c));
        }
        results.sort();
        return results;
    }
    
    @AuraEnabled
    public static void addToExistingListAsync(String campaignId, String memberStatus, Boolean keepExistingStatus, 
                                              List<String> contactIds, Map<String, String> contactSourceMap) {
        String contactSources = JSON.serialize(contactSourceMap);
        Database.executeBatch(new AddListTagResultsToListBatch(campaignId, memberStatus, keepExistingStatus, contactIds, contactSources), 5000);
    }
}