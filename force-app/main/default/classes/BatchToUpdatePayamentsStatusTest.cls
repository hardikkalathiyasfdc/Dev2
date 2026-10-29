@isTest
public class BatchToUpdatePayamentsStatusTest {
    
    @TestSetup
    static void testData() {
        
        Account acc = new Account();
        acc.Name = 'test account';
        acc.ConfidentialNotes__c = 'test notes';
        insert as system acc;
        
        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();
        
        Pledge__c pld = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );
        
        Payment__c pay = new Payment__c();
        pay.Scheduled_Date__c = System.today().addDays(-2);
        pay.Status__c = 'Scheduled';
        pay.Pledge__c = pld.id;
        pay.Amount__c = 10000;
        insert as system pay;

        Payment__c pay1 = new Payment__c();
        pay1.Scheduled_Date__c = System.today().addDays(-3);
        pay1.Status__c = 'Scheduled';
        pay1.Pledge__c = pld.id;
        pay1.Amount__c = 10000;
        insert as system pay1;
        
        
    }
    
    @isTest
    static void testPayments() {
        Test.startTest();
        BatchToUpdatePayamentsStatus batch = new BatchToUpdatePayamentsStatus();
        batch.execute(null);
        Test.stopTest();
        Payment__c payments = [SELECT id,Status__c FROM Payment__c WITH SYSTEM_MODE LIMIT 1];
        system.debug('the payments are'+payments);
        System.assertEquals('Past Due', payments.Status__c);   
    }
    
    @IsTest
    static void execute_catch_only() {
        Test.startTest(); 
        	new BatchToUpdatePayamentsStatus().execute(null, (List<Payment__c>)null);
        Test.stopTest();
    }
}