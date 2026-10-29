@isTest
public class Organizationcustomlookupcontroller_Test {
@TestSetup
    static void testData() { 
        Account acc = new Account();
        acc.Name = 'test account';
        acc.ConfidentialNotes__c = 'test notes';
        insert as system acc;
        Contact con = new Contact(FirstName='Demo', LastName='Contact',AccountId=acc.Id);
        insert as system con;
        Account acc2 = new Account();
        acc2.Name = 'Demo Account';
        acc2.ConfidentialNotes__c = 'test notes comment';
        insert as system acc2;
        
        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();
        
        Pledge__c pld  = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );
        Pledge__c pld2 = TestDataFactory.createPledge(acc2.Id , fa.Id ,100000 );
         
        Payment__c pay= new Payment__c();
        pay.Scheduled_Date__c=system.today().addDays(-2);
        pay.Status__c='Scheduled';
        pay.Pledge__c=pld.id;
        pay.Amount__c=10000;
        insert as system pay;
        Payment__c pay1= new Payment__c();
        pay1.Scheduled_Date__c=system.today().addDays(-3);
        pay1.Status__c='Scheduled';
        pay1.Pledge__c=pld2.id;
        pay1.Amount__c=10000;
        insert as system pay1;
        
        Donor__c donor = new Donor__c(Contact__c = con.Id,Amount__c=10000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert as system donor;
        
        Recipient_Organization__c Org = new Recipient_Organization__c(Organization__c = acc.id,Fundraising_Project__c = fa.id);
        insert as system Org;
    }
    @isTest
    static void testFetchLook() {
         Test.startTest();
        List<Pledge__c> lstpedg = [Select id,Pledge_Amount__c FROM Pledge__c WITH SYSTEM_MODE limit 1];
         string recPled= 'Test';
        organizationCustomLookUpController.fetchLookupData(recPled,'Account');
        Test.stopTest();
    }
     @isTest
    static void testFetchDefaultRec() {
         Test.startTest();
        List<Account> AccId = [Select id FROM Account WITH SYSTEM_MODE limit 1];
         string recPled= AccId[0].Id;
        organizationCustomLookUpController.fetchDefaultRecord(recPled,'Account');
        organizationCustomLookUpController.fetchDefaultRecord('Test' ,'Account');
        Test.stopTest();
    }
     @isTest
    static void testFetchLOOKUP() {
         Test.startTest();
        List<Account> AccId = [Select id FROM Account WITH SYSTEM_MODE limit 1];
         string recPled= AccId[0].Id;
        organizationCustomLookUpController.fetchLookupDataFilter('Test','Recipient_Organization__c','Name',recPled,true);
         organizationCustomLookUpController.fetchLookupDataFilter('Test','Recipient_Organization__c','Name',recPled,false);
        Test.stopTest();
    }
}