public with sharing class PhotosViewerAuraCtrl {

    private static final String ERR_GET_PHOTOS = 'PHOTOS_VIEW_CONTROLLER_GET_PHOTOS_FAILED';

    @TestVisible
    private static Boolean forceException = false;

    @AuraEnabled(cacheable=true)
    public static String getPhotos(String libName) {
        try {
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            ContentWorkspace cw = [
                SELECT Id
                FROM ContentWorkspace
                WHERE Name = :libName
            ];

            Set<Id> contentDocumentIds = new Set<Id>();

            for (ContentDocumentLink link : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :cw.Id
            ]) {
                contentDocumentIds.add(link.ContentDocumentId);
            }

            return JSON.serialize([
                SELECT Id, Title, Description
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds
            ]);

        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_GET_PHOTOS));
            return null;
        }
    }
}