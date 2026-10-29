@IsTest
public class DonorTriggerHelperTest {
	@TestSetup
    static void testData() {
        Account account1 = TestDataFactory.createOrg('Test Account1');
        Account account2 = TestDataFactory.createOrg('Demo Account2');
        Contact c = TestDataFactory.createContact(account1.Id , 'Test1');
        Contact c1 = TestDataFactory.createContact(account1.Id , 'Test2');
       	Fundraising_Project__c project = TestDataFactory.createFundraisingProject();
        Pledge__c pledge1 = TestDataFactory.createPledge(account1.Id ,project.Id , 1000  );

        TestDataFactory.createDonor(null,c.Id , pledge1.Id, 10000, 'Donor - Primary' );
        TestDataFactory.createDonor(account1.Id,null , pledge1.Id ,5000 , 'Donor - Soft' );

        Pledge__c pledge2 = TestDataFactory.createPledge(account2.Id ,project.Id , 2000  );
        TestDataFactory.createDonor(account2.Id,null , pledge2.Id ,2000 , 'Donor - Primary' );
    }

    @isTest
    static void testPledgeUpdatesOnDonorInsert () {
        Pledge__c p = [Select Id, Soft_Credit_s__c, Pledge_Name__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Soft_Credit_s__c == 'Test Account1');
        System.assertEquals (true, p.Pledge_Name__c == 'Test1 Contact');
        Account a = [Select Id from Account where Name = 'Demo Account2' with SYSTEM_MODE LIMIT 1];
        Test.startTest();
        TestDataFactory.createDonor(a.Id,null , p.Id ,5000 , 'Donor - Soft' );
        Test.stopTest();
        p = [Select Id, Soft_Credit_s__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Soft_Credit_s__c == 'Demo Account2, Test Account1');
    }

    @isTest
    static void testSoftCreditsOnDonorUpdate () {
        Pledge__c p = [Select Id, Soft_Credit_s__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Soft_Credit_s__c == 'Test Account1');
        Account softDonorAccount = [Select Id from Account where Name = 'Demo Account2' with SYSTEM_MODE LIMIT 1];
        Donor__c softDonor = [Select Id from Donor__c where Organization__r.Name = 'Test Account1' with SYSTEM_MODE LIMIT 1];
        Contact primaryDonorContact = [Select Id from Contact where FirstName = 'Test2' with SYSTEM_MODE LIMIT 1];
        Donor__c primaryDonor = [Select Id from Donor__c where Contact__r.FirstName = 'Test1' with SYSTEM_MODE];
        Test.startTest();
        softDonor.Organization__c = softDonorAccount.Id;
        update softDonor;
        Test.stopTest();
        p = [Select Id, Soft_Credit_s__c from Pledge__c where Pledge_Amount__c = 1000  with SYSTEM_MODE];
        System.assertEquals (true, p.Soft_Credit_s__c == 'Demo Account2');
    }

    @isTest
    static void testPledgeNameOnDonorUpdate () {
        Pledge__c p = [Select Id, Pledge_Name__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Pledge_Name__c == 'Test1 Contact');
        Contact primaryDonorContact = [Select Id from Contact where FirstName = 'Test2' with SYSTEM_MODE LIMIT 1];
        Donor__c primaryDonor = [Select Id from Donor__c where Contact__r.FirstName = 'Test1' with SYSTEM_MODE];
        Test.startTest();
        primaryDonor.Contact__c = primaryDonorContact.Id;
        update primaryDonor;
        Test.stopTest();
        p = [Select Id, Pledge_Name__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Pledge_Name__c == 'Test2 Contact');
    }

    @isTest
    static void testSoftCreditsOnDonorDelete () {
        Pledge__c p = [Select Id, Soft_Credit_s__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Soft_Credit_s__c == 'Test Account1');
        Donor__c d = [Select Id from Donor__c where Organization__r.Name = 'Test Account1' with SYSTEM_MODE LIMIT 1];
        Test.startTest();
        delete d;
        Test.stopTest();
        p = [Select Id, Soft_Credit_s__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Soft_Credit_s__c == null);
    }

    @isTest
    static void testUpdatePledgeNameOnContactUpdate () {
        Pledge__c p = [Select Id, Pledge_Name__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Pledge_Name__c == 'Test1 Contact');
        Contact c = [Select Id From Contact where Name = 'Test1 Contact' with SYSTEM_MODE LIMIT 1];
        c.FirstName = 'TestUpdated';
        Test.startTest();
       	update c;
        Test.stopTest();
        p = [Select Id, Pledge_Name__c from Pledge__c where Pledge_Amount__c = 1000 with SYSTEM_MODE];
        System.assertEquals (true, p.Pledge_Name__c == 'TestUpdated Contact');
    }

    @isTest
    static void testUpdatePledgeNameOnOrgUpdate () {
        Pledge__c p = [Select Id, Pledge_Name__c from Pledge__c where Pledge_Amount__c = 2000 with SYSTEM_MODE];
        System.assertEquals (true, p.Pledge_Name__c == 'Demo Account2');
        Account a = [Select Id , Name  From Account where Name = 'Demo Account2' with SYSTEM_MODE LIMIT 1];
        a.Name = 'Demo AccountUpdated';
        Test.startTest();
       	update a;
        Test.stopTest();
        p = [Select Id, Pledge_Name__c from Pledge__c where Pledge_Amount__c = 2000 with SYSTEM_MODE];
        System.assertEquals (true, p.Pledge_Name__c == 'Demo AccountUpdated');
    }

    @isTest
    static void testSoftCreditOnContactsMerge () {
        Pledge__c p = [Select Id, Soft_Credit_s__c from Pledge__c where Organization__r.Name = 'Test Account1' with SYSTEM_MODE];
        System.assertEquals (true, p.Soft_Credit_s__c == 'Test Account1');

        Account masterA = [Select Id from Account where Name = 'Demo Account2' with SYSTEM_MODE LIMIT 1];
        Account mergeA = [Select Id from Account where Name = 'Test Account1' with SYSTEM_MODE LIMIT 1];
        test.startTest();
        TriggerFactory.setBypass('PledgeTriggerHandler');
        merge masterA mergeA;
        test.stopTest();

        p = [Select Id, Soft_Credit_s__c from Pledge__c where Id =: p.Id with SYSTEM_MODE];
        System.assertEquals (true, p.Soft_Credit_s__c == 'Demo Account2');
    }
}