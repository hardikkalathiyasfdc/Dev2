@isTest
public class pledgeTriggerHandlerTest {
	
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
        
        Pledge__c pld = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );
        Pledge__c pld2 = TestDataFactory.createPledge(acc2.Id , fa.Id ,100000 );
        
        Payment__c pay = new Payment__c();
        pay.Scheduled_Date__c = System.today().addDays(-2);
        pay.Status__c = 'Scheduled';
        pay.Pledge__c = pld.id;
        pay.Amount__c = 10000;
        insert as system pay;

        Payment__c pay1 = new Payment__c();
        pay1.Scheduled_Date__c = System.today().addDays(-3);
        pay1.Status__c = 'Scheduled';
        pay1.Pledge__c = pld2.id;
        pay1.Amount__c = 10000;
        insert as system pay1;
        
        Recipient_Organization__c Org = new Recipient_Organization__c(Organization__c = acc.id , Fundraising_Project__c = fa.id);
        insert as system Org;
    }
    @isTest
    static void testPayments() {
        Test.startTest();
        List<Pledge__c> lstPledge = [Select id,Pledge_Amount__c FROM Pledge__c WITH SYSTEM_MODE];
        for(Pledge__c pledge: lstPledge){
            pledge.Pledge_Amount__c = 199888;
        }
        update as system lstPledge;
        Test.stopTest();
       
    }

    @isTest
    static void testSoftCreditOnMixedPledgeUpdates() {
        Account firstOrganization = [SELECT Id FROM Account WHERE Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        Account secondOrganization = [SELECT Id FROM Account WHERE Name = 'Demo Account' WITH SYSTEM_MODE LIMIT 1];
        Fundraising_Project__c project = [SELECT Id FROM Fundraising_Project__c WITH SYSTEM_MODE LIMIT 1];
        Contact firstContact = TestDataFactory.createContact(firstOrganization.Id, 'First');
        Contact secondContact = TestDataFactory.createContact(secondOrganization.Id, 'Second');
        Recipient_Organization__c firstMapping = [
            SELECT Id, Recipient_Soft_Credit__c FROM Recipient_Organization__c
            WHERE Organization__c = :firstOrganization.Id AND Fundraising_Project__c = :project.Id
            WITH SYSTEM_MODE LIMIT 1
        ];
        firstMapping.Recipient_Soft_Credit__c = firstContact.Id;
        update as system firstMapping;
        TestDataFactory.createRecipientOrganization(secondOrganization.Id, project.Id, secondContact.Id);
        List<Pledge__c> pledges = [
            SELECT Id, Organization__c, Pledge_Amount__c, Recipient_Soft_Credit__c
            FROM Pledge__c WHERE Fundraising_Effort__c = :project.Id WITH SYSTEM_MODE
        ];
        for (Pledge__c pledge : pledges) {
            if (pledge.Organization__c == firstOrganization.Id) {
                System.assertEquals(firstContact.Id, pledge.Recipient_Soft_Credit__c);
                pledge.Organization__c = secondOrganization.Id;
            } else {
                System.assertEquals(secondContact.Id, pledge.Recipient_Soft_Credit__c);
                pledge.Pledge_Amount__c += 1;
            }
        }

        Test.startTest();
        update as system pledges;
        Test.stopTest();

        for (Pledge__c pledge : [
            SELECT Recipient_Soft_Credit__c FROM Pledge__c
            WHERE Fundraising_Effort__c = :project.Id WITH SYSTEM_MODE
        ]) {
            System.assertEquals(secondContact.Id, pledge.Recipient_Soft_Credit__c);
        }
    }
    @isTest
    static void testdelete() {
        
        Fundraising_Activity__c ac = [Select Id, Activity_Total_Pledge_Amount__c from Fundraising_Activity__c WITH SYSTEM_MODE LIMIT 1];
        
        System.assertEquals (200000, ac.Activity_Total_Pledge_Amount__c);
        Pledge__c lstPledge = [Select id,Pledge_Amount__c FROM Pledge__c WITH SYSTEM_MODE LIMIT 1];
        
        Test.startTest();
        delete lstPledge;
        Test.stopTest();
        
        ac = [Select Id, Activity_Total_Pledge_Amount__c from Fundraising_Activity__c WITH SYSTEM_MODE LIMIT 1];
        
        System.assertEquals(100000, ac.Activity_Total_Pledge_Amount__c);
    } 
     @isTest
    static void testupdateDonor() {
        Test.startTest();
         set<Id> setIdss= new  set<Id>();
        for( Fundraising_Project__c uu: [Select Id FROM Fundraising_Project__c WITH SYSTEM_MODE]) {
            setIdss.add(uu.id);
        }
        PledgeTriggerHandler.updaterecipientOrganization(setIdss);
		Test.stopTest();
    }
    
    @isTest
    static void updatePledgeAmountTest () {
        
        Account a = [Select Id from Account where Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        
        Pledge__c p = [Select Id, Fundraising_Mode__c, Organization__c, Fundraising_Effort__c, Fundraising_Mode__r.Activity_Total_Pledge_Amount__c from Pledge__c where Organization__c =: a.Id WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals (200000, p.Fundraising_Mode__r.Activity_Total_Pledge_Amount__c);
        
        Recipient_Organization__c org = [Select Id, Total_pledge_amounts__c from Recipient_Organization__c where Fundraising_Project__c =: p.Fundraising_Effort__c AND Organization__c =: p.Organization__c WITH SYSTEM_MODE];
        System.assertEquals (100000, org.Total_pledge_amounts__c);
        
        Test.startTest();
        
        p.Report_Amount_USD__c = 150000;        
        update as system p;
        
        p = [Select Id, Fundraising_Mode__c, Fundraising_Effort__c, Organization__c, Fundraising_Mode__r.Activity_Total_Pledge_Amount__c from Pledge__c where Id =: p.Id WITH SYSTEM_MODE];
        System.assertEquals (250000, p.Fundraising_Mode__r.Activity_Total_Pledge_Amount__c);
                
        Test.stopTest();
        
        org = [Select Id, Total_pledge_amounts__c from Recipient_Organization__c where Fundraising_Project__c =: p.Fundraising_Effort__c AND Organization__c =: p.Organization__c WITH SYSTEM_MODE];
        System.assertEquals (150000, org.Total_pledge_amounts__c);
    }

    @isTest
    static void testCoFundingNotesOnPledgedStatusChange() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        Fundraising_Project__c proj = [SELECT Id FROM Fundraising_Project__c WITH SYSTEM_MODE LIMIT 1];
        proj.Political__c = false;
        proj.Personal__c = false;
        update as system proj;

        Pledge__c pld = [SELECT Id FROM Pledge__c WHERE Organization__c = :acc.Id WITH SYSTEM_MODE LIMIT 1];
        pld.Exclude_from_Donor_memo__c = false;
        pld.Report_Amount_USD__c = 100000;
        pld.Pledge_Start_Date__c = Date.newInstance(2022, 1, 1);
        pld.Pledge_End_Date__c = Date.newInstance(2024, 1, 1);
        pld.Status__c = 'Ask';
        update as system pld;

        Donor__c primary = new Donor__c(Organization__c = acc.Id, Amount__c = 100000,
                                        Credit_Type__c = 'Donor - Primary', Pledge__c = pld.Id);
        insert as system primary;

        Test.startTest();
        pld.Status__c = 'Pledged';
        update as system pld;
        Test.stopTest();

        Account result = [SELECT Id, Co_funder__c, Programmatic_Co_Funding_Notes__c
                          FROM Account WHERE Id = :acc.Id WITH SYSTEM_MODE];
        System.assertEquals(true, result.Co_funder__c, 'Org should be flagged as co-funder after Pledged transition');
        System.assertNotEquals(null, result.Programmatic_Co_Funding_Notes__c, 'Notes should be populated');






    }

    @isTest
	static void testCoFundingNotesUpdateOnEndDateChange() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        Fundraising_Project__c fundraisingProj = [SELECT Id FROM Fundraising_Project__c WITH SYSTEM_MODE LIMIT 1];
        fundraisingProj.Political__c = false;
        fundraisingProj.Personal__c = false;
        update as system fundraisingProj;

        Pledge__c pledge = [SELECT Id FROM Pledge__c WHERE Organization__c = :acct.Id WITH SYSTEM_MODE LIMIT 1];
        pledge.Exclude_from_Donor_memo__c = false;
        pledge.Report_Amount_USD__c = 100000;
        pledge.Pledge_Start_Date__c = Date.newInstance(2022, 1, 1);
        pledge.Pledge_End_Date__c = null;
        pledge.Status__c = 'Pledged';
        update as system pledge;

        Donor__c primaryDonor = new Donor__c(Organization__c = acct.Id, Amount__c = 100000,
                                        Credit_Type__c = 'Donor - Primary', Pledge__c = pledge.Id);
        insert as system primaryDonor;

        Account beforeUpdate = [SELECT Programmatic_Co_Funding_Notes__c FROM Account WHERE Id = :acct.Id WITH SYSTEM_MODE];
        System.assert(beforeUpdate.Programmatic_Co_Funding_Notes__c.contains('(2022)'),
                    'Notes should show start year only before end date is set');

        Test.startTest();
            pledge.Pledge_End_Date__c = Date.newInstance(2024, 1, 1);
            update as system pledge;
        Test.stopTest();

        Account acctAfterUpdate = [SELECT Programmatic_Co_Funding_Notes__c FROM Account WHERE Id = :acct.Id WITH SYSTEM_MODE];
        System.assert(acctAfterUpdate.Programmatic_Co_Funding_Notes__c.contains('(2022-2024)'),
                    'Notes should update to year range after end date is set');
    }
}