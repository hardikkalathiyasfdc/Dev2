/**
* Author : Ravi Bheemreddy
* Last Modified Date/By   : 06/05/2024 Hardik Kalathiya
* Jira   : BRME-5268
* Description : This is scheduler class which calculates Touchpoint Summary on Contact Object
* Test   : BatchContactRollupRecordsTest
**/
public without sharing class BatchContactRollupRecords implements Database.Batchable<sObject>, Schedulable {
    private static final String ERR_START   = 'BCRR_START_FAILED';
    private static final String ERR_EXECUTE = 'BCRR_EXECUTE_FAILED';
 
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this,200);
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        try {
            String strQuery = 'SELECT Id FROM Contact';
            return  Database.getquerylocator(strQuery);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_START);
            BBApps_ErrorHandler.logErrors(ex, f);
            return null;
        }
    }
    
    public void execute(Database.BatchableContext BC, List<Contact> contactList){
        try{
            contactList = [SELECT Id, Touchpoint_sum__c, AccountId, Event_Count__c, Name,
                           (SELECT Id FROM Donors__r),
                           (SELECT Id, contactId, RecordType.DeveloperName FROM CampaignMembers),
                           (SELECT Id,contact__c FROM Political_Interactions__r WHERE RecordType.DeveloperName != :Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME),
                           (SELECT Id,contact__c FROM Attachments__r),
                           (SELECT Id,contact__c FROM Tags__r),
                           (SELECT Id FROM ContentDocumentLinks),
                           (SELECT Id FROM Employment_History__r),
                           (SELECT Id FROM Election_Histories__r)
                           FROM CONTACT WHERE ID IN: contactList
                          ];
            List<Contact> lstContactToUpdate = new List<Contact>();
            List<Id> accountIds = new List<Id>();
            Map<Id,Integer> mapOrgWithInteractionCount = new Map<Id,Integer>();
            for(Contact conRecord : contactList){
                accountIds.add(conRecord.AccountId);
            }
            
            AggregateResult[] groupedResults= [SELECT Organization__c, COUNT(ID) interactionCount FROM Interaction__c
                                               WHERE Organization__c=:accountIds AND RecordType.DeveloperName= :Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME
                                               GROUP BY Organization__c];
            for (AggregateResult ar : groupedResults)  {
                mapOrgWithInteractionCount.put(String.valueOf(ar.get('Organization__c')),Integer.valueOf(ar.get('interactionCount')));
            }
            
            Integer countOfChildRecords = 0;
            for(Contact contactRecord : contactList){
                Boolean isUpdated = false;
                
                Integer interactionsWithUniqueOrgCount = contactRecord.AccountId!=null && mapOrgWithInteractionCount.ContainsKey(contactRecord.AccountId) && mapOrgWithInteractionCount.get(contactRecord.AccountId) > 0 ? 1 : 0;
                Integer pledgecount= contactRecord.Donors__r != null ? contactRecord.Donors__r.size() : 0;
                Integer listCount = contactRecord.CampaignMembers != null ? contactRecord.CampaignMembers.size() : 0;
                Integer attachmentCount = contactRecord.Attachments__r != null ? contactRecord.Attachments__r.size() : 0;
                Integer tagCount = contactRecord.Tags__r != null ? contactRecord.Tags__r.size() : 0;
                Integer fileCount = contactRecord.ContentDocumentLinks != null ? contactRecord.ContentDocumentLinks.size() : 0;
                Integer empCount = contactRecord.Employment_History__r != null ? contactRecord.Employment_History__r.size() : 0;
                Integer elecCount = contactRecord.Election_Histories__r != null ? contactRecord.Election_Histories__r.size() : 0;
                Integer politicalInteractionCount = contactRecord.Political_Interactions__r != null ? contactRecord.Political_Interactions__r.size() : 0;
                
                countOfChildRecords = pledgecount + interactionsWithUniqueOrgCount + listcount + attachmentCount + tagCount  + fileCount + empCount + elecCount + politicalInteractionCount;
                
                if(contactRecord.Touchpoint_sum__c != countOfChildRecords) {
                    contactRecord.Touchpoint_sum__c = countOfChildRecords;
                    isUpdated = true;
                }
                
                Integer eventCount = 0;
                if (contactRecord.CampaignMembers != null) {
                    for (CampaignMember cm : contactRecord.CampaignMembers) {
                        if (cm.RecordType.DeveloperName == 'Event') {
                            eventCount++;
                        }
                    }
                }
                
                if (contactRecord.Event_Count__c != eventCount) {
                    contactRecord.Event_Count__c = eventCount;
                    isUpdated = true;
                }
                
                if (isUpdated) {
                    lstContactToUpdate.add(contactRecord);
                }
            }
            
            if (!lstContactToUpdate.isEmpty()) {
                TriggerFactory.setBypass('ContactTriggerHandler');
                BBApps_Crud.doUpdateWithHandling(lstContactToUpdate, false, ERR_EXECUTE);
            }
        }
        
        catch(Exception ex){
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}