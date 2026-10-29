/**
* Author : Hardik Kalathiya
* Date : 11/14/2024
* JIRA : BRME-5537
* Description : The ContentDocumentService class processes file attachments for Agreement and Interaction records, managing the addition, removal,
and update of attachment details to ensure accurate tracking and consistent file information handling for business logic around content document link operations.
* Test : ContentDocumentTriggerTest
* Change Log
Hardik Kalathiya on 11/14/2024 - BRME-5537: Refactor Triggers ContentDocumentLinkTrigger &ContentDocumentTrigger
**/

public without sharing class ContentDocumentService {

    public static Map<Id, ContentDocumentLink> entityIdToContentDocLinkMap = new Map<Id, ContentDocumentLink>();
    private static final String ERR_CLASS_FAILED = 'ContentDocumentService_CLASS_FAILED';
    private static final String ERR_CLASS_UPDATE = 'ContentDocumentService_UPDATE_FAILED';

    public static void processContentDocuments(List<ContentDocumentLink> contentDocLinks, Boolean isInsert) {
        try {
            Set<Id> agreementIds = new Set<Id>();
            Set<Id> interactionIds = new Set<Id>();
            Set<Id> ConfidentialAttachmentId = new Set<Id>();
            // Separate Agreement and Interaction IDs
            for (ContentDocumentLink cdl : contentDocLinks) {
                String sObjectType = string.valueof(cdl.LinkedEntityId.getSObjectType());
                if (sObjectType == 'Agreement__c') {
                    agreementIds.add(cdl.LinkedEntityId);
                    entityIdToContentDocLinkMap.put(cdl.LinkedEntityId,cdl);
                } else if (sObjectType == 'Interaction__c') {
                    interactionIds.add(cdl.LinkedEntityId);
                } else if(sObjectType == 'ConfidentialAttachment__c') {
                    ConfidentialAttachmentId.add(cdl.LinkedEntityId);
                }
            }
            if(!ConfidentialAttachmentId.isEmpty()) {
             List<ConfidentialAttachment__c> attachmentList = [SELECT Id,Interaction__c  FROM ConfidentialAttachment__c WHERE Id IN :  ConfidentialAttachmentId]; 
                for(ConfidentialAttachment__c attachment : attachmentList) {
                    interactionIds.add(attachment.Interaction__c);
                }
            }
            // Process Agreements
            if(!agreementIds.isEmpty()) {
                processAgreements(agreementIds,isInsert);
            }
            // Process Interactions
            if(!interactionIds.isEmpty()) {
                processInteractions(interactionIds,isInsert);
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    // Processes agreements and updates them based on attachment inserts/deletes
    public static void processAgreements(Set<Id> agreementIds, Boolean isInsert) {
        try {
            List<Agreement__c> agreementsToUpdate = [SELECT Id, (SELECT Id, ContentDocumentId, ContentDocument.Title
                                                                 FROM ContentDocumentLinks
                                                                 WHERE ContentDocument.FileType != 'SNOTE')
                                                     FROM Agreement__c
                                                     WHERE Id IN :agreementIds ];
            for(Agreement__c agreement : agreementsToUpdate) {
                Integer numberOfAttachment = isInsert ? agreement.ContentDocumentLinks.size() : agreement.ContentDocumentLinks.size() - 1;
                agreement.NumberAttachment__c = numberOfAttachment;
                // if the number of ContentDocumentLinks after insert is 1 then we are pulling the ContentDocumentId and ContentDocument.Title from the inserted record.
                // if the number of ContentDocumentLinks before delete is 2 then we are checking which one is deleted and update fielname and attachmentId with pending one.
                if(isInsert && numberOfAttachment == 1 ) {
                    agreement.Attachment_Id__c = agreement.ContentDocumentLinks[0].ContentDocumentId;
                    agreement.FileName__c = agreement.ContentDocumentLinks[0].ContentDocument.Title;
                } else if(!isInsert && numberOfAttachment == 1) {
                    //The execution come in this condtion when we have 2 files on the record and we are deleting the one
                    //isFirstFileDelete we use this flag to check which file getting deleted from these two files
                    boolean isFirstFileDelete = entityIdToContentDocLinkMap.get(agreement.Id).ContentDocumentId == agreement.ContentDocumentLinks[0].ContentDocumentId ? true : false;
                    agreement.Attachment_Id__c = isFirstFileDelete ? agreement.ContentDocumentLinks[1].ContentDocumentId : agreement.ContentDocumentLinks[0].ContentDocumentId ;
                    agreement.FileName__c = isFirstFileDelete ? agreement.ContentDocumentLinks[1].ContentDocument.Title : agreement.ContentDocumentLinks[0].ContentDocument.Title;
                } else{
                    //set these to null if there are no documents or more than one document
                    agreement.FileName__c = null;
                    agreement.Attachment_Id__c = null;
                }
            }
            BBApps_Crud.doUpdateWithHandling(agreementsToUpdate, false, ERR_CLASS_UPDATE);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    // Processes interactions and updates based on file attachments during insert/delete
    public static void processInteractions(Set<Id> interactionIds,Boolean isInsert) {
        try {
            List<Interaction__c> interactionsToUpdate = [ 
                SELECT Id,
                       (SELECT Id, ContentDocumentId, ContentDocument.Title 
                        FROM ContentDocumentLinks 
                        WHERE ContentDocument.FileType != 'SNOTE')  
                FROM Interaction__c 	
                WHERE Id IN :interactionIds];
            for (Interaction__c interaction : interactionsToUpdate) {
            interaction.File_Attached_New__c = (isInsert || interaction.ContentDocumentLinks.size() > 1) ? 'Yes' : 'No';
            }
            if(!interactionsToUpdate.isEmpty()) { 
                BBApps_Crud.doUpdateWithHandling(interactionsToUpdate, false, ERR_CLASS_UPDATE);
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}