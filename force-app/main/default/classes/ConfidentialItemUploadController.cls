public with sharing class ConfidentialItemUploadController {
    
    private static final String ERR_SAVE_CHUNK = 'CONFIDENTIAL_ITEM_UPLOAD_CONTROLLER_SAVE_CHUNK_FAILED';
    private static final String ERR_GET_CONFIDINTIAL_FILES = 'CONFIDENTIAL_ITEM_UPLOAD_CONTROLLER_GET_CONFIDENTIAL_FILES_FAILED';
    private static final String ERR_CHECK_USER_CREATION_PERMISSION = 'CONFIDENTIAL_ITEM_UPLOAD_CONTROLLER_CHECK USER_CREATION_PERMISSION_FAILED';
    private static final String ERR_SAVE_THE_FILE = 'CONFIDENTIAL_ITEM_UPLOAD_CONTROLLER_SAVE_THE_FILE_FAILED';
    private static final String ERR_UPDATE_CONFIDENTIAL_ITEM = 'CONFIDENTIAL_ITEM_UPLOAD_CONTROLLER_UPDATE_CONFIDENTIAL_ITEM_FAILED';  
    private static final String ERR_DELETE_CONFIDENTIAL_FILE = 'CONFIDENTIAL_ITEM_UPLOAD_CONTROLLER_DELETE_CONFIDENTIAL_FILE_FAILED'; 
    private static final String ERR_SAVE_CONFIDENTIAL_ATTACHMENT = 'CONFIDENTIAL_ITEM_UPLOAD_CONTROLLER_SAVE_CONFIDENTIAL_ATTACHMENT_FAILED'; 
    
    @AuraEnabled
    public static Id saveChunk(Id parentId, String fileName, String base64Data, String contentType, String itemDesc, String dateOfBriefing) {
        try{
            Confidential_Items__c obj = new Confidential_Items__c();
            //Get object api name from record Id
            String objAPI = parentId.getSObjectType().getDescribe().getName();
            if( !objAPI.endsWith('__c') ) { //if the object is not customize object, add suffix '__c' to match the field api in Confidential Item Object
                objAPI = objAPI+'__c';
            }
            obj.put(objAPI, parentId); //set the field value for related field
            obj.description__c = itemDesc;
            if( String.isNotEmpty(dateOfBriefing) ) {
                obj.DateOfBriefing__c = Date.valueOf(dateOfBriefing);
            }
            
            insert obj;
            parentId = obj.Id;        
            Id fileId = saveTheFile(parentId, fileName, base64Data, contentType); 
            
            return Id.valueOf(fileId);
        }catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SAVE_CHUNK));
            return null ;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getConfidentialFiles(String parentId) {
        try{   
            
            return JSON.serialize([SELECT Name, View__c, Id, Attachment__c
                                   FROM ConfidentialAttachment__c
                                   WHERE Interaction__c =: parentId]);
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_CONFIDINTIAL_FILES));
            return null;
        }
    }
    
    @AuraEnabled
    public static String deleteConfidentialFile(String parentId) {
        
        ContentDocumentLink contentLink = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: parentId];
        ContentDocument contentDocument = [SELECT Id FROM contentDocument WHERE Id =: contentLink.ContentDocumentId];
        ConfidentialAttachment__c attachment = [SELECT Id,Interaction__c  FROM ConfidentialAttachment__c WHERE Id=: parentId];
        List<ConfidentialAttachment__c> attachmentList = [SELECT Id,Interaction__c  FROM ConfidentialAttachment__c WHERE Interaction__c=: attachment.Interaction__c];          
        String processResult = 'success';
        SavePoint sp = Database.setSavepoint();
        try {
            // Delete records only if they are not null
            if (contentDocument != null) {
                delete contentDocument;
            } 
            if (attachment != null) {
                delete attachment;
            }
            If(attachmentList.Size() <= 1){
                Interaction__c  interaction = new Interaction__c();
                interaction.Id = attachment.Interaction__c;
                interaction.File_Attached_New__c = 'No'; 
                BBApps_Crud.doUpdateWithHandling( new List<SObject>{ interaction }, false, new BBApps_ErrorCustomFields(ERR_DELETE_CONFIDENTIAL_FILE));
            } 
        } catch(Exception ex ) {
            Database.rollback(sp);  
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_DELETE_CONFIDENTIAL_FILE));
            insert new MB_Error__c(Description__c='ConfidentialItemUploadController - delete confidential failure (Confidential Attachments): '+parentId+' | '+ex.getMessage());
            processResult = 'failed';
        }
        
        return processResult;
    }
    
    @AuraEnabled
    public static String saveConfidentialAttachment(String documentId, String interactionId) {
        SavePoint sp = Database.setSavepoint();
        String processResult = 'success';
        try {
            
            //Get created Document Link
            ContentDocumentLink contentLink = [SELECT Id 
                                               FROM ContentDocumentLink
                                               WHERE ContentDocumentId = : documentId
                                               AND LinkedEntityId =: interactionId];
            //Get interaction record type value
            Interaction__c interaction = [SELECT RecordType.DeveloperName 
                                          FROM Interaction__c 
                                          WHERE Id =: interactionId];
            //Get Content Version values
            ContentVersion contentVersion = [SELECT Id, FileExtension, Title, ContentDocumentId 
                                             FROM ContentVersion 
                                             WHERE ContentDocumentId =: documentId 
                                             AND IsLatest = true LIMIT 1];
            
            ConfidentialAttachment__c attachment = new ConfidentialAttachment__c();
            attachment.Interaction__c = interactionId;
            attachment.Attachment__c = documentId;
            attachment.InteractionRecordType__c = interaction.RecordType.DeveloperName;
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
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SAVE_CONFIDENTIAL_ATTACHMENT));
            insert new MB_Error__c(Description__c='ConfidentialItemUploadController - ' +' documentId: '+documentId+' - '+'interactionId: '+interactionId+' | '+ex.getMessage());
            processResult = 'failed';
        }
        
        return processResult;
    }

    @AuraEnabled(cacheable=true)
    public static String checkUserCreationPermission(Id parentId) {
        Boolean giveAccess = false;
        try{
            Interaction__c interaction = [SELECT RecordType.DeveloperName FROM Interaction__c WHERE Id =: parentId];
            
            String requiredFieldAccess = '';
            for (ConfidentialAttachmentCreationChecker__mdt checker: [SELECT InteractionRecordType__c, RequiredFieldAccess__c
                                                                      FROM ConfidentialAttachmentCreationChecker__mdt] ) {
                                                                          if( checker.InteractionRecordType__c == interaction.RecordType.DeveloperName ) {
                                                                              requiredFieldAccess = checker.RequiredFieldAccess__c;
                                                                          }
                                                                      }
            if ( requiredFieldAccess != '' ) {
                SObjectType schemaType = Schema.getGlobalDescribe().get('Interaction__c');
                SObjectField schemaField = schemaType.getDescribe().fields.getMap().get(requiredFieldAccess);
                
                giveAccess = schemaField.getDescribe().isAccessible();
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CHECK_USER_CREATION_PERMISSION));
        }
        return String.valueOf(giveAccess);
    }

    private static ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id parentId){
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocumentId;
        contentDocumentLink.LinkedEntityId = parentId;
        contentDocumentLink.ShareType = 'I'; // Inferred permission
        return contentDocumentLink;
    }
 
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        try{
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            
            ContentVersion oAttachment = new ContentVersion();
            oAttachment.FirstPublishLocationId = parentId;
            oAttachment.VersionData = EncodingUtil.base64Decode(base64Data);
            oAttachment.Title = fileName;
            oAttachment.PathOnClient = fileName;
            
            Database.SaveResult attachmentResult = Database.insert(oAttachment);
            if (attachmentResult == null || !attachmentResult.isSuccess()) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                                           'Could not save attachment.'));            
                return null;
            } else {
                updateConfidentialItem(parentId, fileName, attachmentResult.getId());  
            }
            return oAttachment.Id;
        }catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SAVE_THE_FILE));
            return null ;
        }
    }

    private static void updateConfidentialItem(Id parentId, String fileName, String attachmentId) {
        try{
            // update the custom attachment record with some attachment info
            Confidential_Items__c customAttachment = [SELECT Id 
                                                      FROM Confidential_Items__c 
                                                      WHERE Id = :parentId];
            customAttachment.name = fileName;
            customAttachment.Attachment__c = attachmentId;
            BBApps_Crud.doUpdateWithHandling( new List<SObject>{ customAttachment }, false, new BBApps_ErrorCustomFields(ERR_UPDATE_CONFIDENTIAL_ITEM));
        }catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_CONFIDENTIAL_ITEM));
        }
    }
}