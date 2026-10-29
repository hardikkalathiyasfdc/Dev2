/**
* Author      : Nishant Bakhrey
* Description : Test class for GeoAreaOfficeBatch
*/
@isTest
public with sharing class GeoAreaOfficeBatchTest {
    
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
        
        List<Bloomberg_Office__c> offices = new List<Bloomberg_Office__c>();
        for(Integer i = 0; i < 2; i++) {
            offices.add(new Bloomberg_Office__c(Name = 'Office ' + i, Geo_Area__c = city.Id));
        }
        
        insert as system offices;
        
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
    }
    
    @isTest
    static void testGeoAreaOfficeBatch() {
        Test.startTest();
        GeoAreaOfficeBatch batch = new GeoAreaOfficeBatch();
        Database.executeBatch(batch, 50);
        Test.stopTest();
        List<Geo_Area_Focus_Area__c> gafas = [
            SELECT Id, Geo_Area__c, Office_Count__c 
            FROM Geo_Area_Focus_Area__c WITH SYSTEM_MODE
        ];
        System.assertEquals(2, gafas[0].Office_Count__c, 'Office_Count__c should be 2');
    }
}