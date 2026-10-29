/**
* Author      : Ravi Bheemreddy  
* Description : Test class for WeightedFieldLookupSearch
* JIRA 		  : BRME-6660
*/
@IsTest
private class WeightedFieldLookupSearchTest {

    @TestSetup
    static void setupTestData() {
        List<Campaign> campaigns = TestDataFactory.createCampaigns(3, 'Pre_Event', true);
        campaigns[0].Converted_List_Name__c = 'Test Campaign 0';
        campaigns[1].Converted_List_Name__c = 'Test Campaign 1';
        campaigns[2].Converted_List_Name__c = 'Test Campaign 2';
        update campaigns;
    }

    static GenericLookupController.SearchRequest buildRequest(String searchTerm) {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Campaign';
        req.searchTerm = searchTerm;
        req.displayFields = new List<String>{ 'Name' };
        req.maxResults = 10;
        req.searchConfig = JSON.serialize(new Map<String, Object>{
            'primaryField' => 'Name',
            'primaryWeight' => 100,
            'convertedField' => 'Converted_List_Name__c',
            'convertedWeight' => 80
        });
        return req;
    }

    @IsTest
    static void testEmptySearchTermReturnsEmpty() {
        GenericLookupController.SearchRequest req = buildRequest('');

        Test.startTest();
        WeightedFieldLookupSearch search = new WeightedFieldLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testBasicSearchReturnsResults() {
        GenericLookupController.SearchRequest req = buildRequest('Test Campaign');

        Test.startTest();
        WeightedFieldLookupSearch search = new WeightedFieldLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assert(results.size() > 0);
    }

    @IsTest
    static void testConvertedFieldMatch() {
        GenericLookupController.SearchRequest req = buildRequest('Test Campaign 0');

        Test.startTest();
        WeightedFieldLookupSearch search = new WeightedFieldLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assert(results.size() > 0);
    }

    @IsTest
    static void testNoMatchReturnsEmpty() {
        GenericLookupController.SearchRequest req = buildRequest('ZZZNOEXIST');

        Test.startTest();
        WeightedFieldLookupSearch search = new WeightedFieldLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }
}