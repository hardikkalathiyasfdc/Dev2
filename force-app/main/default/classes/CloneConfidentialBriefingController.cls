/********************************************************************************
* Class Name  : CloneConfidentialBriefingController
* Description : This class provides backend logic to fetch campaign/interactions data,
*               retrieve organization details, and clone Confidential Briefing records
*               along with associated files.
* Created By  : Hardik Kalathiya
* Change Log  : Updated - 5/19/2025
********************************************************************************/
public with sharing class CloneConfidentialBriefingController {

    private static final String ERR_CLONE_CB_FILES = 'CLONE_CONFIDENTIAL_BRIEFING_CONTROLLER_CLONE_CB_FILES_FAILED';
    private static final String ERR_GET_ORG_DETAILS = 'CLONE_CONFIDENTIAL_BRIEFING_CONTROLLER_GET_ORG_DETAILS_FAILED';  
    private static final String ERR_CLOME_CB = 'CLONE_CONFIDENTIAL_BRIEFING_CONTROLLER_ERR_CLOME_CB_FAILED';
    
    @AuraEnabled(cacheable=true)
    public static List<CampaignMember> getFilteredRecords(String contactId) {
        try {
            return [
                SELECT CampaignId, Campaign.Name, Campaign.Event_Start_Date_Time__c, Campaign.Start_Date_Time__c, ContactId
                FROM CampaignMember
                WHERE ContactId = :contactId ORDER BY Campaign.Start_Date_Time__c DESC NULLS LAST, Campaign.Name ASC
            ];
        } catch (Exception ex) {
            System.debug('Error fetching Campaign Members: ' + ex.getMessage());
            throw new AuraHandledException('Unable to fetch campaign member data.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getOrgDetails(Id recordId) {
        try {
            Confidential_Items__c confidentialRecord = [
                SELECT Id, Name, Contact__c, Contact__r.AccountId, Contact__r.Account.Name
                FROM Confidential_Items__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            Map<String, String> result = new Map<String, String>();

            if (confidentialRecord != null && confidentialRecord.Contact__c != null) {
                result.put('contactId', confidentialRecord.Contact__c);
                result.put('accountName', confidentialRecord.Contact__r.Account.Name);
                result.put('accountId', confidentialRecord.Contact__r.AccountId);
            }
            return result;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_ORG_DETAILS));
            System.debug('Error fetching Org Details: ' + ex.getMessage());
            throw new AuraHandledException('Unable to fetch organization details.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Interaction__c> getInteractions(String contactId) {
        try {
            return [
                SELECT Id, Name, Contact__c, Interaction_Date__c, Background__c
                FROM Interaction__c
                WHERE Contact__c = :contactId AND RecordType.DeveloperName = 'Leadership_Touchpoint' ORDER BY Interaction_Date__c DESC
            ];
        } catch (Exception ex) {
            System.debug('Error fetching Interactions: ' + ex.getMessage());
            throw new AuraHandledException('Unable to fetch interaction data.');
        }
    }

    @AuraEnabled
    public static void cloneConfidentialBriefing( String objectApiName, String recordId, List<String> selectedIds) {
        try {
            // 1. Query the original CB record
            Confidential_Items__c originalRecord = [
                SELECT Name, DateOfBriefing__c
                FROM Confidential_Items__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            // 2. Create clones for each record
            List<Confidential_Items__c> clonedCBRecords = new List<Confidential_Items__c>();
            Id selectedRecId ;
            for (Id selectedRecordId : selectedIds) {
                selectedRecId = selectedRecordId;
                Confidential_Items__c clone = originalRecord.clone(false, true, false, false);
                assignObjectField(clone, objectApiName, selectedRecordId);
                clone.DateOfBriefing__c = originalRecord.DateOfBriefing__c;
                clonedCBRecords.add(clone);
            }

            insert clonedCBRecords;

            // 3. Clone files and attach to each cloned record
            cloneCBFiles(recordId,selectedRecId,objectApiName, clonedCBRecords);

        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CLOME_CB));
            System.debug('Error cloning Confidential Briefings: ' + ex.getMessage());
            throw new AuraHandledException('Error cloning confidential briefing records.');
        }
    }

    private static void assignObjectField(Confidential_Items__c record, String objectApiName, String selectedRecordId) {
        if (objectApiName == 'Account') {
            record.Account__c = selectedRecordId;
        } else if (objectApiName == 'Campaign') {
            record.Campaign__c = selectedRecordId;
        } else if (objectApiName == 'Interaction__c') {
            //record.Interaction__c = selectedRecordId;
        }else if (objectApiName == 'Contact'){
              record.Contact__c = selectedRecordId;
        }else {
            throw new AuraHandledException('Invalid object type: ' + objectApiName);
        }
    }

    public static void cloneCBFiles( Id recordId,String selectedRecordId,String objectApiName,List<Confidential_Items__c> newCBRecords){
        try{
        //Retrieve all ContentDocumentLinks in a single query
        List<ContentDocumentLink> fileLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];

        if (fileLinks.isEmpty()) {
            return;  // No files to clone
        }

        //Retrieve all ContentVersions for the fetched ContentDocuments
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : fileLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }

        // Get the latest ContentVersions for all linked ContentDocuments
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId, Title, VersionData, Description
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
            AND IsLatest = true
        ];

        for (ContentVersion version : contentVersions) {
            contentVersionMap.put(version.ContentDocumentId, version);
        }

        //Clone ContentVersions and link them to the new record
        List<ContentVersion> newContentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();

        for (ContentDocumentLink link : fileLinks) {
            ContentVersion originalVersion = contentVersionMap.get(link.ContentDocumentId);

            if (originalVersion != null) {
                // Clone ContentVersion
                ContentVersion newVersion = new ContentVersion(
                    Title = originalVersion.Title.split('\\.')[0],
                    VersionData = originalVersion.VersionData,
                    PathOnClient = originalVersion.Title
                );
                newContentVersions.add(newVersion);
            }
        }

        if (!newContentVersions.isEmpty()) {
            insert newContentVersions;
            for(Confidential_Items__c newCBRecord : newCBRecords )  {
                // Link the new file versions to the new record
                for (ContentVersion newVersion : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :newContentVersions]) {
                    ContentDocumentLink newLink = new ContentDocumentLink();
                    newLink.ContentDocumentId = newVersion.ContentDocumentId;

                    // Determine the LinkedEntityId based on the object API name
                    if(objectApiName == 'Interaction__c'){
                        newLink.LinkedEntityId = selectedRecordId;
                    } else {
                        newLink.LinkedEntityId = newCBRecord.Id;
                    }

                    newLink.ShareType = 'V';  // Viewer permission

                    // Assign the ContentVersion ID to the Attachment field on the record
                    newCBRecord.Attachment__c = newVersion.Id;
                    newLinks.add(newLink);
                }
            }
            insert newLinks;
            BBApps_Crud.doUpdateWithHandling(newCBRecords, false, new BBApps_ErrorCustomFields(ERR_CLONE_CB_FILES));
            // Additional processing if the object is 'Interaction__c'
            if(objectApiName == 'Interaction__c'){
                ConfidentialItemUploadController.saveConfidentialAttachment(newLinks[0].ContentDocumentId, selectedRecordId);
            }
        }
    } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CLONE_CB_FILES));
        }
    }
}