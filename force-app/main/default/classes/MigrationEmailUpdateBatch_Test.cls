@isTest
private class MigrationEmailUpdateBatch_Test {

    @isTest
    static void testBatchExecution() {
        Contact cnt = new Contact(FirstName='Test', LastName='Test', Email='test@test.com', Business_Email_2__c='test2@test.com',
            Personal_Email_2__c='test@bloomberg.net1', Alternate_Email__c='test@bloomberg.org1', Web_Email__c='test@test1.com');
        insert cnt;

        Test.startTest();

        MigrationEmailUpdateBatch batch = new MigrationEmailUpdateBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        Contact updatedContact = [SELECT Email, Business_Email_2__c, Personal_Email_2__c, Alternate_Email__c, Web_Email__c
                                 FROM Contact
                                 WHERE Id =: cnt.Id];
        System.assertEquals('test@test.com.invalid', updatedContact.Email);
        System.assertEquals('test@bloomberg.net1.invalid', updatedContact.Personal_Email_2__c);
    }
}