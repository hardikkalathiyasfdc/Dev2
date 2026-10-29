/********************************************************************************
* Class Name  : ConfidentialItemUploadController_Test
* Description : Test class for ConfidentialItemUploadController apex controller.
* Created By  : Slalom Consulting
* Change Log  : Created - 5/24/2019
********************************************************************************/
@isTest
private class ConfidentialItemUploadController_Test {

    @TestSetup
    public static void dataPrep() {
        Account acc = new Account(Name = 'TestAcct');
        insert acc;
        Contact testCon = new Contact(LastName = 'TestCon',AccountId = acc.Id);
        insert testCon;
    }
    public static testmethod void  saveChunk(){
        Contact testCon = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];
        blob file=  Blob.valueOf('sample text');
        ConfidentialItemUploadController.saveChunk(testCon.id,'testAttachment',file.toString(),'jpg','test desc', String.valueOf(Date.today()));
    }

    @isTest
    public static void testSaveConfidentailAttachment() {
        Contact testCon = [SELECT Id FROM Contact WITH SYSTEM_MODE LIMIT 1];
        List<RecordType> interactionTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Interaction__c' AND DeveloperName='LPContactInteraction' WITH SYSTEM_MODE];
        Interaction__c interaction = new Interaction__c();
        interaction.RecordTypeId = interactionTypes[0].Id;
        interaction.Name = 'test interaction';
        interaction.Contact__c = testCon.Id;
        interaction.Teams__c = TestDataFactory.createTeam('IT').Id;
        insert interaction;

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = 'test';
        contentVersion.Title = 'test';
        contentVersion.VersionData = EncodingUtil.base64Decode('test file');

        insert contentVersion;

        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id AND IsLatest = true WITH SYSTEM_MODE LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = interaction.Id;
        contentDocumentLink.ShareType = 'I'; // Inferred permission
        insert contentDocumentLink;

        String result = ConfidentialItemUploadController.saveConfidentialAttachment(contentVersion.ContentDocumentId, interaction.Id);
        System.assertEquals('success', result);
        String access = ConfidentialItemUploadController.checkUserCreationPermission(interaction.Id);
        System.assertEquals(access, 'true', 'User Access is different');

        String docs = ConfidentialItemUploadController.getConfidentialFiles(interaction.Id);

        ConfidentialAttachment__c attachment = [SELECT Id FROM ConfidentialAttachment__c WITH SYSTEM_MODE LIMIT 1];

        String processResult = ConfidentialItemUploadController.deleteConfidentialFile(attachment.Id);
    }
}