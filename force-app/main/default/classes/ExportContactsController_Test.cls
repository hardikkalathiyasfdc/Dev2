@isTest
public class ExportContactsController_Test {
    @testSetup
    static void dataSetup () {
        Account a = TestDataFactory.getOrg('test');
        insert as system a;
        
        Contact con1 = new Contact(FirstName='Bio_t1', LastName='Biotest1', AccountId = a.Id, Bio_Photo__c = 'Bio Photo', Bio_Confidential_Notes__c = 'Bio Confidential Notes', 
                                   Bio_Description__c = 'Bio Description', Team_s__c = 'IT',Categories__c = 'Education;Nonprofit', Office_Phone_Country_Code__c='United States(+1)', Phone='2121231234', MailingStreet = '1600 Pennsylvania Ave NW',
                                   MailingCity = 'New York',MailingState = 'NY',MailingPostalCode = '514402',MailingCountry = 'United States');
        insert as system con1;
        Contact con2 = new Contact(FirstName='Edu2', Significant_Other__c=con1.Id, LastName='Edu2', AccountId = a.Id, Bio_Photo__c = 'Bio Photo', Bio_Confidential_Notes__c = 'Bio Confidential Notes', 
                                   Bio_Description__c = 'Bio Description', Team_s__c = 'IT',Categories__c = 'Education;Nonprofit', Office_Phone_Country_Code__c='United States(+1)', Phone='212123123', MailingStreet = '1600 Pennsylvania Ave NW',
                                   MailingCity = 'New york',MailingState = 'NY',MailingPostalCode = '514402',MailingCountry = 'United States');
        insert as system con2;
        
        con1.Significant_Other__c = con2.Id;
        
        update as system con1;
        Test.startTest();
        Tag__c t = TestDataFactory.getTag('test');
        insert as system t;
        Tag_Junction__c j = TestDataFactory.getTagJunc(t,con1);
        insert as system j;
        
        Campaign testCamp = new Campaign(Name = 'test list');
        insert as system testCamp;
        
        CampaignMember testMem = TestDataFactory.getListMember(
            testCamp.Id,
            con1.Id
        );
        insert as system testMem;
        testMem = TestDataFactory.getListMember(
            testCamp.Id,
            con2.Id
        );
        insert as system testMem;
        Test.stopTest();
    }
    
    @isTest
    static void selectedTagsTest () {
        List<Tag__c> tags = [Select Id from Tag__c];
        ApexPages.StandardSetController standardController = new ApexPages.StandardSetController(tags);
        standardController.setSelected(tags);
        Test.startTest();
        ExportContactsController extension = new ExportContactsController(standardController);
        Test.stopTest();
        System.assertEquals(true, extension.tagIdsString != null);
    }
    
    @isTest
    static void selectedTagsTestWithException () {
        ExportContactsController.forceException = true;
        List<Tag__c> tags = [Select Id from Tag__c];
        ApexPages.StandardSetController standardController = new ApexPages.StandardSetController(tags);
        standardController.setSelected(tags);
        Test.startTest();
        ExportContactsController extension = new ExportContactsController(standardController);
        Test.stopTest();
        System.assertEquals(true, extension.tagIdsString != null);
    }
    
    @isTest
    static void getContactsTest () {
        
        List<Tag__c> tags = [Select Id from Tag__c];
        ApexPages.StandardSetController standardController = new ApexPages.StandardSetController(tags);
        standardController.setSelected(tags);
        Test.startTest();
        ExportContactsController extension = new ExportContactsController(standardController);
        Contact c =[Select Id from Contact where FirstName='Bio_t1'];
        
        List<ExportContactsController.ContactWrapper> contacts = ExportContactsController.getContacts(extension.tagIdsString, 'Standard');
        Test.stopTest();
        System.assertEquals(1, contacts.size());
    }
    
    @isTest
    static void getContactsTestWithException () {
        ExportContactsController.forceException = true;
        List<Tag__c> tags = [Select Id from Tag__c WITH SYSTEM_MODE];
        ApexPages.StandardSetController standardController = new ApexPages.StandardSetController(tags);
        standardController.setSelected(tags);
        Test.startTest();
        ExportContactsController extension = new ExportContactsController(standardController);
        Contact c =[Select Id from Contact where FirstName='Bio_t1' WITH SYSTEM_MODE];
        
        List<ExportContactsController.ContactWrapper> contacts = ExportContactsController.getContacts(extension.tagIdsString, 'Standard');
        Test.stopTest();
    }
    
    @isTest
    static void getContactsFromListTest () {
        Campaign c = [Select Id from Campaign WITH SYSTEM_MODE LIMIT 1];
        
        ExportContactsController.getAvailableColumns('State_Campaign');
        ExportContactsController.AssistantWrapper assistanceWrapper = new ExportContactsController.AssistantWrapper('assistantName', 'assistantPersonnelEmail', 'assistanttBusinessEmail', 'assistantBusinessPhone', 'assistantMobilePhone');
        Test.startTest();
        ExportContactsController.getContactsFromList(c.Id,'Executive');
        ExportContactsController.getDNCContacts(c.Id) ;
        
        List<String> fieldAPINames = new List<String>{'firstOrPreferredFirstName','LastName','significantOther','Title','organization','Priority_Email__c','ffTags','otherTags','Id','listMemberId', 'AssistantPersonalEmail'};
            List<String> listMemberFieldAPINames = new List<String>{'Guest_Email__c','Guest_Email_Type__c'};
                List<String> contactFieldAPINames = new List<String>{'MobilePhone'};
                    ExportContactsController.getMemeberList(c.Id, 'Executive', fieldAPINames, listMemberFieldAPINames, contactFieldAPINames);
        Test.stopTest();
        
    }
    @isTest
    static void getContactsFromListTestWithException () {
        ExportContactsController.forceException = true;
        Campaign c = [Select Id from Campaign WITH SYSTEM_MODE LIMIT 1];
        
        ExportContactsController.getAvailableColumns('State_Campaign');
        ExportContactsController.AssistantWrapper assistanceWrapper = new ExportContactsController.AssistantWrapper('assistantName', 'assistantPersonnelEmail', 'assistanttBusinessEmail', 'assistantBusinessPhone', 'assistantMobilePhone');
        Test.startTest();
        ExportContactsController.getContactsFromList(c.Id,'Executive');
        ExportContactsController.getDNCContacts(c.Id) ;
        
        List<String> fieldAPINames = new List<String>{'firstOrPreferredFirstName','LastName','significantOther','Title','organization','Priority_Email__c','ffTags','otherTags','Id','listMemberId', 'AssistantPersonalEmail'};
            List<String> listMemberFieldAPINames = new List<String>{'Guest_Email__c','Guest_Email_Type__c'};
                List<String> contactFieldAPINames = new List<String>{'MobilePhone'};
                    ExportContactsController.getMemeberList(c.Id, 'Executive', fieldAPINames, listMemberFieldAPINames, contactFieldAPINames);
        Integer restrictedCount = ExportContactsController.getRestrictedContactCount(c.Id);
        System.assertNotEquals(null, restrictedCount);
        Test.stopTest();
    }
    
    @isTest
    static void getContactsFromListTest2 () {
        ExportContactsController.ContactWrapper wr= new ExportContactsController.ContactWrapper();
        wr.BusinessStreet  ='';
        wr.BusinessCity  ='';
        wr.BusinesState  ='';
        wr.BusinessPostalCode  ='';
        wr.BusinessCountry ='';
        wr.HomeStreet ='';
        wr.HomeCity ='';
        wr.HomeStateProvince ='';
        wr.HomePostalCode ='';
        wr.HomeCountry ='';
        wr.ConfidentialAddressType ='';
        wr.ConfidentialStreet ='';
        wr.ConfidentialStreet2 ='';
        wr.ConfidentialStreet3 ='';
        wr.ConfidentialCity ='';
        wr.ConfidentialStateProvince ='';
        wr.ConfidentialZipPostalCode ='';
        wr.ConfidentialCountry ='';
        wr.DoNotCall ='';
        
        Campaign c = [Select Id from Campaign WITH SYSTEM_MODE LIMIT 1];
        ExportContactsController.getAvailableColumns('State_Campaign');
        ExportContactsController.AssistantWrapper assistanceWrapper = new ExportContactsController.AssistantWrapper('assistantName', 'assistantPersonnelEmail', 'assistanttBusinessEmail', 'assistantBusinessPhone', 'assistantMobilePhone');
        Test.startTest();  ExportContactsController.getContactsFromList(c.Id,'Executive');
        List<String> fieldAPINames = new List<String>{'firstOrPreferredFirstName','LastName','significantOther','Title','organization','Priority_Email__c','ffTags','otherTags','Id','listMemberId', 'AssistantPersonalEmail'};
            List<String> listMemberFieldAPINames = new List<String>{'Guest_Email__c','Guest_Email_Type__c'};
                List<String> contactFieldAPINames = new List<String>{'MobilePhone'};
                    
                    ExportContactsController.getMemeberList(c.Id, 'Standard', fieldAPINames, listMemberFieldAPINames, contactFieldAPINames);
        Test.stopTest();
    }
    @isTest
    static void contactWrapperFullCoverageTest() {
        Test.startTest();
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            firstname = 'Code',
            lastName = 'Check',
            Email = 'admin@test.com',
            Username = 'adminuser' + DateTime.now().getTime() + '@test.com',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = 'admint',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = pf.Id,
            Sharing_Team__c = 'System Administration'
        );
        insert as system adminUser;
        
        System.runAs(adminUser) {   
            Account acc = TestDataFactory.getOrg('One_test');
            insert as system acc;
            
            Contact spouse = new Contact(
                FirstName = 'Jane_Test',
                LastName = 'Spouse_Test3',
                Salutation = 'Mrs.',
                Annual_Report_Salutation__c = 'Mr. and Mrs. Smith',
                MailingStreet = '123 Test St',
                MailingCity = 'New York',
                MailingState = 'NY',
                MailingPostalCode = '10001',
                MailingCountry = 'United States',
                OtherStreet = '321 Home Rd',
                OtherCity = 'Boston',
                OtherState = 'MA',
                OtherPostalCode = '02108',
                OtherCountry = 'United States',
                DoNotCall = true
                
            );
            insert as system spouse;
            
            Contact c = new Contact(
                FirstName = 'Johnr',
                LastName = 'Smith_ry',
                Salutation = 'Mr.',
                Title = 'Director',
                AccountId = acc.Id,
                Email = 'john@test.com',
                Alternate_Email__c = 'john.alt@test.com',
                Business_Email_2__c = 'john.biz2@test.com',
                Office_Phone_Country_Code__c = 'United States(+1)',
                Phone = '9998887777',
                MobilePhone = '8887776666',
                Mobile_Phone_Country_Code__c = 'United States(+1)',
                Personal_Email_2__c = 'john.personal2@test.com',
                ConfidentialStreet__c = 'Hidden Lane',
                ConfidentialStreet2__c = 'Secret Apt',
                ConfidentialStreet3__c = 'Private Bldg',
                ConfidentialCity__c = 'Secret City',
                ConfidentialStateProvice__c = 'Conf State',
                ConfidentialZipPostalCode__c = '99999',
                Confidential_Country__c = 'United States',
                ConfidentialAddressType__c = 'Home',
                Contact_Alert_Reason__c = 'Do not disturb',
                CorrespondenceDearLine__c = 'Dear John',
                Annual_Report_Salutation__c = 'Mr. Smith',
                Primary_Spouse__c = true,
                Significant_Other__c = spouse.Id
            );
            insert as system c;
            
            // Link back spouse -> John (for Executive branch)
            spouse.Significant_Other__c = c.Id;
            update as system spouse;
            
            Tag__c tag = new Tag__c(Name = 'FullCoverageTag', Private__c = false);
            insert as system tag;
            
            Tag_Junction__c tj = new Tag_Junction__c(
                Tag__c = tag.Id,
                Contact__c = c.Id
            );
            insert as system tj;
            
            // Run the queueable to cover logic
            System.enqueueJob(new ContactWrapperQueueable(new Set<Id>{ c.Id }, tag.Id));
            Test.stopTest();
        } 
    }
    
    // Child Queueable class to handle logic execution safely
    public class ContactWrapperQueueable implements Queueable, Database.AllowsCallouts {
        private Set<Id> contactIds;
        private String selectedTags;
        
        public ContactWrapperQueueable(Set<Id> contactIds, String selectedTags) {
            this.contactIds = contactIds;
            this.selectedTags = selectedTags;
        }
        
        public void execute(QueueableContext qc) {
            List<Contact> contacts = [
                SELECT Id, Staff_Role__c, Client__c, Contact_Alert_Reason__c,
                FirstName, Annual_Report_Salutation__c, CorrespondenceDearLine__c,
                OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry,
                MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                Priority_Email__c, LastName, Preferred_First_Name__c, MiddleName,
                Personal_Email_2__c, Phone, Office_Phone_Country_Code__c,
                MobilePhone, Mobile_Phone_Country_Code__c, MailingAddress, OtherAddress,
                Business_Email_2__c, Email, Alternate_Email__c, Primary_Spouse__c,
                Salutation, Significant_Other__c, Title, Account.Name,
                Significant_Other__r.FirstName, Significant_Other__r.LastName,
                Significant_Other__r.Salutation, Significant_Other__r.Annual_Report_Salutation__c,
                ConfidentialStreet__c, ConfidentialCity__c, Confidential_Country__c,
                ConfidentialStateProvice__c, ConfidentialZipPostalCode__c
                FROM Contact
                WHERE Id IN :contactIds
                WITH SYSTEM_MODE
            ];
            
            Map<Id, Tag_Junction__c> mapContactIdtoTag = new Map<Id, Tag_Junction__c>(
                [SELECT Id, Tag__c, Contact__c,
                 Tag__r.Private__c,
                 Tag__r.Owner.Name
                 FROM Tag_Junction__c
                 WHERE Contact__c IN :contactIds
                 WITH SYSTEM_MODE]
            );
            
            for (Contact con : contacts) {
                Tag_Junction__c tj = mapContactIdtoTag.get(con.Id);
                
                if (tj != null && tj.Tag__r != null) {
                    new ExportContactsController.ContactWrapper(con, selectedTags, mapContactIdtoTag, 'Executive', contactIds);
                    new ExportContactsController.ContactWrapper(con, selectedTags, mapContactIdtoTag, 'Standard', contactIds);
                } else {
                    System.debug('Skipped contact ' + con.Id + ' because Tag Junction or Tag__r was null');
                }
            }
        }
    }

    @isTest
    static void getMissingEmailContactsTest() {
        Campaign camp = [SELECT Id FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        Contact missingEmail = new Contact(
            FirstName = 'NoEmail',
            LastName = 'Contact',
            AccountId = [SELECT Id FROM Account WITH SYSTEM_MODE LIMIT 1].Id
        );
        insert as system missingEmail;
        insert as system TestDataFactory.getListMember(camp.Id, missingEmail.Id);

        Test.startTest();
            List<ExportContactsController.ContactWrapper> results =
                ExportContactsController.getMissingEmailContacts(camp.Id);
        Test.stopTest();

        Assert.isTrue(results != null && !results.isEmpty(), 'Should return contacts missing priority email');
    }

    @isTest
    static void getAvailableColumnsByRecordTypeTest() {
        Test.startTest();
            Assert.isNotNull(ExportContactsController.getAvailableColumns('State_Campaign'));
            Assert.isNotNull(ExportContactsController.getAvailableColumns('BP_Campaign'));
            Assert.isNotNull(ExportContactsController.getAvailableColumns('Pre_Event'));
            Assert.isNotNull(ExportContactsController.getAvailableColumns('GuestList'));
            Assert.isNotNull(ExportContactsController.getAvailableColumns('Fundraising'));
            ExportContactsController.forceException = true;
            Assert.isNull(ExportContactsController.getAvailableColumns('State_Campaign'));
        Test.stopTest();
    }

    @isTest
    static void getContactsExecutiveAndPreferredNameTest() {
        List<Tag__c> tags = [SELECT Id FROM Tag__c WITH SYSTEM_MODE];
        ApexPages.StandardSetController standardController = new ApexPages.StandardSetController(tags);
        standardController.setSelected(tags);
        ExportContactsController extension = new ExportContactsController(standardController);

        Contact primary = [SELECT Id, Preferred_First_Name__c, Preferred_Last_Name__c FROM Contact WHERE FirstName = 'Bio_t1' WITH SYSTEM_MODE];
        primary.Preferred_First_Name__c = 'PrefBio';
        primary.Preferred_Last_Name__c = 'PrefLast';
        primary.Primary_Spouse__c = true;
        update as system primary;

        Test.startTest();
            List<ExportContactsController.ContactWrapper> executive =
                ExportContactsController.getContacts(extension.tagIdsString, 'Executive');
            List<ExportContactsController.ContactWrapper> standard =
                ExportContactsController.getContacts(extension.tagIdsString, 'Standard');
        Test.stopTest();

        Assert.isTrue(executive != null, 'Executive export should return a list');
        Assert.isTrue(standard != null && !standard.isEmpty(), 'Standard export should return contacts');
    }

    @isTest
    static void getMemberListExecutiveSpouseBranchesTest() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact spouseA = new Contact(FirstName = 'Alex', LastName = 'Alpha', AccountId = acc.Id, Primary_Spouse__c = true);
        Contact spouseB = new Contact(FirstName = 'Blake', LastName = 'Beta', AccountId = acc.Id, Primary_Spouse__c = false);
        insert as system new List<Contact>{ spouseA, spouseB };
        spouseA.Significant_Other__c = spouseB.Id;
        spouseB.Significant_Other__c = spouseA.Id;
        update as system new List<Contact>{ spouseA, spouseB };

        Campaign camp = new Campaign(Name = 'Spouse Export List');
        insert as system camp;
        insert as system new List<CampaignMember>{
            TestDataFactory.getListMember(camp.Id, spouseA.Id),
            TestDataFactory.getListMember(camp.Id, spouseB.Id)
        };

        List<String> fieldAPINames = new List<String>{
            'firstOrPreferredFirstName', 'LastName', 'significantOther', 'Title',
            'organization', 'Priority_Email__c', 'ffTags', 'otherTags', 'Id', 'listMemberId',
            'AssistantPersonalEmail'
        };
        List<String> listMemberFieldAPINames = new List<String>{ 'Guest_Email__c', 'Guest_Email_Type__c' };
        List<String> contactFieldAPINames = new List<String>{ 'MobilePhone' };

        Test.startTest();
        List<ExportContactsController.ExportDataWrapper> executive =
            ExportContactsController.getMemeberList(camp.Id, 'Executive', fieldAPINames, listMemberFieldAPINames, contactFieldAPINames);
        List<ExportContactsController.ExportDataWrapper> standard =
            ExportContactsController.getMemeberList(camp.Id, 'Standard', fieldAPINames, listMemberFieldAPINames, contactFieldAPINames);
        Test.stopTest();

        Assert.isNotNull(executive, 'Executive getMemeberList should not return null');
        Assert.isFalse(executive.isEmpty(), 'Executive member list should return at least the primary spouse row');
        Assert.isNotNull(standard, 'Standard getMemeberList should not return null');
        Assert.isTrue(standard.size() >= 2, 'Standard member list should include both spouses');
    }

    @isTest
    static void hasAccessAndOptionWrappersTest() {
        Map<String, Schema.SObjectField> fieldMap = Contact.SObjectType.getDescribe().fields.getMap();
        Assert.isTrue(ExportContactsController.hasAccess(fieldMap, 'LastName'));
        Assert.isFalse(ExportContactsController.hasAccess(fieldMap, 'Fake_Field__c'));

        ExportContactsController.OptionWrapper ow =
            new ExportContactsController.OptionWrapper('Label', 'value__c');
        Assert.areEqual('Label', ow.fieldLabel);

        ExportContactsController.AvailableOptionWrapper aow =
            new ExportContactsController.AvailableOptionWrapper(
                new List<ExportContactsController.OptionWrapper>{ ow },
                new List<ExportContactsController.OptionWrapper>{ ow }
            );
        Assert.areEqual(1, aow.contactFields.size());
    }
}