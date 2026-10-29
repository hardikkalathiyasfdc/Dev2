@isTest
public class PledgeRecordEditFormController_Test {
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
        Contact con = new Contact(FirstName='Demo', LastName='Contact',AccountId=acc.Id);
        insert as system con;
        
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
        Donor__c donor = new Donor__c(Contact__c = con.Id,Amount__c=10000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert as system donor;
        Donor__c donor1 = new Donor__c(Contact__c = con.Id,Amount__c=20000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert as system donor1;
        Donor__c donor2 = new Donor__c(Contact__c = con.Id,Amount__c=30000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert as system donor2;
        Possible_Benefits__c poBen=new Possible_Benefits__c(Name = 'TestPB',Fundraising_Effort__c = fa.id);
        insert as system poBen;
        
        Pledge_Benefit__c poBenPle=new Pledge_Benefit__c(Benefits__c=poBen.id,Pledge__c=pld.id,Quantity__c=10.0);
        insert poBenPle;
        Possible_Tiers__c pooti=new Possible_Tiers__c(Name = 'testPooTire',Fundraising_Effort__c = fa.id);
         insert as system pooti;
    }
    @isTest
    static void testPledgeEditchild() {
        
        Test.startTest();
        List<Pledge__c> lstPledge = [Select id,Pledge_Amount__c FROM Pledge__c WITH SYSTEM_MODE limit 1];
         List<Sobject> lstBenifit = [Select id FROM Pledge_Benefit__c WITH SYSTEM_MODE limit 1];
         List<Sobject> lstDonor = [Select id FROM Donor__c WITH SYSTEM_MODE limit 1];
         List<Sobject> lstDonornew = [Select id FROM Donor__c WITH SYSTEM_MODE limit 3];
        string recordId=lstPledge[0].Id;
        list<string> lstId=new list<string>();
        lstId.add(lstDonornew[2].Id);
        PledgeRecordEditFormController.createChildRecords(recordId,lstDonor,lstBenifit,lstId);
        Test.stopTest();
    }
     @isTest
    static void testPledgeEditParentId() {
        
        Test.startTest();
        List<Fundraising_Activity__c> lstfundri = [Select id FROM Fundraising_Activity__c WITH SYSTEM_MODE limit 1];
         List<Fundraising_Project__c> lstFubdPro = [Select id FROM Fundraising_Project__c WITH SYSTEM_MODE limit 1];
         List<Possible_Tiers__c> lstpposTier = [Select id FROM Possible_Tiers__c WITH SYSTEM_MODE limit 1];
        string recordIdfund=lstfundri[0].Id;
        string recordIdfundPro=lstFubdPro[0].Id;
        string recordIdoppTier=lstpposTier[0].Id;
        PledgeRecordEditFormController.getParentIds(recordIdfund);
        PledgeRecordEditFormController.getParentIds(recordIdfundPro);
        PledgeRecordEditFormController.getParentIds(recordIdoppTier);
        Test.stopTest();
    }
     @isTest
    static void testPledgeEditchildget() {
        
        Test.startTest();
        List<Pledge__c> lstpedg = [Select id,Pledge_Amount__c FROM Pledge__c WITH SYSTEM_MODE limit 1];
         string recPled= lstpedg[0].Id;
        PledgeRecordEditFormController.getPledgeChilds(recPled);
        Test.stopTest();
    }
}