/**
* Author      : Ravi Bheemreddy
* Description : Test class for GeoAreaFocusAreaBatch
*/
@isTest
private with sharing class GeoAreaFocusAreaBatchTest {
    @testSetup
    static void setupTestData() {
        Geo_Area__c continent = TestDataFactory.createGeoAreaByRecordType('Continent', 'North America');
        insert as system continent;
        Geo_Area__c country = TestDataFactory.createGeoAreaByRecordType('Country', 'United States');
        country.Parent__c = continent.Id;
        insert as system country;
        Geo_Area__c state = TestDataFactory.createGeoAreaByRecordType('State', 'Newyork State');
        state.Parent__c = country.Id;
        insert as system state;
        Geo_Area__c city = TestDataFactory.createGeoAreaByRecordType('City', 'Newyork');
        city.Parent__c = state.Id;
        insert as system city;
        Account testOrg = TestDataFactory.getOrg('Test Organization');
        testOrg.Government_Geo_Area__c = city.Id; 
        testOrg.Org_Type__c ='Government - City';
        insert as system testOrg;
        
        Map<String, Focus_Area__c> focusAreaMap = TestDataFactory.createFocusAreas(new List<String>{ 'Arts'});
        Focus_Area__c artsFocusArea = focusAreaMap.get('Arts');



        
        Foundation_Code__c rootFoundationCode = TestDataFactory.createRootFoundationCode();
        Foundation_Code__c foundationCode = TestDataFactory.buildFoundationCode('Arts', 'Focus Area', rootFoundationCode.Id, artsFocusArea.Id);
        insert as system foundationCode;
        
        Id InitiativeRecordTypeId = Schema.SObjectType.Association__c.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
        Association__c association = TestDataFactory.getAssociation('John John');
		association.Association_Category__c = 'Finalist';
		association.Publish_to_CityView__c = TRUE;
		association.Deleted__C = False;
		association.Active__c = TRUE;
		association.Foundation_Coding__c = foundationCode.Id;
		association.RecordTypeId = InitiativeRecordTypeId;
		association.Start_Date__c = Date.today().addYears(-1);
		association.End_Date__c = Date.today().addYears(2);
        association.Focus_Area__c = artsFocusArea.Id;
        insert as system association;
        
        Id Bloomberg_ConnectsRecordTypeId = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName().get('City_View').getRecordTypeId();
        
        Org_Association__c orgAssociation = new Org_Association__c(
            Association__c = association.Id,
            Organization__c = testOrg.Id,
            RecordTypeId = Bloomberg_ConnectsRecordTypeId,
            From__c = System.Today().addYears(-1),
            To__c = System.Today().addYears(2)
        );
        insert as system orgAssociation;






















        
        List<Focus_Area__c> faList = TestDataFactory.createFocusAreas();




    }
    
    @isTest
    static void testGeoAreaFocusAreaBatch_Success() {
        List<Geo_Area_Focus_Area__c> records1 = [SELECT Geo_Area__c, Focus_Area__c, Association_Count__c FROM Geo_Area_Focus_Area__c WITH SYSTEM_MODE];
        Test.startTest();
        GeoAreaFocusAreaBatch batchJob = new GeoAreaFocusAreaBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();

        List<Geo_Area_Focus_Area__c> records = [SELECT Geo_Area__c, Focus_Area__c, Association_Count__c FROM Geo_Area_Focus_Area__c WITH SYSTEM_MODE];
        System.assertEquals(1, records.size(), 'Two Geo_Area_Focus_Area__c record should be created');

        for (Geo_Area_Focus_Area__c gaf : records) {
            System.assertEquals(1, gaf.Association_Count__c, 'City should have 1 associated record');
        }
    }

    @isTest
    static void testGeoAreaFocusAreaBatch_NoData() {
        delete as system [SELECT Id FROM Org_Association__c WITH SYSTEM_MODE];
        delete as system [SELECT Id FROM Association__c WITH SYSTEM_MODE];
        delete as system [SELECT Id FROM Geo_Area__c WITH SYSTEM_MODE];
        
        Test.startTest();
        GeoAreaFocusAreaBatch batchJob = new GeoAreaFocusAreaBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Geo_Area_Focus_Area__c WITH SYSTEM_MODE];
        System.assertEquals(0, count, 'No Geo_Area_Focus_Area__c records should be created when there is no data');
    }
    
    @IsTest
    static void testGeoAreaFocusAreaBatch_execute_catch_only() {
        Test.startTest();
        	new GeoAreaFocusAreaBatch().execute(null, (List<Account>)null);
         	GeoAreaFocusAreaBatch batchJob = new GeoAreaFocusAreaBatch();
        	batchJob.processCounts((Set<Id>)null, false);
        Test.stopTest();
    }
}