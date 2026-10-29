@isTest
public class FieldHistoryControllerTest {

    static Contact testContact;
    static Contact testContact2;

    @testSetup
    static void dataSetup () {

        testContact2 = TestDataFactory.getContact('Contact');
        testContact2.Annual_Report_Salutation__c = 'Test Report';
        testContact = TestDataFactory.getContact('Contact2');
		testContact.Annual_Report_Salutation__c = 'Test Report';
        Database.DMLOptions dmlTest = new Database.DMLOptions();
        dmlTest.DuplicateRuleHeader.AllowSave = true;
        Database.insert(new List<Contact>{ testContact2,testContact }, dmlTest);
     }

    @isTest
    static void getHistoryRecordsTest () {

       	Contact newContact = TestdataFactory.getContact('Contact 1');
       	newContact.Deceased__c = true;
        newContact.BioLastReviewedDate__c = System.today();
        newContact.Annual_Report_Salutation__c = 'Test Report2';
        newContact.Bio_Photo__c = 'test bio';
        Test.startTest();
        Database.DMLOptions dmlTest = new Database.DMLOptions();
        dmlTest.DuplicateRuleHeader.AllowSave = true;
        Database.insert(new List<Contact>{ newContact }, dmlTest);
        Test.stopTest();
        List<FieldHistoryController.HistoryWrapper> histories = FieldHistoryController.fetchHistoryRecords(newContact.Id, 0, 50);
        System.assertEquals (4, histories.size());
    }

    @isTest
    static void getHistoryRecordsTestWithException () {
        FieldHistoryController.forceException = true;
        Contact newContact = TestdataFactory.getContact('Contact 1');
        newContact.Deceased__c = true;
        newContact.BioLastReviewedDate__c = System.today();
        newContact.Annual_Report_Salutation__c = 'Test Report2';
        Test.startTest();
        Database.DMLOptions dmlTest = new Database.DMLOptions();
        dmlTest.DuplicateRuleHeader.AllowSave = true;
        Database.insert(new List<Contact>{ newContact}, dmlTest);
        Test.stopTest();
        List<FieldHistoryController.HistoryWrapper> histories = FieldHistoryController.fetchHistoryRecords(newContact.Id, 0, 50);
    }

    @isTest
    static void statesUtilTest () {
        List<Account> accList = [select Id from Account with SYSTEM_MODE limit 3];
        List<Id> idList = new List<Id>();
        for(Account acc : accList) {
            idList.add(acc.Id);
        }
        Test.startTest();
        StatesUtil.recalculateSharingForAccounts(idList);
        Test.stopTest();
    }
}