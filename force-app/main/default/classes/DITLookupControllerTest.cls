@isTest
public class DITLookupControllerTest {
    @TestSetup
    static void testData() {
        Account acc = new Account();
        acc.Name = 'test account';
        acc.ConfidentialNotes__c = 'test notes';
        insert acc;
        Account acc2 = new Account();
        acc2.Name = 'Demo Account';
        acc2.ConfidentialNotes__c = 'test notes comment';
        insert acc2;
        //created this for search contact name
        Contact conn=new Contact();
        conn.AccountId=acc.Id;
        conn.FirstName='Test Ved';
        conn.Title='Dev Test';
        conn.Email='dileep@gmail.com';
        conn.LastName='Dlii';
        insert conn;
        Contact conn1=new Contact();
        conn1.AccountId=acc.Id;
        conn1.FirstName='TestD Ved';
        conn1.Title='Dev TestD';
        conn1.Email='dileepD@gmail.com';
        conn1.LastName='test';
        insert conn1;
        Fundraising_Project__c fa = TestDataFactory.createFundraisingProject();
        Pledge__c pld = TestDataFactory.createPledge(acc.Id , fa.Id ,100000 );
        Recipient_Organization__c Org = new Recipient_Organization__c(Organization__c = acc.id,Fundraising_Project__c = fa.id);
        insert Org;
    }

    @isTest
    static void testGenerals() {
        List<Contact> conlst = [SELECT Id FROM Contact with SYSTEM_MODE];
        DITLookupController.SearchWrapper  wrap = new DITLookupController.SearchWrapper();
        DITLookupController.SearchWrapper  wrap3 = new DITLookupController.SearchWrapper();
        DITLookupController.ResultWrapper  Resll = new DITLookupController.ResultWrapper();
        wrap.fieldApiName='Name';
        wrap.objectApiName='Contact';
        wrap.selectedRecordId=null;
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
        DITLookupController.getPickLists('Pledge__c','Status__c');
        try {
            DITLookupController.fetchRecords(wrap);
            DITLookupController.fetchRecords(wrap3);
            wrap.objectApiName='Account';
            wrap.selectedRecordId='';
            wrap.searchString='test';
            DITLookupController.fetchRecords(wrap);
            wrap.objectApiName='Account';
            wrap.selectedRecordId= null;
            wrap.searchString='test';
            DITLookupController.fetchRecords(wrap);
             wrap.objectApiName='Account';
            wrap.selectedRecordId= [Select Id from Account with SYSTEM_MODE limit 1]?.Id;
            wrap.searchString='test';
            DITLookupController.fetchRecords(wrap);
        } catch (Exception e) {}
        Test.stopTest();
    }

}