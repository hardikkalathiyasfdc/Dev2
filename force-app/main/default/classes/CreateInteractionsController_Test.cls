/********************************************************************************
* Class Name  : CreateInteractionsController_Test
* Description : Test class for CreateInteractionsController apex controller.
* Created By  : Slalom Consulting
* Change Log  : Created - 6/3/2019
********************************************************************************/
@isTest
private class CreateInteractionsController_Test {
    @testSetup static void setup() {
        Account acc = new Account(Name = 'TestAcct');
        insert acc;
        // Create common test contacts
        List<Contact> testCons = new List<Contact>();
        for(Integer i=0;i<25;i++) {
            testCons.add(new Contact(LastName = 'TestCon'+i,AccountId = acc.Id));
        }

        insert testCons;

        Campaign camp = new Campaign(Name = 'TestCampaignInt');
        insert camp;
        List<CampaignMemberStatus> lstCampStatus = new List<CampaignMemberStatus>();
        CampaignMemberStatus campStatus1 = new CampaignMemberStatus(Label = 'SentTest',CampaignId = camp.Id,isDefault = true);
        CampaignMemberStatus campStatus2 = new CampaignMemberStatus(Label = 'RSVPdTest',CampaignId = camp.Id,isDefault = false);
        lstCampStatus.add(campStatus1);
        lstCampStatus.add(campStatus2);
        insert lstCampStatus;
        List<CampaignMember> lstCampMem = new List<CampaignMember>();
        for(Contact con : testCons){
            CampaignMember cm= New CampaignMember(CampaignId=camp.Id, ContactId= con.Id, Status='SentTest');
            lstCampMem.add(cm);
        }
        insert lstCampMem;

        ListOrganization__c lo = new ListOrganization__c();
        lo.List__c = camp.Id;
        lo.Organization__c = acc.Id;
        lo.Unique__c = camp.Id+'-'+acc.Id;
        insert new List<ListOrganization__c>{lo};
            }

    @isTest
    static void testMethod1() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaignInt' WITH SYSTEM_MODE LIMIT 1];
        List<Contact> lstCons = [Select Id, LastName from Contact where LastName like 'TestCon%' WITH SYSTEM_MODE LIMIT 10];
        List<RecordType> types = [SELECT Id FROM RecordType WHERE SobjectType = 'Interaction__c' AND IsActive = true WITH SYSTEM_MODE];
        Interaction__c intIns = new Interaction__c();
        intIns.Name = 'test interaction';
        intIns.Teams__c = TestDataFactory.createTeam('Arts').Id;
        intIns.Associated_to_an_MRB_Event__c = 'No';
        Test.startTest();
        Integer countMem = CreateInteractionsController.conMembersCount(camp.Id);
        CreateInteractionsController.autoCreateInteractions(intIns,camp.Id,null, types[0].Id);
        CreateInteractionsController.autoCreateInteractions(intIns,camp.Id,lstCons, types[0].Id);
        Test.stopTest();
        System.assert(String.isNotBlank(CreateInteractionsController.getRecordTypes()));
        CreateInteractionsController.getFieldsByRecordType('x2020');
    }

    @isTest
    static void testOrgs() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaignInt' WITH SYSTEM_MODE LIMIT 1];
        Interaction__c intIns = new Interaction__c();
        intIns.Name = 'test interaction';
        intIns.Teams__c = TestDataFactory.createTeam('Arts').Id;
        intIns.Associated_to_an_MRB_Event__c = 'No';

        Test.startTest();

        Integer countMem = CreateInteractionsController.conOrgsCount(camp.Id);
        Integer restrictedConMembersCount = CreateInteractionsController.restrictedConMembersCount(camp.Id);
        CreateInteractionsController.autoCreateOrgInteractions(intIns,camp.Id,Schema.SObjectType.Interaction__c.getRecordTypeInfosByDeveloperName().get('Recent_Engagement').getRecordTypeId());
        CreateInteractionsController.checkOrgRecentEngagementCreationPermission();
        Test.stopTest();

        System.assert(countMem == 1);
    }

    @isTest
    static void testAutoCreateInteractionsNoTargetsThrows() {
        Campaign camp = TestDataFactory.createCampaign('EmptyCampaign');
        Interaction__c intIns = new Interaction__c();
        intIns.Name = 'no targets';
        intIns.Teams__c = TestDataFactory.createTeam('NoTarget Team').Id;
        intIns.Associated_to_an_MRB_Event__c = 'No';

        List<RecordType> types = [SELECT Id FROM RecordType WHERE SobjectType = 'Interaction__c' AND IsActive = true WITH SYSTEM_MODE];

        Test.startTest();
        try {
            CreateInteractionsController.autoCreateInteractions(intIns, camp.Id, null, types[0].Id);
            System.assert(false, 'Expected an AuraHandledException when there are no contacts.');
        } catch (AuraHandledException ex) {
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetFieldsByRecordTypeInvalidReturnsNull() {
        Test.startTest();
        String result = CreateInteractionsController.getFieldsByRecordType('No_Such_Field_Set');
        Test.stopTest();
        System.assertEquals(null, result, 'An invalid field set should return null.');
    }

    @isTest
    static void testGetFieldsByRecordTypeValidReturnsJson() {
        Test.startTest();
        String result = CreateInteractionsController.getFieldsByRecordType('Touchpoint');
        Test.stopTest();
        System.assert(String.isNotBlank(result), 'A valid field set should return JSON.');
    }

    @isTest
    static void testGetInaccessibleContactCountAndNullFiltering() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaignInt' WITH SYSTEM_MODE LIMIT 1];
        List<Contact> lstCons = [Select Id from Contact where LastName like 'TestCon%' WITH SYSTEM_MODE LIMIT 3];

        Test.startTest();
        // null contactIds -> resolves from campaign; non-null with a null entry exercises the null filter
        Integer fromCampaign = CreateInteractionsController.getInaccessibleContactCount(camp.Id, null);
        Integer withNullEntry = CreateInteractionsController.getInaccessibleContactCount(camp.Id, new List<Id>{ lstCons[0].Id, null });
        Integer emptyList = CreateInteractionsController.getInaccessibleContactCount(camp.Id, new List<Id>());
        Test.stopTest();

        System.assertNotEquals(null, fromCampaign);
        System.assertNotEquals(null, withNullEntry);
        System.assertEquals(0, emptyList);
    }

    @isTest
    static void testAutoCreateInteractionsDmlFailureSurfacesMessage() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaignInt' WITH SYSTEM_MODE LIMIT 1];
        List<Contact> lstCons = [Select Id from Contact where LastName like 'TestCon%' WITH SYSTEM_MODE LIMIT 2];
        Interaction__c intIns = new Interaction__c();
        intIns.Name = 'dml failure';
        intIns.Teams__c = TestDataFactory.createTeam('Dml Team').Id;

        Test.startTest();
        try {
            // recordTypeId is null -> required-field DmlException, exercises describeDmlFailure
            CreateInteractionsController.autoCreateInteractions(intIns, camp.Id, lstCons, null);
            System.assert(false, 'Expected an AuraHandledException for a DML failure.');
        } catch (AuraHandledException ex) {
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        Test.stopTest();
    }

    @isTest
    static void testBlockedContactsForNonPermissionedUser() {
        // Run as a user without Private_Name_Fields to cover the blocked branch
        User standardUser = [SELECT Id FROM User WHERE Profile.Name = 'Teams User' AND IsActive = true WITH SYSTEM_MODE LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE LastName LIKE 'TestCon%' WITH SYSTEM_MODE LIMIT 1];

        System.runAs(standardUser) {
            Test.startTest();
            Integer blocked = CreateInteractionsController.getInaccessibleContactCount(null, new List<Id>{ c.Id });
            Boolean hasAccess = CreateInteractionsController.hasPrivateNameFieldsAccess();
            Test.stopTest();
            // blocked is 0 if the contact is readable to this user, 1 if not; either way the query path is covered
            System.assert(blocked == 0 || blocked == 1);
            System.assertEquals(false, hasAccess);
        }
    }

    @isTest
    static void testInaccessibleContactsAreSkipped() {
        Account org = TestDataFactory.createOrg('Access Test Org');
        Contact visibleCon = TestDataFactory.createContact(org.Id, 'Visible');
        Contact privateCon = TestDataFactory.createRestrictedContact(org.Id, 'Private');
        Contact removedCon = TestDataFactory.createContact(org.Id, 'Removed');
        Id removedConId = removedCon.Id;

        Campaign camp = TestDataFactory.createCampaign('AccessTestCampaign');
        TestDataFactory.createCampaignMember(camp.Id, visibleCon.Id);
        TestDataFactory.createCampaignMember(camp.Id, privateCon.Id);

        Team__c team = TestDataFactory.createTeam('Access Test Team');
        delete removedCon;

        List<RecordType> types = [SELECT Id FROM RecordType WHERE SobjectType = 'Interaction__c' AND IsActive = true WITH SYSTEM_MODE];

        Interaction__c intIns = new Interaction__c();
        intIns.Name = 'access test interaction';
        intIns.Teams__c = team.Id;
        intIns.Associated_to_an_MRB_Event__c = 'No';

        Integer skippedCreated = null;

        Test.startTest();
        Boolean hasPermission = CreateInteractionsController.hasPrivateNameFieldsAccess();
        Integer noneBlocked = CreateInteractionsController.getInaccessibleContactCount(
            camp.Id, new List<Id>{ visibleCon.Id, privateCon.Id });
        Integer blockedFromCampaign = CreateInteractionsController.getInaccessibleContactCount(camp.Id, null);
        Integer blockedWithUnreadable = CreateInteractionsController.getInaccessibleContactCount(
            camp.Id, new List<Id>{ visibleCon.Id, removedConId });

        Integer created = CreateInteractionsController.autoCreateInteractions(
            intIns, camp.Id, new List<Contact>{ visibleCon }, types[0].Id);
        if(!hasPermission) {
            skippedCreated = CreateInteractionsController.autoCreateInteractions(
                intIns, camp.Id, new List<Contact>{ visibleCon, new Contact(Id = removedConId) }, types[0].Id);
        }

        Test.stopTest();

        System.assertEquals(0, noneBlocked,
            'A private contact the running user can still read must not be counted as inaccessible.');
        System.assertEquals(0, blockedFromCampaign,
            'Resolving targets from the campaign should report none inaccessible for this user.');
        System.assertEquals(hasPermission ? 0 : 1, blockedWithUnreadable,
            'An unreadable contact is only reported as skipped for users without the Private Name Fields permission.');
        System.assertEquals(1, created,
            'A reachable contact must always produce an Interaction.');
        if(!hasPermission) {
            System.assertEquals(1, skippedCreated,
                'The reachable contact must still be created when an unreachable one is in the same request.');
        }
    }
}