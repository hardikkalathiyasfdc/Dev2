/********************************************************************************
* Class Name  : ContentDocumentHandler
* Business Purpose: BRME-5537
* Description : This class is used by ContentDocumentTrigger. 
The ContentDocumentHandler class processes ContentDocument records (attachments) and updates related Agreements and Interactions objects when ContentDocuments are created, updated, or deleted.
********************************************************************************/

public without sharing class ContentDocumentHandler extends TriggerHandler {
    public override void bulkBefore() {
        If(Trigger.isDelete && !trigger.oldMap.keyset().isEmpty()){
            Set<Id> recordIdSet = Trigger.oldMap.keySet();//added local property as using in soql query.
            List<ContentDocumentLink> contentDocLinks = [
                SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.Title,ContentDocument.FileType 
                FROM ContentDocumentLink 
                WHERE ContentDocumentId IN :recordIdSet
            ];
            ContentDocumentService.processContentDocuments(contentDocLinks, false);
        }
    }
}