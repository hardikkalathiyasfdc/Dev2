@isTest
public class FundraisingProjectTriggerHandlerTest {
@TestSetup
    static void testData() {
        
        Account acc = new Account();
        acc.Name = 'test account';
        acc.ConfidentialNotes__c = 'test notes';
        insert as system acc;

        Account acc2 = new Account();
        acc2.Name = 'Demo Account';
        acc2.ConfidentialNotes__c = 'test notes comment';
        insert as system acc2;
        
        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();
        
    }
     @isTest
    static void testPaymentsupdate() {
        Test.startTest();
        List<Fundraising_Project__c> lstfund = new List<Fundraising_Project__c>();
        lstfund = [Select id,Name FROM Fundraising_Project__c WITH SYSTEM_MODE limit 1];
        lstfund[0].name='test FEINew';
        lstfund[0].Political__c = true;
        update as system lstfund[0];
           Test.stopTest();
        System.assertEquals(lstfund.isEmpty(), false);
    }
    @isTest
    static void testPayments() {
        Test.startTest();
        Delete [Select id FROM Fundraising_Project__c WITH SYSTEM_MODE];
        Test.stopTest();
        List<Fundraising_Project__c> lstfund = new List<Fundraising_Project__c>();
        lstfund = [Select id,Name FROM Fundraising_Project__c WITH SYSTEM_MODE];
       
        System.assertEquals(lstfund.isEmpty(), true);
    }
}