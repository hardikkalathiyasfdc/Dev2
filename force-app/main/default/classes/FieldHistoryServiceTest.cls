@isTest
public class FieldHistoryServiceTest {

    static Contact testContact;
    static Contact testContact2;


    @testSetup
    static void dataSetup () {
        test.startTest();

        testContact2 = TestDataFactory.getContact('Contact');
        testContact2.Annual_Report_Salutation__c = 'Test Report';
        testContact = TestDataFactory.getContact('Contact2');
		testContact.Annual_Report_Salutation__c = 'Test Report';
        Database.DMLOptions dmlTest = new Database.DMLOptions();
        dmlTest.DuplicateRuleHeader.AllowSave = true;
        Database.insert(new List<Contact>{ testContact, testContact2 }, dmlTest);
    	test.stopTest();
    }

	@isTest
    static void testInsert () {
        Contact newContact = TestdataFactory.getContact('Contact 1');
        newContact.Annual_Report_Salutation__c = 'Test Report';
        Test.startTest();
        Database.DMLOptions dmlTest = new Database.DMLOptions();
        dmlTest.DuplicateRuleHeader.AllowSave = true;
        Database.insert(new List<Contact>{ newContact }, dmlTest);
        Test.stopTest();
        List<Custom_History__c> historyRecords = [SELECT Id, Object_API_Name__c, Record_ID__c, Field_API_Name__c, Old_Value__c, New_Value__c
                                                  FROM Custom_History__c
                                                  WHERE Object_API_Name__c = 'Contact' AND Record_ID__c = :newContact.Id
                                                  WITH SYSTEM_MODE];
        System.assertEquals(3, historyRecords.size());
        System.assertEquals('Annual_Report_Salutation__c', historyRecords[0].Field_API_Name__c);
        System.assertEquals(null, historyRecords[0].Old_Value__c);
        System.assertEquals('Test Report', historyRecords[0].New_Value__c);
    }

    @isTest
    static void testUpdate () {
        Contact insertedCOntact = queryAccounts()[0];

        Contact oldContact = insertedCOntact.clone();
        Contact newContact1 = new Contact();
        newContact1.Id = insertedContact.Id;
        newContact1.Annual_Report_Salutation__c = 'Test Report 2';
        test.startTest();
        Database.DMLOptions dmlTest = new Database.DMLOptions();
        dmlTest.DuplicateRuleHeader.AllowSave = true;
        Database.update(new List<Contact>{ newContact1 }, dmlTest);
        test.stopTest();
        List<Custom_History__c> historyRecords = [SELECT Id, Object_API_Name__c, Record_ID__c, Field_API_Name__c, Old_Value__c, New_Value__c
                                                  FROM Custom_History__c
                                                  WHERE Object_API_Name__c = 'Contact' AND Record_ID__c = :newContact1.Id
                                                  WITH SYSTEM_MODE
                                                  ORDER BY CreatedDate DESC];

        System.assertEquals(4, historyRecords.size());
        System.assertEquals('Annual_Report_Salutation__c', historyRecords[0].Field_API_Name__c);
        System.assertEquals('Test Report', historyRecords[0].Old_Value__c);
        System.assertEquals('Test Report 2', historyRecords[0].New_Value__c);
    }

    private static List<Contact> queryAccounts() {
        List<History_Setting__mdt> fieldsToTrack = FieldHistoryService.getFieldsToTrack ('Contact');
        List<String> fields = new List<String> ();

        for (History_Setting__mdt mdt: fieldsToTrack) {
            fields.add(mdt.Field__c);
        }
        String baseQuery = 'SELECT ';
        String fieldQueryPart = String.join(fields, ',');
        baseQuery += fieldQueryPart + ' FROM Contact WITH SYSTEM_MODE LIMIT 1';

        List<Contact> results = Database.query(baseQuery);
        return results;
    }
}