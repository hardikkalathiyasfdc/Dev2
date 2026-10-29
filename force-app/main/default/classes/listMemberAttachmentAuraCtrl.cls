public with sharing class listMemberAttachmentAuraCtrl {


    @AuraEnabled(cacheable=true)
    public static String getListId(String listMemberId) {
        return JSON.serialize([SELECT CampaignId
                              FROM CampaignMember
                              WHERE Id =: listMemberId]);
    }

    @AuraEnabled(cacheable=true)
    public static String getConfidentialFiles(String parentId) {
        String listMemberId = '%'+parentId + '%';
        return JSON.serialize([SELECT Name, Id, Attachment__c
                              FROM ListMemberAttachment__c
                              WHERE UniqueId__c LIKE : listMemberId]);
    }

    @AuraEnabled
    public static String deleteConfidentialFile(String parentId) {
        ContentDocumentLink contentLink = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: parentId];
        ContentDocument contentDocument = [SELECT Id FROM contentDocument WHERE Id =: contentLink.ContentDocumentId];
        ListMemberAttachment__c attachment = [SELECT Id FROM ListMemberAttachment__c WHERE Id=: parentId];

        String processResult = 'success';
        SavePoint sp = Database.setSavepoint();
        try {
            delete contentLink;
            delete contentDocument;
            delete attachment;
        } catch( Exception ex ) {
            Database.rollback(sp);

            insert new MB_Error__c(Description__c=' Delete List Attachment: '+parentId+' | '+ex.getMessage() +' | ' + ex.getStackTraceString(),
                                    Type__c='listMemberAttachmentAuraCtrl.cls');
            processResult = 'failed';
        }

        return processResult;
    }

    @AuraEnabled
    public static String saveListMemberAttachment(String documentId, String listMemberId, String listId) {
        SavePoint sp = Database.setSavepoint();
        String processResult = 'success';
        try {
            //Get created Document Link
            ContentDocumentLink contentLink = [SELECT Id
                                               FROM ContentDocumentLink
                                               WHERE ContentDocumentId = : documentId
                                               AND LinkedEntityId =: listId];
            //Get interaction record type value
            CampaignMember cm = [SELECT Campaign.RecordType.DeveloperName
                                          FROM CampaignMember
                                          WHERE Id =: listMemberId];
            //Get Content Version values
            ContentVersion contentVersion = [SELECT Id, FileExtension, Title, ContentDocumentId
                                            FROM ContentVersion
                                            WHERE ContentDocumentId =: documentId
                                            AND IsLatest = true LIMIT 1];

            ListMemberAttachment__c attachment = new ListMemberAttachment__c();
            attachment.UniqueId__c = listMemberId+'|'+documentId;
            attachment.Attachment__c = documentId;
            attachment.RecordTypeName__c = cm.Campaign.RecordType.DeveloperName;
            String title = contentVersion.Title +'.'+contentVersion.FileExtension;
            if( title.length() > 80 ) {
                title = title.right(80);
            }
            attachment.Name = title;

            insert attachment;

            ContentDocumentLink contentDocumentLink = createContentDocumentLink(documentId,  attachment.Id);

            insert contentDocumentLink;

            delete contentLink;
        } catch (Exception ex) {

            Database.rollback(sp);

            insert new MB_Error__c(Description__c='listMemberAttachmentAuraCtrl - ' +' documentId: '+documentId+' - '+'List Member: '+listMemberId+' | '+ex.getMessage(),
                                    Type__c='listMemberAttachmentAuraCtrl');
            processResult = 'failed';
        }

        return processResult;
    }

    private static ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id parentId){
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocumentId;
        contentDocumentLink.LinkedEntityId = parentId;
        contentDocumentLink.ShareType = 'I'; // Inferred permission
        return contentDocumentLink;
    }
}