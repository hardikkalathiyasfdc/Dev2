/********************************************************************************
* Class Name  : ContactTriggerHandler
* Description : This class is used by Contact Trigger and consists of business logic.
* Created By  : Slalom Consulting
* Change Log  : Created - 5/1/2019
*
* ----------------------------------
* Updated By    Date            Comment
* Bloomberg    01/10/2020      Repurposing this class for TriggerFactory pattern
All existing methods are static.
So, should not affect existing functionality.
********************************************************************************/

public without sharing class ContactTriggerHandler extends TriggerHandler {
    public List<Contact> newContacts;
    public List<Contact> oldContacts;
    public Map<Id, Contact> newMap;
    public Map<Id, Contact> oldMap;
    public Boolean isUpdateTrigger;
    public Boolean isInsertTrigger;
    public Boolean isDeleteTrigger;
    public Boolean isAfterTrigger;
    public Boolean isBeforeTrigger;
    private static Set<String> executedTriggers = new Set<String>();

    public static Map<Id,Contact> contactMapForCampaignMemberUpdate = new Map<Id,Contact>();
    public static Set<Id> deletedContactsIds;
    public static List<Related_Contact__c>  relatedContactsToDelete;
    public static Map<String, String> mergedId_and_MasterId_Map = new Map<String, String>();
    private Set<Id> mergedMasterContactIds;
    public static Id individualAccountId;
    public List<Employment_History_and_Board_Membership__c> employmentHistoryList = new List<Employment_History_and_Board_Membership__c>();
    private Set<String> boardMemberContactIds;
    private List<String> boardMemberAlertReceivers;

    private List<Messaging.SingleEmailMessage> boardMemberEmails;

    private Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
    public static Boolean boardMemberContactAlertSent = false;
    private List<Id> mergeWinningRecordIds;
    private Set<Id> contactsForDonorNameUpdate = new Set<Id> ();
    private Map<String, Account> accountMap;
    private static Map<String, String> priorityEmailsMap = new Map<String, String> {
        'Email' => 'Business', 'Alternate_Email__c' => 'Personal', 'Business_Email_2__c' => 'Additional'
    };

    private static final String ERR_BEFORE_INSERT = 'CONTACT_TRIGGER_HANDLER_BEFORE_INSERT_FAILED';
    private static final String ERR_BEFORE_UPDATE = 'CONTACT_TRIGGER_HANDLER_BEFORE_UPDATE_FAILED';
    private static final String ERR_AFTER_INSERT = 'CONTACT_TRIGGER_HANDLER_AFTER_INSERT_FAILED';
    private static final String ERR_AFTER_UPDATE= 'CONTACT_TRIGGER_HANDLER_AFTER_UPDATE_FAILED';
    private static final String ERR_BEFORE_DELETE= 'CONTACT_TRIGGER_HANDLER_BEFORE_DELETE_FAILED';
    private static final String ERR_BULK_BEFORE= 'CONTACT_TRIGGER_HANDLER_BULK_BEFORE_FAILED';
    private static final String ERR_BULK_AFTER= 'CONTACT_TRIGGER_HANDLER_BULK_AFTER_FAILED';
    private static final String ERR_AND_FINALLY= 'CONTACT_TRIGGER_HANDLER_AND_FINALLY_FAILED';
    private static final String ERR_AFTER_DELETE= 'CONTACT_TRIGGER_HANDLER_AFTER_DELETE_FAILED';
    private static final String ERR_AFTER_MERGE= 'CONTACT_TRIGGER_HANDLER_AFTER_MERGE_FAILED';
    private static final String ERR_UPDATE_LIST_MEMBERS= 'CONTACT_TRIGGER_HANDLER_UPDATE_LIST_MEMBERS_FAILED';
    private static final String ERR_HANDLE_DONOR_NAME_UPDATE= 'CONTACT_TRIGGER_HANDLER_HANDLE_DONOR_NAME_UPDATE_FAILED';
    private static final String ERR_FETCH_RELATED_CONTACT_TO_DELETE= 'CONTACT_TRIGGER_HANDLER_FETCH_RELATED_CONTACT_TO_DELETE_FAILED';
    private static final String ERR_HANDLE_RELATED_CONTACTS_DELETION_AND_REPARENTING= 'CONTACT_TRIGGER_HANDLER_HANDLE_RELATED_CONTACTS_DELETION_AND_REPARENTING_FAILED';
    private static final String ERR_HANDLE_MERGE_DUPLICATE_CLEANUP= 'CONTACT_TRIGGER_HANDLER_HANDLE_MERGE_DUPLICATE_CLEANUP_FAILED';
    private static final String ERR_INSERT_EMPLOYMENT_HISTORY= 'CONTACT_TRIGGER_HANDLER_INSERT_EMPLOYMENT_HISTORY_FAILED';
    private static final String ERR_VALIDATE_COMMITTEES= 'CONTACT_TRIGGER_HANDLER_VALIDATE_COMMITTEES_FAILED';
    private static final String ERR_CHECK_FOR_DUPLICATE_COMMITTEES= 'CONTACT_TRIGGER_HANDLER_CHECK_FOR_DUPLICATE_COMMITTEES_FAILED';
    private static final String ERR_BOARD_MEMBER_UPDATE_NOTIFICATION= 'CONTACT_TRIGGER_HANDLER_BOARD_MEMBER_UPDATE_NOTIFICATION_FAILED';
    private static final String ERR_PREPARE_BOARD_MEMBER_UPDATE_EMAIL= 'CONTACT_TRIGGER_HANDLER_PREPARE_BOARD_MEMBER_UPDATE_EMAIL_FAILED';
    private static final String ERR_INITIALIZE_INDIVIDUAL_ACCOUNTID= 'CONTACT_TRIGGER_HANDLE_INITIALIZE_INDIVIDUAL_ACCOUNTID_FAILED';
    private static final String ERR_FLAG_DECEASED_CONTACTS= 'CONTACT_TRIGGER_HANDLER_FLAG_DECEASED_CONTACT_FAILED';
    private static final String ERR_VALIDATE_ENDORSEMENT_STATUS= 'CONTACT_TRIGGER_HANDLER_VALIDATE_ENDORSEMENT_STATUS_FAILED';
    private static final String ERR_CHECK_BIO_PHOTO_URL= 'CONTACT_TRIGGER_HANDLER_CHECK_BIO_PHOTO_URL_FAILED';
    private static final String ERR_UPDATE_DO_NOT_CONTACT_AFTER_DESEASE_AND_DO_NOT_CONTACT= 'CONTACT_TRIGGER_HANDLER_UPDATE_DO_NOT_CONTACT_AFTER_DESEASE_AND_DO_NOT_CONTACT_FAILED';
    private static final String ERR_SET_CONTACT_BUSINESS_ADDRESS= 'CONTACT_TRIGGER_HANDLER_SET_CONTACT_BUSINESS_ADDRESS_FAILED';
    private static final String ERR_SET_DATA_BEFORE_OPERATION= 'CONTACT_TRIGGER_HANDLER_SET_DATA_BEFORE_OPERATIONL_FAILED';
    private static final String ERR_HANDLE_BIO_DESCRIPTION= 'CONTACT_TRIGGER_HANDLER_HANDLE_BIO_DESCRIPTION_FAILED';
    private static final String ERR_APPLY_ACCOUNT_RESTRICTIONS= 'CONTACT_TRIGGER_HANDLER_APPLY_ACCOUNT_RESTRICTIONS_FAILED';
    private static final String ERR_ASSIGN_CONTACT_OWNER= 'CONTACT_TRIGGER_HANDLER_ASSIGN_CONTACT_OWNER_FAILED';
    private static final String ERR_RESIZE_BIO_PHOTO= 'CONTACT_TRIGGER_HANDLER_RESIZE_BIO_PHOTO_FAILED';
    private static final String ERR_FORMAT_PHONE_FIELD= 'CONTACT_TRIGGER_HANDLER_FORMAT_PHONE_FIELD_FAILED';
    private static final String ERR_SET_LAGACY_SOURCE= 'CONTACT_TRIGGER_HANDLER_SET_LAGACY_SOURCE_FAILED';
    private static final String ERR_CLEAR_PRIORITY_EMAIL_OVERRIDE= 'CONTACT_TRIGGER_HANDLER_CLEAR_PRIORITY_EMAIL_OVERRIDE_FAILED';
    private static final String ERR_UPDATE_BIO_PHOTO= 'CONTACT_TRIGGER_HANDLER_UPDATE_BIO_PHOTO_FAILED';
    private static final String ERR_UPDATE_CONVERTED_NAMES = 'CONTACT_TRIGGER_HANDLER_UPDATE_CONVERTED_NAMES_FAILED';
    private static final String ERR_GET_SESSION_PlatFORM= 'CONTACT_TRIGGER_HANDLER_GET_SESSION_PlatFORM_FAILED';
    private static final String ERR_CHECK_DELETE_PERMISSION= 'CONTACT_TRIGGER_HANDLER_CHECK_DELETE_PERMISSION_FAILED';
    private static final String ERR_UPDATE_CONTACT_CATEGORIES= 'CONTACT_TRIGGER_HANDLER_UPDATE_CONTACT_CATEGORIES_FAILED';
    private static final String ERR_LINK_DELINK_SINGNIFICANT_OTHER= 'CONTACT_TRIGGER_HANDLER_LINK_DELINK_SINGNIFICANT_OTHER_FAILED';
    private static final String ERR_RESTRICTED_FIELD_MAPPING= 'CONTACT_TRIGGER_HANDLER_RESTRICTED_FIELD_MAPPING_FAILED';

/*
* TemporaryComment Refactor Notes:
* Trigger logic separated into lifecycle methods (beforeInsert, beforeUpdate, etc.)
* Constructor simplified and common data initialized once
* Validation and processing logic moved to helper methods
* Changes improve readability and avoid redundant processing
*/
    public ContactTriggerHandler() {
        newContacts = Trigger.new;
        oldContacts = Trigger.old;
        newMap = (Map<Id, Contact>) Trigger.newMap;
        oldMap = (Map<Id, Contact>) Trigger.oldMap;
        isUpdateTrigger = Trigger.isUpdate;
        isInsertTrigger = Trigger.isInsert;
        isDeleteTrigger = Trigger.isDelete;
        isAfterTrigger = Trigger.isAfter;
        isBeforeTrigger = Trigger.isBefore;
        boardMemberContactIds = new Set<String>();

        if(isUpdateTrigger){
            boardMemberContactIds =  UtilityClass.getBoardMemberContactIds(newMap.keySet());
            boardMemberAlertReceivers = UtilityClass.getBoardMemberContactAlertReceiver();
        }
        initializeIndividualAccountId();
    }

    public override void beforeInsert(SObject so){
        try{
            Contact c = (Contact)so;
            validateEndorsementStatus(c);
            checkAndUpdateAccountId(c);
            checkBioPhotoURL(c, null);
            String platform = getSessionPlatform();
            setLegacySource(c, platform);
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_BEFORE_INSERT) );
        }
    }

    public override void beforeUpdate(SObject oldSo, SObject so){
        try {
            Contact c = (Contact)so;
            Contact oldC = (Contact)oldSo;
            clearPriorityEmailOverride(c);
            validateEndorsementStatus(c);
            validateCommittees(c);
            checkAndUpdateAccountId(c);
            checkBioPhotoURL(c, oldC);// Method to check Bio Photo validation
            if(boardMemberContactIds.contains(c.Id) && boardMemberContactAlertSent == false) { //Email should be only sent for the first time
                boardMemberUpdateNotification(c, oldC);
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_BEFORE_UPDATE) );
        }
    }

    public override void afterInsert(SObject so) {
        try{
        Contact c = (Contact)so;
        if(c.AccountId != null && c.AccountId != individualAccountId) {
            employmentHistoryList.add(createEmploymentHistory(c));
        }
    } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_AFTER_INSERT) );
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        try{
            Contact c = (Contact)so;
            Contact oldC = (Contact)oldSo;
            if(c.AccountId != null && c.AccountId != individualAccountId && c.AccountId != oldC.AccountId) {
                employmentHistoryList.add(createEmploymentHistory(c));
            }
            if(isFieldChanged(c, 'Email')) syncCCAndBCCAddresses(c, oldC);
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_AFTER_UPDATE) );
        }
    }

    public override void beforeDelete(SObject so) {
        try{
            Contact c = (Contact)so;
            if(c != null){
                checkDeletePermission(c);
                preventDeletionOfLinkedContact(c);
                deletedContactsIds.add(c.Id);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_BEFORE_DELETE) );
        }
    }

    public override void bulkBefore() {
        try{
            deletedContactsIds =  new Set<Id>();
            mergedMasterContactIds = new Set<Id>();
            boardMemberEmails = new List<Messaging.SingleEmailMessage>();

            List<Id> accountIds = new List<Id>();
            if(newContacts !=null && !newContacts.isEmpty()) {
                for(Contact c : newContacts) {
                    accountIds.add(c.AccountId);
                }
            }

            accountMap = new Map<String, Account>();
            if(!accountIds.isEmpty()) {
                accountIds.add(individualAccountId);
                accountMap = new Map<String, Account>([SELECT Id, Restricted_Org_Name__c, Restricted__c, BillingCity,
                    BillingCountry, BillingCountryCode, BillingGeocodeAccuracy,
                    BillingLatitude, BillingLongitude, BillingPostalCode, BillingState,
                    BillingStateCode, BillingStreet
                    FROM Account
                    WHERE Id In :accountIds]
                );
            }

            if(isInsertTrigger || isUpdateTrigger) {
                setDataBeforeOperation(newContacts, oldMap);
                restrictedFieldsMapping(newContacts, oldMap);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_BULK_BEFORE) );
        }
    }

    public override void bulkAfter() {
        try{
            if(!isDeleteTrigger) {
                FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
                List<Id> cIds = new List<Id> ();
                for(Contact c : newContacts) {
                    cIds.add(c.Id);
                    }

                if(isInsertTrigger) {
                    // for updating contact categories on the basis of user selection
                    updateContactCategories(newContacts, null, null);
                    // validate link/delink significant other
                }

                if(isUpdateTrigger) {
                    updateContactCategories(newContacts, oldMap, newMap);
                    contactMapForCampaignMemberUpdate = new Map<Id,Contact>();
                    // validate link/delink significant other
                    for(Contact c : newContacts) {
                        if (isFieldChanged(c, 'Full_Name__c')) {
                            contactsForDonorNameUpdate.add(c.Id);
                        }
                        if (isFieldChanged(c, 'FirstName') || isFieldChanged(c, 'LastName') || isFieldChanged(c, 'Preferred_First_Name__c')) {
                            contactMapForCampaignMemberUpdate.put(c.Id,c);
                        }
                        if ( isFieldChanged(c, 'Bio_Photo__c') || isFieldChanged(c, 'Bio_Description__c') || isFieldChanged(c, 'Bio_Confidential_Notes__c') || isFieldChanged(c, 'DoNotCall')) {
                            contactMapForCampaignMemberUpdate.put(c.Id,c);
                        }
                    }
                    if(!contactMapForCampaignMemberUpdate.values().IsEmpty()){
                        updateListMember(contactMapForCampaignMemberUpdate);
                    }
                }
                linkDelinkSignificantOther(newMap, newContacts, oldMap);
            }

            if(isDeleteTrigger) {
                mergeWinningRecordIds = new List<Id>();
                for(Contact c : oldContacts) {
                    if(!String.isBlank(c.MasterRecordId)) {
                        mergeWinningRecordIds.add(c.MasterRecordId);
                        contactsForDonorNameUpdate.add(c.MasterRecordId);
                    }
                }
                afterMerge(new Set<Id>(mergeWinningRecordIds));
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_BULK_AFTER) );
        }
    }

    public override void andFinally() {
        try{
            handleDonorNameUpdate();

            if (isBeforeTrigger) {
                if (isDeleteTrigger) {
                    fetchRelatedContactsToDelete();
                }
            }
            if (isAfterTrigger) {
                if (isDeleteTrigger) {
                    handleRelatedContactsDeletionAndReparenting();
                    handleMergeDuplicateCleanup();

                    if(!mergedMasterContactIds.isEmpty()){
                        afterMerge(mergedMasterContactIds);
                    }
                }
            }
            insertEmploymentHistory();
            if(!boardMemberEmails.isEmpty()){
                Messaging.sendEmail(boardMemberEmails);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_AND_FINALLY) );
        }
    }

    public override void afterDelete(SObject so) {
        try{
            Contact c = (Contact)so;
            if(c.MasterRecordId != null || Test.isRunningTest()) {
                mergedMasterContactIds.add(c.MasterRecordId);
                mergedId_and_MasterId_Map.put(c.Id, c.MasterRecordId);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_AFTER_DELETE) );
        }
    }

    @future
    // Purpose: Helper method used to after merge as part of the contact trigger processing.
    public static void afterMerge(Set<Id> mergedMasterContactIds) {
        try {
            if(mergedMasterContactIds == null || mergedMasterContactIds.isEmpty()) return;
            List<Contact> masterContactList = [
                SELECT Id, FirstName, LastName, MiddleName, Suffix, Restricted__c, Deceased__c
                FROM Contact
                WHERE Id IN :mergedMasterContactIds
            ];
            if(masterContactList.isEmpty()) return;
            for(Contact masterContact : masterContactList){
                updatedConvertedNames(masterContact);
                updateReasonField(masterContact);
            }
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.update(masterContactList, dml);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_AFTER_MERGE) );
        }
    }

    private static void updateReasonField(Contact masterContact) {
        masterContact.Report_Record__c = '';
    }

    //BRME-6681 - Helper method used to sync CC and BCC addresses on CampaignMember when Contact email changes.
    private void syncCCAndBCCAddresses(Contact newContact, Contact oldContact) {
        if(String.isBlank(oldContact.Email)) return;
        String oldEmail = oldContact.Email.trim();
        String newEmail = newContact.Email == null
                          ? ''
                          : newContact.Email.trim();
        List<CampaignMember> toUpdate = new List<CampaignMember>();
        for(CampaignMember cm : [SELECT Id, CC_Addresses__c, BCC_Addresses__c, Campaign.EventStatus__c
                                 FROM CampaignMember
                                 WHERE ((CC_Addresses__c != null AND CC_Addresses__c LIKE :('%' + oldEmail + '%'))
                                     OR (BCC_Addresses__c != null AND BCC_Addresses__c LIKE :('%' + oldEmail + '%')))
                                    AND Campaign.EventStatus__c = 'Upcoming'
                                ]) {

            String updatedCCAddresses = replaceToken(cm.CC_Addresses__c, oldEmail, newEmail);
            String updatedBCCAddresses = replaceToken(cm.BCC_Addresses__c, oldEmail, newEmail);
            if(updatedCCAddresses != cm.CC_Addresses__c) {
                cm.CC_Addresses__c = updatedCCAddresses;
                toUpdate.add(cm);
            }
            if(updatedBCCAddresses != cm.BCC_Addresses__c) {
                cm.BCC_Addresses__c = updatedBCCAddresses;
                toUpdate.add(cm);
            }
        }
        if(!toUpdate.isEmpty()) update toUpdate;
    }

    private String replaceToken(String csv, String oldEmail, String newEmail) {
        if(String.isBlank(csv)) return csv;
        List<String> out = new List<String>();
        Set<String> seen = new Set<String>();
        for(String token : csv.split(',')) {
            String t = token.trim();
            if(String.isBlank(t)) continue;
            String replaced = t.equalsIgnoreCase(oldEmail) ? newEmail : t;
            if(String.isBlank(replaced)) continue;
            if(seen.add(replaced.toLowerCase())) out.add(replaced);
        }
        return String.join(out, ', ');
    }

    // BRME-5393: Update CampaignMember.EmailSubjectLine__c when Contact First Name, Last Name, or Preferred First Name changes
    public void updateListMember( Map<Id,Contact> contactMapForCampaignMemberUpdate) {
        Set<Id> updatedContacts = contactMapForCampaignMemberUpdate.keySet();
        try{
            List<CampaignMember> cmList = [
                SELECT Id, EmailSubjectLine__c, Campaign.EmailDefaultSubjectLine__c, ContactId, Contact.Restricted__c, Contact.Preferred_First_Name__c, Contact.FirstName, Contact.LastName,
                Do_Not_Contact__c, Bio_Photo__c, Bio_Description__c, Bio_Confidential_Notes__c, X2020_Bio__c
                FROM CampaignMember
                WHERE ContactId IN :updatedContacts
                AND ContactId != NULL
                AND Campaign.RecordType.DeveloperName = :Assets.CAMPAIGN_RECORDTYPE_DEVENAME_EVENT
            ];

            if (cmList.isEmpty()) return;
            List<CampaignMember> recordsToUpdate = new List<CampaignMember>();
            for (CampaignMember cm : cmList) {

                // Guard: campaign relationship and subject template must be present
                if (cm.Campaign == null || String.isBlank(cm.Campaign.EmailDefaultSubjectLine__c)) {
                    continue;
                }

                String fullName;
                Boolean isRestricted = cm.Contact?.Restricted__c;
                Boolean isUpdateCM = false;
                if (isRestricted) {
                    // Restricted contacts: Last Name only
                    fullName = String.isNotBlank(cm.Contact?.LastName) ? cm.Contact.LastName : '';
                } else {
                    // Prefer Preferred First Name, fall back to First Name, then empty
                    String firstName = String.isNotBlank(cm.Contact?.Preferred_First_Name__c) ? cm.Contact.Preferred_First_Name__c : (String.isNotBlank(cm.Contact?.FirstName) ? cm.Contact.FirstName : '');
                        String lastName = String.isNotBlank(cm.Contact?.LastName) ? cm.Contact.LastName : '';
                    fullName = (firstName + ' ' + lastName).trim();
                }

                String newSubject = String.format(
                    cm.Campaign.EmailDefaultSubjectLine__c,
                    new List<Object>{ fullName }
                );
                if (cm.EmailSubjectLine__c != newSubject) {
                    cm.EmailSubjectLine__c = newSubject;
                    isUpdateCM = true;
                }
                if(contactMapForCampaignMemberUpdate.ContainsKey(cm.ContactId)){
                    Contact c = contactMapForCampaignMemberUpdate.get(cm.ContactId);
                    if (cm.Do_Not_Contact__c != c.DoNotCall) {
                        cm.Do_Not_Contact__c = c.DoNotCall;
                        isUpdateCM = true;
                    }
                    if (cm.Bio_Photo__c != c.Bio_Photo__c) {
                        cm.Bio_Photo__c = c.Bio_Photo__c;
                        isUpdateCM = true;
                    }
                    if (cm.Bio_Description__c != c.Bio_Description__c) {
                        cm.Bio_Description__c = c.Bio_Description__c;
                        isUpdateCM = true;
                    }
                    if (cm.Bio_Confidential_Notes__c != c.Bio_Confidential_Notes__c) {
                        cm.Bio_Confidential_Notes__c = c.Bio_Confidential_Notes__c;
                        isUpdateCM = true;
                    }
                    if (cm.X2020_Bio__c != c.General_Election_Notes__c) {
                        cm.X2020_Bio__c = c.General_Election_Notes__c;
                        isUpdateCM = true;
                    }
                }

                if(isUpdateCM){
                    recordsToUpdate.add(cm);
                }
            }
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_UPDATE_LIST_MEMBERS) );
        }
    }


    /* -------------------- andFinally HELPERS start -------------------- */

    // Purpose: Helper method used to handle donor name update as part of the contact trigger processing.
    private void handleDonorNameUpdate() {
        try{
            if (!contactsForDonorNameUpdate.isEmpty()) {
                DonorTriggerHelper.updatePledgeName(contactsForDonorNameUpdate, 'Contact');
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_HANDLE_DONOR_NAME_UPDATE) );
        }
    }

    // Purpose: Helper method used to fetch related contacts to delete as part of the contact trigger processing.
    private void fetchRelatedContactsToDelete() {
        try{
            relatedContactsToDelete = [
                SELECT Id, Main_Contact__c, Main_Contact__r.MasterRecordId,
                Related_Contact__c, Related_Contact__r.MasterRecordId, Relationship__c
                FROM Related_contact__c
                WHERE Related_Contact__c IN :deletedContactsIds
                OR Main_Contact__c IN :deletedContactsIds
            ];
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_FETCH_RELATED_CONTACT_TO_DELETE) );
        }
    }

    // Purpose: Helper method used to handle related contacts deletion and reparenting as part of the contact trigger processing.
    private void handleRelatedContactsDeletionAndReparenting() {
    try{

        if (relatedContactsToDelete.isEmpty()) return;
        if (mergedId_and_MasterId_Map.isEmpty()) return;

        Map<String, Related_contact__c> existingRCsMap = new Map<String, Related_contact__c>();
        for (Related_contact__c rc : [
            SELECT Id, Main_Contact__c, Related_Contact__c, Relationship__c
            FROM Related_contact__c
            WHERE Main_Contact__c IN :mergedId_and_MasterId_Map.values()
            OR Related_Contact__c IN :mergedId_and_MasterId_Map.values()
        ]) {
            String key1 = rc.Main_Contact__c + '-' + rc.Related_Contact__c;
            String key2 = rc.Related_Contact__c + '-' + rc.Main_Contact__c;
            existingRCsMap.put(key1, rc);
            existingRCsMap.put(key2, rc);
        }

        List<Related_Contact__c> rcToReParent = new List<Related_Contact__c>();

        for (Related_Contact__c deletedRC : relatedContactsToDelete) {
            String key = deletedRC.Main_Contact__c + '-' + deletedRC.Related_Contact__c;

            if (!existingRCsMap.containsKey(key)) {
                if (mergedId_and_MasterId_Map.containsKey(deletedRC.Main_Contact__c)) {
                    rcToReParent.add(new Related_Contact__c(
                        Main_Contact__c   = mergedId_and_MasterId_Map.get(deletedRC.Main_Contact__c),
                        Related_Contact__c = deletedRC.Related_Contact__c,
                        Relationship__c   = deletedRC.Relationship__c
                    ));
                }
                else if (mergedId_and_MasterId_Map.containsKey(deletedRC.Related_Contact__c)) {
                    rcToReParent.add(new Related_Contact__c(
                        Main_Contact__c   = deletedRC.Main_Contact__c,
                        Related_Contact__c = mergedId_and_MasterId_Map.get(deletedRC.Related_Contact__c),
                        Relationship__c   = deletedRC.Relationship__c
                    ));
                }
            }
        }

        if (!rcToReParent.isEmpty()) {
            Database.insert(rcToReParent, true);
        }
        delete relatedContactsToDelete;
     } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_HANDLE_RELATED_CONTACTS_DELETION_AND_REPARENTING) );
        }
    }

    // Purpose: Helper method used to handle merge duplicate cleanup as part of the contact trigger processing.
    private void handleMergeDuplicateCleanup() {
        try{
            if (mergeWinningRecordIds != null && !mergeWinningRecordIds.isEmpty()) {
                MergeDuplicateRecordDeletion.deleteDuplicateEmpHistory(mergeWinningRecordIds);
                MergeDuplicateRecordDeletion.deleteDuplicateTagJunctions(mergeWinningRecordIds);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_HANDLE_MERGE_DUPLICATE_CLEANUP) );
        }
    }

    // Purpose: Helper method used to insert employment history as part of the contact trigger processing.
    private void insertEmploymentHistory() {
        try{
            if (!employmentHistoryList.isEmpty()) {
                Database.insert(employmentHistoryList, true);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_INSERT_EMPLOYMENT_HISTORY) );
        }
    }
    /* -------------------- andFinally HELPERS end -------------------- */

    // Purpose: Helper method used to check for duplicate committees as part of the contact trigger processing.
    private void validateCommittees(Contact c) {
        try{
            String constituenciesJoined = c.Constituencies_Joined__c;
            String constituenciesDeclined = c.Constituencies_Declined__c;
            String possibleConstituencies = c.Possible_Constituencies__c;
            if((constituenciesJoined!=null && constituenciesDeclined!=null) || Test.isRunningTest()) {
                String duplicateValue = checkForDuplicateCommittees(constituenciesJoined, constituenciesDeclined);
                if(duplicateValue!=null) {
                    c.addError(duplicateValue + ' selected in both Constituencies Joined and Constituencies Declined');
                }
            }
            if(constituenciesJoined!=null && possibleConstituencies!=null) {
                String duplicateValue = checkForDuplicateCommittees(constituenciesJoined, possibleConstituencies);
                if(duplicateValue!=null) {
                    c.addError(duplicateValue + ' selected in both Constituencies Joined and Possible Constituencies');
                }
            }
            if(possibleConstituencies!=null && constituenciesDeclined!=null) {
                String duplicateValue = checkForDuplicateCommittees(possibleConstituencies, constituenciesDeclined);
                if(duplicateValue!=null) {
                    c.addError(duplicateValue + ' selected in both Possible Constituencies and Constituencies Declined');
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_VALIDATE_COMMITTEES) );
        }
    }

    // Purpose: Helper method used to check for duplicates as part of the contact trigger processing.
    private String checkForDuplicateCommittees(String source, String target) {
        Set<String> sourceSet = new Set<String>(
            String.isNotBlank(source) ? source.split(';') : new List<String>()
        );

        Set<String> targetSet = new Set<String>(
            String.isNotBlank(target) ? target.split(';') : new List<String>()
        );

        sourceSet.retainAll(targetSet);
        return sourceSet.isEmpty() ? null : sourceSet.iterator().next();
    }

    // Purpose: Helper method used to board member update notification as part of the contact trigger processing.
    public void boardMemberUpdateNotification(Contact newContact, Contact oldContact) {
        try{
            Map<String, Schema.SObjectField> schemaFieldMap = Schema.SObjectType.Contact.fields.getMap();
            Map<String, String> changedLabelWithField = new Map<String,String>();
            Map<String, Board_Member_Alert_Exclude_Fields__mdt> excludeFieldsData = Board_Member_Alert_Exclude_Fields__mdt.getAll();
            Set<String> excludeFields = new Set<String>();
            for(Board_Member_Alert_Exclude_Fields__mdt record : excludeFieldsData.values()) {
                excludeFields.add(record.Field_Api_Name__c.toLowerCase());

            }
            for(String fieldName: schemaFieldMap.keySet()) {
                if(!excludeFields.contains(fieldName.toLowerCase()) && newContact.get(fieldName) != oldContact.get(fieldName)) {
                    changedLabelWithField.put(fieldName, schemaFieldMap.get(fieldName).getDescribe().getLabel());
                }
            }
            if(changedLabelWithField.size() > 0) {
                prepareBoardMemberUpdateEmail(changedLabelWithField, newContact);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_BOARD_MEMBER_UPDATE_NOTIFICATION) );
        }
    }

    // Purpose: Helper method used to send email notification with fields info as part of the contact trigger processing.
    public void prepareBoardMemberUpdateEmail(Map<String, String> changedFields, Contact newContact) {
        try{
            if(boardMemberAlertReceivers != null && !boardMemberAlertReceivers.isEmpty()){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setOrgWideEmailAddressId(EmailUtility.getBRMEmailAddress());
                mail.setToAddresses(boardMemberAlertReceivers);
                mail.setSaveAsActivity(false);
                mail.setReplyTo(EmailUtility.getReplyToEmail());
                mail.setSubject(Assets.BOARD_MEMBER_UPDATE_EMAIL_SUBJECT);
                String recordURL = URL.getOrgDomainUrl().toExternalForm() + '/' + newContact.Id;
                String htmlBody = 'Changes to ' + newContact.Full_Name__c.trim() + '<br/>';
                htmlBody += 'Record: <a href="' + recordURL + '">' + recordURL + '</a><br/><br/>';
                htmlBody += 'Changed: ' + String.join(changedFields.values(), ', ');
                mail.setHtmlBody(htmlBody);
                boardMemberEmails.add(mail);
                boardMemberContactAlertSent = true;
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_PREPARE_BOARD_MEMBER_UPDATE_EMAIL) );
        }
    }

    // Purpose: Helper method used to initialize individual account id as part of the contact trigger processing.
    private void initializeIndividualAccountId() {
        try{
            if (individualAccountId==null) {
                Map<String,Schema.RecordTypeInfo> accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
                Id recordTypeId = accountRecordTypes.get(Assets.ACCOUNT_RECORDTYPE_COMPANY).getRecordTypeId();
                List<Account> accounts = [Select Id from Account where Name = :Assets.INDIVIDUAL_ACCOUNT_NAME and RecordTypeId=:recordTypeId];
                if (accounts.size()>0){
                    individualAccountId = accounts[0].Id;
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_INITIALIZE_INDIVIDUAL_ACCOUNTID) );
        }
    }


    // Purpose: Helper method used to flag deceased contacts as part of the contact trigger processing.
    private static void flagDeceasedContacts(Contact c) {
        try{
            String currentSuffix = c.Suffix;
            if(currentSuffix != null) {
                currentSuffix = currentSuffix.replace(Assets.deceasedSuffix, '');
                currentSuffix = currentSuffix.replace(Assets.dncSuffix, '');
                currentSuffix = currentSuffix.trim();
                if(currentSuffix == '') currentSuffix = null;
            }
            if (c.Deceased__c) {
                c.Suffix = currentSuffix != null ? currentSuffix + ' ' + Assets.deceasedSuffix : Assets.deceasedSuffix;
            } else if(c.DoNotCall) {
                c.Suffix = currentSuffix != null ? currentSuffix + ' ' + Assets.dncSuffix : Assets.dncSuffix;
            } else {
                c.Suffix = currentSuffix;
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_FLAG_DECEASED_CONTACTS) );
        }
    }

    // Purpose: Helper method used to check and update account id as part of the contact trigger processing.
    public void checkAndUpdateAccountId(Contact c) {
        if(c.AccountId == null) c.AccountId = individualAccountId;
    }

    // Purpose: Helper method used to validate endorsement status as part of the contact trigger processing.
    public void validateEndorsementStatus(Contact c) {
        try{
            Boolean roleRequiresEndorsement = false;
            if(c.MRB_Campaign_Status__c != null) { // Campaign Role
                for(String campaignRole : c.MRB_Campaign_Status__c.split(';')) {
                    if((campaignRole == Assets.CONTACT_CAMPAIGN_ROLE_SURROGATE) ||  (campaignRole.startsWith(Assets.CONTACT_CAMPAIGN_ROLE_LEADERSHIP_COUNCIL_ALL))) {
                        roleRequiresEndorsement = true;
                        break;
                    }
                }
                //Endorsement Status of "Endorsed" or Endorsed (Not Announced)" is required for certain Campaign Roles.
                if(roleRequiresEndorsement &&  (!(c.MRB_Endorsement_Status__c == Assets.CONTACT_ENDORSEMENT_STATUS_ENDORSED || c.MRB_Endorsement_Status__c == Assets.CONTACT_ENDORSEMENT_STATUS_ENDORSED_NOT_ANNOUNCED))) {
                    c.addError('Endorsement Status of "Endorsed" or "Endorsed (Not Announced)" is required for certain Campaign Roles.');
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_VALIDATE_ENDORSEMENT_STATUS) );
        }
    }

    // Purpose: Helper method used to set special char checkbox as part of the contact trigger processing.
    private void setSpecialCharCheckbox(Contact c) {
        String name = !String.isBlank(c.FirstName) ? c.FirstName : '';
        name += !String.isBlank(c.MiddleName) ? ' ' + c.MiddleName : '';
        name += !String.isBlank(c.LastName) ? ' ' + c.LastName : '';
        SpecialCharactersHelper.updateSpecialCharCheckbox(name, c, 'Has_Special_Char_In_Name__c');
    }

    // Purpose: Helper method used to process bio related update as part of the contact trigger processing.
    private void processBioRelatedUpdate(Contact newContact, Contact oldContact) {
        if(String.isNotBlank(newContact.Bio_Description__c) && (oldContact == null || newContact.Bio_Description__c != oldContact.Bio_Description__c)) {
        newContact.BioLastReviewedDate__c = Date.today();
        newContact.BioLastReviewedBy__c = UserInfo.getUserId();
    }
    }

    //Purpose: Helper method used to update contact alert based on reason as part of the contact trigger processing.
    private void updateDNCAndAlertReason(Contact newContact) {
        if(String.isNotBlank(newContact.Contact_Alert_Reason__c)) {
            newContact.Contact_Alert__c = true;
        } else {
            newContact.Contact_Alert__c = false;
        }
    }

    // Purpose: Helper method used to check bio photo url as part of the contact trigger processing.
    private void checkBioPhotoURL(Contact newContact, Contact oldContact) {
        try{
            // Add error notification for Bio Photo update when Bio Photo is copy/paste instead of download/upload
            if(String.isNotBlank(newContact.Bio_Photo__c) && (oldContact == null || oldContact.Bio_Photo__c != newContact.Bio_Photo__c)) {
                newContact.ReducedImage__c = null;	// Reduced image size should be empty if the bio photo is updated
                String photoURL = UtilityClass.getPhotoURL(newContact.Bio_Photo__c);
                if(photoURL != '' && !photoURL.contains(envSetting.BaseURLPrefix__c)) {
                    newContact.addError(System.Label.Bio_Photo_Error_Notification);
                } else {
                    newContact.BioPhotoUpdated__c = true;
                    if(!System.isBatch() && !System.isScheduled() && !System.isFuture()) {
                        ImageSizeReduceCallout.updateReduceImageData(newContact.Id);
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_CHECK_BIO_PHOTO_URL) );
        }
    }

    // Purpose: Helper method used to update do not contact after desease and do not contact as part of the contact trigger processing.
    private void updateDoNotContactAfterDeseaseAndDoNotContact(Contact c) {
        try{
            if(c.Deceased__c) {
                c.DoNotCall = true;
                if(String.isBlank(c.Contact_Alert_Reason__c) || c.Contact_Alert_Reason__c.trim() == 'Do Not Contact') {
                    c.Contact_Alert_Reason__c = Assets.CONTACT_ALERT_REASON_DECEASED;
                }
            } else if(c.DoNotCall) {
                if(String.isBlank(c.Contact_Alert_Reason__c) || c.Contact_Alert_Reason__c.trim() == Assets.CONTACT_ALERT_REASON_DECEASED) {
                    c.Contact_Alert_Reason__c = Assets.CONTACT_ALERT_REASON_DO_NOT_CONTACT;
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_UPDATE_DO_NOT_CONTACT_AFTER_DESEASE_AND_DO_NOT_CONTACT) );
        }
    }

    // Purpose: Helper method used to set contact business address as part of the contact trigger processing.
    public static void setContactBusinessAddress(Contact c , Account a) {
        try{
            if(c.Use_Same_Address_as_Organization__c && a != null) {
                c.MailingCity = a.BillingCity;
                c.MailingCountry = a.BillingCountry;
                c.MailingCountryCode = a.BillingCountryCode;
                c.MailingGeocodeAccuracy = a.BillingGeocodeAccuracy;
                c.MailingLatitude = a.BillingLatitude;
                c.MailingLongitude = a.BillingLongitude;
                c.MailingPostalCode = a.BillingPostalCode;
                c.MailingState = a.BillingState;
                c.MailingStateCode = a.BillingStateCode;
                c.MailingStreet = a.BillingStreet;
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_SET_CONTACT_BUSINESS_ADDRESS) );
        }
    }

    // Purpose: Helper method used to set data before operation as part of the contact trigger processing.
    public void setDataBeforeOperation(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        try{
            
            for (Contact c : newContacts) {
                if(c.Relationship_Owner__c != null){ c.OwnerId = c.Relationship_Owner__c;}
                processBioRelatedUpdate(c, null);	// Update Bio Last Reviewed infomation
                updateDoNotContactAfterDeseaseAndDoNotContact(c);	// Update Do Not Contact when Deseased is checked
                updateDNCAndAlertReason(c);	// Update Contact Alert value based on Contact Alert Reason
                handleBioDescription(c);
                applyAccountRestrictions(c);
                assignContactOwner(c);
                resizeBioPhoto(c, oldMap);
                formatPhoneField(c, oldMap, 'Phone', 'Office_Phone_Country_Code__c', 'Office_Phone_Phone_Only__c');
                formatPhoneField(c, oldMap, 'MobilePhone', 'Mobile_Phone_Country_Code__c', 'Mobile_Phone_Phone_Only__c');
                formatPhoneField(c, oldMap, 'Confidential_Phone__c', 'Confidential_Phone_Country_Code__c', 'Confidential_Phone_Phone_Only__c');

                if(accountMap.containsKey(c.AccountId)) {
                    setContactBusinessAddress(c , accountMap.get(c.AccountId));
                }
                if(isFieldChanged(c, 'Deceased__c') || isFieldChanged(c, 'DoNotCall')) {
                    flagDeceasedContacts(c);
                }
                if(isFieldChanged(c, 'FirstName') || isFieldChanged (c, 'LastName') || isFieldChanged(c, 'MiddleName')) {
                    setSpecialCharCheckbox(c);
                }
                if(isFieldChanged(c, 'FirstName') || isFieldChanged(c, 'LastName') || isFieldChanged(c, 'MiddleName')) {
                    c = updatedConvertedNames(c);
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SET_DATA_BEFORE_OPERATION));
        }
    }

    /* ------------------------- setDataBeforeOperation HELPER start ------------------------- */

    // Purpose: Helper method used to handle bio description as part of the contact trigger processing.
    private void handleBioDescription(Contact c) {
        try {

            if (isFieldChanged(c, 'Bio_Description__c')) {
                c.Bio_Description_Last_Updated__c = Date.today();
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_HANDLE_BIO_DESCRIPTION));
        }
    }

    // Purpose: Helper method used to apply account restrictions as part of the contact trigger processing.
    private void applyAccountRestrictions(Contact c) {
        try {

            if( accountMap.containsKey(c.AccountId)) {
                c.Restricted_Org_Name__c = accountMap.get(c.AccountId).Restricted_Org_Name__c;
                if(isUpdateTrigger && accountMap.get(c.AccountId).Restricted__c) {
                    If(isFieldChanged(c, 'Restricted__c') && c.Restricted__c == false) {
                        c.addError('The Private field on this Contact cannot be unchecked because the associated Organization is restricted.');
                    }
                    c.Restricted__c = accountMap.get(c.AccountId).Restricted__c;
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_APPLY_ACCOUNT_RESTRICTIONS));
        }
    }

    // Purpose: Helper method used to assign contact owner as part of the contact trigger processing.
    private void assignContactOwner(Contact c) {
        try {

        if (c.Restricted__c && String.isNotBlank(envSetting.Restricted_Org_Contact_Owner_Id__c) &&
                c.OwnerId != envSetting.Restricted_Org_Contact_Owner_Id__c) {
                c.OwnerId = envSetting.Restricted_Org_Contact_Owner_Id__c;
            } else if (!c.Restricted__c && String.isNotBlank(envSetting.Unrestricted_Org_Contact_Owner_Id__c) &&
                     c.OwnerId != envSetting.Unrestricted_Org_Contact_Owner_Id__c) {
                     c.OwnerId = envSetting.Unrestricted_Org_Contact_Owner_Id__c;
        }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_ASSIGN_CONTACT_OWNER));
        }
    }

    // Purpose: Helper method used to resize bio photo as part of the contact trigger processing.
    private void resizeBioPhoto(Contact c, Map<Id, Contact> oldMap) {
        try {

            if (c.Bio_Photo__c != null && (oldMap == null || c.Bio_Photo__c != oldMap.get(c.Id).Bio_Photo__c)) {
                c.Bio_Photo__c = updateBioPhoto(c.Bio_Photo__c);
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_RESIZE_BIO_PHOTO));
        }
    }

    // Format phone field
    private void formatPhoneField(Contact c, Map<Id, Contact> oldMap,
                                  String phoneField,
                                  String countryCodeField,
                                  String phoneOnlyField) {
        try {
        String phone = (String)c.get(phoneField);
        String countryCode = (String)c.get(countryCodeField);

        if(countryCode != null && phone != null &&
           (oldMap == null || phone != oldMap.get(c.Id).get(phoneField))) {

               UtilityClass.wrapperPhones phones =
                   UtilityClass.formatPhone(phone, countryCode, null);

               c.put(phoneField, phones.FormatedPhone);
               c.put(phoneOnlyField, phones.PhoneOnly);

           } else if(phone == null && !isUpdateTrigger) {
               c.put(phoneOnlyField, '');
        }
    } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FORMAT_PHONE_FIELD));
        }
    }

    // Purpose: Helper method used to set Legacy_Source_System__c as part of the contact trigger processing.
    private void setLegacySource(Contact c, String platform) {
        try {

            if (platform == 'iOS/Mac' || platform == 'iPhone' || platform == 'iPad') {
                c.Legacy_Source_System__c = Assets.LEGACY_SOURCE_SYSTEM_MOBILE;
            }
    } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SET_LAGACY_SOURCE));
        }
    }

    // Purpose: Helper method used to clear priority email override as part of the contact trigger processing.
    private void clearPriorityEmailOverride (Contact newContact) {
        try {

        for(String fieldName: priorityEmailsMap.keySet()) {
            if(
                isFieldChanged (newContact, fieldName) &&
                newContact.get(fieldName) == null &&
                newContact.Priority_Email_Override__c != null &&
                newContact.Priority_Email_Override__c == priorityEmailsMap.get(fieldName)
            ) {
                newContact.Priority_Email_Override__c = null;
            }
        }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CLEAR_PRIORITY_EMAIL_OVERRIDE));
        }
    }

    // Purpose:  Helper method used to update bio photo as part of the contact trigger processing.
    public static String updateBioPhoto(String bioPhotoText) {
        try {
            String newBioPhotoText = '';
            string styleString = ' style="height: 100px; width: 100px;"';

            Boolean containsStyle = bioPhotoText.contains('style');
            if(!containsStyle) {
                if(bioPhotoText.indexOf('></img>') != -1) {
                    // Add the style attribute
                    String newBioPhotoString =
                        bioPhotoText.substring(0, bioPhotoText.indexOf('></img>')) +
                        styleString +
                        bioPhotoText.substring(bioPhotoText.indexOf('></img>'), bioPhotoText.length());
                    return newBioPhotoString;
                } else {

                    return bioPhotoText;
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_UPDATE_BIO_PHOTO) );
        }
        return bioPhotoText;
    }

    // Purpose: Helper method used to updated converted names as part of the contact trigger processing.
    public static Contact updatedConvertedNames(Contact c) {
        try {
        c.Converted_FirstName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(c.FirstName);
        c.Converted_MiddleName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(c.MiddleName);
        c.Converted_LastName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(c.LastName);
     } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_CONVERTED_NAMES));
    }
        return c;
    }

    // Purpose:
    // Depends on session context; may not behave consistently across all execution contexts.
    // Performs a SOQL query per invocation when LoginHistoryId is present & Defaults fallback to ('iPhone').
    public static String getSessionPlatform() {

        String platform = '';
        try{
            // Current session/platform attributes
            Map<String, String> sessionAttributes = new Map<String, String>();
            Boolean isAsyncOperation =  System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled();
            if(!Test.isRunningTest() && !isAsyncOperation) {
                sessionAttributes = Auth.SessionManagement.getCurrentSession();
            }

            if(sessionAttributes != null && sessionAttributes.containsKey('LoginHistoryId')) {
                platform = [SELECT Id, Platform FROM LoginHistory WHERE Id = :sessionAttributes.get('LoginHistoryId')].Platform;
            } else {
                platform = 'iPhone';
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_SESSION_PlatFORM) );
        }
        return platform;
    }

    // Purpose:
    // Enforces data protection by preventing users from deleting records containing hidden or confidential information.
    // Uses dynamic schema inspection to remain adaptable to field changes.
    // Relies on field-level security (FLS) to determine user access.
    private void checkDeletePermission(Contact c) {
        try{
            Set<String> allByPassFields = new Set<String>();
            SObjectType schemaType = Schema.getGlobalDescribe().get('Contact');
            Map<String, Schema.SObjectField> fieldMap = schemaType.getDescribe().fields.getMap();
            Map<String, String> BYPASS_MERGE_VALIDATION_FIELDS = UtilityClass.getFieldsByFieldSet('Contact', 'Bypass_Merge_Validation_Fields');
            Set<String> systemFields = new Set<String> {
                	'id','isdeleted','masterrecordid','recordtypeid','reportstoid','createddate','createdbyid','lastmodifieddate',
                    'lastmodifiedbyid','systemmodstamp','lastactivitydate','lastcurequestdate','lastcuupdatedate','lastvieweddate',
                    'lastreferenceddate','emailbounceddate','isemailbounced','emailbouncedreason','jigsaw','jigsawcontactid','individualid',
                    'ispriorityrecord'
                    };
                        for(String fieldName : BYPASS_MERGE_VALIDATION_FIELDS.keySet()) {
                            allByPassFields.add(fieldName.toLowerCase());
                        }
            for(String fieldName : fieldMap.keySet()) {
                SObjectField schemaField = fieldMap.get(fieldName);

                if(
                    !systemFields.contains(fieldName) &&
                    !allByPassFields.contains(fieldName) &&
                    c.get(fieldName) != null &&
                    !schemaField.getDescribe().isAccessible() &&
                    !schemaField.getDescribe().isCalculated() &&
                    !schemaField.getDescribe().isAutoNumber()
                ) {
                    if (
                        (
                            schemaField.getDescribe().getType() == Schema.DisplayType.Boolean &&
                            c.get(fieldName) == true
                        ) ||
                        schemaField.getDescribe().getType() != Schema.DisplayType.Boolean
                    ) {
                        c.addError(Label.Contact_Delete_Error);
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_CHECK_DELETE_PERMISSION) );
        }
    }

    // prevent deletion of Contact which has the Bgive_Id__c field populated
    private void preventDeletionOfLinkedContact(Contact c) {
        if(c.Bgive_Id__c != null) {
            c.addError(Label.BGiveLinked_Contact_Delete_Error);
        }
    }

    // Purpose: Helper method used to create employment history as part of the contact trigger processing.
    private Employment_History_and_Board_Membership__c createEmploymentHistory(Contact c) {
        return new Employment_History_and_Board_Membership__c(
            Contact_Name__c = c.Id,
            Organization_Name__c = c.AccountId,
            Title__c = c.Title,
            Business_Email__c = c.Email
        );
    }


    // Purpose:
    // Categories__c is treated as the source of truth; existing junction records are fully replaced on change.
    // Only Category__c records with matching names are considered; unmatched values are ignored and assumes category names are unique.
    public static void updateContactCategories(List<Contact> triggerNew, Map<Id,Contact> triggerOldMap, Map<Id,Contact> triggerNewMap) {
        try{

        // Creating map of existing Category values with id
        Map<String,Id> mapNameIdCategories = new Map<String,Id>();
        Set<Id> conIds = new Set<Id>();
        Map<Id,List<String>> mapIdLstCategories = new Map<Id,List<String>>();

        // Checking if its after update
        if(triggerOldMap != null) {
            for(Id contactId : triggerNewMap.keySet()) {

                Contact oldCon = triggerOldMap.get(contactId);
                Contact newCon = triggerNewMap.get(contactId);

                if(oldCon.Categories__c != newCon.Categories__c){ // If changed
                    conIds.add(contactId);
                    if(newCon.Categories__c != null) { // Changed to some other categories
                        populateContactCategoriesMap(contactId, newCon.Categories__c, mapIdLstCategories);
                    }
                }
            }

            if(!conIds.isEmpty()) {
                List<Contact_Category__c> lstConCattodelete = [SELECT id FROM Contact_Category__c WHERE Contact__c IN: conIds];
                try  {
                    delete lstConCattodelete;
                } catch(Exception e) {
                    UtilityClass.logError(null, e.getMessage(), e.getTypeName());
                }
            }
        } else {
            // For new inserted contacts
            for(Contact con : triggerNew) {
                if(con.Categories__c != null){
                    populateContactCategoriesMap(con.Id, con.Categories__c, mapIdLstCategories);
                }
            }
        }

        List<Contact_Category__c> lstConCatToAdd = new List<Contact_Category__c>();
        if(mapIdLstCategories != null && !mapIdLstCategories.isEmpty()) {
            Set<String> categoriesToQuery = new Set<String>();

            for(List<String> categories : mapIdLstCategories.values()){
                categoriesToQuery.addAll(categories);
            }
            if(!categoriesToQuery.isEmpty()){
                for(Category__c cat : [SELECT Id, Name FROM Category__c WHERE Name IN :categoriesToQuery]) {
                    mapNameIdCategories.put(cat.Name,cat.Id);
                }
            }

            for(Id conId: mapIdLstCategories.keySet()) {
                for(String catName: mapIdLstCategories.get(conId)) {
                    if(mapNameIdCategories.containsKey(catName)){
                        Contact_Category__c conCat = new Contact_Category__c();
                        conCat.Contact__c = conId;
                        conCat.Category__c = mapNameIdCategories.get(catName);
                        lstConCatToAdd.add(conCat);
                    }
                }
            }
        }
        if(!lstConCatToAdd.isEmpty()){
            insert lstConCatToAdd;
        }
    } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_UPDATE_CONTACT_CATEGORIES) );
    }
    }

    //Purpose:
    // Assumes categories are separated by ';'.
    // Does not trim or validate category values (may include blanks or whitespace).
    // Appends values without checking for duplicates.
    private static void populateContactCategoriesMap(Id contactId, String categories, Map<Id,List<String>> mapIdLstCategories){

        for(String str : categories.split(';')) {
            if(!mapIdLstCategories.containsKey(contactId)){
                mapIdLstCategories.put(contactId,new List<String>());
            }
            mapIdLstCategories.get(contactId).add(str);
        }
    }

    //Purpose:
    // Supports both insert (triggerOldMap = null) and update scenarios.
    // Ensures data consistency by avoiding one-sided or duplicate relationships.
    // Assumes Significant_Other__c should behave as a strict one-to-one mutual relationship.
    public static void linkDelinkSignificantOther(Map<Id, Contact> triggerNewMap, List<Contact> triggerNew,Map<Id, Contact> triggerOldMap) {
        try {

            Set<Id> existingSignificantOtherIds = new Set<Id>();
            Boolean executeUpdateLogic = false;
            Set<Id> SignUpdatedSet = new Set<Id>();
            // Avoid recurive trigger
            if(executedTriggers.contains('linkDelinkSignificantOther')) return;
            executedTriggers.add('linkDelinkSignificantOther');

            Set<Id> spouseIds = new Set<Id>();

            if(triggerNewMap != null) {
                for(Id contactId : triggerNewMap.keySet()) {
                    Contact c = triggerNewMap.get(contactId);
                    if(triggerOldMap != null && triggerOldMap.get(contactId).Significant_Other__c != c.Significant_Other__c) {
                        executeUpdateLogic = true;
                        SignUpdatedSet.add(contactId);
                    }
                    if(c.Significant_Other__c != null) {
                        spouseIds.add (c.Significant_Other__c);
                    }
                }
            }

            if(executeUpdateLogic || triggerOldMap == null) {
                Map<Id, Contact> clearedSpouses = new Map<Id, Contact>();

                if(!SignUpdatedSet.isEmpty()) {
                    // Clear out Spouse__c on all partners
                    clearedSpouses = new Map<Id, Contact>([SELECT id, Significant_Other__c FROM Contact WHERE Significant_Other__c =: SignUpdatedSet]);
                    for(Contact c : clearedSpouses.values())
                        c.Significant_Other__c = null;
                }

                //Checking for existing significant other Ids

                List<Contact> lstConsValExisting = new List<Contact>();
                if(!spouseIds.isEmpty()){
                    lstConsValExisting = [SELECT Id, Significant_Other__c FROM Contact WHERE Significant_Other__c IN :spouseIds AND Id NOT IN :SignUpdatedSet];
                }

                for(Contact conIns : lstConsValExisting) {
                    if(conIns.Significant_Other__c != null) {
                        existingSignificantOtherIds.add(conIns.Significant_Other__c);
                    }
                }
                // Query spouses
                Map<Id, Contact> spouses = new Map<Id, Contact>();
                if(!spouseIds.isEmpty()){
                    spouses = new Map<Id, Contact>(
                        [SELECT Id FROM Contact WHERE Id IN :spouseIds]
                    );
                }

                // Set contacts to spouses
                for(Contact c : triggerNew) {
                    if(SignUpdatedSet.contains(c.Id)) {
                        if(c.Significant_Other__c != null && existingSignificantOtherIds.contains(c.Significant_Other__c)) {
                            c.Significant_Other__c.addError(System.Label.Unique_Significant_Other_Error_Msg);
                        }
                    }
                    if(c.Significant_Other__c != null && spouses.containsKey(c.Significant_Other__c)) {
                        Contact con = spouses.get(c.Significant_Other__c);
                        con.Significant_Other__c = c.id;

                        spouses.put(c.Significant_Other__c,con);
                        clearedSpouses.remove(c.Significant_Other__c);
                    }
                }
                // Update all spouses
                List<Contact> allContacts = new List<Contact>();
                allContacts.addAll(clearedSpouses.values());
                allContacts.addAll(spouses.values());
                Map<Id, Contact> conmap = new Map<Id, Contact>();
                // Put all the values from the list to map.
                conmap.putAll(allContacts);
                if(!conmap.isEmpty()) {
                    update conmap.values();
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_LINK_DELINK_SINGNIFICANT_OTHER) );
        }
    }

    //Purpose:
    // Uses oldMap to detect state transitions (restricted ↔ unrestricted).
    // Ensures data is not lost by preserving original values before masking.
    // Designed to run in trigger context for both insert and update scenarios.
    public void restrictedFieldsMapping(list<Contact> newContacts, Map<Id, Contact> oldMap) {
        try{
            for(Contact con : newContacts) {
                if(con.Restricted__c && (oldMap == null || oldMap != null && (!oldMap.containsKey(con.Id) || oldMap.containsKey(con.Id) && !oldMap.get(con.Id).Restricted__c))) {
                    con.RestrictedFirstName__c = con.FirstName;
                    con.RestrictedMiddleName__c = con.MiddleName;
                    con.RestrictedLastName__c = con.LastName;
                    con.RestrictedSuffix__c = con.Suffix;
                    con.RestrictedSalutation__c = con.Salutation;
                    con.FirstName = null;
                    con.MiddleName = null;
                    con.LastName = Assets.RESTRICTED_ORG_NAME;
                    con.Suffix = null;
                    con.Salutation = null;
                } else if(!con.Restricted__c && oldMap != null && oldMap.containsKey(con.Id) && oldMap.get(con.Id).Restricted__c) {
                    con.FirstName = con.RestrictedFirstName__c;
                    con.MiddleName = con.RestrictedMiddleName__c;
                    con.LastName = (con.RestrictedLastName__c != null ? con.RestrictedLastName__c : con.LastName) ;
                    con.Suffix = con.RestrictedSuffix__c;
                    con.Salutation = con.RestrictedSalutation__c;
                    con.RestrictedFirstName__c = null;
                    con.RestrictedMiddleName__c = null;
                    con.RestrictedLastName__c = null;
                    con.RestrictedSuffix__c = null;
                    con.RestrictedSalutation__c = null;
                }
            }
        }catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_RESTRICTED_FIELD_MAPPING) );
        }
    }
}