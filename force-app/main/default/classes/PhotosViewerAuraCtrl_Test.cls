@isTest
private class PhotosViewerAuraCtrl_Test {
    
    @isTest
    static void testPhotoView() {
        // Create a user
        User u = TestDataFactory.createUser();
        
        // Create a ContentVersion
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'dummy';
        cv1.PathOnClient = 'dummy.pdf';
        cv1.VersionData = EncodingUtil.base64Decode('test');
        insert cv1;
        
        // Get the ContentDocumentId from the inserted ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id].ContentDocumentId;
        
        // Run setup object operations inside System.runAs
        System.runAs(u) {
            // Create a ContentWorkspace
            ContentWorkspace cw = new ContentWorkspace();
            cw.Name = 'test';
            insert cw;
            
            // Create a ContentDocumentLink with the correct ContentDocumentId
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = cw.Id;
            insert cdl;
        }
        
        Test.startTest();
        String result = PhotosViewerAuraCtrl.getPhotos('Asset Library');
        System.assert(String.isNotBlank(result), 'Result should not be blank');
        Test.stopTest();
    }
    
        @isTest
    static void testPhotoViewwithException() {
        // Create a user
        User u = TestDataFactory.createUser();
        
        // Create a ContentVersion
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'dummy';
        cv1.PathOnClient = 'dummy.pdf';
        cv1.VersionData = EncodingUtil.base64Decode('test');
        insert cv1;
        
        // Get the ContentDocumentId from the inserted ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id].ContentDocumentId;
        
        // Run setup object operations inside System.runAs
        System.runAs(u) {
            // Create a ContentWorkspace
            ContentWorkspace cw = new ContentWorkspace();
            cw.Name = 'test';
            insert cw;
            
            // Create a ContentDocumentLink with the correct ContentDocumentId
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = cw.Id;
            insert cdl;
        }
        
        Test.startTest();
        PhotosViewerAuraCtrl.forceException = True;
        String result = PhotosViewerAuraCtrl.getPhotos('Asset Library');
        Test.stopTest();
    }
}