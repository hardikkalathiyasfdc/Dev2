global without sharing class InteractionFilesMigration implements Database.Batchable<sObject> {
    public String query;
    private static final String ERR_INSERT_FAILED = 'InteractionFilesMigration_INSERT_FAILED';
    private static final String ERR_UPDATE_FAILED = 'InteractionFilesMigration_UPDATE_FAILED';
    private static final String ERR_CLASS_FAILED = 'InactiveElectedStatusBatch_CLASS_FAILED';

    private final Map<String, String> FILE_TYPE = new Map<String,String>{'JPEG'=>'image/jpeg', 'PDF'=>'application/pdf', 'UNKNOWN'=>''};
    global InteractionFilesMigration() {
        this.query = query;
    }

    global Iterable<sObject> start(Database.BatchableContext bc) {
        return [SELECT ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN (SELECT Id 
                                         FROM Interaction__c 
                                         WHERE RecordType.DeveloperName IN ('x2020'))];
    }

    global void execute(Database.BatchableContext BC, list<ContentDocumentLink> scope) {
        try {
            Map<Id, Id> contentDocumentWithLinkIds  = new Map<Id, Id>();
            List<ConfidentialAttachment__c> attaches = new List<ConfidentialAttachment__c>();
            Set<Id> interactionIds = new Set<Id>();
            ConfidentialAttachment__c att = null;
            for(ContentDocumentLink inter : scope) {
                contentDocumentWithLinkIds.put(inter.ContentDocumentId, inter.LinkedEntityId);
                att = new ConfidentialAttachment__c();
                att.Interaction__c = inter.LinkedEntityId;
                att.Name = inter.ContentDocumentId;
                attaches.add(att);
                interactionIds.add(inter.LinkedEntityId);
            }
            Map<Id, Interaction__c> interactionById = new Map<Id, Interaction__c>([
                SELECT RecordType.DeveloperName FROM Interaction__c WHERE Id = :interactionIds]);
            Map<Id, ContentVersion> contents = new Map<Id, ContentVersion>();
            for(ContentVersion cv : [SELECT FileExtension,FileType,Title,VersionData, ContentDocumentId, ContentSize
                                     FROM ContentVersion 
                                     WHERE ContentDocumentId IN :contentDocumentWithLinkIds.keySet() 
                                       AND IsLatest = true]) {
                contents.put(cv.ContentDocumentId, cv);
            }
            if(attaches.size() > 0) {
                for(ConfidentialAttachment__c  attach : attaches) {
                    attach.InteractionRecordType__c = interactionById.get(attach.Interaction__c).RecordType.DeveloperName;
                }
                BBApps_Crud.doInsertWithHandling(attaches, false, ERR_INSERT_FAILED);
            }
            List<ContentDocumentLink> atts = new List<ContentDocumentLink>();
            ContentDocumentLink contentDocumentLink = null;
            for(ConfidentialAttachment__c tmpConfAtt: attaches) {
                contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = tmpConfAtt.Name;
                contentDocumentLink.LinkedEntityId = tmpConfAtt.Id;
                contentDocumentLink.ShareType = 'I'; // Inferred permission
                atts.add(contentDocumentLink);
                if(contentDocumentWithLinkIds.get(tmpConfAtt.Name) != null) {
                    tmpConfAtt.Attachment__c = tmpConfAtt.Name;
                    if(contents.get(tmpConfAtt.Name) != null) {
                        String title = contents.get(tmpConfAtt.Name).Title + '.' + contents.get(tmpConfAtt.Name).FileExtension;
                        if(title.length() > 80) {
                            title = title.right(80);
                        }
                        tmpConfAtt.Name = title;
                    }
                }
            }
            BBApps_Crud.doUpdateWithHandling(attaches, false, ERR_UPDATE_FAILED);
            if(atts.size() > 0) {
                BBApps_Crud.doInsertWithHandling(atts, false, ERR_INSERT_FAILED);
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    global void finish(Database.BatchableContext BC) {}
}