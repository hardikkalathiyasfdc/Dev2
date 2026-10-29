/**
 * @description       : Test class used for Generic Lookup custom component controller (GenericLookupController)
 * @author            : Ravi Bheemreddy
 * @jira			  : BRME-6394
 **/
@IsTest
private class GenericLookupControllerTest {
    
    @TestSetup
    static void setupTestData() {
        List<Campaign> campaigns = TestDataFactory.createCampaigns(15, 'Pre_Event', true);
    }
    
    @IsTest
    static void testSearchRecords() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Campaign';
        req.searchTerm = 'Test Campaign';
        req.displayFields = new List<String>{'Name'};
        req.maxResults = 10;
        req.accessMode = 'USER_MODE';
        req.withoutSharing = false;
        
        Test.startTest();
        GenericLookupController.SearchResponse response = GenericLookupController.searchRecords(JSON.serialize(req));
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.records);
        System.assert(response.records.size() > 0);
        System.assert(response.hasMore);
    }
    
    @IsTest
    static void testSearchRecordsWithFilterAndOrder() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Campaign';
        req.searchTerm = 'Test Campaign';
        req.searchFields = new List<String>{'Name'};
        req.displayFields = new List<String>{'Name'};
        req.filterClause = 'Name LIKE \'%1%\'';
        req.orderByClause = 'Name DESC';
        req.maxResults = 10;
        req.accessMode = 'SYSTEM_MODE';
        req.withoutSharing = true;
        
        Test.startTest();
        GenericLookupController.SearchResponse response = GenericLookupController.searchRecords(JSON.serialize(req));
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assert(response.records.size() > 0);
    }
    
    @IsTest
    static void testGetRecordsByIds() {
        List<Campaign> campaigns = [SELECT Id FROM Campaign LIMIT 3];
        List<String> campaignIds = new List<String>();
        for (Campaign c : campaigns) {
            campaignIds.add(c.Id);
        }
        
        GenericLookupController.IdsRequest req = new GenericLookupController.IdsRequest();
        req.objectApiName = 'Campaign';
        req.recordIds = campaignIds;
        req.displayFields = new List<String>{'Name'};
        req.accessMode = 'USER_MODE';
        req.withoutSharing = false;
        
        Test.startTest();
        List<GenericLookupController.LookupRecord> records = GenericLookupController.getRecordsByIds(JSON.serialize(req));
        Test.stopTest();
        
        System.assertNotEquals(null, records);
        System.assertEquals(3, records.size());
    }
    
    @IsTest
    static void testGetRecordsByIdsEmpty() {
        GenericLookupController.IdsRequest req = new GenericLookupController.IdsRequest();
        req.objectApiName = 'Campaign';
        req.recordIds = new List<String>();
        req.displayFields = new List<String>{'Name'};
        req.accessMode = 'USER_MODE';
        req.withoutSharing = true;
        
        Test.startTest();
        List<GenericLookupController.LookupRecord> records = GenericLookupController.getRecordsByIds(JSON.serialize(req));
        Test.stopTest();
        
        System.assertNotEquals(null, records);
        System.assertEquals(0, records.size());
    }
    
    @IsTest
    static void testGetRecentlyViewed() {
        GenericLookupController.RecentRequest req = new GenericLookupController.RecentRequest();
        req.objectApiName = 'Campaign';
        req.displayFields = new List<String>{'Name'};
        req.filterClause = 'Name != null';
        req.maxResults = 5;
        req.accessMode = 'USER_MODE';
        req.withoutSharing = false;
        
        Test.startTest();
        List<GenericLookupController.LookupRecord> records = GenericLookupController.getRecentlyViewed(JSON.serialize(req));
        Test.stopTest();
        
        System.assertNotEquals(null, records);
    }
    
    @IsTest
    static void testGetObjectInfo() {
        Test.startTest();
        GenericLookupController.ObjectInfoResult result = GenericLookupController.getObjectInfo('Campaign');
        GenericLookupController.ObjectInfoResult invalidResult = GenericLookupController.getObjectInfo('InvalidObject__c');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('Campaign', result.apiName);
        System.assertNotEquals(null, result.label);
        System.assertNotEquals(null, invalidResult);
    }
    
    @IsTest
    static void testGetFieldSetFields() {
        Test.startTest();
        List<String> fields = GenericLookupController.getFieldSetFields('Contact', 'New_Contact');
        Test.stopTest();
        
        System.assertNotEquals(null, fields);
        System.assert(fields.size() > 0);
    }
    
    @IsTest
    static void testGetFieldSetFieldsInvalidObject() {
        Test.startTest();
        List<String> fields = GenericLookupController.getFieldSetFields('InvalidObject__c', 'New_Contact');
        Test.stopTest();
        
        System.assertNotEquals(null, fields);
        System.assertEquals(0, fields.size());
    }
    
    @isTest
    static void errorHandlingLogicTestOne () {
        try {
            GenericLookupController.getRecordsByIds(null);
        	GenericLookupController.searchRecords(null); 
        } catch (Exception e) {
            
        }
    }
    
    @isTest
    static void errorHandlingLogicTestTwo () {
        try {
        	GenericLookupController.searchRecords(null); 
        } catch (Exception e) {
            
        }
    }
    @IsTest
    static void testSearchRecordsWithCustomSearchClass() {
        TestDataFactory.createCampaigns(5, 'Pre_Event', true);
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Campaign';
        req.searchTerm = 'Test Campaign';
        req.displayFields = new List<String>{'Name'};
        req.maxResults = 10;
        req.accessMode = 'USER_MODE';
        req.withoutSharing = false;
        req.customSearchClass = 'WeightedFieldLookupSearch';
        req.searchConfig = JSON.serialize(new Map<String, Object>{
            'primaryField' => 'Name',
            'primaryWeight' => 100,
            'convertedField' => 'Converted_List_Name__c',
            'convertedWeight' => 80
        });

        Test.startTest();
        GenericLookupController.SearchResponse response = GenericLookupController.searchRecords(JSON.serialize(req));
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.records);
    }

    @IsTest
    static void testSearchRecordsWithInvalidCustomSearchClass() {
        GenericLookupController.SearchRequest req = new GenericLookupController.SearchRequest();
        req.objectApiName = 'Campaign';
        req.searchTerm = 'Test Campaign';
        req.displayFields = new List<String>{'Name'};
        req.maxResults = 10;
        req.accessMode = 'USER_MODE';
        req.withoutSharing = false;
        req.customSearchClass = 'NonExistentSearchClass';

        Test.startTest();
        GenericLookupController.SearchResponse response = GenericLookupController.searchRecords(JSON.serialize(req));
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.records);
    }

}