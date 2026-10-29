@isTest
public class PledgeWidgetController_Test {

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

        Contact con = new Contact(FirstName='Demo', LastName='Contact',AccountId=acc.Id);
        insert con;

        Contact con2 = new Contact(FirstName='Contact', LastName='Two',AccountId=acc.Id);
        insert con2;

        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();

        Pledge__c pld  = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );
        Pledge__c pld2 = TestDataFactory.createPledge(acc2.Id , fa.Id ,100000 );
        Pledge__c pld3 = TestDataFactory.createPledge(acc2.Id , fa.Id ,100000 );

        Recipient_Organization__c Org = new Recipient_Organization__c(Organization__c = acc.id,Fundraising_Project__c = fa.id);
        insert Org;

        List<Donor__c> donorsToInsert = new List<Donor__c> ();

        Donor__c donor = new Donor__c(Contact__c = con.Id,Amount__c = 10000,Credit_Type__c='Donor - Primary',
                                      Pledge__c = pld.id);
        donorsToInsert.add (donor);

        Donor__c donor1 = new Donor__c(Contact__c = con.Id,Amount__c = 20000,Credit_Type__c='Donor - Primary',
                                      Pledge__c = pld2.id);
        donorsToInsert.add (donor1);

        Donor__c donor2 = new Donor__c(Contact__c = con2.Id,Amount__c = 30000,Credit_Type__c='Donor - Soft',
                                      Pledge__c = pld.id);
        donorsToInsert.add (donor2);

        Donor__c donor21 = new Donor__c(Organization__c = acc.Id,Amount__c = 30000,Credit_Type__c='Donor - Soft',
                                      Pledge__c = pld.id);
        donorsToInsert.add (donor21);

        Donor__c donor3 = new Donor__c(Contact__c = con2.Id,Amount__c = 40000,Credit_Type__c='Donor - Primary',
                                      Pledge__c = pld3.id);
        donorsToInsert.add (donor3);

        insert donorsToInsert;
    }

    @isTest
    static void pastSoftCreditsPositiveTest () {
        Donor__c d = [Select Id, Pledge__c from Donor__c where Amount__c = 20000 with SYSTEM_MODE LIMIT 1];

        PledgeWidgetController.DonorsData data = PledgeWidgetController.getPreviousSoftCredits (d.Pledge__c);

        System.assertEquals (!data.donorContacts.isEmpty(), true);
        System.assertEquals (!data.donorOrgs.isEmpty(), true);
    }

    @isTest
    static void pastSoftCreditsNegativeTest () {
        Donor__c d = [Select Id, Pledge__c from Donor__c where Amount__c = 40000 with SYSTEM_MODE LIMIT 1];

        PledgeWidgetController.DonorsData data = PledgeWidgetController.getPreviousSoftCredits (d.Pledge__c);
        System.assertEquals (data.donorContacts == null, true);
        System.assertEquals (data.donorOrgs == null, true);
    }

    @isTest
    static void testErrorBlock () {
        try {
            Donor__c d = [Select Id, Pledge__c from Donor__c where Amount__c = 10000 with SYSTEM_MODE LIMIT 1];
        	PledgeWidgetController.DonorsData data = PledgeWidgetController.getPreviousSoftCredits (d.Pledge__c);
        } catch (Exception e) {

        }
    }
}