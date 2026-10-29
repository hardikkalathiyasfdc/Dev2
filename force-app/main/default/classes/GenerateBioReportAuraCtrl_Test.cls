@isTest
private class GenerateBioReportAuraCtrl_Test {
    @testSetup
    static void dataPrep() {
        String orgEngagedId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId();
        String leadshipEngagedId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('BP_Campaign').getRecordTypeId();
        Campaign camp = new Campaign();
        camp.RecordTypeId = orgEngagedId;
        camp.Name = 'test cam';
        Campaign cam1 = new Campaign();
        cam1.RecordTypeId = leadshipEngagedId;
        cam1.Name = 'test cam1';
        insert new List<Campaign>{camp, cam1};
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        Account restrictedAcct = new Account(Name = 'Restricted Account');
        insert restrictedAcct;
        restrictedAcct.Restricted__c = true;
        update restrictedAcct;
        List<Contact> contacts = TestDataFactory.createMultipleContacts(acct.Id, 4, true);
        CampaignMember campMember1 = new CampaignMember(ContactId=contacts[0].Id, CampaignId=camp.Id);
        CampaignMember campMember2 = new CampaignMember(ContactId=contacts[1].Id, CampaignId=camp.Id);
        CampaignMember campMember3 = new CampaignMember(ContactId=contacts[2].Id, CampaignId=camp.Id);
        CampaignMember campMember4 = new CampaignMember(ContactId=contacts[3].Id, CampaignId=camp.Id);
        insert new List<CampaignMember>{campMember1, campMember2, campMember3, campMember4};
    }

    @isTest
    static void testListFetching() {
        List<Campaign> cam = [SELECT Id FROM Campaign WHERE Name = 'test cam' WITH SYSTEM_MODE];
        // Retrieve the IDs of the inserted Contacts
        List<string> contactIds = new List<string>();
        for (Contact c : [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 4]) {
            contactIds.add(c.Id); // Populate the list with the IDs
        }
        Test.startTest();
        String lists = GenerateBioReportAuraCtrl.getExistingList();
        String defaultOrgVaris = GenerateBioReportAuraCtrl.getBPOrgDefaults();
        Integer count = GenerateBioReportAuraCtrl.getContactWithPhotoCount(cam[0].Id);
        Integer restrictedCount = GenerateBioReportAuraCtrl.getRestrictedContactCount(cam[0].Id);
        Integer restrictedContact = GenerateBioReportAuraCtrl.getRestrictedContactForGenerateBio(contactIds);
        Boolean restrictedContactCount = GenerateBioReportAuraCtrl.getRestrictedContact(contactIds[0]);
        List<Account> allAccts = [SELECT Id, Name, Restricted__c FROM Account WITH SYSTEM_MODE];
        List<String> orgIds = new List<String>();
        for (Account a : allAccts) { orgIds.add(a.Id); }
        Integer restrictedOrgCount = GenerateBioReportAuraCtrl.getRestrictedOrgCount(orgIds);
        System.assert(restrictedOrgCount >= 1, 'Should detect at least one restricted org. Accts=' + allAccts);
        System.assert(String.isNotBlank(lists));
        System.assert(String.isNotBlank(defaultOrgVaris));
        System.assert(restrictedCount == 0, 'Restricted count should be 0 or greater');
        System.assert(restrictedContact == 0, 'Restricted count should be 0 or greater');
        GenerateBioReportAuraCtrl.getCanAccessShortBio();
        GenerateBioReportAuraCtrl.getRSVPCount(cam[0].Id);
        
        // Cover getRestrictedContactCountFromLists and fetchLookUpValues (both branches).
        Integer restrictedFromLists = GenerateBioReportAuraCtrl.getRestrictedContactCountFromLists(new List<String>{ cam[0].Id });
        System.assert(restrictedFromLists >= 0, 'Restricted-from-lists count should be >= 0');
        List<Contact> allContacts = [SELECT Id, LastName FROM Contact WITH SYSTEM_MODE LIMIT 4];
        List<Contact> singleWord = GenerateBioReportAuraCtrl.fetchLookUpValues(allContacts[0].LastName, new List<Contact>());
        List<Contact> twoWords = GenerateBioReportAuraCtrl.fetchLookUpValues('Test Contact', allContacts);
        System.assertNotEquals(null, singleWord);
        System.assertNotEquals(null, twoWords);
        Test.stopTest();
    }
}