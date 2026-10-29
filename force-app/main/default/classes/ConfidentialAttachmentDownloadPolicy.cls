/****
 * Author: Nishant Bakhrey
 * Description: This class is used in a Transaction Security Policy to determine if a file download event
 *              is related to a confidential item.
 *****/
global without sharing class ConfidentialAttachmentDownloadPolicy implements TxnSecurity.EventCondition {

    public Boolean evaluate(SObject event) {
        FileEventStore fileEvent = (FileEventStore) event;
        if(fileEvent == null) return false;
        if(fileEvent.DocumentId == null) return false;
        if(fileEvent.FileAction != 'API_DOWNLOAD' && fileEvent.FileAction != 'UI_DOWNLOAD') {
            return false;
        }
        Id contentDocumentId = Id.valueOf(fileEvent.DocumentId);
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
        ];
        for(ContentDocumentLink link : links) {
            if(link.LinkedEntityId != null &&
               link.LinkedEntityId.getSObjectType() == Confidential_Items__c.SObjectType) {

                return true;
            }
        }
        return false;
    }
}