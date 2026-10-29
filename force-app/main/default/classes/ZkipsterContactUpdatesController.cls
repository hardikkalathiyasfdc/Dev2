/**
 * Description : Controller to display the pending changes for a synced contacts
 * Author : Nishant Bakhrey
 * Last Modified : 08/03/2026
 * JIRA : BRME-6787
 * Test : ZkipsterContactUpdatesControllerTest
**/
public with sharing class ZkipsterContactUpdatesController {

    private static final String STATUS_PENDING = 'Pending';
    private static final String STATUS_ACCEPTED = 'Accepted';
    private static final String STATUS_REJECTED = 'Rejected';

    private static final String ERR_GET_PENDING_CHANGES = 'ZkipsterContactUpdatesController_getPendingChanges_FAILED';
    private static final String ERR_APPLY_SELECTED_CHANGES = 'ZkipsterContactUpdatesController_applySelectedChanges_FAILED';
    private static final String ERR_REJECT_SELECTED_CHANGES = 'ZkipsterContactUpdatesController_rejectSelectedChanges_FAILED';

    @AuraEnabled(cacheable=true)
    public static List<Zkipster_Contact_Update__c> getPendingChanges(Id campaignId) {
        List<Zkipster_Contact_Update__c> results = new List<Zkipster_Contact_Update__c>();
        try {
            if(campaignId == null) return results;
            for(Zkipster_Contact_Update__c changeRecord : [
                SELECT Id, List__c, Contact__c, Contact__r.Name, Status__c, Guest_Name__c,
                       Field_API_Name__c, Field_Label__c, Current_BRM_Value_Formula__c, Zkipster_Value__c
                FROM Zkipster_Contact_Update__c
                WHERE List__c = :campaignId
                  AND Status__c = :STATUS_PENDING
                  AND Contact__c != null
                  AND Zkipster_Value__c != null
                  AND Zkipster_Value__c != ''
                WITH USER_MODE
                ORDER BY Contact__r.Name, Field_Label__c
            ]) {

                results.add(changeRecord);
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_PENDING_CHANGES));
            throw new AuraHandledException('An error occurred while retrieving the pending changes.');
        }
        return results;
    }

    @AuraEnabled
    public static String applySelectedChanges(List<Id> changeIds) {
        try {
            if(changeIds == null || changeIds.isEmpty()) {
                throw new AuraHandledException('Select at least one change to apply.');
            }
            List<Zkipster_Contact_Update__c> changes = [
                SELECT Id, Contact__c, Field_API_Name__c, Current_BRM_Value_Formula__c, Zkipster_Value__c, Status__c
                FROM Zkipster_Contact_Update__c
                WHERE Id IN :changeIds
                  AND Status__c = :STATUS_PENDING
                  AND Contact__c != null
                WITH USER_MODE
            ];
            if(changes.isEmpty()) {
                throw new AuraHandledException('The selected changes are no longer pending.');
            }
            Set<Id> contactIds = new Set<Id>();
            for(Zkipster_Contact_Update__c changeRecord : changes) {
                contactIds.add(changeRecord.Contact__c);
            }
            Map<Id, Contact> existingContacts = new Map<Id, Contact>([
                SELECT Id, Salutation, FirstName, LastName, Title, MobilePhone, Mobile_Phone_Country_Code__c
                FROM Contact
                WHERE Id IN :contactIds
                WITH USER_MODE
            ]);
            Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
            List<Zkipster_Contact_Update__c> processedChanges = new List<Zkipster_Contact_Update__c>();
            for(Zkipster_Contact_Update__c changeRecord : changes) {
                if(String.isBlank(changeRecord.Zkipster_Value__c)) continue;
                Contact existingContact = existingContacts.get(changeRecord.Contact__c);
                if(existingContact == null) continue;
                Contact contactToUpdate = contactsToUpdate.get(changeRecord.Contact__c);
                if(contactToUpdate == null) {
                    contactToUpdate = new Contact(Id = changeRecord.Contact__c);
                }
                contactToUpdate.put(changeRecord.Field_API_Name__c, changeRecord.Zkipster_Value__c);
                contactsToUpdate.put(contactToUpdate.Id, contactToUpdate);
                changeRecord.Status__c = STATUS_ACCEPTED;
                processedChanges.add(changeRecord);
            }
            validatePhoneCountryCodeChanges(changes, existingContacts, contactsToUpdate);
            if(!contactsToUpdate.isEmpty()) update contactsToUpdate.values();
            if(!processedChanges.isEmpty()) update processedChanges;
            String message = processedChanges.size() +
                (processedChanges.size() == 1
                    ? ' change was applied to '
                    : ' changes were applied to ') +
                contactsToUpdate.size() +
                (contactsToUpdate.size() == 1
                    ? ' Contact.'
                    : ' Contacts.');
            return message;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_APPLY_SELECTED_CHANGES));
            throw new AuraHandledException('An error occurred while applying the selected changes.');
        }
    }

    @AuraEnabled
    public static String rejectSelectedChanges(List<Id> changeIds) {
        try {
            if(changeIds == null || changeIds.isEmpty()) {
                throw new AuraHandledException('Select at least one change to reject.');
            }
            List<Zkipster_Contact_Update__c> changes = [
                SELECT Id, Contact__c, Status__c
                FROM Zkipster_Contact_Update__c
                WHERE Id IN :changeIds
                AND Status__c = :STATUS_PENDING
                WITH USER_MODE
            ];
            Set<Id> contactIds = new Set<Id>();
            for(Zkipster_Contact_Update__c changeRecord : changes) {
                changeRecord.Status__c = STATUS_REJECTED;
                if(changeRecord.Contact__c != null) {
                    contactIds.add(changeRecord.Contact__c);
                }
            }
            if(!changes.isEmpty()) update changes;
            String message = changes.size() + (changes.size() == 1
                            ? ' change was rejected.'
                            : ' changes were rejected.');
            return message;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_REJECT_SELECTED_CHANGES));
            throw new AuraHandledException('An error occurred while rejecting the selected changes.');
        }
    }

    private static void validatePhoneCountryCodeChanges(List<Zkipster_Contact_Update__c> changes, Map<Id, Contact> existingContacts, Map<Id, Contact> contactsToUpdate) {
        Set<Id> mobilePhoneContactIds = new Set<Id>();
        Set<Id> countryCodeContactIds = new Set<Id>();
        for(Zkipster_Contact_Update__c changeRecord : changes) {
            if(changeRecord.Field_API_Name__c == 'MobilePhone') {
                mobilePhoneContactIds.add(changeRecord.Contact__c);
            }
            if(changeRecord.Field_API_Name__c == 'Mobile_Phone_Country_Code__c') {
                countryCodeContactIds.add(changeRecord.Contact__c);
            }
        }
        for(Id contactId : mobilePhoneContactIds) {
            Contact existingContact = existingContacts.get(contactId);
            Contact contactToUpdate = contactsToUpdate.get(contactId);
            String finalCountryCode = contactToUpdate != null && String.isNotBlank(contactToUpdate.Mobile_Phone_Country_Code__c)
                                      ? contactToUpdate.Mobile_Phone_Country_Code__c
                                      : existingContact != null ? existingContact.Mobile_Phone_Country_Code__c : null;
            if(String.isBlank(finalCountryCode) && !countryCodeContactIds.contains(contactId)) {
                throw new AuraHandledException(
                    'Select the Mobile Phone Country Code change when applying the Mobile Phone change.'
                );
            }
        }
    }
}