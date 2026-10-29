@isTest
public class DonorTriggerHandlerTest {
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
        
        Test.startTest();
        List<Donor__c> donors = new List<Donor__c> ();
        
        Donor__c donor = new Donor__c(Contact__c = con.Id,Amount__c=10000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        donors.add(donor);
        Donor__c donorCred = new Donor__c(Contact__c = con.Id,Amount__c=5000,Credit_Type__c='Donor - Soft',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        donors.add(donorCred);
        insert as system donors;
        Test.stopTest();
    }
    
    @isTest
    static void testDelete() {
        Test.startTest();
        List<Donor__c> lstdonor = [Select id FROM Donor__c WITH SYSTEM_MODE];
        
        delete lstdonor;
        Test.stopTest();
        List<Donor__c> lstdonor2 = new List<Donor__c>();
        lstdonor2 = [Select id FROM Donor__c WITH SYSTEM_MODE];
        System.assertEquals(lstdonor2.isEmpty(), true);
    }
    
    @isTest
    static void testUpdate() {
        List<Donor__c> lstdonor = [Select id, Contact__c FROM Donor__c WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(lstdonor[0].Contact__c != null, true);
        
        Test.startTest();
        lstdonor[0].Donor_Type__c = 'Organization';
        update as system lstdonor[0];        
        Test.stopTest();
        
        lstdonor = [Select id, Contact__c FROM Donor__c where Id =: lstdonor WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(lstdonor[0].Contact__c == null, true);
    }

    @isTest
    static void testCoFundingNotesPopulatedOnDonorInsert() {
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Demo Account' WITH SYSTEM_MODE LIMIT 1];
        Fundraising_Project__c proj = [SELECT Id FROM Fundraising_Project__c WITH SYSTEM_MODE LIMIT 1];
        proj.Political__c = false;
        proj.Personal__c = false;
        update as system proj;

        Pledge__c pld2 = [SELECT Id FROM Pledge__c WHERE Organization__c = :acc2.Id WITH SYSTEM_MODE LIMIT 1];
        pld2.Status__c = 'Pledged';
        pld2.Exclude_from_Donor_memo__c = false;
        pld2.Report_Amount_USD__c = 100000;
        pld2.Pledge_Start_Date__c = Date.newInstance(2022, 1, 1);
        pld2.Pledge_End_Date__c = Date.newInstance(2023, 1, 1);
        update as system pld2;

        Test.startTest();
        Donor__c primary = new Donor__c(Organization__c = acc2.Id, Amount__c = 100000,
                                        Credit_Type__c = 'Donor - Primary', Pledge__c = pld2.Id);
        insert as system primary;
        Test.stopTest();

        Account result = [SELECT Id, Co_funder__c, Programmatic_Co_Funding_Notes__c
                          FROM Account WHERE Id = :acc2.Id WITH SYSTEM_MODE];
        System.assertEquals(true, result.Co_funder__c, 'Org should be flagged as co-funder');
        System.assertNotEquals(null, result.Programmatic_Co_Funding_Notes__c, 'Notes should be populated');
        System.assert(result.Programmatic_Co_Funding_Notes__c.contains('for:'), 'Notes should contain the summary header');
    }
}