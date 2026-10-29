/**
* Author      : Ravi Bheemreddy  
* Description : Test class for OrganizationLookupSearch
* JIRA 		  : BRME-6660
*/
@IsTest
private class OrganizationLookupSearchTest {

    @TestSetup
    static void setupTestData() {
        Account a1 = TestDataFactory.createOrg('Major League Baseball');
        Account a2 = TestDataFactory.createOrg('Major League Baseball Foundation');
        Account a3 = TestDataFactory.createOrg('MLB Org');
        Account a4 = TestDataFactory.createOrg('Private Org');

        a1.Converted_Org_Name__c = 'Major League Baseball';
        a2.Converted_Org_Name__c = 'Major League Baseball Foundation';
        a3.AKA__c = 'MLB';
        a3.Converted_AKA__c = 'MLB';
        a3.Converted_Org_Name__c = 'MLB Org';
        a4.Name = null;
        a4.Restricted__c = true;
        a4.Restricted_Org_Name__c = 'Private League Baseball';
        a4.Converted_Org_Name__c = 'Private League Baseball';

        update new List<Account>{ a1, a2, a3, a4 };
    }

    @IsTest
    static void testEmptySearchTermReturnsEmpty() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Account';
        req.searchTerm = '';
        req.displayFields = new List<String>{ 'Name' };
        req.maxResults = 10;

        Test.startTest();
        OrganizationLookupSearch search = new OrganizationLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testExactMatchRankedFirst() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Account';
        req.searchTerm = 'Major League Baseball';
        req.displayFields = new List<String>{ 'Name' };
        req.maxResults = 10;

        Test.startTest();
        OrganizationLookupSearch search = new OrganizationLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals('Major League Baseball', results[0].fields.get('Name'));
    }

    @IsTest
    static void testAKABonus() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Account';
        req.searchTerm = 'MLB';
        req.displayFields = new List<String>{ 'Name' };
        req.maxResults = 10;

        Test.startTest();
        OrganizationLookupSearch search = new OrganizationLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals('MLB Org', results[0].fields.get('Name'));
    }

    @IsTest
    static void testNoMatchReturnsEmpty() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Account';
        req.searchTerm = 'ZZZNOEXIST';
        req.displayFields = new List<String>{ 'Name' };
        req.maxResults = 10;

        Test.startTest();
        OrganizationLookupSearch search = new OrganizationLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }
}