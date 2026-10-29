@isTest
private class InteractionFilesMigration_Test {

	@TestSetup
	static void dataPrep() {
		Account acc = new Account(Name = 'TestAcct');
        insert acc;
        Contact testCon = new Contact(LastName = 'TestCon',AccountId = acc.Id);      
        insert testCon; 

        List<RecordType> interactionTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Interaction__c' AND DeveloperName='x2020'];
        Interaction__c interaction = new Interaction__c();
        interaction.RecordTypeId = interactionTypes[0].Id;
        interaction.Name = 'test interaction';
        interaction.Contact__c = testCon.Id;
        interaction.Teams__c = TestDataFactory.createTeam('IT').Id;
        insert interaction;

    	Blob fileContent = Blob.valueOf('test file');
    	String fileName = 'test filename';
    	ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = fileName;
        contentVersion.Title = fileName;
        contentVersion.VersionData = EncodingUtil.base64Decode(EncodingUtil.base64Encode(fileContent));

        insert contentVersion;

        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id AND IsLatest = true LIMIT 1];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = interaction.Id;
        contentDocumentLink.ShareType = 'I'; // Inferred permission

        insert contentDocumentLink;
	}

	@isTest
    static void testFileMigration() {
        Test.startTest();
        InteractionFilesMigration migration = new InteractionFilesMigration();
        Database.executeBatch(migration);
        Test.stopTest();
    }
}