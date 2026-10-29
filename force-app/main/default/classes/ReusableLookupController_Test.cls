@isTest
public class ReusableLookupController_Test {
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
        //created this for search contact name
        Contact conn=new Contact();
        conn.AccountId=acc.Id;
        conn.FirstName='Test Ved';
        conn.Title='Dev Test';
        conn.Email='dileep@gmail.com';
        conn.LastName='Dlii';
        insert as system conn;
        Contact conn1=new Contact();
        conn1.AccountId=acc.Id;
        conn1.FirstName='TestD Ved';
        conn1.Title='Dev TestD';
        conn1.Email='dileepD@gmail.com';
        conn1.LastName='test';
        insert as system conn1;
        
        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();
        
        Pledge__c pld  = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );

        Recipient_Organization__c Org = new Recipient_Organization__c(Organization__c = acc.id,Fundraising_Project__c = fa.id);
        insert as system Org;
    }
    @isTest
    static void testGenerals() {
        
        List<Contact> conlst = [SELECT Id FROM Contact WITH SYSTEM_MODE];
        ReusableLookupController.SearchWrapper  wrap = new ReusableLookupController.SearchWrapper();
        ReusableLookupController.SearchWrapper  wrap3 = new ReusableLookupController.SearchWrapper();
        ReusableLookupController.ResultWrapper  Resll = new ReusableLookupController.ResultWrapper();
        wrap.fieldApiName='Name';
        wrap.objectApiName='Contact';
        wrap.selectedRecordId=conlst[0].Id;
        wrap.searchString='Tes';
        wrap.otherFieldApiName='Title';
        wrap.parentRecordId='';
        wrap.parentFieldApiName='';
        wrap3.fieldApiName='Name';
        wrap3.objectApiName='Contact';
        wrap3.selectedRecordId=conlst[1].Id;
        wrap3.searchString='TestD';
        wrap.otherFieldApiName='Title';
        wrap.parentRecordId='';
        wrap.parentFieldApiName='';
        Test.startTest();
        try
        {
            ReusableLookupController.fetchRecords(wrap);
            ReusableLookupController.fetchRecords(wrap3);
        }
        catch(exception e)
        {
        }     
        
        
        Test.stopTest();
    }
    
}