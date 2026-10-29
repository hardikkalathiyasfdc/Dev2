/**
 * @description       : Class to handle sync to Zkipster from BRM
 * @author            : Ravi Bheemreddy
 * Last Modified      : 03/02/2026
 * JIRA               : BRME-4751, BRME-6463
**/
global without sharing class SyncGuestsToZkipster implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public String query;
    public Id campId;
    public boolean isFailed= false;
    @TestVisible
    private List<Id> failedRecordIds = new List<Id>();
    // Ids to retry, passed in via constructor (input); failures from this run go to failedRecordIds (output)
    List<Id> retryRecordIds = new List<Id>();

    private static final String ERR_EXECUTE = 'SYNC_GUESTS_TO_ZKIPSTER_EXECUTE_FAILED';
    private static final String ERR_FINISH = 'SYNC_GUESTS_TO_ZKIPSTER_FINISH_FAILED';
    private static final String ERR_SEND_EMAIL_ALERTS = 'SYNC_GUESTS_TO_ZKIPSTER_sendEmailAlerts_FAILED';

    global SyncGuestsToZkipster() {
    }

    global SyncGuestsToZkipster(List<Id> retryRecordIds) {
       this.retryRecordIds = retryRecordIds;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(retryRecordIds.size() > 0) {
            String newQuery = 'SELECT Id, CreatedBy.Email, Table__c, Seat__c, Title, Dietary__c,  ' +
                                     'UB_FirstName__c, First_Preferred_First_Name__c, ' +
                                     'Email, SpouseInvited__c, RSVPNotes__c, UB_LastName__c, ' +
                                     'Contact.Full_Name__c, Contact.Account.Name,Guest_Email__c, Contact.CorrespondenceDearLine__c,' +
                                     'RSVPStatus__c, ZkipsterGuestId__c, PartySize__c, Phone, Last_Preferred_Last_Name__c, ' +
                                     'Contact.Significant_Other__r.Full_Name__c, Contact.Salutation, Contact.RestrictedSalutation__c, Contact.FirstName, Contact.LastName, Contact.Preferred_First_Name__c, ' +
                                     'Contact.Restricted__c,Contact.RestrictedFirstName__c,Contact.RestrictedLastName__c,Contact.Account.Restricted_Org_Name__c, ' +
                                     'Campaign.ZkipsterGuestListId__c, Synced_With_Zkipster__c ' +
                             ' FROM CampaignMember ' +
                             ' WHERE Synced_With_Zkipster__c = False ' +
                               ' AND Id IN :retryRecordIds ' +
                               ' AND RSVPStatus__c != \'Waitlist 1\' ' +
                               ' AND RSVPStatus__c != \'Waitlist 2\'';
            return Database.getQueryLocator(newQuery);
        } else {
            return Database.getQueryLocator(query);
        }
    }

    global void execute(Database.BatchableContext BC, list<CampaignMember> scope) {
        try {
            List<CampaignMember> guests = new List<CampaignMember>();
            String guestListId;
            if(campId != null) {
                Campaign camp = [SELECT ZkipsterGuestListId__c FROM Campaign WHERE Id = :campId LIMIT 1];
                guestListId = camp.ZkipsterGuestListId__c;
            }
            // Dedup guard: match blank-id guests against existing zkipster guests by name to avoid re-creating them.
            // getAllZkipsterGuestIdsByName downloads the WHOLE zkipster list (paginated callout), so it is fetched
            // once per chunk — outside the loop — and only when this chunk actually has blank-id guests to dedup.
            Map<String, String> zkipsterGuestIdsByName = new Map<String, String>();
            Boolean hasNewGuests = false;
            for(CampaignMember guest : scope) {
                if(String.isBlank(guest.ZkipsterGuestId__c)) {
                    hasNewGuests = true;
                    break;
                }
            }
            if(hasNewGuests && guestListId != null) {
                zkipsterGuestIdsByName = ZkipsterIntegration.getAllZkipsterGuestIdsByName(guestListId);
            }
            for(CampaignMember guest : scope) {
                if (String.isBlank(guest.ZkipsterGuestId__c)) {
                    matchExistingZkipsterGuest(guest, zkipsterGuestIdsByName);
                }
                try {
                // Create when the guest has no zkipster id yet, otherwise update the existing zkipster guest
                Boolean isNewGuest = String.isBlank(guest.ZkipsterGuestId__c);
                String guestId = isNewGuest
                    ? ZkipsterIntegration.createZkipsterGuest(guest, guestListId)
                    : ZkipsterIntegration.updateZkipsterGuest(guest, guestListId);
                if (String.isNotBlank(guestId) && guestId != 'error') {
                    if (isNewGuest) {
                        // Stamp the newly created zkipster guest id so future syncs update instead of re-create
                        guest.ZkipsterGuestId__c = guestId;
                    }
                    guest.Synced_With_Zkipster__c = true;
                    guests.add(guest);
                } else {
                    if(!isFailed) isFailed = true;
                    failedRecordIds.add(guest.Id);
                }

                } catch(Exception guestEx) {
                    // Isolate per-guest failures (e.g. null PartySize) so one bad guest doesn't abort the whole scope
                    if(!isFailed) isFailed = true;
                    failedRecordIds.add(guest.Id);
                    BBApps_ErrorHandler.logErrors(guestEx, new BBApps_ErrorCustomFields(ERR_EXECUTE));
                }
            }
            if(guests.size() > 0) {
                List<BBApps_DMLResult> saveResults = BBApps_Crud.doUpdateWithHandling(guests, false, ERR_EXECUTE);
                if(saveResults != null) {
                    for(Integer i = 0; i < saveResults.size(); i++) {
                        if(!saveResults[i].isSuccess()) {
                            if(!isFailed) isFailed = true;
                            failedRecordIds.add(guests[i].Id);
                        }
                    }
                }
            }
        } catch(Exception ex) {
            if(!isFailed) isFailed = true;
            for(CampaignMember guest : scope) {
                failedRecordIds.add(guest.Id);
            }
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    /**
     * @description Matches a blank-id guest against the existing zkipster guests by normalized
     *              name and stamps the zkipster guest id when a match is found, so the sync updates
     *              the existing zkipster guest instead of creating a duplicate. Builds the dedup key
     *              from the SAME name fields the payload sends (ZkipsterIntegration), incl. restricted handling.
     */
    private static void matchExistingZkipsterGuest(CampaignMember guest, Map<String, String> zkipsterGuestIdsByName) {
        Boolean isRestricted = guest.Contact != null && guest.Contact.Restricted__c;
        String firstName = isRestricted
            ? guest.Contact.RestrictedFirstName__c
            : (String.isNotBlank(guest.First_Preferred_First_Name__c) ? guest.First_Preferred_First_Name__c : '');
        String lastName = isRestricted
            ? guest.Contact.RestrictedLastName__c
            : (String.isNotBlank(guest.Last_Preferred_Last_Name__c) ? guest.Last_Preferred_Last_Name__c : '');
        firstName = firstName == null ? '' : firstName.trim().toLowerCase();
        lastName = lastName == null ? '' : lastName.trim().toLowerCase();
        String matchedId = zkipsterGuestIdsByName.get(firstName + '|' + lastName);
        if(String.isNotBlank(matchedId)) {
            guest.ZkipsterGuestId__c = matchedId;
        }
    }

    global void finish(Database.BatchableContext BC) {
        try {
            if(failedRecordIds.size() > 0 && failedRecordIds.size() != retryRecordIds.size()) {
                Long milliseconds = Long.valueOf(System.Label.SyncGuestsToZkipsterDelay);
                Integer start = System.Now().millisecond();
                while(System.now().millisecond() < start + milliseconds) {}
                SyncGuestsToZkipster sync =new SyncGuestsToZkipster(failedRecordIds);
                sync.campId = campId;
                Database.executeBatch(sync, 100);
            }
            Campaign campRec = [SELECT Id, Name FROM Campaign WHERE Id = :campId LIMIT 1];
            if(isFailed || failedRecordIds.size() > 0) {
                sendEmailAlerts('failed', campRec);
            } else {
                sendEmailAlerts('success', campRec);
            }
            if(campId == null) return;
            Campaign c = new Campaign();
            c.Id = campId;
            c.Is_Zkipster_Sync__c = false;
            BBApps_Crud.doUpdateWithHandling(c, false, ERR_FINISH);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_FINISH);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    public static void sendEmailAlerts(string statusType, Campaign campRec) {
        try {
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
            String listLink = '<a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + campRec.Id + '">' + campRec.Name + '</a>';
            String subject = statusType == 'success'
                             ? 'Finished syncing guests to Zkipster: ' + campRec.Name
                             : 'Unable to sync guests to Zkipster: ' + campRec.Name;
            String htmlBody = '';
            if(statusType == 'success') {
                htmlBody = 'Hello ' + UserInfo.getFirstName() +
                           ',<br/><br/> Your request to sync guests to Zkipster is now complete (' + listLink + '). ' +
                           '<br/><br/> All guests and their RSVPs are now updated in Zkipster.';
            } else {
                htmlBody = 'Hello '+ UserInfo.getFirstName() +
                           ',<br/><br/> Your request to sync guests to Zkipster was unsuccessful (' + listLink + '). ' +
                           '<br/><br/> Please reach out to a member of the BRM team at bpsalesforceteam@e.bloomberg.org to resolve.';
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[]{ UserInfo.getUserEmail() };
            if(statusType == 'failed') toAddresses.add('bpsalesforceteam@e.bloomberg.org');
            mail.setOrgWideEmailAddressId(EmailUtility.getBRMEmailAddress());
            mail.setToAddresses(toAddresses);
            mail.setReplyTo(EmailUtility.getReplyToEmail());
            mail.setSubject(subject);
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setHtmlBody(htmlBody);
            mails.add(mail);
            Messaging.sendEmail(mails);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SEND_EMAIL_ALERTS));
        }
    }
}