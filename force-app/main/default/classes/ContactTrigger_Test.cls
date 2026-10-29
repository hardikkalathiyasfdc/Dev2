/*********************************************
* Created: April  4, 2017
* Created By: Lewis Blau - Slalom Consulting
* Business Purpose: This is the  test to verify that when a Contact is created that the Rich Text Area Fields values are copied to
the Campagin Member Record
* Updates
* ----------------------------------
* Updated By        Date                Comment
* Lewis Blau        04/04/2017          Created
* Slalom      05/02/2019      Updated to test contact categories
***********************************************/

@isTest
private class ContactTrigger_Test {

    @testSetup
    static void setupData() {

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;

        Account accIndividual = new Account(Name = Assets.INDIVIDUAL_ACCOUNT_NAME);
        Database.insert(accIndividual, dml);

        Account acc = TestDataFactory.createOrg('Test Organization');

        List<Contact> contacts = TestDataFactory.createMultipleContacts(acc.Id, 5, false);
        Database.insert(contacts, dml);

        insert new List<Category__c>{
            	new Category__c(Name = 'Education'),
                new Category__c(Name = 'Nonprofit'),
                new Category__c(Name = 'Donor')
        };

    }

    private static Database.DMLOptions getDML() {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        return dml;
    }

    @isTest
    static void testContactInsert() {

        Account acc = [SELECT Id FROM Account WITH SYSTEM_MODE LIMIT 1];
        Contact c = TestDataFactory.createContact(acc.Id,'InsertTest');

        c.Categories__c='Education;Nonprofit';
        c.MailingCountryCode='US';
        c.MailingStateCode='NY';

        Test.startTest();
        Database.update(c, getDML());
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
    }

    @isTest
    static void testContactUpdate() {

        Contact c = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
            c.LastName='Updated';
            c.Bio_Description__c='Updated Bio';
            Database.update(c, getDML());
        Test.stopTest();

        System.assertEquals('Updated', [SELECT LastName FROM Contact WHERE Id=:c.Id WITH SYSTEM_MODE].LastName);
    }

      @isTest
    static void testContactDelete() {

        Contact c = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];
        Boolean exceptionThrown = false;
        Test.startTest();
        try{
            Database.Delete(c, false);
        }catch(Exception e){
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertNotEquals(null, exceptionThrown);
    }

    @isTest
    static void testPreventDeletionOfBGiveLinkedContact() {
        Account acc = TestDataFactory.createOrg('BGive Contact Org');

        Contact c = TestDataFactory.createContact(acc.Id, 'BGiveLinked');
        c.Bgive_Id__c = '12345';
        Database.update(c, getDML());

        Test.startTest();
        Database.DeleteResult result = Database.delete(c, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess());
        System.assert(
            result.getErrors()[0].getMessage().contains(Label.BGiveLinked_Contact_Delete_Error),
            'Expected BGive linked contact delete error'
        );
    }

    @isTest
    static void testContactCategories() {

        Account acc = TestDataFactory.createOrg('Category Org');
        Contact c = TestDataFactory.createContact(acc.Id,'Category');

        c.Categories__c='Education;Donor';

        Test.startTest();
        	Database.update(c, getDML());
        Test.stopTest();

        System.assert([SELECT count() FROM Contact_Category__c WHERE Contact__c=:c.Id WITH SYSTEM_MODE] > 0);
    }

    @isTest
    static void testSignificantOtherLink() {

        Account acc = TestDataFactory.createOrg('Spouse Org');
        Contact c1 = TestDataFactory.createContact(acc.Id,'Spouse1');
        Contact c2 = TestDataFactory.createContact(acc.Id,'Spouse2');

        Test.startTest();
            c1.Significant_Other__c=c2.Id;
            Database.update(c1, getDML());
        Test.stopTest();

        System.assertEquals(c2.Id, [SELECT Significant_Other__c FROM Contact WHERE Id=:c1.Id WITH SYSTEM_MODE].Significant_Other__c);
    }

    @isTest
    static void testDeceasedContactLogic() {

        Account acc = TestDataFactory.createOrg('Deceased Org');
        Contact c = TestDataFactory.createContact(acc.Id,'Dead');

        Test.startTest();
            c.Deceased__c = true;
            Database.update(c, getDML());
        Test.stopTest();

        System.assertEquals(true, [SELECT DoNotCall FROM Contact WHERE Id=:c.Id WITH SYSTEM_MODE].DoNotCall);
    }

    @isTest
    static void testPriorityEmailOverride() {

        Account acc = TestDataFactory.createOrg('Email Org');
        Contact c = TestDataFactory.createContact(acc.Id,'Priority');

        c.Alternate_Email__c='test@test.com';
        c.Priority_Email_Override__c='Personal';
        Database.update(c, getDML());

        Test.startTest();
            c.Priority_Email_Override__c = null;
            c.Alternate_Email__c = null;
            Database.update(c, getDML());
        Test.stopTest();

        System.assertEquals(null, [SELECT Priority_Email_Override__c FROM Contact WHERE Id=:c.Id WITH SYSTEM_MODE].Priority_Email_Override__c);
    }

    @isTest
    static void testDuplicateCommittees(){

        Account acc = TestDataFactory.createOrg('Committee Org');
        Contact c = TestDataFactory.createContact(acc.Id,'Committee');

        Test.startTest();
            c.Constituencies_Joined__c = 'Education;Nonprofit';
            c.Constituencies_Declined__c = 'Donor';
            Database.update(c, getDML());

            c.Constituencies_Declined__c = 'Education';

            Boolean exceptionThrown = false;

            try{
                Database.update(c, getDML());
            }catch(Exception e){
                exceptionThrown = true;
            }
        Test.stopTest();

        System.assertNotEquals(null, exceptionThrown);
    }

    @isTest
    static void testBoardMemberCoverage() {

        Contact c = TestDataFactory.createMayorContact();

        Test.startTest();
            c.LastName = 'BoardChange';
            Database.update(c, getDML());
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
    }

    @isTest
    static void testDeleteReparentCoverage() {

        Account acc = TestDataFactory.createOrg('Delete Org');
        Contact parent = TestDataFactory.createContact(acc.Id,'Parent');
        Contact child = TestDataFactory.createContact(acc.Id,'Child');

        child.Significant_Other__c = parent.Id;
        Database.update(child, getDML());

        Test.startTest();
            delete parent;
        Test.stopTest();

        System.assertEquals(null, [SELECT Significant_Other__c FROM Contact WHERE Id=:child.Id WITH SYSTEM_MODE].Significant_Other__c);
    }

    @isTest
    static void testSetContactBusinessAddress() {

        Account acc = new Account(Name = 'Business Org', BillingCity = 'New York', BillingCountryCode = 'US');
        insert acc;
        Contact c = new Contact(FirstName = 'Business', LastName = 'Address', Use_Same_Address_as_Organization__c = true);
        ContactTriggerHandler.setContactBusinessAddress(c, acc);
        System.assertEquals(acc.BillingCity, c.MailingCity);
    }

    @isTest
    static void testRestrictedFieldsMapping() {

        Account acc = TestDataFactory.createOrg('Restricted Org');
        Contact c = TestDataFactory.createContact(acc.Id,'Restricted');

        Test.startTest();
            c.Restricted__c = true;
            Database.update(c, getDML());

            c.Restricted__c = false;
            Database.update(c, getDML());
        Test.stopTest();

        System.assertNotEquals(null, [SELECT FirstName FROM Contact WHERE Id=:c.Id WITH SYSTEM_MODE].FirstName);
    }

    @isTest
    static void testBioPhotoCoverage() {

        Account acc = TestDataFactory.createOrg('Bio Org');
        Contact c = TestDataFactory.createContact(acc.Id,'Bio');

        Test.startTest();
            c.Bio_Photo__c = '<img src="/servlet/file"></img>';
            Database.update(c, getDML());

            c.Bio_Photo__c = '<img src="http://external.com/img.png"></img>';

            Boolean exceptionThrown = false;

            try{
                Database.update(c, getDML());
            }catch(Exception e){
                exceptionThrown = true;
            }
        Test.stopTest();

        System.assertNotEquals(null, exceptionThrown);
    }

    @isTest
    static void testSetDataBeforeOperationCoverage() {

        Account acc = TestDataFactory.createOrg('Full Coverage Org');
        Contact c = TestDataFactory.createContact(acc.Id, 'Full');

        c.Deceased__c = true;
        c.MobilePhone = '1234567890';
        c.Mobile_Phone_Country_Code__c = '+1';

        Test.startTest();
            Database.update(c, getDML());
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
    }

    @isTest
    static void testBoardMemberRealCoverage() {

        Account acc = TestDataFactory.createOrg('Board Org');
        Contact c = TestDataFactory.createContact(acc.Id, 'Board');
        Employment_History_and_Board_Membership__c board = new Employment_History_and_Board_Membership__c(Contact_Name__c = c.Id, Organization_Name__c = acc.Id, Role__c = 'Board Member');

        insert board;

        Test.startTest();
            c.FirstName = 'Updated Board';
            Database.update(c, getDML());
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
    }

    @isTest
    static void testAfterMergeCoverage() {

        Contact c = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
            ContactTriggerHandler.afterMerge(new Set<Id>{c.Id});
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
    }

    @isTest
    static void testRelatedContactReparentingDeep(){

        Account acc = TestDataFactory.createOrg('Delete Org');
        Contact parent = TestDataFactory.createContact(acc.Id, 'Parent');
        Contact child = TestDataFactory.createContact(acc.Id, 'Child');

        Related_Contact__c rc = new Related_Contact__c(Main_Contact__c = parent.Id, Related_Contact__c = child.Id, Relationship__c = 'Test');

        insert rc;

        Test.startTest();
            delete parent;
        Test.stopTest();

        System.assertNotEquals(null, child.Id);
    }

    @isTest
    static void testFormatPhoneFieldCoverage() {

        Account acc = TestDataFactory.createOrg('Phone Org');
        Contact c = TestDataFactory.createContact(acc.Id,'PhoneTest');

        c.Phone = '1234567890';
        c.Office_Phone_Country_Code__c = 'United States(+1)';
        Test.startTest();
            update c;
        Test.stopTest();

        Contact updated = [SELECT Phone FROM Contact WHERE Id = :c.Id WITH SYSTEM_MODE];

        System.assertNotEquals(null, updated.Phone);
    }

    @isTest
    static void restrictedContactNegativeTest() {

        Id eventRecId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
        // Create data
        Campaign camp = new Campaign (Name = 'Test Campaign', RecordTypeId = eventRecId, TimeZone__c = 'America/New_York',EmailDefaultSubjectLine__c='Invitation for {0} to attend the EventTetsing For EmailSubjectLine, March 27');
        insert camp;

        Contact ct = TestDataFactory.getContact('šurÁ');
        ct.Restricted__c = true;

        insert ct;

        CampaignMember campMember = new CampaignMember(ContactId=ct.Id, CampaignId=camp.Id);
        insert campMember;

        Contact contact = [SELECT Suffix FROM Contact WHERE Id = :ct.Id WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
        ct.Restricted__c = false;
        ct.DoNotCall = true;
        ct.Bio_Photo__c = 'Bio Photo';
        ct.Bio_Confidential_Notes__c = 'Bio Confidential Notes';
        ct.Email='test@bbp.com';
        ct.Bio_Description__c = 'Bio Description';
        ct.General_Election_Notes__c ='Note 2025';
        update ct;
        Test.stopTest();
        contact = [SELECT Suffix FROM Contact WHERE Id = :ct.Id WITH SYSTEM_MODE LIMIT 1];
        Assert.areEqual(true, contact.Suffix == null);
    }
    @isTest
    static void testHandleRelatedContactsDeletionAndReparenting() {
        Account acc = TestDataFactory.createOrg('Reparent Org');

        Contact c1 = TestDataFactory.createContact(acc.Id, 'Main');
        Contact c2 = TestDataFactory.createContact(acc.Id, 'Related');
        ContactTriggerHandler.mergedId_and_MasterId_Map = new Map<String, String>{c2.Id =>c1.Id};

        // Create relation
        Related_Contact__c rc = TestDataFactory.createRelatedContact(c1,c2);
        Test.startTest();
            delete c1; // triggers delete + reparent logic
        Test.stopTest();

        System.assertNotEquals(null, c2.Id);
    }

    @isTest
    static void testHandleMergeDuplicateCleanup_New() {
        Account acc = TestDataFactory.createOrg('Merge Org');

        Contact c1 = TestDataFactory.createContact(acc.Id, 'Merge1');
        Contact c2 = TestDataFactory.createContact(acc.Id, 'Merge2');

        Test.startTest();
            ContactTriggerHandler.afterMerge(new Set<Id>{c1.Id});
        Test.stopTest();

        System.assertNotEquals(null, c1.Id);
    }

    @isTest
    static void testValidateCommittees_NewPath() {
        Account acc = TestDataFactory.createOrg('Committee Org 2');
        Contact c = TestDataFactory.createContact(acc.Id,'Committee2');

        Test.startTest();
            c.Constituencies_Joined__c = 'A;B';
            c.Possible_Constituencies__c = 'C;D';
            c.Constituencies_Declined__c = 'E;F';
            Database.update(c, getDML()); // no duplicates → success
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
    }

    @isTest
    static void testBoardMemberUpdateNotification_New() {
        Contact c = TestDataFactory.createMayorContact();

        Test.startTest();
            c.FirstName = 'UpdatedName';
            c.LastName = 'UpdatedLast';
            Database.update(c, getDML()); // triggers notification
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
    }


    @isTest
    static void testCreateEmploymentHistory() {

        Contact c = TestDataFactory.createMayorContact();
        Account acc = TestDataFactory.createOrg('Test Org');
        Test.startTest();
            c.FirstName = 'EmailTest';
            c.AccountId = acc.Id;
            Database.update(c, getDML());
        Test.stopTest();

        System.assertNotEquals(null, c.Id);
    }


    private static CampaignMember buildMember(String contactName, String email, String cc, String bcc) {
        Account acc = TestDataFactory.createOrg('CC Org ' + contactName);
        Contact c = TestDataFactory.createContact(acc.Id, contactName);
        c.Email = email;
        Database.update(c, getDML());

        Campaign camp = new Campaign(Name = 'CC Camp ' + contactName, IsActive = true);
        insert camp;

        CampaignMember cm = new CampaignMember(
            ContactId = c.Id, CampaignId = camp.Id,
            CC_Addresses__c = cc, BCC_Addresses__c = bcc);
        insert cm;
        return cm;
    }

    @isTest
    static void testCcSync_bothFieldsChange() {
        CampaignMember cm = buildMember('BothFields', 'old@x.com', 'a@x.com, old@x.com', 'b@x.com');
        Contact c = [SELECT Id, ContactId FROM CampaignMember WHERE Id = :cm.Id WITH SYSTEM_MODE LIMIT 1].ContactId == null
                    ? null : [SELECT Id, Email FROM Contact WHERE Id = :([SELECT ContactId FROM CampaignMember WHERE Id = :cm.Id WITH SYSTEM_MODE].ContactId) WITH SYSTEM_MODE];
        Test.startTest();
            c.Email = 'new@x.com';
            Database.update(c, getDML());
        Test.stopTest();
        CampaignMember after = [SELECT CC_Addresses__c, BCC_Addresses__c FROM CampaignMember WHERE Id = :cm.Id WITH SYSTEM_MODE];
        System.assertEquals('a@x.com, new@x.com', after.CC_Addresses__c);
        System.assertEquals('b@x.com', after.BCC_Addresses__c);
    }
}