public with sharing class ListTagSavedSearchController {
    private static final String ERR_SAVE_SEARCH = 'ERR_SAVE_SEARCH';
    private static final String ERR_DELETE_SEARCH = 'ERR_DELETE_SEARCH';

    @AuraEnabled
    public static Id saveSearch(
        String searchName, 
        String availableLists,
        String listIds,
        String selectedAdditionalContacts,
        String selectedLists,
        String selectedTags,
        Boolean isInsert,
        Id searchId
    ) {
        try {
            Lists_Tags_Tool_Search__c savedSearch;
            if(!isInsert && searchId != null) {
                savedSearch = [SELECT Id FROM Lists_Tags_Tool_Search__c WHERE Id = :searchId WITH SYSTEM_MODE LIMIT 1];
            } else {
                savedSearch = new Lists_Tags_Tool_Search__c();
            }
            
            savedSearch.Name = searchName;
            savedSearch.Available_Lists__c = availableLists;
            savedSearch.List_IDs__c = listIds;
            savedSearch.Selected_Additional_Contacts__c = selectedAdditionalContacts;
            savedSearch.Selected_Lists__c = selectedLists;
            savedSearch.Selected_Tags__c = selectedTags;
            
            BBApps_Crud.doUpsertWithHandling(
                (List<SObject>)new List<Lists_Tags_Tool_Search__c>{ savedSearch },
                false,
                new BBApps_ErrorCustomFields(ERR_SAVE_SEARCH)
            );
            return savedSearch.Id;
        } catch (Exception e) {
            BBApps_ErrorHandler.logErrors('ListTagSavedSearchController.saveSearch', e);
            throw new AuraHandledException('An unexpected error occurred while saving the search.');
        }
    }
    
    @AuraEnabled
    public static void deleteSearch(Id searchId) {
        try {
            if(searchId == null) {
                throw new AuraHandledException('No search selected.');
            }
            Lists_Tags_Tool_Search__c searchRecord = [
                SELECT Id FROM Lists_Tags_Tool_Search__c 
                WHERE Id = :searchId 
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            BBApps_Crud.doDeleteWithHandling(
                (List<SObject>)new List<Lists_Tags_Tool_Search__c>{ searchRecord },
                false,
                new BBApps_ErrorCustomFields(ERR_DELETE_SEARCH)
            );
        } catch (Exception e) {
            BBApps_ErrorHandler.logErrors('ListTagSavedSearchController.deleteSearch', e);
            throw new AuraHandledException('An unexpected error occurred while deleting the search.');
        }
    }

    @AuraEnabled
    public static List<Lists_Tags_Tool_Search__c> getSavedSearches() {
        try {
            return [
                SELECT Id, Name, Available_Lists__c, List_IDs__c, Selected_Additional_Contacts__c, Selected_Lists__c, Selected_Tags__c, LastModifiedDate
                FROM Lists_Tags_Tool_Search__c
                WHERE CreatedById =: UserInfo.getUserId()
                WITH SYSTEM_MODE
                ORDER BY LastModifiedDate DESC
            ];
        } catch (Exception e) {
            BBApps_ErrorHandler.logErrors('ListTagSavedSearchController.getSavedSearches', e);
            throw new AuraHandledException('An unexpected error occurred while retrieving saved searches.');
        }
    }
}