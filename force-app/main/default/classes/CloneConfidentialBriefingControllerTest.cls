@isTest
public class CloneConfidentialBriefingControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create an Account
        Account testAccount = TestDataFactory.createOrg('Test Account');
        // Create a Contact linked to the Account
        Contact testContact = TestDataFactory.createContact(testAccount.Id,'Test Contact');
        // Create a Campaign
        Campaign testCampaign = TestDataFactory.createCampaign('Test Campaign');
        // Create a CampaignMember linked to the Campaign and Contact
        TestDataFactory.createCampaignMember(testCampaign.Id,testContact.Id);
        TestDataFactory.createInteraction(testContact.Id, 'Test Interaction', 'Arts',null);
        // Create Confidential_Items__c record linked to the Contact
        Confidential_Items__c testConfidentialItem = TestDataFactory.createConfidentialItem(testContact.Id,'Test Confidential Item');
        TestDataFactory.createFile('TestDocument.pdf',testConfidentialItem.Id);
    }

    @isTest
    static void testGetFilteredRecords() {
        // Fetch the contact
        Contact testContact = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];

        // Call the method
        List<CampaignMember> result = CloneConfidentialBriefingController.getFilteredRecords(testContact.Id);

        // Verify results
        System.assertEquals(1, result.size(), 'One CampaignMember should be returned');
        System.assertEquals(testContact.Id, result[0].ContactId, 'Contact ID should match');
    }

    @isTest
    static void testGetOrgDetails() {
        // Fetch the Confidential_Items__c record
        Confidential_Items__c confidentialItem = [SELECT Id, Contact__r.AccountId FROM Confidential_Items__c WITH SYSTEM_MODE LIMIT 1];

        // Call the method
        Map<String, String> result = CloneConfidentialBriefingController.getOrgDetails(confidentialItem.Id);

        // Verify results
        System.assertNotEquals(null, result.get('contactId'), 'Contact ID should not be null');
        System.assertEquals(confidentialItem.Contact__r.AccountId, result.get('accountId'), 'Account ID should match');
    }

    @isTest
    static void testGetInteractions() {
        // Fetch the contact
        Contact testContact = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];

        // Call the method
        List<Interaction__c> interactions = CloneConfidentialBriefingController.getInteractions(testContact.Id);

        // Verify results
        System.assertEquals(0, interactions.size(), 'no Interaction should be returned');
    }

    @isTest
    static void testCloneConfidentialBriefing_Account() {
        // Fetch the Confidential_Items__c record and Account ID
        Confidential_Items__c originalItem = [SELECT Id, Name, Contact__c FROM Confidential_Items__c WITH SYSTEM_MODE LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WITH SYSTEM_MODE LIMIT 1];

        // Call the cloneConfidentialBriefing method for Account
        Test.startTest();
        CloneConfidentialBriefingController.cloneConfidentialBriefing('Account', originalItem.Id, new list<string>{string.valueof(testAccount.Id)});
        Test.stopTest();

        // Verify the new cloned record
        Confidential_Items__c clonedItem = [
            SELECT Id, Name, Account__c
            FROM Confidential_Items__c
            WHERE Account__c = :testAccount.Id
            AND Name = :originalItem.Name
            WITH SYSTEM_MODE LIMIT 1
        ];

        System.assertNotEquals(null, clonedItem, 'Cloned Confidential Item should exist for the Account');
    }

    @isTest
    static void testCloneConfidentialBriefing_Campaign() {
        // Fetch the Confidential_Items__c record and Campaign ID
        Confidential_Items__c originalItem = [SELECT Id, Name, Contact__c FROM Confidential_Items__c WITH SYSTEM_MODE LIMIT 1];
        Campaign testCampaign = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];

        // Call the cloneConfidentialBriefing method for Campaign
        Test.startTest();
        CloneConfidentialBriefingController.cloneConfidentialBriefing('Campaign', originalItem.Id, new list<string>{string.valueof(testCampaign.Id)});
        Test.stopTest();

        // Verify the new cloned record
        Confidential_Items__c clonedItem = [
            SELECT Id, Name, Campaign__c
            FROM Confidential_Items__c
            WHERE Campaign__c = :testCampaign.Id
            AND Name = :originalItem.Name
            WITH SYSTEM_MODE LIMIT 1
        ];

        System.assertNotEquals(null, clonedItem, 'Cloned Confidential Item should exist for the Campaign');
    }

    @isTest
    static void testCloneConfidentialBriefing_Interaction() {
        // Fetch the Confidential_Items__c record and Interaction ID
        Confidential_Items__c originalItem = [SELECT Id, Name, Contact__c FROM Confidential_Items__c WITH SYSTEM_MODE LIMIT 1];
        Interaction__c testInteraction = [SELECT Id FROM Interaction__c WITH SYSTEM_MODE LIMIT 1];

        // Call the cloneConfidentialBriefing method for Interaction
        Test.startTest();
        CloneConfidentialBriefingController.cloneConfidentialBriefing('Interaction__c', originalItem.Id, new list<string>{string.valueof(testInteraction.Id)});
        Test.stopTest();

        // Verify the new cloned record
        Confidential_Items__c clonedItem = [
            SELECT Id, Name
            FROM Confidential_Items__c
            WHERE Name = :originalItem.Name
            WITH SYSTEM_MODE LIMIT 1
        ];

        System.assertNotEquals(null, clonedItem, 'Cloned Confidential Item should exist for the Interaction');
    }

    @isTest
    static void testCloneConfidentialBriefing_Contact() {
        // Fetch the Confidential_Items__c record and Account ID
        Confidential_Items__c originalItem = [SELECT Id, Name, Contact__c FROM Confidential_Items__c WITH SYSTEM_MODE LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];

        // Call the cloneConfidentialBriefing method for Account
        Test.startTest();
        CloneConfidentialBriefingController.cloneConfidentialBriefing('Contact',originalItem.Id, new List<Id> {testContact.Id});
        Test.stopTest();

        // Verify the new cloned record
        Confidential_Items__c clonedItem = [
            SELECT Id, Name, Account__c
            FROM Confidential_Items__c
            WHERE contact__c = :testContact.Id
            AND Name = :originalItem.Name
            WITH SYSTEM_MODE LIMIT 1
        ];

        System.assertNotEquals(null, clonedItem, 'Cloned Confidential Item should exist for the Contact');
    }
}