@isTest
public class DonorMemoHelper_Test {
	
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
        
        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();
        
        Pledge__c pld = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );
        Pledge__c pld2 = TestDataFactory.createPledge(acc2.Id , fa.Id ,100000 );

        Recipient_Organization__c Org = new Recipient_Organization__c(Organization__c = acc.id,Fundraising_Project__c = fa.id);
        insert Org;
        Donor__c donor = new Donor__c(Contact__c = con.Id,Amount__c=10000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert donor;
        Donor__c donor1 = new Donor__c(Contact__c = con.Id,Amount__c=20000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert donor1;
        Donor__c donor2 = new Donor__c(Contact__c = con.Id,Amount__c=30000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert donor2;
        Possible_Benefits__c poBen=new Possible_Benefits__c(Name = 'TestPB',Fundraising_Effort__c = fa.id);
        insert poBen;
        
        TestDataFactory.createCampaign('Test event');
    }
    
    @isTest
    static void getFiltersDataTest () {
        DonorMemoHelper.FiltersData data = DonorMemoHelper.getFiltersData();
        System.assertEquals (true, data != null);
        System.assertEquals (true, !data.projects.isEmpty());
    }
    
    @isTest
    static void searchDonorsTest () {
        List<Campaign> lists = DonorMemoHelper.searchDonorLists('event', new List<Id> {});
        System.assertEquals(1, lists.size());
    }
}