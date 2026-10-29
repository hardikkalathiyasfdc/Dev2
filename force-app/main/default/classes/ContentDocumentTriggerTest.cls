@isTest
private class ContentDocumentTriggerTest {
    @testSetup
    Static void testdata(){
        // Create Data
        Account acc = TestDataFactory.createOrg('Test Account');
        Fundraising_Project__c fundProj = TestDataFactory.createFundraisingProject();
        Pledge__c pledge = TestDataFactory.createPledge(acc.Id , fundProj.Id ,100000 );
        Agreement__c agg = TestDataFactory.createAgreement('Test', pledge.Id,'Pledge','Awaiting Signature' );
    }

    @isTest static void insertFileForInteraction(){
        // Create Data
        Account acc2 = TestDataFactory.createCityViewOrg();
        Interaction__c interaction = TestDataFactory.createOrgInteraction(acc2.Id,'Test Report 1 (Email)', 'Arts','Publish to CityView');

        Test.startTest();
        TestDataFactory.createFile('Test',interaction.Id);
        Test.stopTest();
        interaction = [Select Id, File_Attached_New__c from Interaction__c where Id = :interaction.Id WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(interaction.File_Attached_New__c, 'Yes', 'Error File_Attached_New__c  is not updated correctly for Interaction');
    }

    @isTest
    public static void deleteFileForInteraction(){
        // Create Data
        Account acc2 = TestDataFactory.createCityViewOrg();
        Interaction__c interaction = TestDataFactory.createOrgInteraction(acc2.Id,'Test Report 1 (Email)', 'Arts','Publish to CityView');

        Test.startTest();
        ContentDocumentLink objCDL = TestDataFactory.createFile('Test',interaction.Id);
        List<ContentDocument> cdls = [Select Id, title from ContentDocument WHERE Id =: objCDL.ContentDocumentId WITH SYSTEM_MODE];
        Delete cdls;
        Test.stopTest();
        interaction = [Select Id, File_Attached_New__c from Interaction__c where Id = :interaction.Id WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(interaction.File_Attached_New__c, 'No', 'Error File_Attached_New__c is not updated correctly for Interaction');
    }

    @Istest
    public static void testAggremnetMultipleFiles(){
        Agreement__c agg = [Select Id FROM Agreement__c WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        TestDataFactory.createFile('Test',agg.Id);
        TestDataFactory.createFile('Test2',agg.Id);
        Test.stopTest();
        agg = [Select Id,NumberAttachment__c,Attachment_Id__c,FileName__c FROM Agreement__c WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(agg.NumberAttachment__c, 2, 'Files count should be 2 for Agreement');
        System.assertEquals(agg.Attachment_Id__c, null, 'Attachment Id should not be populated');
        System.assertEquals(agg.FileName__c, null, 'FileName Id should not be populated');
    }

    @Istest
    public static void testAggremnetDeleteMultipleFiles(){
        Agreement__c agg = [Select Id FROM Agreement__c WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        ContentDocumentLink objCDL = TestDataFactory.createFile('Test',agg.Id);
        ContentDocumentLink objCDL2 = TestDataFactory.createFile('Test2',agg.Id);
        List<ContentDocument> cdls = [Select Id, title from ContentDocument WHERE Id = :objCDL.ContentDocumentId];
        Delete cdls;
        Test.stopTest();
        agg = [Select Id,NumberAttachment__c,Attachment_Id__c,FileName__c FROM Agreement__c WITH SYSTEM_MODE LIMIT 1];
        System.assertEquals(agg.NumberAttachment__c, 1, 'Files count should be 1 for Agreement');
        System.assertNotEquals(agg.Attachment_Id__c, null, 'Attachment Id should be populated');
        System.assertNotEquals(agg.FileName__c, null, 'FileName Id should be populated');
    }
}