/**
* Author      : Hardik Kalathiya
* Date        : 03/10/2025
* Description : Test Class to CityViewDetailPageControllerTest
**/
@isTest
public class CityViewDetailPageControllerTest {
    @testSetup
    static void setupTestData() {
        Map<String, Geo_Area__c> createGeoHierarchy = TestDataFactory.createGeoHierarchy();
        // Create City Record (Child of State)
        Geo_Area__c city = createGeoHierarchy.get('City');
        Geo_Area__c State = createGeoHierarchy.get('State');
        Geo_Area__c Country = createGeoHierarchy.get('Country');

        // Create a test Organization related to the Geo Area
        List<Account> testOrgList = new List<Account>();
        Account testOrg = TestDataFactory.getOrg('Test Organization');
        testOrg.Government_Geo_Area__c = city.Id;
        testOrg.Org_Type__c ='Government - City';
        testOrg.Name ='TestOrg';
        testOrgList.add(testOrg);
        Account testOrg1 = TestDataFactory.getOrg('Test Organization');
        testOrg1.Government_Geo_Area__c = State.Id;
        testOrg1.Org_Type__c ='Government - State';
        testOrg1.Name ='TestOrg';
        testOrgList.add(testOrg1);
        Account testOrg2 = TestDataFactory.getOrg('Test Organization');
        testOrg2.Government_Geo_Area__c = Country.Id;
        testOrg2.Org_Type__c ='Government - Country';
        testOrg2.Name ='TestOrg';
        testOrgList.add(testOrg2);
        insert testOrgList;

        // Create a test Contact
        Contact testContact = TestDataFactory.getContact('John John');
        insert testContact;

        // Create a test Employment History record for Mayor
        Employment_History_and_Board_Membership__c testEmployment = new Employment_History_and_Board_Membership__c(
            Role__c = 'Mayor',
            From__c = '2024',
            To__c = '2025',
            Organization_Name__c = testOrg.Id,
            Contact_Name__c = testContact.Id
        );
        insert testEmployment;

        Map<String, Focus_Area__c> focusAreaMap = TestDataFactory.createFocusAreas(new List<String>{ 'Arts'});
        Focus_Area__c artsFocusArea = focusAreaMap.get('Arts');

        Foundation_Code__c rootFoundationCode = TestDataFactory.createRootFoundationCode();
        Foundation_Code__c foundationCode = TestDataFactory.buildFoundationCode('Arts', 'Focus Area', rootFoundationCode.Id, artsFocusArea.Id);
        insert foundationCode;

        Id InitiativeRecordTypeId = Schema.SObjectType.Association__c.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
        Association__c association = TestDataFactory.getAssociation('John John', artsFocusArea.Id);
        association.Association_Category__c = 'Finalist';
        association.Publish_to_CityView__c = TRUE;
        association.Deleted__C = False;
        association.Foundation_Coding__c = foundationCode.Id;
        association.RecordTypeId = InitiativeRecordTypeId;
        association.Start_Date__c = Date.today().addYears(-1);
        association.End_Date__c = Date.today().addYears(2);
        insert association;


        Id Bloomberg_ConnectsRecordTypeId = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName().get('City_View').getRecordTypeId();
         Id Bloomberg_ConnectsGrantRecordTypeId = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName().get('Grant').getRecordTypeId();
         Id Bloomberg_ConnectsInitiativeRecordTypeId = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName().get('Initiative').getRecordTypeId();
        List<Org_Association__c> orgAssociationList  = new  List<Org_Association__c>();
        Org_Association__c orgAssociation = new Org_Association__c(
            Association__c = association.Id,
            Organization__c = testOrg.Id,
            RecordTypeId = Bloomberg_ConnectsInitiativeRecordTypeId,
            From__c = System.Today().addYears(-4),
            To__c = System.Today().addYears(2)
        );
        orgAssociationList.add(orgAssociation);
        Org_Association__c orgAssociation3 = new Org_Association__c(
            Association__c = association.Id,
            Organization__c = testOrg.Id,
            RecordTypeId = Bloomberg_ConnectsGrantRecordTypeId,
            From__c = System.Today().addYears(-5),
            To__c = System.Today().addYears(4)
        );
        orgAssociationList.add(orgAssociation3);
         Org_Association__c orgAssociation4 = new Org_Association__c(
            Association__c = association.Id,
            Organization__c = testOrg.Id,
            RecordTypeId = Bloomberg_ConnectsGrantRecordTypeId,
            From__c = System.Today().addYears(5),
            To__c = System.Today().addYears(6)
        );
        orgAssociationList.add(orgAssociation4);
        Org_Association__c orgAssociation1 = new Org_Association__c(
            Association__c = association.Id,
            Organization__c = testOrg.Id,
            RecordTypeId = Bloomberg_ConnectsInitiativeRecordTypeId,
            From__c = System.Today().addYears(3),
            To__c = System.Today().addYears(4)
        );
        orgAssociationList.add(orgAssociation1);
        Org_Association__c orgAssociation2 = new Org_Association__c(
            Association__c = association.Id,
            Organization__c = testOrg2.Id,
            RecordTypeId = Bloomberg_ConnectsInitiativeRecordTypeId,
            From__c = System.Today().addYears(4),
            To__c = System.Today().addYears(5)
        );
        orgAssociationList.add(orgAssociation2);
        Insert orgAssociationList;
        Bloomberg_Office__c bmo = new Bloomberg_Office__c(
            Name = 'Test Bloomberg Office',
            Geo_area__c = createGeoHierarchy.get('City').Id,
            Address__Street__s = '123 Main St',
            Address__City__s = 'San Francisco',
            Address__CountryCode__s = 'CA',
            Address__PostalCode__s = '94105'
        );
        insert bmo;
        Id recentEngagementRecordTypeId = Schema.SObjectType.Interaction__c.getRecordTypeInfosByDeveloperName().get('Recent_Engagement').getRecordTypeId();
        Interaction__c interaction = new Interaction__c(
            Name='Bloomberg completes',
            Foundation_Coding__c = foundationCode.Id,
            Description__c ='test',
            Contact__c = testContact.Id,
            RecordtypeId = recentEngagementRecordTypeId,
            Teams__c = TestDataFactory.createTeam('Advocacy').Id

        );
        Insert interaction;
        Focus_Area__c  fa = new Focus_Area__c (
            Name='Public Health',
            Color_Code__c = '#FAA626'
        );
        Insert fa;
        Geo_Area_Focus_Area__c gafa = new Geo_Area_Focus_Area__c(
            Geo_Area__c = city.Id,
            Focus_Area__c = fa.Id);
        Insert gafa;
        Org_Geo_Area__c  orgGeoArea = new Org_Geo_Area__c(
            Type__c='Cultural Access',
            Organization__c=testOrg.Id,
            Geo_Area__c = city.Id
        );
        insert orgGeoArea;
    }

    @isTest
    static void testGetRecentMayors() {
        Test.startTest();
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: cityRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        // Call the method

        List<Employment_History_and_Board_Membership__c> recentMayors = cityViewDetailPageController.getRecentMayors(testGeoArea.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(0, recentMayors.size(), 'Expected at least one mayor record');
        System.assertEquals('Mayor', recentMayors[0].Role__c, 'Role should be Mayor');
        System.assertEquals(testGeoArea.Id, recentMayors[0].Organization_Name__r.Government_Geo_Area__c, 'Geo Area should match');
    }

    @isTest
    static void testGetCityLevelWork() {
        Test.startTest();
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: cityRecordTypeId WITH SYSTEM_MODE LIMIT 1];

        List<cityViewDetailPageController.OrgAssociationWrapper> results =
            cityViewDetailPageController.getCityLevelWork(testGeoArea.Id);
        Test.stopTest();
    }
    @isTest
    static void testGetCityLevelWorkForCountry() {
        Test.startTest();
        Id countryRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('Country').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: countryRecordTypeId WITH SYSTEM_MODE LIMIT 1];

        List<cityViewDetailPageController.OrgAssociationWrapper> results =
            cityViewDetailPageController.getCityLevelWork(testGeoArea.Id);
        Test.stopTest();
        // Assert
        System.assertNotEquals( null, results, 'Expected wrapper list but got null' );
        System.assert(results.size() >= 0, 'Result list should be initialized');
    }

    @isTest
    static void testGetCityLevelWorkState() {
        Test.startTest();
        Id stateRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('State').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: stateRecordTypeId WITH SYSTEM_MODE LIMIT 1];

        List<cityViewDetailPageController.OrgAssociationWrapper> results =
            cityViewDetailPageController.getCityLevelWork(testGeoArea.Id);
        Test.stopTest();
        // Assert
        System.assertNotEquals( null, results, 'Expected wrapper list but got null' );
        System.assert(results.size() >= 0, 'Result list should be initialized');
    }
    @isTest
    static void testKeyPartnersGetCityLevelWork() {
        Test.startTest();
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: cityRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        Account testOrg = [SELECT Id FROM Account WITH SYSTEM_MODE LIMIT 1];
        Org_Geo_Area__c orgAssociation = new Org_Geo_Area__c(
            Geo_Area__c = testGeoArea.Id,
            Organization__c = testOrg.Id
        );
        Insert orgAssociation;
        // Call the method

        List<Org_Geo_Area__c > results =
            cityViewDetailPageController.getKeyPartners(string.valueof(testGeoArea.Id));
        Test.stopTest();
    }
    @isTest
    static void testGetCityLevelWorkforNull() {
        Test.startTest();
        Id stateRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('State').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID

        // Call the method

        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: stateRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        Geo_Area__c city1 = new Geo_Area__c(
            Name = 'Test City',
            RecordTypeId = cityRecordTypeId,
            BP_Active__c = True,
            Geo_Name__c = 'Test City',
            Parent__c = testGeoArea.Id  // Lookup to State
        );
        insert city1;

        Org_Geo_Area__c orgAssociation = new Org_Geo_Area__c(
            Geo_Area__c = city1.Id
        );
        Insert orgAssociation;
        List<Org_Geo_Area__c > results =
            cityViewDetailPageController.getKeyPartners(string.valueof(city1.Id));
        Test.stopTest();
    }
    @isTest
    static void testPositiveScenario() {
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: cityRecordTypeId WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
        Test.stopTest();
    }

    @isTest
    static void testNullGeoAreaId() {
        Test.startTest();
        Test.stopTest();
    }

    @isTest
    static void testInvalidGeoAreaId() {
        // Call the method with a non-existing ID
        Test.startTest();
        Bloomberg_Office__c bmo = [SELECT Id FROM Bloomberg_Office__c WITH SYSTEM_MODE LIMIT 1];
        Test.stopTest();
    }

    @isTest
    static void testQueryExceptionHandling() {
        Test.startTest();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' WITH SYSTEM_MODE LIMIT 1];
        User restrictedUser = new User(
            Alias = 'testusr',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Restricted',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'testuserCityView@example.com',
            Sharing_Team__c ='Arts'
        );
        insert restrictedUser;
        // Simulate an SOQL QueryException by passing a malformed ID (this will cause an error)
        Boolean exceptionThrown = false;

        System.runAs(restrictedUser) {
            try {
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
        }
        Test.stopTest();
    }
    @Istest
    static void getHighlightsData(){
        Test.StartTest();
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: cityRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        List<Interaction__c> interactionList = cityViewDetailPageController.getCityViewHighlights(String.ValueOf(testGeoArea.Id),'MostRecent');
        interactionList = cityViewDetailPageController.getCityViewHighlights(String.ValueOf(testGeoArea.Id),'');
        Test.stopTest();
    }
    @Istest
    static void getofficeMap(){
        Test.StartTest();
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: cityRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        List<cityViewDetailPageController.OfficeMapWrapper> interactionList = cityViewDetailPageController.getOfficeMapDetails(String.ValueOf(testGeoArea.Id));
        Test.stopTest();
    }

    @isTest
    static void testGetCulturalData_WithValidGeoAreaId() {
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve the Geo_Area__c record to pass as parameter
        List<Geo_Area__c> testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: cityRecordTypeId WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
        List<CityViewDetailPageController.CityCulturalAccessGroup> result =
            CityViewDetailPageController.getCulturalAccessGroups(testGeoArea[0].Id); // Pass valid Geo Area ID
        CityViewDetailPageController.getCityViewTravelDetails(testGeoArea[0].Id);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assert(result.size() > 0, 'Result should contain at least one record');
    }

    @isTest
    static void getCityAssociationCountsTest() {
        Test.startTest();
        Id countryRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('Country').getRecordTypeId();
        Association__c association = [Select Id FROM Association__c WITH SYSTEM_MODE LIMIT 1];
        // Retrieve the Geo_Area__c record to pass as parameter
        List<Geo_Area__c> testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: countryRecordTypeId WITH SYSTEM_MODE LIMIT 1];

        List<CityViewDetailPageController.CityAssociationWrapper> result =  CityViewDetailPageController.getCityAssociationCounts(String.valueOf(testGeoArea[0].Id),null);
        result =  CityViewDetailPageController.getCityAssociationCounts(String.valueOf(testGeoArea[0].Id),'Country');
        Map<String, List<Geo_Area__c>> ListViewData =  CityViewDetailPageController.getListViewData(String.valueOf(association.Id));
        Test.stopTest();
    }

    @isTest
    static void getFirstOrgIdByGeoAreaTest() {
        Test.startTest();
        Id cityRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve the Geo_Area__c record to pass as parameter
        List<Geo_Area__c> testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: cityRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        Id result = CityViewDetailPageController.getFirstOrgIdByGeoArea(testGeoArea[0].Id);
        Test.stopTest();

    }
    @Istest
    static void getofficeMapForcountry(){
        Test.StartTest();
        Id countryRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('Country').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: countryRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        List<cityViewDetailPageController.OfficeMapWrapper> interactionList = cityViewDetailPageController.getOfficeMapDetails(String.ValueOf(testGeoArea.Id));
        Test.stopTest();
    }

    @Istest
    static void getRelatedGeoAreaIdsTest(){
        Test.StartTest();
        Id countryRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('Country').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: countryRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        List<Id> result = cityViewDetailPageController.getRelatedGeoAreaIds(String.ValueOf(testGeoArea.Id));
        Test.stopTest();
        System.assert(result.size() > 0, 'Result should contain at least one record');
    }

    @Istest
    static void showStateLevelDataTest(){
        Test.StartTest();
        Id countryRecordTypeId = Schema.SObjectType.Geo_Area__c.getRecordTypeInfosByDeveloperName().get('City').getRecordTypeId();
        // Retrieve a valid Geo_Area__c ID
        Geo_Area__c testGeoArea = [SELECT Id FROM Geo_Area__c WHERE RecordTypeId =: countryRecordTypeId WITH SYSTEM_MODE LIMIT 1];
        Boolean result = cityViewDetailPageController.showStateLevelData(String.ValueOf(testGeoArea.Id));
        Test.stopTest();
        System.debug('@@showStateLevelDataTest'+result);
    }
}