@isTest
public class Fundraising_Summary_Test {
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
        Pledge__c pld3 = TestDataFactory.createPledge(acc2.Id , fa.Id ,100000 );

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

    }
    @isTest
    static void tesfudSummary() {

        Test.startTest();
        List<Pledge__c> lstPledge = [Select id,Pledge_Amount__c FROM Pledge__c WITH SYSTEM_MODE limit 1];
         List<Sobject> lstBenifit = [Select id FROM Pledge_Benefit__c WITH SYSTEM_MODE limit 1];
         List<Donor__c> lstDonor = [Select id,Contact__r.Id ,Organization__r.Id FROM Donor__c WITH SYSTEM_MODE limit 1];
         List<Donor__c> lstDonornew = [Select id,Contact__r.Id ,Organization__r.Id FROM Donor__c WITH SYSTEM_MODE limit 3];
        Id recordId=lstDonornew[0].Organization__r.Id;
        Id recordIdcont=lstDonornew[0].Contact__r.Id;
        Fundraising_Summary.getFundraisingList(recordId);
        Fundraising_Summary.getFundraisingRecepient (recordId);
        Fundraising_Summary.getRecordDetails (recordId);
        Fundraising_Summary.getFundraisingList(recordIdcont);
        Test.stopTest();
    }

    @isTest
    static void testContactReceivingDetails() {
        Contact contactRecord = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];
        Account accountRecord = [SELECT Id FROM Account WITH SYSTEM_MODE LIMIT 1];

        Test.startTest();
        List<Pledge__c> contactPledges = Fundraising_Summary.getContactReceivingDetails(contactRecord.Id);
        List<Pledge__c> accountPledges = Fundraising_Summary.getContactReceivingDetails(accountRecord.Id);
        List<Pledge__c> nullRecordPledges = Fundraising_Summary.getContactReceivingDetails(null);
        Test.stopTest();

        System.assertNotEquals(null, contactPledges);
        System.assertEquals(0, accountPledges.size());
        System.assertEquals(0, nullRecordPledges.size());
    }
}