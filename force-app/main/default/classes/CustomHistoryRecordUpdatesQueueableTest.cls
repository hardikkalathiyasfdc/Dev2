@isTest
public class CustomHistoryRecordUpdatesQueueableTest {

    @testSetup
    static void dataSetup () {
        Account testAccount = TestdataFactory.getOrg('Test Account');
        Account testAccount2 = TestdataFactory.getOrg('Test Account 2');
        insert new List<Account>{ testAccount, testAccount2 };

        Contact testContact = TestdataFactory.getContact('Test Last');
        insert testContact;
    }

    @isTest
    static void referenceFieldTest () {
        Account a = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' with SYSTEM_MODE LIMIT 1];
        Account oldA = [SELECT Id, Name FROM Account WHERE Name = 'Test Account 2' with SYSTEM_MODE LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Test Last' with SYSTEM_MODE LIMIT 1];
        Test.startTest ();
        Custom_History__c h = new Custom_History__c (
            Old_Value__c = oldA.Id,
            New_Value__c = a.Id,
            Record_ID__c = c.Id,
            Field_API_Name__c = 'AccountId',
            Object_API_Name__c = 'Contact'
        );
        insert h;
        System.enqueueJob(new CustomHistoryRecordUpdatesQueueable(new List<Custom_History__c> {h}));
        Test.stopTest ();
        Custom_History__c historyRecord = [SELECT Id, Record_ID__c, Old_Value__c, New_Value__c, Field_API_Name__c FROM Custom_History__c WHERE Id =: h.Id with SYSTEM_MODE];
        System.assertEquals (true, historyRecord.Old_Value__c == 'Test Account 2');
        System.assertEquals (true, historyRecord.New_Value__c == 'Test Account');
    }
}