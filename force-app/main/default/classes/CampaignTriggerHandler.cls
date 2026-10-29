/**
 * Changelog          : 
 * Paddy - 10/22/2026 : BRME-7027: Added to the existing EmailDefaultSubject__c changes copy onto
 *                      CampaignMember.EmailSubjectLine__c (blank and Pend RSVPs); limit it to Upcoming events,
 *                      and include Waitlist 1 and Waitlist 2.
 * Test               : CampaignTriggerHandlerTest
 */
public without sharing class CampaignTriggerHandler extends TriggerHandler {
    public List<Id> campaignIdsForCampaignMemberUpdate;
    public Set<Id> campaignIdsForCampaignMemberAssistantUpdate;
    public static Id eventRecId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
    public static Id MEMBER_EVENT_RECORD_TYPE_ID = Schema.SObjectType.CampaignMember.getRecordTypeInfosByDeveloperName().get('Event').getRecordTypeId();
    public static Set<Id> listEventIds = new Set<Id>{Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId(), Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('GuestList').getRecordTypeId()};
    public static Boolean isAdmin = isAdminProfile();
    public static Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
    public Boolean isAfterTrigger = false;
    public Boolean isDeleteTrigger = false;
    private static Set<String> SUBJECT_LINE_RSVP_STATUSES = new Set<String>{
        null, 'Pend', 'Waitlist 1', 'Waitlist 2'
    };

    public CampaignTriggerHandler() {
        campaignIdsForCampaignMemberUpdate = new List<Id>();
        campaignIdsForCampaignMemberAssistantUpdate = new Set<Id>();
        if(Trigger.isAfter) isAfterTrigger = true;
        if(Trigger.isDelete) isDeleteTrigger = true;
    }

    public override void beforeInsert(SObject so){
        Campaign c = (Campaign) so;
        updateListMemberTypes(c);
        preventEventCreation(c);
        updateCampaignSubject(c);
        validateStartDateEndDate(c);
        updateDefaultEventCoordinator(c);
        updateTimeZone(c);

        c.IsActive = true;

        if(c.Start_Date_Time__c != null) {
            if(c.TimeZone__c != null && listEventIds.contains(c.RecordTypeId)) {
                TimeZone tz = Timezone.getTimeZone(c.TimeZone__c);
                TimeZone tz1 = UserInfo.getTimeZone();
                Integer hoursDifferent = tz1.getOffset(c.Start_Date_Time__c)/3600000 - tz.getOffset(c.Start_Date_Time__c)/3600000;
                c.StartDateUtc__c = c.Start_Date_Time__c.addHours(hoursDifferent);
            }
            c.Event_Start_Date_Time__c = c.Start_Date_Time__c.format();
        }

        if(c.End_Date_Time__c != null) {
            if (c.TimeZone__c != null && listEventIds.contains(c.RecordTypeId)) {
                TimeZone tz = Timezone.getTimeZone(c.TimeZone__c);
                TimeZone tz1 = UserInfo.getTimeZone();
                Integer hoursDifferent = tz1.getOffset(c.End_Date_Time__c)/3600000 - tz.getOffset(c.End_Date_Time__c)/3600000;
                c.EndDateUtc__c = c.End_Date_Time__c.addHours(hoursDifferent);
            }
            c.Event_End_Date_Time__c  = c.End_Date_Time__c.format();
        }
        updateEventStatus(c);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Campaign c = (Campaign)so;
        Campaign oldC = (Campaign)oldSo;
        updateTimeZone(c);
        if(c.Name != oldC.Name) {
            return;
        }
        if ( (c.Start_Date_Time__c != oldC.Start_Date_Time__c || c.End_Date_Time__c != oldC.End_Date_Time__c || c.TimeZone__c != oldC.TimeZone__c)) {
            if(listEventIds.contains(c.RecordTypeId) && c.TimeZone__c != null) {
                TimeZone tz = Timezone.getTimeZone(c.TimeZone__c);
                TimeZone tz1 = UserInfo.getTimeZone();
                if(c.Start_Date_Time__c != null){
                    Integer hoursDifferent = tz1.getOffset(c.Start_Date_Time__c)/3600000 - tz.getOffset(c.Start_Date_Time__c)/3600000;
                    c.StartDateUtc__c = c.Start_Date_Time__c.addHours(hoursDifferent);
                    c.Event_Start_Date_Time__c = c.Start_Date_Time__c.format();
                    if(c.End_Date_Time__c != null){
                        c.EndDateUtc__c = c.End_Date_Time__c.addHours(hoursDifferent);
                        c.Event_End_Date_Time__c  = c.End_Date_Time__c.format();
                    }else{
                        c.EndDateUtc__c = null;
                    }
                }
            } else {
                if(c.Start_Date_Time__c != null){
                    c.Event_Start_Date_Time__c = c.Start_Date_Time__c.format();
                    if(c.End_Date_Time__c != null){
                        c.Event_End_Date_Time__c  = c.End_Date_Time__c.format();
                    }
                }
            }
        }

        if(c.Name != oldC.Name) {
            c.EmailDefaultSubjectLine__c = 'Invitation for {0} to attend '+c.Name;
        }
        updateListMemberTypes(c);
        preventListRecUpdate(c);
        validateStartDateEndDate(c);
        updateDefaultEventCoordinator(c);
        updateEventStatus(c);
        if(isFieldChanged(c, 'Private_Campaign__c')) updateCampaignSubject(c);
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        Campaign c = (Campaign)so;
        Campaign oldC = (Campaign)oldSo;
        if (
            c.Constituency__c!=oldC.Constituency__c ||
            c.EmailDefaultSubjectLine__c != oldC.EmailDefaultSubjectLine__c
        ) {
            campaignIdsForCampaignMemberUpdate.add(c.Id);
        }

        if(isFieldChanged(c,'EventStatus__c') && c.EventStatus__c == 'Upcoming' ){
            system.debug('Step 1');
            campaignIdsForCampaignMemberAssistantUpdate.add(c.Id);
        }
    }

    public override void andFinally() {
        List<CampaignMember> toUpdate = new List<CampaignMember>();
        if (!isDeleteTrigger && isAfterTrigger) {
            FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
        }

        Set<Id> allCampaignIds = new Set<Id>();
        allCampaignIds.addAll(campaignIdsForCampaignMemberUpdate);
        allCampaignIds.addAll(campaignIdsForCampaignMemberAssistantUpdate);

        if (allCampaignIds.isEmpty()) return;

        List<CampaignMember> members = [
            SELECT ContactId, Status__c, RSVPStatus__c, Assistant__c,
                   EmailSubjectLine__c, CampaignId, Contact.Constituencies_Joined__c,
                   Contact.Constituencies_Declined__c, Contact.Possible_Constituencies__c,
                   Contact.Preferred_First_Name__c, Contact.FirstName,
                     Contact.Preferred_Last_Name__c, Contact.LastName, Campaign.EmailDefaultSubjectLine__c, Campaign.RecordType.Name,
                   Campaign.RecordType.DeveloperName, Campaign.Constituency__c, Campaign.Name,
                   Campaign.EventStatus__c, Campaign_isActive__c
            FROM CampaignMember
            WHERE CampaignId IN :allCampaignIds
        ];

        Set<String> contactIds = new Set<String>();
        for (CampaignMember cm : members) {
            if (cm.ContactId != null) {
                contactIds.add(cm.ContactId);
            }
        }

        Map<String, Related_Contact__c> relatedContacts = new Map<String, Related_Contact__c>();
        if (!contactIds.isEmpty()) {
            relatedContacts = EventMangementAuraCtrl.getAssistantByContact(
               new List<String>(contactIds)
            );
        }


        for (CampaignMember cm : members) {
            Boolean isUpdated = false;
            if (campaignIdsForCampaignMemberUpdate.contains(cm.CampaignId) && cm.Campaign_isActive__c) {

                if (cm.Campaign.Constituency__c != null && cm.Campaign.RecordType.Name == Assets.CAMPAIGN_RECORDTYPE_CONSTITUENCIES) {
                    String newStatus = null;
                    if (cm.Contact.Constituencies_Joined__c != null && cm.Contact.Constituencies_Joined__c.contains(cm.Campaign.Constituency__c)) {
                        newStatus = 'Yes';
                    } else if (cm.Contact.Constituencies_Declined__c != null && cm.Contact.Constituencies_Declined__c.contains(cm.Campaign.Constituency__c)) {
                        newStatus = 'No';
                    } else if (cm.Contact.Possible_Constituencies__c != null && cm.Contact.Possible_Constituencies__c.contains(cm.Campaign.Constituency__c)) {
                        newStatus = 'Maybe';
                    }
                    if (cm.Status__c != newStatus) {
                        cm.Status__c = newStatus;
                        isUpdated = true;
                    }
                }

                if (cm.Campaign.RecordType.DeveloperName == Assets.CAMPAIGN_RECORDTYPE_DEVENAME_EVENT 
                    && cm.Campaign.EmailDefaultSubjectLine__c != null && cm.Campaign.Name != null 
                    && cm.Campaign.EventStatus__c == 'Upcoming' 
                    /*&& (cm.RSVPStatus__c == null || cm.RSVPStatus__c == 'Pend' ||
                    cm.RSVPStatus__c == 'Waitlist 1') || cm.RSVPStatus__c == 'Waitlist 2') {*/
                    && SUBJECT_LINE_RSVP_STATUSES.contains(cm.RSVPStatus__c)) {
                    String firstName = String.isNotBlank(cm.Contact.Preferred_First_Name__c) ? cm.Contact.Preferred_First_Name__c : (String.isNotBlank(cm.Contact.FirstName) ? cm.Contact.FirstName : '');
                    String lastName = String.isNotBlank(cm.Contact.Preferred_Last_Name__c) ? cm.Contact.Preferred_Last_Name__c : (String.isNotBlank(cm.Contact.LastName) ? cm.Contact.LastName : '');
                    String fullName = (firstName + ' ' + lastName).trim();
                    String formattedSubject = String.format(cm.Campaign.EmailDefaultSubjectLine__c.replace('\'', '\'\''),  new List<Object>{ fullName } );
                    if (cm.EmailSubjectLine__c != formattedSubject) {
                        cm.EmailSubjectLine__c = formattedSubject;
                        isUpdated = true;
                    }
                }
            }

            if (campaignIdsForCampaignMemberAssistantUpdate.contains(cm.CampaignId)
                && cm.ContactId != null && relatedContacts.containsKey(cm.ContactId)
                && cm.Campaign.RecordType.DeveloperName == Assets.CAMPAIGN_RECORDTYPE_DEVENAME_EVENT  && cm.Campaign.EventStatus__c == 'Upcoming') {
                Id newAssistant = relatedContacts.get(cm.ContactId).Related_Contact__c;
                if (cm.Assistant__c != newAssistant) {
                    cm.Assistant__c = newAssistant;
                    isUpdated = true;
                }
            }

            if (isUpdated) {
                toUpdate.add(cm);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private void updateTimeZone(Campaign c) {
        if(c.RecordTypeId != eventRecId || c.TimeZone__c != null) {
            return;
        }
        if(c.TimeZone__c == null) c.TimeZone__c = 'America/New_York';
    }

    private static Boolean isAdminProfile(){
        String name =  [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1].Name;
        return name.containsIgnoreCase('admin');
    }

    private static String formatEventName (String name) {
        String eventName = 'Invitation for {0} to attend '+name;
        return eventName;
    }

    private void updateListMemberTypes(Campaign c){
        Id recId = c.RecordTypeId;
        if(listEventIds.contains(recId)) { //Check whether current event is Event type. If yes, then member should be Event type too
            c.CampaignMemberRecordTypeId = MEMBER_EVENT_RECORD_TYPE_ID;
        } else {
            c.CampaignMemberRecordTypeId = null;
        }
    }

    private void preventListRecUpdate(Campaign c){
        if(!isAdmin && Trigger.isUpdate && isFieldChanged(c, 'RecordTypeId')){
            c.addError('Only admins are allowed to change record types');
        }
    }

    private void preventEventCreation(Campaign c){
        if(isAdmin || !Trigger.isInsert || c.RecordTypeId != eventRecId || EventMangementAuraCtrl.isFromEventsTab == true){
            return;
        }
    }

    private void validateStartDateEndDate(Campaign c) {
        if(c.RecordTypeId != eventRecId || (c.Start_Date_Time__c == null && c.End_Date_Time__c == null)){
            return;
        }
        if(c.Start_Date_Time__c != null && c.End_Date_Time__c == null) {
            c.End_Date_Time__c = c.Start_Date_Time__c.addHours(1).addMinutes(30);
        }
        if(c.End_Date_Time__c < c.Start_Date_Time__c) {
            c.addError('End date must be after start date.');
        }
    }

    private void updateDefaultEventCoordinator(Campaign c) {
        if(c.RecordTypeId != eventRecId || c.EventCoordinator__c != null) {
            return;
        }
        if(c.EventCoordinator__c == null && envSetting.Default_Event_Coordinator__c != null) {
            c.EventCoordinator__c = envSetting.Default_Event_Coordinator__c;
        }
    }

    private void updateEventStatus(Campaign c) {
        if(c.RecordTypeId != eventRecId || c.End_Date_Time__c == null) {
            return;
        }
        if(c.EventStatus__c != 'Cancelled') {
            if(c.End_Date_Time__c > DateTime.now()) {
                c.EventStatus__c = 'Upcoming';
            } else if(!'complete'.equalsIgnoreCase(c.EventStatus__c) && !'archive'.equalsIgnoreCase(c.EventStatus__c)){
                c.EventStatus__c = 'Complete';
            }
        }
    }

    //Method to update the List Subject with 'Private' if the field Private_Campaign__c is true
    private void updateCampaignSubject(Campaign listRecord) {
        String privateTag = ' (Private)';
        if(listRecord.Private_Campaign__c && !listRecord.Name.contains(privateTag)) {
            listRecord.Original_List_Name__c = listRecord.Name;
            listRecord.Name = listRecord.Name.left(70) + privateTag;
        } else if(!listRecord.Private_Campaign__c && listRecord.Name.contains(privateTag)) {
            listRecord.Name = (listRecord.Original_List_Name__c == null || listRecord.Original_List_Name__c == '')
                ? listRecord.Name.replace(privateTag, '')
                : listRecord.Original_List_Name__c;
        }
    }
}