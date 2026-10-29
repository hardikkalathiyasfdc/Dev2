@isTest
public without sharing class CustomSummaryCmpControllerTest {
    @isTest
    public static void validateGetSummaries() {
        Contact c = [SELECT Id FROM Contact WHERE Name = 'testContact' WITH SYSTEM_MODE LIMIT 1];
        CustomSummaryCmpController.customSettings = getContactSettings();
        Test.startTest();
        List<Object> summaries = CustomSummaryCmpController.getSummaries(c.Id);
        Test.stopTest();
        System.assertNotEquals(null, summaries);
        System.assertEquals(3, summaries.size());
    }

    @isTest
    static void validateOrganizationSummaries() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'test' WITH SYSTEM_MODE LIMIT 1];
        CustomSummaryCmpController.customSettings = getOrganizationSettings();
        Test.startTest();
        List<Object> summaries = CustomSummaryCmpController.getSummaries(testOrg.Id);
        Test.stopTest();
        System.assertNotEquals(null, summaries);
        System.assertEquals(4, summaries.size());
    }

    private static Map<String, List<Summary_Settings__mdt>> getOrganizationSettings() {
        Summary_Settings__mdt orgHighlight = new Summary_Settings__mdt();
        orgHighlight.MasterLabel = 'Organization Highlights/CityView';
        orgHighlight.Sort_Order__c = 1;
        orgHighlight.Type__c = 'Account';
        orgHighlight.Icon__c = 'standard:account';

        Summary_Settings__mdt orgAssociation = new Summary_Settings__mdt();
        orgAssociation.MasterLabel = 'Organization Associations';
        orgAssociation.Sort_Order__c = 2;
        orgAssociation.Type__c = 'Account';
        orgAssociation.Icon__c = 'standard:account';

        Summary_Settings__mdt leadershipContact = new Summary_Settings__mdt();
        leadershipContact.MasterLabel = 'Leadership Contacts';
        leadershipContact.Sort_Order__c = 3;
        leadershipContact.Type__c = 'Account';
        leadershipContact.Icon__c = 'standard:contact';

        Summary_Settings__mdt organizationContacts = new Summary_Settings__mdt();
        organizationContacts.MasterLabel = 'Organization Contacts';
        organizationContacts.SObject__c = 'Contact';
        organizationContacts.Related_Field__c = 'AccountId';
        organizationContacts.Sort_Order__c = 5;
        organizationContacts.Type__c = 'Account';
        organizationContacts.Icon__c = 'standard:contact';

        Summary_Settings__mdt tags = new Summary_Settings__mdt();
        tags.MasterLabel = 'Tags';
        tags.Sort_Order__c = 6;
        tags.Type__c = 'Account';
        tags.Icon__c = 'standard:account';

        return new Map<String, List<Summary_Settings__mdt>>{
            'Account' => new List<Summary_Settings__mdt>{ orgHighlight, orgAssociation, leadershipContact, organizationContacts }
        };
    }

    private static Map<String, List<Summary_Settings__mdt>> getContactSettings() {

        Summary_Settings__mdt settings2 = new Summary_Settings__mdt();
        settings2.MasterLabel = 'Org Engagements';
        settings2.RecordType__c = 'Organization Engagement/CityView';
        settings2.Related_Field__c = 'Id';
        settings2.SObject__c = 'Contact';
        settings2.Sort_Order__c = 2;
        settings2.ParentField__c = 'AccountId';
        settings2.Icon__c = 'standard:contact';
        settings2.Type__c = 'Contact';

        Summary_Settings__mdt settings4 = new Summary_Settings__mdt();
        settings4.DeveloperName = 'Lists';
        settings4.MasterLabel = 'Lists';
        settings4.Related_Field__c = 'ContactId';
        settings4.SObject__c = 'CampaignMember';
        settings4.Sort_Order__c = 2;
        settings4.Icon__c = 'standard:contact';
        settings4.Type__c = 'Contact';

        Summary_Settings__mdt settings5 = new Summary_Settings__mdt();
        settings5.MasterLabel = 'Events';
        settings5.Sort_Order__c = 3;
        settings5.Icon__c = 'standard:contact';
        settings5.Type__c = 'Contact';
        Map<String, List<Summary_Settings__mdt>> testMap = new Map<String, List<Summary_Settings__mdt>>();
        testMap.put('Contact', new List<Summary_Settings__mdt>{ settings2, settings4, settings5 });
        return testMap;
    }

    @TestSetup
    private static void makeData() {
        Account testOrg = TestDataFactory.getOrg('test');
        insert testOrg;
        Contact testC = TestDataFactory.getContact('testContact');
        testC.AccountId = testOrg.Id;
        insert testC;
        ElectedOffice__c eo1 = new ElectedOffice__c();
        eo1.Contact__c = testC.Id;
        eo1.ElectedStatus__c = 'Active';
        eo1.TermEndDate__c = Date.today().addDays(-1);
        insert eo1;
        Campaign testCamp = new Campaign(Name = 'test');
        insert testCamp;
        CampaignMember testMem = new CampaignMember(CampaignId = testCamp.Id, ContactId = testC.Id);
        insert testMem;
    }
}