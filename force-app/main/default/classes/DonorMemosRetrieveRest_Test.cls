@isTest
public class DonorMemosRetrieveRest_Test {
	
    @testSetup
    static void dataSetup () {
        Account acc = new Account();
        acc.Name = 'test account';
        acc.ConfidentialNotes__c = 'test notes';
        acc.Donor_Memo_Override_Name__c = 'test override';
        insert as system acc;
        Account acc2 = new Account();
        acc2.Name = 'Demo Account';
        acc2.ConfidentialNotes__c = 'test notes comment';
        insert as system acc2;
        
		
		Account acc3 = new Account();
        acc3.Name = 'Donor Org';
        acc3.ConfidentialNotes__c = 'test notes comment sdsdf';
        insert as system acc3;
        
        Contact con = new Contact(FirstName='Demo', LastName='Contact',AccountId=acc.Id);
        insert as system con;
        
        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();
        
        Pledge__c pld  = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );
        Pledge__c pld2 = TestDataFactory.createPledge(acc2.Id , fa.Id ,100000 );
        Pledge__c pld3 = TestDataFactory.createPledge(acc2.Id , fa.Id ,100000 );

       
        List<Pledge__c> pledges = new List<Pledge__c>();
        pld.Pledge_Start_Date__c = System.today().addDays(-31);
        pld.Status__c = 'Pledged';
        pledges.add(pld);

        pld2.Pledge_Start_Date__c = System.today().addDays(-31);
        pld.Status__c = 'Pledged';
        pledges.add(pld2);

        pld3.Pledge_Start_Date__c = System.today().addDays(-31);
        pld.Status__c = 'Pledged';
        pledges.add(pld3);

        update as system pledges;
        
        
        Recipient_Organization__c Org = new Recipient_Organization__c(Organization__c = acc.id,Fundraising_Project__c = fa.id);
        insert as system Org;

        Donor__c donor = new Donor__c(Contact__c = con.Id,Amount__c=10000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert as system donor;
        Donor__c donor1 = new Donor__c(Amount__c=20000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert as system donor1;
        Donor__c donor2 = new Donor__c(Contact__c = con.Id,Amount__c=30000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc.id,Pledge__c=pld.id);
        insert as system donor2;
        Donor__c donor3 = new Donor__c(Amount__c=30000,Credit_Type__c='Donor - Primary',
                                      Organization__c=acc3.id,Pledge__c=pld.id);
        insert as system donor3;
        Possible_Benefits__c poBen=new Possible_Benefits__c(Name = 'TestPB',Fundraising_Effort__c = fa.id);
        insert as system poBen;
    }
    
    @isTest
    static void retrieveDonorMemoByDonorTest () {
        Date start = System.today().addDays(-45);
        String startDate = String.valueOf(start.year())+'-'+String.valueOf(start.month())+'-'+String.valueOf(start.day());
        Date endD = System.today();
        String endDate = String.valueOf(endD.year())+'-'+String.valueOf(endD.month())+'-'+String.valueOf(endD.day());
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/getDonorMemos';
        req.addParameter('startDate', startDate);
        req.addParameter('endDate', endDate);
        req.addParameter('sortBy', 'Donor');
        req.addParameter('minAmount', '1');
        req.addParameter('coverPage', 'false');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        
        DonorMemoService.DonorMemo memo = DonorMemosRetrieveRest.doGet();
        Test.stopTest();
        system.assertEquals(memo.mainPageSection.donors.size(), 3);    
    }
    
    @isTest
    static void retrieveDonorMemoByFocusAreaTest () {
        Date start = System.today().addDays(-45);
        String startDate = String.valueOf(start.year())+'-'+String.valueOf(start.month())+'-'+String.valueOf(start.day());
        Date endD = System.today();
        String endDate = String.valueOf(endD.year())+'-'+String.valueOf(endD.month())+'-'+String.valueOf(endD.day());
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/getDonorMemos';
        req.addParameter('startDate', startDate);
        req.addParameter('endDate', endDate);
        req.addParameter('sortBy', 'Focus Area');
        req.addParameter('minAmount', '1');
        req.addParameter('coverPage', 'false');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        
        DonorMemoService.DonorMemo memo = DonorMemosRetrieveRest.doGet();
        Test.stopTest();
        system.assertEquals(memo.mainPageSection.focusAreasWithDonors.size(), 1);    
    }
    
    @isTest
    static void retrieveDonorMemoByProjectTest () {
        Date start = System.today().addDays(-45);
        String startDate = String.valueOf(start.year())+'-'+String.valueOf(start.month())+'-'+String.valueOf(start.day());
        Date endD = System.today();
        String endDate = String.valueOf(endD.year())+'-'+String.valueOf(endD.month())+'-'+String.valueOf(endD.day());
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/getDonorMemos';
        req.addParameter('startDate', startDate);
        req.addParameter('endDate', endDate);
        req.addParameter('sortBy', 'Project');
        req.addParameter('minAmount', '1');
        req.addParameter('coverPage', 'false');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        
        DonorMemoService.DonorMemo memo = DonorMemosRetrieveRest.doGet();
        Test.stopTest();
        system.assertEquals(memo.mainPageSection.projectsWithDonors.size(), 1);    
    }
    
    @isTest
    static void retrieveDonorMemoWithListsTest() {
        Account org = [SELECT Id FROM Account WHERE Name = 'test account' WITH SYSTEM_MODE LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Contact' WITH SYSTEM_MODE LIMIT 1];

        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName();
        String contactRtDevName;
        for (String devName : rtMap.keySet()) {
            if (devName != 'Organization' && rtMap.get(devName).isAvailable()) {
                contactRtDevName = devName;
                break;
            }
        }

        Campaign orgCampaign = TestDataFactory.createCampaigns(1, 'Organization', true)[0];
        Campaign contactCampaign = TestDataFactory.createCampaigns(
            1,
            contactRtDevName != null ? contactRtDevName : 'Organization',
            true
        )[0];

        TestDataFactory.createListOrganization(orgCampaign.Id, org.Id);
        TestDataFactory.createCampaignMember(contactCampaign.Id, con.Id);

        Date start = System.today().addDays(-45);
        String startDate = String.valueOf(start.year())+'-'+String.valueOf(start.month())+'-'+String.valueOf(start.day());
        Date endD = System.today();
        String endDate = String.valueOf(endD.year())+'-'+String.valueOf(endD.month())+'-'+String.valueOf(endD.day());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getDonorMemos';
        req.addParameter('startDate', startDate);
        req.addParameter('endDate', endDate);
        req.addParameter('sortBy', 'Donor');
        req.addParameter('minAmount', '1');
        req.addParameter('coverPage', 'false');
        req.addParameter('selectedDonorLists', orgCampaign.Id + ',' + contactCampaign.Id);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        DonorMemoService.DonorMemo memo = DonorMemosRetrieveRest.doGet();
        Test.stopTest();

        System.assertNotEquals(null, memo);
        System.assertNotEquals(null, memo.mainPageSection);
    }
}