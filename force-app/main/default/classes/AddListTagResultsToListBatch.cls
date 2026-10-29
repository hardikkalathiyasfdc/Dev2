public with sharing class AddListTagResultsToListBatch implements Database.batchable<sObject>, Database.stateful {
    public String campaignId;
    public String memberStatus;
    public Boolean keepExistingStatus;
    public String contactSources;
    public List<Id> contactIds;
    private Map<String, String> sourceNames;
    private Map<Id, CampaignMember> existingCMMap;
    private Integer insertedCount = 0;
    private Integer updatedCount = 0;
    private Integer doNotContactCount = 0;
    private static final String ERR_BATCH_JOB_FAILED = 'AddListTagResultsToListBatch_BATCH_JOB_FAILED';
    private static final String ERR_UPDATE_FAILED = 'AddListTagResultsToListBatch_UPDATE_FAILED';

    public AddListTagResultsToListBatch(String campaignId, String memberStatus, Boolean keepExistingStatus, 
                                        List<Id> contactIds, String contactSources) {
        this.campaignId = campaignId;
        this.memberStatus = String.isBlank(memberStatus) ? 'Sent' : memberStatus;
        this.keepExistingStatus = keepExistingStatus == null ? false : keepExistingStatus;
        this.contactSources = contactSources;
        this.contactIds = contactIds;
        Map<String, String> sourceNames = new Map<String, String>();
        Map<String, Object> contactSourcesMap = (Map<String, Object>)JSON.deserializeUntyped(contactSources);
        for(String key : contactSourcesMap.keySet()) {
            sourceNames.put(key, (String)contactSourcesMap.get(key));
        }
        this.sourceNames = sourceNames;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, DoNotCall
            FROM Contact
            WHERE Id IN :contactIds 
            WITH SYSTEM_MODE
        ]);
    }

    public void execute(Database.BatchableContext context, List<Contact> contacts) {
        try {
            Set<Id> contactIds = new Set<Id>();
            for (Contact c : contacts) contactIds.add(c.Id);
            List<CampaignMember> existingCMs = [
                SELECT Id, ContactId, Status, Source__c
                FROM CampaignMember
                WHERE CampaignId = :campaignId 
                AND ContactId IN :contactIds 
                WITH SYSTEM_MODE];
            existingCMMap = new Map<Id, CampaignMember>();
            for(CampaignMember cm : existingCMs) {
                existingCMMap.put(cm.ContactId, cm);
            }
            List<CampaignMember> cmToInsert = new List<CampaignMember>();
            List<CampaignMember> cmToUpdate = new List<CampaignMember>();
            for(Contact c : contacts) {
                if(c.DoNotCall) {
                    doNotContactCount++;
                    continue;
                }
                String sourceVal = sourceNames.containsKey(c.Id) ? sourceNames.get(c.Id) : '';
                if(existingCMMap.containsKey(c.Id)) {
                    CampaignMember existingCM = existingCMMap.get(c.Id);
                    existingCM.Source__c = sourceVal;
                    if(!keepExistingStatus) existingCM.Status = memberStatus;
                    cmToUpdate.add(existingCM);
                } else {
                    cmToInsert.add(new CampaignMember(
                        ContactId = c.Id,
                        CampaignId = campaignId,
                        Status = memberStatus,
                        Source__c = sourceVal
                    ));
                }
            }
            if(!cmToInsert.isEmpty()) {
                insert as system cmToInsert;
                insertedCount += cmToInsert.size();
            }
            if(!cmToUpdate.isEmpty()) {
                update as system cmToUpdate;
                updatedCount += cmToUpdate.size();
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    public void finish(Database.BatchableContext context) {
        try {
            Campaign campaign = [
                SELECT Id, Updated_Member_Count__c, Inserted_Member_Count__c, 
                       DoNotCall_Count__c, Deceased_Count__c
                FROM Campaign 
                WHERE Id = :campaignId 
                WITH SYSTEM_MODE
            ];
            campaign.Updated_Member_Count__c = updatedCount;
            campaign.Inserted_Member_Count__c = insertedCount;
            campaign.DoNotCall_Count__c = doNotContactCount;
            campaign.Deceased_Count__c = doNotContactCount;
            BBApps_Crud.doUpdateWithHandling(campaign, false, ERR_UPDATE_FAILED);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}