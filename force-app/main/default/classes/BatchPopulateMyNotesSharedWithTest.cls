@isTest
public class BatchPopulateMyNotesSharedWithTest {
    @testSetup
    public static void createTestData(){

        User createUser = TestDataFactory.createUser();
        Account accountData = TestDataFactory.createOrg('Test Organization');
        My_Notes__c myNotes = TestDataFactory.createMyNotes('Test Subject',accountData.Id);
        My_Notes__Share myNotesShare = TestDataFactory.createMyNotesShare(myNotes.Id,createUser.Id);

    }

    @isTest
    public static void myNotesShareTest(){
        Test.startTest();
        BatchPopulateMyNotesSharedWith objBatch = new BatchPopulateMyNotesSharedWith();
        Database.executeBatch(objBatch);
        objBatch.execute(null);
        Test.stopTest();
        My_Notes__c user_shared_with_test = [SELECT Shared_With__c FROM My_Notes__c WITH SYSTEM_MODE];
        System.debug('user_shared_with_test:'+user_shared_with_test);
        System.assertEquals('Code Check',user_shared_with_test.Shared_With__c, 'Checking if notes has been shared with appropriate user');

    }

}