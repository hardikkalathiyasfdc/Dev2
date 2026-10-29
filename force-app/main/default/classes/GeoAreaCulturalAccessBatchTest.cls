/**
* Author      : Ravi Bheemreddy
* Description : Test class for GeoAreaCulturalAccessBatch
*/

@isTest
private with sharing class GeoAreaCulturalAccessBatchTest {
    @testSetup
    static void setupData() {
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
        
        List<Account> orgs = new List<Account> ();
        
        Account cityOrg1 = TestDataFactory.getOrg('Test City Organization 1');
        cityOrg1.Government_Geo_Area__c = city.Id; 
        cityOrg1.Org_Type__c ='Government - City';
        orgs.add(cityOrg1);
        
        Account cityOrg2 = TestDataFactory.getOrg('Test City Organization 2');
        orgs.add(cityOrg2);
        
        Account cityOrg3 = TestDataFactory.getOrg('Test City Organization 3');
        orgs.add(cityOrg3);
        
        Account cityOrg4 = TestDataFactory.getOrg('Test City Organization 4');
        orgs.add(cityOrg4);
        
        insert as system orgs;

        List<Org_Geo_Area__c> orgGeoAreas = new List<Org_Geo_Area__c>();
        orgGeoAreas.add(TestDataFactory.createOrgGeoAreabyType(
			Assets.ORGGEOAREACULTURALACCESS,
            cityOrg2.Id,
            city.Id
        ));
        
        orgGeoAreas.add(TestDataFactory.createOrgGeoAreabyType(
			Assets.ORGGEOAREACULTURALIMPLICIT,
            cityOrg1.Id,
            city.Id
        ));
        
        orgGeoAreas.add(TestDataFactory.createOrgGeoAreabyType(
			Assets.ORGGEOAREAKEYPARTNER,
            cityOrg4.Id,
            city.Id
        ));
        
        insert as system orgGeoAreas;
    }

    @isTest
    static void testBatchCreatesOrUpdatesFocusArea() {
        Test.startTest();
        Database.executeBatch(new GeoAreaCulturalAccessBatch());
        Test.stopTest();

        List<Geo_Area_Focus_Area__c> focusAreas = [
            SELECT Id, Geo_Area__c, Cultural_Access_Count__c
            FROM Geo_Area_Focus_Area__c WITH SYSTEM_MODE
        ];

        System.assertEquals(3, focusAreas.size(), 'Expected one Geo_Area_Focus_Area__c record');
        System.assertEquals(2, focusAreas[0].Cultural_Access_Count__c, 'Cultural_Access_Count__c should be 2');
    }
    
    @IsTest
    static void execute_catch_only() {
        Test.startTest();
        try {
            new GeoAreaCulturalAccessBatch().execute(null, (List<Account>)null);
        } catch (Exception e) {
            
        }
        	
        Test.stopTest();
    }
}