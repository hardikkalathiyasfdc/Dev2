@IsTest
private class ConfidentialAttachmentDownloadPolicyTest {

    @TestSetup
    static void setupData() {
        Confidential_Items__c confidentialItem = new Confidential_Items__c();
        insert confidentialItem;
        ContentVersion version = new ContentVersion(
            Title = 'Confidential Test File',
            PathOnClient = 'ConfidentialTestFile.txt',
            VersionData = Blob.valueOf('Confidential test content')
        );
        insert version;
        version = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ];
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = version.ContentDocumentId,
            LinkedEntityId = confidentialItem.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;
    }

    @IsTest
    static void testConfidentialFileUIDownload() {
        ContentVersion version = [
            SELECT ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        FileEventStore fileEvent = new FileEventStore();
        fileEvent.DocumentId = String.valueOf(version.ContentDocumentId);
        fileEvent.FileAction = 'UI_DOWNLOAD';
        Test.startTest();
        Boolean result = new ConfidentialAttachmentDownloadPolicy().evaluate(fileEvent);
        Test.stopTest();
        System.assertEquals(
            true,
            result,
            'UI download of a file linked to a Confidential Item should trigger the policy.'
        );
    }

    @IsTest
    static void testConfidentialFileAPIDownload() {
        ContentVersion version = [
            SELECT ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        FileEventStore fileEvent = new FileEventStore();
        fileEvent.DocumentId = String.valueOf(version.ContentDocumentId);
        fileEvent.FileAction = 'API_DOWNLOAD';
        Test.startTest();
        Boolean result = new ConfidentialAttachmentDownloadPolicy().evaluate(fileEvent);
        Test.stopTest();
        System.assertEquals(
            true,
            result,
            'API download of a file linked to a Confidential Item should trigger the policy.'
        );
    }

    @IsTest
    static void testNonDownloadAction() {
        ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        FileEventStore fileEvent = new FileEventStore();
        fileEvent.DocumentId = String.valueOf(version.ContentDocumentId);
        fileEvent.FileAction = 'PREVIEW';
        Test.startTest();
        Boolean result =
            new ConfidentialAttachmentDownloadPolicy().evaluate(fileEvent);
        Test.stopTest();
        System.assertEquals(
            false,
            result,
            'Non-download actions should not trigger the policy.'
        );
    }

    @IsTest
    static void testNullDocumentId() {
        FileEventStore fileEvent = new FileEventStore();
        fileEvent.FileAction = 'UI_DOWNLOAD';
        Boolean result =
            new ConfidentialAttachmentDownloadPolicy().evaluate(fileEvent);
        System.assertEquals(
            false,
            result,
            'An event without a DocumentId should not trigger the policy.'
        );
    }

    @IsTest
    static void testFileNotLinkedToConfidentialItem() {
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;
        ContentVersion version = new ContentVersion(
            Title = 'Normal File',
            PathOnClient = 'NormalFile.txt',
            VersionData = Blob.valueOf('Normal content')
        );
        insert version;
        version = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ];
        insert new ContentDocumentLink(
            ContentDocumentId = version.ContentDocumentId,
            LinkedEntityId = account.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        FileEventStore fileEvent = new FileEventStore();
        fileEvent.DocumentId = String.valueOf(version.ContentDocumentId);
        fileEvent.FileAction = 'UI_DOWNLOAD';
        Test.startTest();
        Boolean result =
            new ConfidentialAttachmentDownloadPolicy().evaluate(fileEvent);
        Test.stopTest();
        System.assertEquals(
            false,
            result,
            'A file linked to a non-confidential record should not trigger the policy.'
        );
    }

    @IsTest
    static void testNullEvent() {
        Boolean result =
            new ConfidentialAttachmentDownloadPolicy().evaluate(null);
        System.assertEquals(
            false,
            result,
            'Null event should return false.'
        );
    }
}