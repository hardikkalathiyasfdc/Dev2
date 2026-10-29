@isTest
private class MergeDuplicateRecordDeletionTest {

    @isTest
    static void testDeleteDuplicateTagJunctions() {
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            testContacts.add(new Contact(FirstName = 'Test' + i, LastName = 'Contact'));
        }
        insert testContacts;

        List<Tag__c> testTags = new List<Tag__c>();
        for (Integer i = 0; i < 5; i++) {
            testTags.add(new Tag__c(Name = 'Tag' + i));
        }
        insert testTags;

        List<Tag_Junction__c> testTagJunctions = new List<Tag_Junction__c>();
        for (Integer i = 0; i < 5; i++) {
                testTagJunctions.add(new Tag_Junction__c(Contact__c = testContacts[i].Id, Tag__c = testTags[i].Id));
            }
        for (Integer j = 0; j < 5; j++) {
                testTagJunctions.add(new Tag_Junction__c(Contact__c = testContacts[j].Id, Tag__c = testTags[j].Id));
            }

        insert testTagJunctions;

        List<Id> contactIds = new List<Id>();
        for (Contact con : testContacts) {
            contactIds.add(con.Id);
        }

        Test.startTest();
        MergeDuplicateRecordDeletion.deleteDuplicateTagJunctions(contactIds);
        Test.stopTest();

        List<Tag_Junction__c> remainingTagJunctions = [SELECT Id FROM Tag_Junction__c WHERE Contact__c IN :contactIds with SYSTEM_MODE];
        System.assertEquals(5, remainingTagJunctions.size());
    }

     @isTest
    static void testDeleteDuplicateTagJunctionsForAccount() {
        List<Account> testAccount = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccount.add(new Account(Name = 'Test' + i));
        }
        insert testAccount;

        List<Tag__c> testTags = new List<Tag__c>();
        for (Integer i = 0; i < 5; i++) {
            testTags.add(new Tag__c(Name = 'Tag' + i));
        }
        insert testTags;

        List<Tag_Junction__c> testTagJunctions = new List<Tag_Junction__c>();
        for (Integer i = 0; i < 5; i++) {
                testTagJunctions.add(new Tag_Junction__c(Account__c = testAccount[i].Id, Tag__c = testTags[i].Id));
            }
        for (Integer j = 0; j < 5; j++) {
                testTagJunctions.add(new Tag_Junction__c(Account__c = testAccount[j].Id, Tag__c = testTags[j].Id));
            }

        insert testTagJunctions;

        List<Id> accountIds = new List<Id>();
        for (Account con : testAccount) {
            accountIds.add(con.Id);
        }

        Test.startTest();
        MergeDuplicateRecordDeletion.deleteDuplicateTagJunctionsForAccount(accountIds);
        Test.stopTest();

        List<Tag_Junction__c> remainingTagJunctions = [SELECT Id FROM Tag_Junction__c WHERE Account__c IN :accountIds with SYSTEM_MODE];
        System.assertEquals(5, remainingTagJunctions.size());
    }

    @isTest
    static void testdeleteDuplicateEmpHistory() {
        List<Account> testAccount = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccount.add(new Account(Name = 'Test' + i));
        }
        insert testAccount;
        Account acc = TestDataFactory.createOrg('Bloomberg Philanthropies');
        testAccount.add(acc);
         List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < testAccount.size(); i++) {
            testContacts.add(new Contact(AccountId= testAccount[i].Id ,FirstName = 'Test' + i, LastName = 'Contact'));
        }
        insert testContacts;

        List<Employment_History_and_Board_Membership__c> testEmpHistory = new List<Employment_History_and_Board_Membership__c>();
        for (Integer i = 0; i < testAccount.size(); i++) {
            Employment_History_and_Board_Membership__c emp1 = new Employment_History_and_Board_Membership__c(Organization_Name__c = testAccount[i].Id,
                                                                                                             Contact_Name__c = testContacts[i].Id,
                                                                                                             Role__c = 'Board Member',
                                                                                                            To__c=null);
            testEmpHistory.add(emp1);
        }
        for (Integer j = 0; j < testAccount.size(); j++) {
            Employment_History_and_Board_Membership__c emp1 = new Employment_History_and_Board_Membership__c(Organization_Name__c = testAccount[j].Id,
                                                                                                             Contact_Name__c = testContacts[j].Id,
                                                                                                             Role__c = 'Board Member',
                                                                                                            To__c=null);
            testEmpHistory.add(emp1);
        }
        insert testEmpHistory;
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        database.update (testContacts,dml);

        List<Id> contactIds = new List<Id>();
        for (Contact con : testContacts) {
            contactIds.add(con.Id);
        }

        Test.startTest();
        MergeDuplicateRecordDeletion.deleteDuplicateEmpHistory(contactIds);
        Test.stopTest();

        List<Employment_History_and_Board_Membership__c> remainingTagJunctions = [SELECT Id FROM Employment_History_and_Board_Membership__c WHERE Contact_Name__c IN :contactIds with SYSTEM_MODE];
    }
}