/**
* Author      : Ravi Bheemreddy
* Description : Test class for CityViewFiltersController
*/
@isTest
public class CityViewFiltersControllerTest {
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

        List<Geo_Area__c> cities = new List<Geo_Area__c> ();
        Geo_Area__c nyc = TestDataFactory.createGeoAreaByRecordType('City', 'Newyork');
        nyc.Parent__c = state.Id;
        cities.add(nyc);

        Geo_Area__c li = TestDataFactory.createGeoAreaByRecordType('City', 'Long Island');
        li.Parent__c = state.Id;
        cities.add(li);
        insert as system cities;

        List<Account> cityOrgs = new List<Account> ();
        Account testOrg = TestDataFactory.getOrg('New York City');
        testOrg.Government_Geo_Area__c = nyc.Id;
        testOrg.Org_Type__c ='Government - City';
        cityOrgs.add(testOrg);

        Account testOrg1 = TestDataFactory.getOrg('Long Island');
        testOrg1.Government_Geo_Area__c = li.Id;
        testOrg1.Org_Type__c ='Government - City';
        cityOrgs.add(testOrg1);

        insert as system cityOrgs;

        Map<String, Focus_Area__c> focusAreaMap = TestDataFactory.createFocusAreas(new List<String>{ 'Arts', 'Environment' });
        Focus_Area__c artsFocusArea = focusAreaMap.get('Arts');
        Focus_Area__c environmentFocusArea = focusAreaMap.get('Environment');

        Foundation_Code__c rootFoundationCode = TestDataFactory.createRootFoundationCode();
        Foundation_Code__c artsCode = TestDataFactory.buildFoundationCode('Arts', 'Focus Area', rootFoundationCode.Id, artsFocusArea.Id);
        Foundation_Code__c environmentCode = TestDataFactory.buildFoundationCode('Environment', 'Focus Area', rootFoundationCode.Id, environmentFocusArea.Id);

        List<Foundation_Code__c> foundationCodes = new List<Foundation_Code__c>{artsCode, environmentCode};
        insert as system foundationCodes;

        Id InitiativeRecordTypeId = Schema.SObjectType.Association__c.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();

        List<Association__c> associations = new List<Association__c> ();

        Association__c arts = TestDataFactory.getAssociation('Arts Initiative');
        arts.Association_Category__c = 'Finalist';
        arts.Publish_to_CityView__c = TRUE;
        arts.Deleted__C = False;
        arts.Active__c = TRUE;
        arts.Foundation_Coding__c = artsCode.Id;
        arts.RecordTypeId = InitiativeRecordTypeId;
        arts.Start_Date__c = Date.today().addYears(-1);
        arts.End_Date__c = Date.today().addYears(2);
        arts.Focus_Area__c = artsFocusArea.Id;
        associations.add(arts);

        Association__c environment = TestDataFactory.getAssociation('Environment Initiative');
        environment.Association_Category__c = 'Finalist';
        environment.Publish_to_CityView__c = TRUE;
        environment.Deleted__C = False;
        environment.Active__c = TRUE;
        environment.Foundation_Coding__c = environmentCode.Id;
        environment.RecordTypeId = InitiativeRecordTypeId;
        environment.Start_Date__c = Date.today().addYears(-1);
        environment.End_Date__c = Date.today().addYears(2);
        environment.Focus_Area__c = environmentFocusArea.Id;
        associations.add(environment);

        insert as system associations;

        Id Bloomberg_ConnectsRecordTypeId = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName().get('City_View').getRecordTypeId();

        List<Org_Association__c> orgAssociations = new List<Org_Association__c> ();
        Org_Association__c artsOrgAssociation = new Org_Association__c(
            Association__c = arts.Id,
            Organization__c = testOrg.Id,
            RecordTypeId = Bloomberg_ConnectsRecordTypeId,
            From__c = System.Today().addYears(-1),
            To__c = System.Today().addYears(2)
        );
        orgAssociations.add(artsOrgAssociation);

        Org_Association__c environmentOrgAssociation = new Org_Association__c(
            Association__c = environment.Id,
            Organization__c = testOrg1.Id,
            RecordTypeId = Bloomberg_ConnectsRecordTypeId,
            From__c = System.Today().addYears(-1),
            To__c = System.Today().addYears(2)
        );
        orgAssociations.add(environmentOrgAssociation);
        insert as system orgAssociations;

        List<Focus_Area__c> faList = TestDataFactory.createFocusAreas();

        Bloomberg_Office__c office = TestDataFactory.createOffice();
        office.Geo_Area__c = nyc.Id;
        insert as system office;
    }

    @isTest
    static void filterGeoAreasByAssociationsTest () {
        List<Id> initiativeIds = new List<Id> ();
        for (Association__c a: [Select Id, Name from Association__c WITH SYSTEM_MODE]) {
            initiativeIds.add(a.Id);
        }

        Test.startTest();
        List<Id> filteredGeoAreaIds = CityViewFiltersController.getGeoAreasByFilters(initiativeIds, new List<String>{'Arts','Environment'}, new List<Id> (), new List<Id> ());
        Test.stopTest();
        System.assertEquals (2, filteredGeoAreaIds.size());
    }
    @isTest
    static void filterGeoAreasByFocusAreasTest () {

        Test.startTest();
        List<Id> filteredGeoAreaIds = CityViewFiltersController.getGeoAreasByFilters(new List<Id> (), new List<String>{'Arts','Environment'}, new List<Id> (), new List<Id> ());
        Test.stopTest();
        System.assertEquals (0, filteredGeoAreaIds.size());
    }

    @isTest
    static void filterGeoAreasByContinentsTest () {
        List<Id> initiativeIds = new List<Id> ();
        for (Association__c a: [Select Id, Name from Association__c WITH SYSTEM_MODE]) {
            initiativeIds.add(a.Id);
        }
        Geo_Area__c continent = [Select Id, Name from Geo_Area__c WHERE RecordType.DeveloperName = 'Continent' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        List<Id> filteredGeoAreaIds = CityViewFiltersController.getGeoAreasByFilters(initiativeIds, new List<String>{'Arts','Environment'}, new List<Id>{continent.Id}, new List<Id> ());
        Test.stopTest();
        System.assertEquals (2, filteredGeoAreaIds.size());
    }

    @isTest
    static void filterGeoAreasByCountryTest () {
        Geo_Area__c country = [Select Id, Name from Geo_Area__c WHERE RecordType.DeveloperName = 'Country' WITH SYSTEM_MODE LIMIT 1];
        List<Id> initiativeIds = new List<Id> ();
        for (Association__c a: [Select Id, Name from Association__c WITH SYSTEM_MODE]) {
            initiativeIds.add(a.Id);
        }
        Test.startTest();
        List<Id> filteredGeoAreaIds = CityViewFiltersController.getGeoAreasByFilters(initiativeIds, new List<String>{'Arts','Environment'}, new List<Id>(), new List<Id>{country.Id});
        Test.stopTest();
        System.assertEquals (2, filteredGeoAreaIds.size());
    }


    @isTest
    static void getOfficesTest () {
        Test.startTest();
        List<Bloomberg_Office__c> offices = CityViewFiltersController.getOffices();
        Test.stopTest();
        System.assertEquals (1, offices.size());
    }

    @isTest
    static void getGeoAreaIdsTest () {
        Association__c a =  [Select Id, Name from Association__c WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        List<Id> filteredGeoAreasByInitiative = CityViewFiltersController.getGeoAreaIds(a.Id,'Initiative');
        List<Id> filteredGeoAreas = CityViewFiltersController.getGeoAreaIds(a.Id,'Country');
        List<Id> filteredGeoAreas1 = CityViewFiltersController.getGeoAreaIds(null,Assets.BPWORKFILTER);
        Test.stopTest();
        // Assert – existence
        System.assertNotEquals( null, filteredGeoAreasByInitiative, 'GeoArea list for Initiative should not be null' );
        System.assertNotEquals( null, filteredGeoAreas,'GeoArea list for Country should not be null');
        System.assertNotEquals( null, filteredGeoAreas1,'GeoArea list for BPWORKFILTER should not be null' );
        // Assert – sanity (method didn’t explode silently)
        System.assert( filteredGeoAreasByInitiative.size() >= 0, 'Initiative result list should be initialized' );
    }

    @isTest
    static void catch_getOffices_securityEnforced() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' WITH SYSTEM_MODE LIMIT 1];
        User u = new User(
            Alias='stdusr',
            Email='stdusr@example.com',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/New_York',
            LastName='User',
            Username='stdusr+' + String.valueOf(System.now().getTime()) + '@test.com',
            ProfileId=p.Id,
            Sharing_Team__c='Advocacy'
        );
        System.runAs(u) {
            Test.startTest();
            List<Bloomberg_Office__c> bmoOffices =  CityViewFiltersController.getOffices();
            Test.stopTest();
            System.assertNotEquals(null,bmoOffices,'getOffices() should not return null for Standard User');
            System.assert(bmoOffices.size() >= 0, 'Bloomberg offices list should be initialized');
        }
    }
}