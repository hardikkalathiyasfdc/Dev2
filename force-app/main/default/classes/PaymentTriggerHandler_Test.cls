@isTest
public class PaymentTriggerHandler_Test {

    @testSetup
    static void dataSetup () {
        Account acc = new Account();
        acc.Name = 'test account';
        acc.ConfidentialNotes__c = 'test notes';
        insert acc;
        Account acc2 = new Account();
        acc2.Name = 'Demo Account';
        acc2.ConfidentialNotes__c = 'test notes comment';
        insert acc2;

        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();

        Pledge__c pld  = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );
        Pledge__c pld2 = TestDataFactory.createPledge(acc2.Id , fa.Id ,10000 );

        Payment__c pay= new Payment__c();
        pay.Scheduled_Date__c=system.today().addDays(-2);
        pay.Status__c='Scheduled';
        pay.Pledge__c=pld.id;
        pay.Amount__c=10000;
        insert pay;

        Payment__c pay1= new Payment__c();
        pay1.Scheduled_Date__c=system.today().addDays(-3);
        pay1.Status__c='Scheduled';
        pay1.Pledge__c=pld2.id;
        pay1.Amount__c = 10000;
        pay1.Payment_Amount_USD__c = 11000;
        insert pay1;
    }

    @isTest
    static void testPaymentAmountOnInsertPositive () {
        Payment__c p = [Select Id, Payment_Amount_USD__c from Payment__c where Pledge__r.Pledge_Amount__c = 100000 with SYSTEM_MODE LIMIT 1];
        System.assertEquals (true, p.Payment_Amount_USD__c == 10000);
    }

    @isTest
    static void testPaymentAmountOnInsertNegative () {
        Payment__c p = [Select Id, Payment_Amount_USD__c from Payment__c where Pledge__r.Pledge_Amount__c = 10000 with SYSTEM_MODE LIMIT 1];
        System.assertEquals (false, p.Payment_Amount_USD__c == 11000);
    }

    @isTest
    static void testPaymentAmountOnUpdatePositive () {
        Payment__c p = [Select Id, Payment_Amount_USD__c from Payment__c where Pledge__r.Pledge_Amount__c = 100000 with SYSTEM_MODE LIMIT 1];
        p.Amount__c = 20000;
        update p;
        p = [Select Id, Payment_Amount_USD__c from Payment__c where Id =: p.Id with SYSTEM_MODE LIMIT 1];
        System.assertEquals (true, p.Payment_Amount_USD__c == 20000);
    }

    @isTest
    static void testPaymentAmountOnUpdateNegative () {
        Payment__c p = [Select Id, Payment_Amount_USD__c from Payment__c where Pledge__r.Pledge_Amount__c = 10000 with SYSTEM_MODE LIMIT 1];
        p.Amount__c = 20000;
        update p;
        p = [Select Id, Payment_Amount_USD__c from Payment__c where Id =: p.Id with SYSTEM_MODE LIMIT 1];
        System.assertEquals (false, p.Payment_Amount_USD__c == 11000);
    }
}