@isTest
public with sharing class CityViewControllerTest {
    
    @testSetup
    static void setupTestData() {
        Map<String, Geo_Area__c> createGeoHierarchy = TestDataFactory.createGeoHierarchy();
        Geo_Area__c city = createGeoHierarchy.get('City');  
        // Create a test Organization related to the Geo Area
        Account testOrg = TestDataFactory.getOrg('Test Organization');
        testOrg.Government_Geo_Area__c = city.Id;
        testOrg.Org_Type__c ='Government - City';
        insert as system testOrg;
        
        Focus_Area__c  fa = new Focus_Area__c (
            Name='Public Health',
            Color_Code__c = '#FAA626'
        );
        Insert as system fa;
        Geo_Area_Focus_Area__c gafa =   [SELECT ID, Focus_Area__c FROM Geo_Area_Focus_Area__c WHERE Geo_Area__c =: city.Id WITH SYSTEM_MODE LIMIT 1];
        gafa.Focus_Area__c = fa.Id;
        update as system gafa;
        Org_Geo_Area__c  orgGeoArea = new Org_Geo_Area__c(
            Type__c='Cultural Access',
            Organization__c=testOrg.Id,
            Geo_Area__c = city.Id
        );
        insert as system orgGeoArea;
    }
    
    @isTest
    static void testGetCityViewMarkersData() {
        Test.startTest();
        List<Geo_Area_Focus_Area__c> results = CityViewController.getCityViewMarkersData();
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Expected markers to be returned');
        List<Focus_Area__c> results2 = CityViewController.getCityViewFocusAreas(); 
        System.assertEquals(0, results2.size(), 'Expected no FOCUS AREA to be returned');
    }
    
    @isTest
    static void testGetGeoArea() {
        Geo_Area__c city = [SELECT Id FROM Geo_Area__c WITH SYSTEM_MODE LIMIT 1];
        
        Test.startTest();
        Geo_Area__c result = CityViewController.getGeoArea(city.Id);
        Test.stopTest();
        
        System.assertEquals(city.Id, result.Id, 'Geo Area Id should match');
        
    }
    
}