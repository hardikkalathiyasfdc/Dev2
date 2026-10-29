@isTest
public class FundraisingProjectController_Test {

    @testSetup static void setup() {
        Account acc = new Account();
        acc.Name = 'test account';
        acc.ConfidentialNotes__c = 'test notes';
        insert as system acc;
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
        
        Recipient_Organization__c Org = new Recipient_Organization__c(Organization__c = acc.id,Fundraising_Project__c = fa.id);
        insert as system Org;
        
        }
     @istest static void testgetfundprojectCon() {
         
         List<Fundraising_Project__c> FunfId = [select id from Fundraising_Project__c WITH SYSTEM_MODE limit 1];
            Test.startTest();
        FundraisingProjectController.getchildrecords(FunfId[0].Id);
         Test.stopTest();
    }
    @istest static void testgetfundprojectConRecOrg() {
        Test.startTest();
         List<sObject> recOrg = [select id from Recipient_Organization__c WITH SYSTEM_MODE limit 1];
    
        FundraisingProjectController.createchildrecords(recOrg);
        Test.stopTest();
       
    }
     @istest static void testgetfundprojConRecOrg() {
          Test.startTest();
         List<sObject> testFail= new List<sObject>();
     sObject sobjFail = new Account(Name='Test ACCOUNTFailed',ConfidentialNotes__c = 'testFail',Industry__c='test');
         testFail.add(sobjFail);
        FundraisingProjectController.createchildrecords(testFail);
           Test.stopTest();
    }
 @istest static void testgetfundprojectConRecOrgValidate() {
         List<sObject> recOrg = [select id from Recipient_Organization__c WITH SYSTEM_MODE limit 1];
     string Idsr=recOrg[0].Id;
        FundraisingProjectController.validateanddeleteOrg(Idsr);
     
    }
    @istest static void testgetfundprojectSingleAct() {
         List<Fundraising_Activity__c> recOrg = [select id from Fundraising_Activity__c WITH SYSTEM_MODE limit 1];
     string FiunfaCT=recOrg[0].Id;
        FundraisingProjectController.getSingleActivity();
    }
     @istest static void testgetfundprojAppealRec() {
          
     sObject sobj1 = new Account(Name='TestAppral',ConfidentialNotes__c = 'testnotesApplea');
        FundraisingProjectController.createAppealrecod(sobj1);
         FundraisingProjectController.duplicateFundd('Test');
         FundraisingProjectController.checkFundraisingCodingAccess();
    }
    
    @isTest
    static void testForErrors () {
        try {
			FundraisingProjectController.createAppealrecod(null);   
        } catch (Exception e) {
        }
        
        try {
            FundraisingProjectController.createchildrecords(null);
        } catch (Exception e) {
        }
        
        try {
            FundraisingProjectController.getchildrecords(null);
        } catch (Exception e) {
        }
        
        try {
            FundraisingProjectController.duplicateFundd(null);
        } catch (Exception e) {
        }
    }
}