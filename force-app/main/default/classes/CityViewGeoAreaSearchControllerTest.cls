@isTest
public with sharing class CityViewGeoAreaSearchControllerTest {
    @testSetup
    static void setupTestData() {
        TestDataFactory.createGeoHierarchy();
    }
    
    @isTest
    static void testSearchLookupRecords() {
        Test.startTest();
        List<String> selectedIds = new List<String>();
        List<CityViewGeoAreaSearchController.LookupSearchResult> results = 
            CityViewGeoAreaSearchController.fetchAllRecords(
                'Geo_Area__c', 
                'Name', 
                'Geo_Name__c'
            );
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Results should not be empty');
        for (CityViewGeoAreaSearchController.LookupSearchResult res : results) {
            System.assertNotEquals(res.Id, null, 'Result Id should not be null');
            System.assertNotEquals(res.title, null, 'Title should not be null');
        }
    }
}