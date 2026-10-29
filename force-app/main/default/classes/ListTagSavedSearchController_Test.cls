@isTest
public class ListTagSavedSearchController_Test {
	
    @testSetup
    static void dataSetup () {
        Lists_Tags_Tool_Search__c savedSearch = TestDataFactory.createListTagSavedSearch();
        insert as system savedSearch;
    }
    
    @isTest
    static void saveSearchInsertTest () {
        Test.startTest ();
        Id savedSearchId = ListTagSavedSearchController.saveSearch('Test Search', '701V9000027m9pUIAQ', '701V9000027m9pUIAQ', '701V9000027m9pUIAQ', '701V9000027m9pUIAQ', '701V9000027m9pUIAQ', true, null);
        System.assertEquals(true, savedSearchId != null);
        Test.stopTest ();
    }
    
    @isTest
    static void saveSearchUpdateTest () {
        Lists_Tags_Tool_Search__c searchRecord = [
            SELECT Id, Name FROM Lists_Tags_Tool_Search__c 
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        
        System.assertEquals(true, searchRecord.Name == 'Test Search');
        
        Test.startTest ();
        ListTagSavedSearchController.deleteSearch(searchRecord.Id);
        System.assertEquals(true, [Select Id from Lists_Tags_Tool_Search__c where Id =: searchRecord.Id WITH SYSTEM_MODE].isEmpty());
        Test.stopTest ();
    }
    
    @isTest
    static void saveSearchDeleteTest () {
        Lists_Tags_Tool_Search__c searchRecord = [
            SELECT Id FROM Lists_Tags_Tool_Search__c 
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        Test.startTest ();
        Id savedSearchId = ListTagSavedSearchController.saveSearch('Test Search Updated', '701V9000027m9pUIAQ', '701V9000027m9pUIAQ', '701V9000027m9pUIAQ', '701V9000027m9pUIAQ', '701V9000027m9pUIAQ', false, searchRecord.Id);
        System.assertEquals(true, [Select Id, Name from Lists_Tags_Tool_Search__c where Id =: searchRecord.Id WITH SYSTEM_MODE].Name == 'Test Search Updated');
        Test.stopTest ();
    }

    @isTest
    static void getSavedSearchesTest () {
        Test.startTest();
        List<Lists_Tags_Tool_Search__c> results = ListTagSavedSearchController.getSavedSearches();
        Test.stopTest();
        System.assertEquals(true, results.size() > 0);
        System.assertEquals('Test Search', results[0].Name);
    }
}