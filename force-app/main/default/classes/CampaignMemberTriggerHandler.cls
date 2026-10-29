public without sharing class CampaignMemberTriggerHandler extends TriggerHandler {
    public static Boolean IS_SKIP_VALIDATION = false;
    public static Boolean historyTrackingRun = false;
    public static Boolean isCampaignDeleting = false;
    public List<CampaignMember> newCampaignMembers;
    public List<CampaignMember> oldCampaignMembers;
    public static Map<Id, Campaign> campaignMap;
    public static Map<Id, Contact> contactMap;
    public Map<Id, Contact> updateContactMap;
    public Boolean isUpdateTrigger;
    public Boolean isInsertTrigger;
    public Boolean isDeleteTrigger;
    public Boolean isAfterTrigger;
    public Boolean isBeforeTrigger;
    public Boolean isUndeleteTrigger;

    public static Map<Id, Schema.RecordTypeInfo> campaignRecordTypes = Schema.SObjectType.Campaign.getRecordTypeInfosById();
    public List<CampaignMember> addedMemberList;
    public List<CampaignMember> deletedMemberList;
    
    private static final String ERR_BULK_BEFORE = 'CAMPAIGN_MEMBER_BULK_BEFORE_FAILED';
    private static final String ERR_BULK_AFTER = 'CAMPAIGN_MEMBER_BULK_AFTER_FAILED';
    private static final String ERR_BEFORE_INSERT = 'CAMPAIGN_MEMBER_BEFORE_INSERT_FAILED';
    private static final String ERR_BEFORE_UPDATE = 'CAMPAIGN_MEMBER_BEFORE_UPDATE_FAILED';
    private static final String ERR_AND_FINALLY = 'CAMPAIGN_MEMBER_AND_FINALLY_FAILED';
    private static final String ERR_INSERT_FEEDLIST = 'CAMPAIGN_MEMBER_INSERT_FEEDLIST_FAILED';
    private static final String ERR_INSERT_INTERACTIONS = 'CAMPAIGN_MEMBER_INSERT_INTERACTIONS_FAILED';
    
    public CampaignMemberTriggerHandler() {
        isUpdateTrigger = Trigger.isUpdate;
        isInsertTrigger = Trigger.isInsert;
        isDeleteTrigger = Trigger.isDelete;
        isAfterTrigger = Trigger.isAfter;
        isBeforeTrigger = Trigger.isBefore;
        isUndeleteTrigger = Trigger.isUndelete;
        if (isInsertTrigger || isUndeleteTrigger) {
            this(Trigger.New, new List<CampaignMember>());
        }
        if (isUpdateTrigger) {
            this(Trigger.New, Trigger.Old);
        }
        if (isDeleteTrigger) {
            this(new List<CampaignMember>(), Trigger.Old);
        }
    }
    
    public CampaignMemberTriggerHandler(List<CampaignMember> newMembers, List<CampaignMember> oldMembers) {
        newCampaignMembers = newMembers;
        oldCampaignMembers = oldMembers;
        addedMemberList = new List<CampaignMember>();
        deletedMemberList = new List<CampaignMember>();
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> assistantContactIds = new Set<Id>();
        for (CampaignMember cm : newMembers) {
            campaignIds.add(cm.CampaignId);
            contactIds.add(cm.ContactId);
            if(cm.Assistant__c <> null){
                assistantContactIds.add(cm.Assistant__c);
            }
        }
        for (CampaignMember cm : oldMembers) {
            campaignIds.add(cm.CampaignId);
            contactIds.add(cm.ContactId);
            if(cm.Assistant__c <> null){
                assistantContactIds.add(cm.Assistant__c);
            }
        }
        if(!assistantContactIds.Isempty()){
            contactIds.addAll(assistantContactIds);
        }
        campaignMap = new Map<Id, Campaign>([
            SELECT Id, Name, Constituency__c, RecordTypeId, RecordType.Name, EmailDefaultSubjectLine__c, RecordType.DeveloperName, EventStatus__c
            FROM Campaign
            WHERE Id IN :campaignIds WITH SYSTEM_MODE
        ]);
        contactMap = new Map<Id, Contact>([
            SELECT Id, Constituencies_Joined__c, Constituencies_Declined__c, Preferred_First_Name__c, Preferred_Last_Name__c,
            Possible_Constituencies__c, LastName, FirstName, DoNotCall, Bio_Photo__c,
            Bio_Description__c, Bio_Confidential_Notes__c, Email, Business_Email_2__c,
            Personal_Email_2__c, Alternate_Email__c, Dietary_Restrictions_Text__c, Full_Name__c,
            Restricted__c, RestrictedFirstName__c, RestrictedLastName__c, Restricted_Name__c
            FROM Contact
            WHERE Id IN :contactIds WITH SYSTEM_MODE
        ]);
        updateContactMap = new Map<Id, Contact>();
    }
    
    public override void beforeInsert(SObject so) {
        try {
            CampaignMember cm = (CampaignMember) so;
            Campaign campaignRecord = campaignMap.get(cm.CampaignId);
            updateBioDetails(cm,contactMap);
            // Once Campaign is Event, the Event Email should be auto-populated for Event guests
            updateEmailSubjectLine(cm,campaignRecord);
            clearFundOrg(cm);
            updateRSVPDateTime(cm);
            updateGuestEmailType(cm);
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BEFORE_INSERT));
        }
    }
    
    public override void bulkBefore() {
        try {
            Map<String, Related_Contact__c> relatedContacts = new Map<String, Related_Contact__c>();
            if (isInsertTrigger) {
                Set<Id> contactIds = new Set<Id>();
                for (CampaignMember cm : newCampaignMembers) {
                    if (cm.ContactId <> null) {
                        contactIds.add(cm.ContactId);
                    }
                }
                if(!contactIds.Isempty()) {
                    List<String> contactIdList = new List<String>();
                    for (Id cId : contactIds) {
                        contactIdList.add(String.valueOf(cId));
                    }
                    relatedContacts = EventMangementAuraCtrl.getAssistantByContact(contactIdList);
                    if(!relatedContacts.IsEmpty()) {
                        updateAssitantOnCampaignMember(newCampaignMembers, relatedContacts);
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_BEFORE));
        }
    }

    public override void bulkAfter() {
        try {
            Set<Id> campaignIds = new Set<Id>();
            if(isInsertTrigger || isUpdateTrigger || isUndeleteTrigger) {
                for(CampaignMember cm : newCampaignMembers) {
                    if(cm.CampaignId != null && cm.ContactId != null) {
                        campaignIds.add(cm.CampaignId);
                    }
                }
            }
            if(isUpdateTrigger || isDeleteTrigger) {
                for(CampaignMember cm : oldCampaignMembers) {
                    if(cm.CampaignId != null && cm.ContactId != null) {
                        campaignIds.add(cm.CampaignId);
                    }
                }
            }
            ContactMissingEmailRollupService.recalculateForCampaigns(campaignIds);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_AFTER));
        }
    }

    public static void updateAssitantOnCampaignMember(List<CampaignMember> newMembers, Map<String, Related_Contact__c> relatedContacts) {
        if (!relatedContacts.isEmpty()) {
            for (CampaignMember cm : newMembers) {
                if (cm.ContactId <> null
                    && relatedContacts.containsKey(cm.ContactId) && campaignMap.containskey(cm?.CampaignId ) && 
                    campaignMap.get(cm?.CampaignId)?.RecordType.DeveloperName == Assets.CAMPAIGN_RECORDTYPE_DEVENAME_EVENT
                    && campaignMap.get(cm?.CampaignId)?.EventStatus__c == 'Upcoming') {
                        cm.Assistant__c = relatedContacts.get(cm.ContactId).Related_Contact__c;
                        if(cm.CC_Assistant__c && cm.CC_Assistant__c  == true){
                            updateCCEmailAddress(cm, null, contactMap);
                        }        
                    }
            }
        }
    }
    
    public static void updateBioDetails(CampaignMember cm,Map<Id, Contact> contactMap){
        
        if (contactMap.get(cm.ContactId) != null && contactMap.get(cm.ContactId).DoNotCall) {
            cm.addError('The following Contacts were not added because they have a Do Not Contact alert: ' +
                contactMap.get(cm.ContactId).FirstName + ' ' + contactMap.get(cm.ContactId).LastName +
                ' (Deceased)'
            );
        } else if (contactMap.get(cm.ContactId) != null) {
            cm.Bio_Photo__c = contactMap.get(cm.ContactId).Bio_Photo__c;
            cm.Bio_Description__c = contactMap.get(cm.ContactId).Bio_Description__c;
            cm.Bio_Confidential_Notes__c = contactMap.get(cm.ContactId).Bio_Confidential_Notes__c;
        }
    }
    
    public static void updateEmailSubjectLine(CampaignMember cm, Campaign campaignRecord ){
        
        if (campaignRecordTypes.get(campaignRecord.RecordTypeId).getDeveloperName() == Assets.CAMPAIGN_RECORDTYPE_DEVENAME_EVENT) {
            Contact contactRec = contactMap.get(cm.ContactId);
            
            if (String.isNotBlank(campaignRecord.EmailDefaultSubjectLine__c)) {
                String fullName;
                Boolean isRestricted = contactRec?.Restricted__c;
                if (isRestricted) {
                    fullName = String.isNotBlank(contactRec?.Preferred_Last_Name__c)
                        ? contactRec.Preferred_Last_Name__c
                        : (String.isNotBlank(contactRec?.LastName) ? contactRec.LastName : '');
                } else {
                    String firstName = String.isNotBlank(contactRec?.Preferred_First_Name__c)
                        ? contactRec.Preferred_First_Name__c
                        : (String.isNotBlank(contactRec?.FirstName) ? contactRec.FirstName : '');
                    String lastName = String.isNotBlank(contactRec?.Preferred_Last_Name__c)
                        ? contactRec.Preferred_Last_Name__c
                        : (String.isNotBlank(contactRec?.LastName) ? contactRec.LastName : '');
                    fullName = (firstName + ' ' + lastName).trim();
                }
                String emailSubjectLine = campaignRecord.EmailDefaultSubjectLine__c.replace('\'', '\'\'');
                cm.EmailSubjectLine__c = String.format(emailSubjectLine, new List<Object>{ fullName });
            }
        }
    }
    
    private void updateGuestEmailType(CampaignMember cm) {
        if (contactMap == null || contactMap.isEmpty() || contactMap.get(cm.ContactId) == null) {
            return;
        }
        Contact c = contactMap.get(cm.ContactId);
        cm.Guest_Email_Type__c = getEmailType(c);
    }
    
    private String getEmailType(Contact c) {
        if (String.isNotBlank(c.Email)) {
            return 'Business';
        }
        if (String.isNotBlank(c.Alternate_Email__c)) {
            return 'Personal';
        }
        if (String.isNotBlank(c.Business_Email_2__c)) {
            return 'Additional';
        }
        if (String.isNotBlank(c.Personal_Email_2__c)) {
            return 'Confidential';
        }
        return 'Business';
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so) {
        try {
            CampaignMember cm = (CampaignMember) so;
            CampaignMember oldCm = (CampaignMember) oldSo;
            clearFundOrg(cm);
            updateRSVPDateTime(cm);
            // assistant change updates the cc address on list member
            if(isFieldChanged(cm, 'CC_Assistant__c') || isFieldChanged(cm, 'Assistant__c') && cm.Assistant__c != null && cm.CC_Assistant__c  == true  && cm.CampaignId != null) {
                updateCCEmailAddress(cm, oldCm, contactMap);
            }
            if(isFieldChanged(cm, 'CC_Assistant__c') && cm.CC_Assistant__c  == FALSE){
                  updateCCEmailAddressNull(cm,oldCm,contactMap);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BEFORE_UPDATE));
        }
    }

    // update CC email address null on List Member
    public static void updateCCEmailAddressNull(CampaignMember cm, CampaignMember oldCm, Map<Id, Contact> contactMap) {
        
        if (oldCm == null || oldCm.Assistant__c == null ||
            !contactMap.containsKey(oldCm.Assistant__c) ||
            String.isBlank(oldCm.CC_Addresses__c)) {
                return;
            }

        String oldEmail = contactMap.get(oldCm.Assistant__c).Email;
        if (String.isBlank(oldEmail)) {
            return;
        }

        Set<String> emailSet = new Set<String>();

        // Emails coming from LWC
        if (String.isNotBlank(cm.CC_Addresses__c)) {
            for (String email : cm.CC_Addresses__c.split(',')) {
                emailSet.add(email.trim());
            }
        }

        // Keep old emails except assistant email
        for (String email : oldCm.CC_Addresses__c.split(',')) {
            email = email.trim();
            if (String.isNotBlank(email) && !email.equalsIgnoreCase(oldEmail)) {
                emailSet.add(email);
            }
        }

        // Remove emails deleted in LWC
        emailSet.removeAll(getRemovedEmails(oldCm, cm));
        if(emailSet.contains(oldEmail)){
            emailSet.remove(oldEmail);
        }
        
        cm.CC_Addresses__c = emailSet.isEmpty() ? null : String.join(new List<String>(emailSet), ',');
    }
    
    public static Set<String> getRemovedEmails (CampaignMember oldCm, CampaignMember cm ){
        Set<String> oldEmails = new Set<String>();
        Set<String> newEmails = new Set<String>();
        
        if (String.isNotBlank(oldCm.CC_Addresses__c)) {
            oldEmails.addAll(oldCm.CC_Addresses__c.split(','));
        }
        
        if (String.isNotBlank(cm.CC_Addresses__c)) {
            newEmails.addAll(cm.CC_Addresses__c.split(','));
        }
        
        // Removed emails
        Set<String> removedEmails = oldEmails.clone();
        removedEmails.removeAll(newEmails);
        
        return removedEmails;
    }
    // update CC email address on List Member
    public static void updateCCEmailAddress( CampaignMember cm, CampaignMember oldCm, Map<Id, Contact> contactMap) {
        
        if (cm.Assistant__c != null &&
            cm.CampaignId != null &&
            contactMap.containsKey(cm.Assistant__c) &&
            campaignMap.containsKey(cm.CampaignId) &&
            campaignMap.get(cm.CampaignId).EventStatus__c == 'Upcoming') {
                
                String newEmail = contactMap.get(cm.Assistant__c).Email;
                String oldEmail = '';
                
                if (oldCm != null &&
                    oldCm.Assistant__c != null &&
                    contactMap.containsKey(oldCm.Assistant__c)) {
                        oldEmail = contactMap.get(oldCm.Assistant__c).Email;
                    }
                
                if (String.isNotBlank(newEmail)) {
                    if ((oldCm ==null || String.isBlank(oldCm.CC_Addresses__c)) &&  String.isBlank(cm.CC_Addresses__c) ) {
                        cm.CC_Addresses__c = newEmail;
                    } else{
                        
                        List<String> emailList = new List<String>();
                        
                        Boolean replaced = false;
                        Boolean alreadyExists = false;
                        if(String.isNotBlank(oldCm.CC_Addresses__c)){
                            emailList.addAll(oldCm.CC_Addresses__c.split(','));
                            
                            for (Integer i = 0; i < emailList.size(); i++) {
                                String email = emailList[i] != null ? emailList[i].trim() : '';
                                
                                if (String.isBlank(email)) {
                                    continue;
                                }
                                if (email.equalsIgnoreCase(newEmail)) {
                                    alreadyExists = true;
                                }
                                
                                if (String.isNotBlank(oldEmail) &&
                                    email.equalsIgnoreCase(oldEmail) && oldEmail <> newEmail) {
                                        
                                        if (alreadyExists) {
                                            emailList[i] = null;
                                        } else {
                                            emailList[i] = newEmail;
                                        }
                                        replaced = true;
                                    }
                            }
                        }
                        
                        emailList.addAll(cm.CC_Addresses__c.split(','));
                        Set<String> cleanedList = new Set<String>();
                        for (String e : emailList) {
                            if (String.isNotBlank(e)) {
                                cleanedList.add(e.trim());
                            }
                        }
                        Set<String> removedEmails =  getRemovedEmails(oldCm,cm);
                        if(!removedEmails.isEmpty()){
                            cleanedList.RemoveAll(removedEmails);
                        }
                        if (!replaced && !alreadyExists) {
                            cleanedList.add(newEmail);
                        }
                        cm.CC_Addresses__c = String.join(cleanedList, ',');
                    }
                }
            }
    }
    
    public override void afterInsert(SObject so) {
        CampaignMember cm = (CampaignMember) so;
        addedMemberList.add(cm);
    }
    
    public override void beforeDelete(SObject so) {
        CampaignMember cm = (CampaignMember) so;
        deletedMemberList.add((CampaignMember) so);
        if(String.isNotBlank(cm.ZkipsterGuestId__c) && !isCampaignDeleting){
            ZkipsterIntegration.deleteZkipsterGuest(cm.ZkipsterGuestId__c);
        }
    }
    
    public override void andFinally() {
        try {
            processHistoryTracking();
            createContactInteraction();
            if (!updateContactMap.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(updateContactMap.values(), false, new BBApps_ErrorCustomFields(ERR_INSERT_FEEDLIST));
            }
            if (!isCampaignFeed()) return;
            createNewMemberFeeds();
            deleteNewMemberFeeds();
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AND_FINALLY));
        }
    }

    private void updateRSVPDateTime(CampaignMember mem) {
        if ((isInsertTrigger && String.isNotBlank(mem.RSVPStatus__c)) || (isUpdateTrigger && isFieldChanged(mem, 'RSVPStatus__c'))) {
            mem.RSVPUpdateDate__c = DateTime.now();
        }
    }

    private void processHistoryTracking() {
        if(!isDeleteTrigger && !historyTrackingRun) {
            historyTrackingRun = true;
            FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
        }
    }
    
    private void createNewMemberFeeds() {
        if (addedMemberList.isEmpty()) return;
        List<FeedItem> feedsList = new List<FeedItem>();
        for (CampaignMember cm : addedMemberList) {
            if (cm.ContactId != null) {
                FeedItem newFeed = new FeedItem();
                newFeed.ParentId = cm.CampaignId;
                newFeed.Title = Assets.ADDED_TITLE;
                newFeed.Body = cm.Name + ' added to ' + cm.CampaignId + ' | ' + cm.ContactId;
                feedsList.add(newFeed);
            }
        }
        BBApps_Crud.doInsertWithHandling((List<SObject>) feedsList, false, new BBApps_ErrorCustomFields(ERR_INSERT_FEEDLIST));
    }
    
    private void deleteNewMemberFeeds() {
        if (deletedMemberList.isEmpty()) return;
        List<FeedItem> feedsList = new List<FeedItem>();
        for (CampaignMember cm : deletedMemberList) {
            if (cm.ContactId != null) {
                FeedItem newFeed = new FeedItem();
                newFeed.ParentId = cm.CampaignId;
                newFeed.Title = Assets.REMOVED_TITLE;
                newFeed.Body = cm.Name + ' removed from ' + cm.CampaignId + ' | ' + cm.ContactId;
                feedsList.add(newFeed);
            }
        }
        BBApps_Crud.doInsertWithHandling((List<SObject>) feedsList, false, new BBApps_ErrorCustomFields(ERR_INSERT_FEEDLIST));
    }
    
    private static void clearFundOrg(CampaignMember member) {
        if (member.RecordTypeId == null || !'Individual'.equalsIgnoreCase(member.Fundraising_Donor_Type__c)) {
            return;
        }
        member.Fundraising_Organization__c = null;
    }
    
    public Boolean isCampaignFeed() {
        try {
            Bypass_Automation_Setting__c setting = Bypass_Automation_Setting__c.getInstance();
            return setting.Campaign_Feed__c == false;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_AFTER));
            return false;
        }
    }
    
    private void createContactInteraction() {
        if (isAfterTrigger && (isUpdateTrigger || isInsertTrigger)) {
            List<Interaction__c> interactions = new List<Interaction__c>();
            Id contactInteractionRecordTypeId = Schema.SObjectType.Interaction__c.getRecordTypeInfosByName()
                .get('Contact Interaction (BP)').getRecordTypeId();
            Boolean isFundraisingUser = UtilityClass.checkIfUserHasAssignedPermissionSet(UserInfo.getUserId(), 'Fundraising_Users');
            if (isFundraisingUser) {
                for (CampaignMember cm : newCampaignMembers) {
                    if (cm.Tour_Date__c != null && isFieldChanged(cm, 'Tour_Date__c')) {
                        Interaction__c interaction = new Interaction__c(
                            RecordTypeId = contactInteractionRecordTypeId,
                            Name = 'PAC Tour',
                            Contact__c = cm.ContactId,
                            Interaction_Date__c = cm.Tour_Date__c,
                            Interaction_Type__c = 'Tour'
                        );
                        interactions.add(interaction);
                    }
                }
                if (!interactions.isEmpty()) {
                    BBApps_Crud.doInsertWithHandling((List<SObject>) interactions, false, new BBApps_ErrorCustomFields(ERR_INSERT_INTERACTIONS));
                }
            }
        }
    }
}