@isTest
public class RecipientOrganizationTriggerHandlerTest {
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
    @isTest
    static void testPayments() {
        Test.startTest();
        Account acc = [Select id FROM Account WHERE Name='Demo Account'];
        Recipient_Organization__c lstOrg = [Select id,Composite_Key__c,Organization__c FROM Recipient_Organization__c WITH SYSTEM_MODE limit 1];
        lstOrg.Organization__c=acc.id;
        update as system lstOrg;
        Test.stopTest();
        System.assertEquals(lstOrg.Composite_Key__c != null, true);
        
        
    }

    @isTest
    static void testSoftCreditAssignment() {
        Account organization = [SELECT Id FROM Account WHERE Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        Fundraising_Project__c project = [SELECT Id FROM Fundraising_Project__c WITH SYSTEM_MODE LIMIT 1];
        Recipient_Organization__c recipient = getRecipient(organization, project);
        Contact softCreditRecipient = createContact(organization, 'First');

        Test.startTest();
        recipient.Recipient_Soft_Credit__c = softCreditRecipient.Id;
        update as system recipient;
        Test.stopTest();
        System.assertEquals(softCreditRecipient.Id, getPledge(organization, project).Recipient_Soft_Credit__c);
    }

    @isTest
    static void testSoftCreditChange() {
        Account organization = [SELECT Id FROM Account WHERE Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        Fundraising_Project__c project = [SELECT Id FROM Fundraising_Project__c WITH SYSTEM_MODE LIMIT 1];
        Recipient_Organization__c recipient = getRecipient(organization, project);
        Contact firstRecipient = createContact(organization, 'First');
        Contact secondRecipient = createContact(organization, 'Second');

        Test.startTest();
        recipient.Recipient_Soft_Credit__c = firstRecipient.Id;
        update as system recipient;
        recipient.Recipient_Soft_Credit__c = secondRecipient.Id;
        update as system recipient;
        Test.stopTest();
        System.assertEquals(secondRecipient.Id, getPledge(organization, project).Recipient_Soft_Credit__c);
    }

    @isTest
    static void testSoftCreditDelete() {
        Account organization = [SELECT Id FROM Account WHERE Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        Fundraising_Project__c project = [SELECT Id FROM Fundraising_Project__c WITH SYSTEM_MODE LIMIT 1];
        Recipient_Organization__c recipient = getRecipient(organization, project);
        Contact softCreditRecipient = createContact(organization, 'First');

        Test.startTest();
        recipient.Recipient_Soft_Credit__c = softCreditRecipient.Id;
        update as system recipient;
        delete as system recipient;
        Test.stopTest();
        System.assertEquals(null, getPledge(organization, project).Recipient_Soft_Credit__c);
    }

    @isTest
    static void testSoftCreditUndelete() {
        Account organization = [SELECT Id FROM Account WHERE Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        Fundraising_Project__c project = [SELECT Id FROM Fundraising_Project__c WITH SYSTEM_MODE LIMIT 1];
        Recipient_Organization__c recipient = getRecipient(organization, project);
        Contact softCreditRecipient = createContact(organization, 'First');

        Test.startTest();
        recipient.Recipient_Soft_Credit__c = softCreditRecipient.Id;
        update as system recipient;
        delete as system recipient;
        undelete as system recipient;
        Test.stopTest();
        System.assertEquals(softCreditRecipient.Id, getPledge(organization, project).Recipient_Soft_Credit__c);
    }

    private static Recipient_Organization__c getRecipient(Account organization, Fundraising_Project__c project) {
        return [
            SELECT Id, Fundraising_Project__c, Organization__c, Recipient_Soft_Credit__c
            FROM Recipient_Organization__c
            WHERE Organization__c = :organization.Id AND Fundraising_Project__c = :project.Id
            WITH SYSTEM_MODE
            LIMIT 1
        ];
    }

    private static Pledge__c getPledge(Account organization, Fundraising_Project__c project) {
        return [
            SELECT Recipient_Soft_Credit__c
            FROM Pledge__c
            WHERE Organization__c = :organization.Id AND Fundraising_Effort__c = :project.Id
            WITH SYSTEM_MODE
            LIMIT 1
        ];
    }

    private static Contact createContact(Account organization, String firstName) {
        Contact softCreditRecipient = new Contact(FirstName = firstName, LastName = 'Recipient', AccountId = organization.Id);
        insert as system softCreditRecipient;
        return softCreditRecipient;
    }
}