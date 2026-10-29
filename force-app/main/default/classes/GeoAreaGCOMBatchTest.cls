/**
* Author      : Ravi Bheemreddy
* Description : Test class for GeoAreaGCOMBatch
*/
@isTest
public with sharing class GeoAreaGCOMBatchTest {
	
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
        
        insert as system orgs;
        
        Map<String, Focus_Area__c> focusAreaMap = TestDataFactory.createFocusAreas(new List<String>{ 'Arts', 'Environment' });
        Focus_Area__c artsFocusArea = focusAreaMap.get('Arts');
        Focus_Area__c environmentFocusArea = focusAreaMap.get('Environment');
        
        Foundation_Code__c rootFoundationCode = TestDataFactory.createRootFoundationCode();        
        Foundation_Code__c artsCode = TestDataFactory.buildFoundationCode('Arts', 'Focus Area', rootFoundationCode.Id, artsFocusArea.Id);     
        Foundation_Code__c environmentCode = TestDataFactory.buildFoundationCode('Environment', 'Focus Area', rootFoundationCode.Id, environmentFocusArea.Id);

        List<Foundation_Code__c> foundationCodes = new List<Foundation_Code__c>{artsCode, environmentCode};
        insert as system foundationCodes;
        
        Id InitiativeRecordTypeId = Schema.SObjectType.Association__c.getRecordTypeInfosByDeveloperName().get('GCOM').getRecordTypeId();
        Association__c association = TestDataFactory.getAssociation('John John');
        association.Focus_Area__c = artsFocusArea.Id;
		association.Association_Category__c = 'Finalist';
		association.Publish_to_CityView__c = TRUE;
		association.Deleted__C = False;
		association.Active__c = TRUE;
		association.Foundation_Coding__c = foundationCodes[0].Id;
		association.RecordTypeId = InitiativeRecordTypeId;
		association.Start_Date__c = Date.today().addYears(-1);
		association.End_Date__c = Date.today().addYears(2);
        insert association;
        
        Id Bloomberg_ConnectsRecordTypeId = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName().get('GCOM').getRecordTypeId();
        
        Org_Association__c orgAssociation = new Org_Association__c(
            Association__c = association.Id,
            Organization__c = cityOrg1.Id,
            RecordTypeId = Bloomberg_ConnectsRecordTypeId,
            From__c = System.Today().addYears(-1),
            To__c = System.Today().addYears(2)
        );
        insert as system orgAssociation;
    }
    
    @isTest
    static void testGCOMBatchPositive () {
        Test.startTest();
        Database.executeBatch(new GeoAreaGCOMBatch());
        Test.stopTest();
        
         List<Geo_Area__c> geoAreas = [
            SELECT Id, Has_GCOM_Association__c FROM Geo_Area__c where RecordType.DeveloperName = 'City' WITH SYSTEM_MODE
        ];

        System.assertEquals(true, geoAreas[0].Has_GCOM_Association__c);
    }
}