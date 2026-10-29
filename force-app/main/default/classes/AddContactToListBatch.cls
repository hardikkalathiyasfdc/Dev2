global without sharing class AddContactToListBatch implements Database.batchable<sObject>, Database.Stateful{
    
    global String currentListId;
    global String listValue;
    global Boolean newList;
    global Id newListId;
    global Campaign existingList;
    global Map<Id, CampaignMember> existingListMemberContacts = new Map<Id, CampaignMember>();
    global List<CampaignMember> existingListMembers = new List<CampaignMember>();
    global Integer countOfDeceased = 0;
    global Integer countOfDonotCall = 0;
    global Integer countOfInserted = 0;
    global Integer countOfUpdated = 0;
    global String sourceName;
    private static final String ERR_BATCH_JOB_FAILED = 'AddContactToListBatch_BATCH_JOB_FAILED';
    private static final String ERR_UPDATE_FAILED = 'AddContactToListBatch_UPDATE_FAILED';
    private static final String ERR_INSERT_FAILED = 'AddContactToListBatch_INSERT_FAILED';
    
    global AddContactToListBatch(String currentListId, String listValue, Boolean newList) {
        this.currentListId = currentListId;
        this.listValue = listValue;
        this.newList = newList;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(newList) {
            newListId = AddContactsToListController.createNewList(listValue);
        } else {
            newListId = listValue;
            existingList = [SELECT Id, RecordType.DeveloperName FROM Campaign WHERE Id = :newListId];
            existingListMembers = [
                SELECT Id, Source__c, ContactId,contact.Deceased__c,contact.DonotCall,campaign.Name 
                FROM CampaignMember 
                WHERE CampaignId = :newListId
            ];
            for(CampaignMember member : existingListMembers) {

                existingListMemberContacts.put(member.ContactId, member);
            }
        }
        Set<Id> contactIds = new Set<Id> ();
        for(CampaignMember mem: [SELECT Id, ContactId,campaign.Name  FROM CampaignMember WHERE CampaignId =: currentListId ]) {
            sourceName= mem.campaign.Name ;
            contactIds.add(mem.ContactId);
        }
        String queryString = 'SELECT Id, ContactId, campaign.Name, Source__c, contact.Deceased__c, contact.DonotCall ' + 
                            ' FROM CampaignMember ' + 
                            ' WHERE CampaignId = :currentListId ';        
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        try {
            List<CampaignMember> listMembersToInsert = new List<CampaignMember> ();
            List<CampaignMember> listMembersToUpdate = new List<CampaignMember> ();
            for(CampaignMember c : (List<CampaignMember>)scope) {
                CampaignMember member = new CampaignMember (
                    ContactId = c.contactId,
                    CampaignId = newListId
                );
                if(this.newList) member.Source__c = 'List: ' + c.campaign.Name;
                if(existingListMemberContacts.containsKey(c.ContactId)) {
                    this.countOfUpdated = this.countOfUpdated + 1;
                    CampaignMember upateCampaignMember = existingListMemberContacts.get(c.ContactId);
                    if(upateCampaignMember.Source__c != null) {
                        String strSoruce  = upateCampaignMember.Source__c;
                    strSoruce = strSoruce.replace('List: ','');
                        List<String> listSources = strSoruce.split('; ');
                        if(!listSources.Contains(c.campaign.Name)) {
                            upateCampaignMember.Source__c = upateCampaignMember.Source__c+'; ' + c.campaign.Name;
                        }
                    } else {
                        upateCampaignMember.Source__c =  'List: ' + c.campaign.Name;
                    }
                    listMembersToUpdate.add(upateCampaignMember);
                } else {
                    if(c.Contact.Deceased__c || c.Contact.DonotCall) {
                        this.countOfDonotCall+=1;
                    } else {
                        member.Source__c =  'List: ' + c.campaign.Name;
                        listMembersToInsert.add(member);
                    }
                }
            }
            if(!listMembersToInsert.isEmpty()) {
                BBApps_Crud.doInsertWithHandling(listMembersToInsert, false, new BBApps_ErrorCustomFields(ERR_INSERT_FAILED));
            }
            if(!listMembersToUpdate.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(listMembersToUpdate, false, ERR_UPDATE_FAILED);
            }
            this.countOfInserted = this.countOfInserted + listMembersToInsert.size();
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    global void finish(Database.BatchableContext BC) {
        try {
            if(!newList && existingList.RecordType.DeveloperName == 'Pre_Event') {
                Campaign currentList = [SELECT Id, CreatedById, CreatedBy.IsActive FROM Campaign WHERE Id = :currentListId ];
                List<Collaborator__c> collaboratorList = [
                        SELECT Id 
                        FROM Collaborator__c 
                        WHERE Collaborator__c = :currentList.CreatedById 
                            AND Collaborator__r.ISACtive = true];
                if(collaboratorList.isEmpty() && currentList.CreatedBy.IsActive) {
                    Collaborator__c c = new Collaborator__c (
                        Access_Level__c = 'Read',
                        Collaborator__c = currentList.CreatedById,
                        List__c = newListId
                    );
                    BBApps_Crud.doInsertWithHandling(c, false, new BBApps_ErrorCustomFields(ERR_INSERT_FAILED));
                }
            }
            Campaign camp = new Campaign();
            camp.Id = newListId;
            camp.Inserted_Member_Count__c = this.countOfInserted;
            camp.Updated_Member_Count__c = this.countOfUpdated;
            camp.Deceased_Count__c = this.countOfDeceased;
            camp.DoNotCall_Count__c = this.countOfDonotCall;
            BBApps_Crud.doUpdateWithHandling(camp, false, ERR_UPDATE_FAILED);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}