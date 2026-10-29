/********************************************************************************
* Class Name  : RelatedContactTriggerHandler
* Business Purpose: Enforce a single “Events Primary Staff Contact” per Main Contact
*                   and sync that selected staff contact to related Campaign Members. (BRME-3582)
*
* Description :
* This handler is invoked by the Related_Contact__c trigger and supports before/after
* insert and update operations.
* Test class: RelatedContactTriggerHandlerTest
********************************************************************************/
public without sharing class RelatedContactTriggerHandler extends TriggerHandler{
    
    public List<Related_Contact__c> newContacts;
    public List<Related_Contact__c> oldContacts;
    public Map<Id,Related_Contact__c> newMap;   
    public Map<Id,Related_Contact__c> oldMap;
    public Boolean isBeforeTrigger = false;
    public Boolean isAfterTrigger = false;
    public Boolean isUpdateTrigger = false;
    public Boolean isDeleteTrigger = false;
    public Boolean isInsertTrigger = false;
    
    
    public RelatedContactTriggerHandler() {
        this(Trigger.old, Trigger.new,(Map<Id,Related_Contact__c>)Trigger.oldMap,(Map<Id,Related_Contact__c>)Trigger.newMap);
        if (Trigger.isBefore) isBeforeTrigger = true;
        if (Trigger.isAfter) isAfterTrigger = true;
        if (Trigger.isUpdate) isUpdateTrigger = true;
        if (Trigger.isDelete) isDeleteTrigger = true; 
        if (Trigger.isInsert) isInsertTrigger = true;       
    }
    
    public RelatedContactTriggerHandler(List<Related_Contact__c> oldCList, List<Related_Contact__c> newCList,Map<Id,Related_Contact__c> oldMap,Map<Id,Related_Contact__c> newMap) {
        this.oldContacts = oldCList;
        this.newContacts = newCList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    
    public override void bulkBefore() {
        if (Trigger.isInsert || Trigger.isUpdate) {
            validatePrimaryContact(
                (List<Related_Contact__c>) Trigger.new,
                Trigger.isUpdate
                ? (Map<Id, Related_Contact__c>) Trigger.oldMap
                : null
            );
        }
    }
    
    public override void bulkAfter() {
        Set<Id> mainContactIds = new Set<Id>();
        Map<Id, Related_Contact__c> primaryFromCurrentTxnByMainContact = new Map<Id, Related_Contact__c>();
        Map<Id, Set<String>> mainContactToEmails = new Map<Id, Set<String>>();
        
        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
            for (Related_Contact__c rc : newContacts) {
                if (rc.Main_Contact__c == null) continue;
                // Always collect Main Contact if record is inserted or updated
                mainContactIds.add(rc.Main_Contact__c);
                // If it became primary, prefer current txn value
                if (rc.Events_Primary_Staff_Contact__c && rc.Related_Contact__c != null) {
                    primaryFromCurrentTxnByMainContact.put(rc.Main_Contact__c, rc);
                }
            }
        }
        
        if (Trigger.isDelete) {
            for (Related_Contact__c rc : oldContacts){
                if (rc.Main_Contact__c != null) mainContactIds.add(rc.Main_Contact__c);
                if(rc.Main_Contact__c != null &&  rc.Related_Contact__c != null && rc.Related_Contact_Business_Email__c != null){
                    
                    if(!mainContactToEmails.containsKey(rc.Main_Contact__c)){
                        mainContactToEmails.put(rc.Main_Contact__c, new Set<String>());
                    }
                    
                    mainContactToEmails.get(rc.Main_Contact__c).add(rc.Related_Contact_Business_Email__c.toLowerCase());
                }
            }
        }
        
        if (!mainContactIds.isEmpty()){    
            Map<String, Related_Contact__c> existingPrimaryByMainContact = EventMangementAuraCtrl.getAssistantByContact(new List<Id>(mainContactIds));
            updateAssistantContactOnListMember(mainContactIds, primaryFromCurrentTxnByMainContact, existingPrimaryByMainContact, mainContactToEmails);
        }
    }
    public static void updateAssistantContactOnListMember( Set<Id> mainContactIds, Map<Id, Related_Contact__c> primaryFromCurrentTxnByMainContact,Map<String, Related_Contact__c> existingPrimaryByMainContact, Map<Id, Set<String>> mainContactToEmails) {      
        List<CampaignMember> campaignMembers = [
            SELECT Id, ContactId, Assistant__c,CC_Addresses__c
            FROM CampaignMember
            WHERE ContactId IN :mainContactIds AND Campaign.EventStatus__c ='Upcoming' AND Campaign.RecordType.DeveloperName = :Assets.CAMPAIGN_RECORDTYPE_DEVENAME_EVENT WITH SYSTEM_MODE
        ];
        
        List<CampaignMember> membersToUpdate = new List<CampaignMember>();
        
        for (CampaignMember member : campaignMembers) {
            Id newAssistantId;
            boolean updateRequired = false;
            if (existingPrimaryByMainContact != null && existingPrimaryByMainContact.containsKey(member.ContactId) && existingPrimaryByMainContact.get(member.ContactId).Events_Primary_Staff_Contact__c){
                newAssistantId = existingPrimaryByMainContact.get(member.ContactId).Related_Contact__c;
            }          
            else if (primaryFromCurrentTxnByMainContact.containsKey(member.ContactId)){
                newAssistantId = primaryFromCurrentTxnByMainContact.get(member.ContactId).Related_Contact__c;
            }
            else if (existingPrimaryByMainContact != null && existingPrimaryByMainContact.containsKey(member.ContactId)){
                newAssistantId = existingPrimaryByMainContact.get(member.ContactId).Related_Contact__c;
            } 
            
            if (member.Assistant__c != newAssistantId) {
                member.Assistant__c = newAssistantId;
                updateRequired = true;  
            }
            if(mainContactToEmails.containsKey(member.ContactId) && !String.isBlank(member.CC_Addresses__c)){
                Set<String> emailsToRemove = mainContactToEmails.get(member.ContactId);
                
                List<String> existingEmails = member.CC_Addresses__c.split(',');
                List<String> finalEmails = new List<String>();
                for(String email : existingEmails){
                    
                    String trimmedEmail = email.trim().toLowerCase();
                    
                    if(!emailsToRemove.contains(trimmedEmail)){
                        finalEmails.add(email.trim());
                    }
                }
                system.debug('@@finalEmails'+finalEmails);
                member.CC_Addresses__c = String.join(finalEmails, ',');
                updateRequired = true;
            }
            
            if( updateRequired == true) {
                System.debug('@@existing Emails'+member.CC_Addresses__c);
                membersToUpdate.add(member);
            }
        }
        

        if (!membersToUpdate.isEmpty()) update membersToUpdate;
    }
    
    public static void validatePrimaryContact( List<Related_Contact__c> newList, Map<Id, Related_Contact__c> oldMap ) {
        Set<Id> contactIds = new Set<Id>();
        
        // Step 1: Collect Contact Ids where Primary = true
        for (Related_Contact__c rc : newList) {
            Boolean isBecomingPrimary =
                rc.Events_Primary_Staff_Contact__c &&
                (oldMap == null ||
                 oldMap.get(rc.Id).Events_Primary_Staff_Contact__c != true);
            
            if (isBecomingPrimary && rc.Main_Contact__c != null) {
                contactIds.add(rc.Main_Contact__c);
            }
        }
        
        if (contactIds.isEmpty()) return;
        
        // Step 2: Query existing primary related contacts
        Map<Id, Integer> primaryCountByContact = new Map<Id, Integer>();
        
        for (AggregateResult ar : [
            SELECT Main_Contact__c contactId, COUNT(Id) cnt
            FROM Related_Contact__c
            WHERE Main_Contact__c IN :contactIds
            AND Events_Primary_Staff_Contact__c = true WITH SYSTEM_MODE
            GROUP BY Main_Contact__c
        ]) {
            primaryCountByContact.put(
                (Id) ar.get('contactId'),
                (Integer) ar.get('cnt')
            );
        }
        
        // Step 3: Add error if primary already exists
        for (Related_Contact__c rc : newList) {
            if (rc.Events_Primary_Staff_Contact__c &&
                rc.Main_Contact__c != null &&
                primaryCountByContact.containsKey(rc.Main_Contact__c)) {
                    rc.addError(
                        'There is already an Events Primary Staff Contact selected for this contact.'
                    );
                }
        }
    }
}