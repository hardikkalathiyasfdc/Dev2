/**
* Author      : Ravi Bheemreddy  
* Description : Test class for ContactLookupSearch
* JIRA 		  : BRME-6660
*/
@IsTest
private class ContactLookupSearchTest {

    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createOrg('Test Organization');

        Contact c1 = TestDataFactory.createContact(acc.Id, 'Kim');
        Contact c2 = TestDataFactory.createContact(acc.Id, 'Taylor');
        Contact c3 = TestDataFactory.createContact(acc.Id, 'Kim');

        c1.LastName = 'Bat';
        c1.Converted_FirstName__c = 'Kim';
        c1.Converted_LastName__c = 'Bat';

        c2.LastName = 'Swift';
        c2.Converted_FirstName__c = 'Taylor';
        c2.Converted_LastName__c = 'Swift';

        c3.LastName = 'Batista';
        c3.Preferred_First_Name__c = 'Kim';
        c3.Converted_FirstName__c = 'Kim';
        c3.Converted_LastName__c = 'Batista';

        update new List<Contact>{ c1, c2, c3 };

        Contact c4 = new Contact(
            AccountId = acc.Id,
            LastName = 'Restricted',
            Restricted__c = true,
            RestrictedFirstName__c = 'Taylor',
            RestrictedLastName__c = 'Swifton',
            Converted_FirstName__c = 'Taylor',
            Converted_LastName__c = 'Swifton'
        );
        insert c4;
    }

    @IsTest
    static void testEmptySearchTermReturnsEmpty() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Contact';
        req.searchTerm = '';
        req.displayFields = new List<String>{ 'Search_Display_Name__c' };
        req.maxResults = 10;

        Test.startTest();
        ContactLookupSearch search = new ContactLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testSingleTokenExactMatch() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Contact';
        req.searchTerm = 'Swift';
        req.displayFields = new List<String>{ 'Search_Display_Name__c' };
        req.maxResults = 10;

        Test.startTest();
        ContactLookupSearch search = new ContactLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assert(results.size() > 0);
    }

    @IsTest
    static void testMultiTokenMatchReturnsResults() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Contact';
        req.searchTerm = 'Kim Bat';
        req.displayFields = new List<String>{ 'Search_Display_Name__c' };
        req.maxResults = 10;

        Test.startTest();
        ContactLookupSearch search = new ContactLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assert(results.size() > 0);
    }

    @IsTest
    static void testNoMatchReturnsEmpty() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Contact';
        req.searchTerm = 'ZZZNOEXIST';
        req.displayFields = new List<String>{ 'Search_Display_Name__c' };
        req.maxResults = 10;

        Test.startTest();
        ContactLookupSearch search = new ContactLookupSearch();
        List<GenericLookupController.LookupRecord> results = search.search(req);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }
}