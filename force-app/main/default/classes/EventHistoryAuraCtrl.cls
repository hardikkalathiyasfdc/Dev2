/**
* Author : Slalom
* Date   : 05/02/2024
* Jira   : BRME-5192
* Description : This is controller class for Events Widget on contact page.
* Modified By : Neha - BRME-5192 : Changed code to check Print Button permission.
* Test : EventHistoryAuraCtrl_Test
*/
public without sharing class EventHistoryAuraCtrl {

    private static final String ERR_CLASS_FAILED = 'EventHistoryAuraCtrl_CLASS_FAILED';

    @AuraEnabled(cacheable=true)
    public static Boolean getEventPrintButtonAccess() {
        return UtilityClass.hasRequiredPermission('Events_Print_Button_Access');
    }
    
    @AuraEnabled(cacheable=true)
    public static String getEventsByContact(String contactId) {
        Map<String, EventHistory> events = new Map<String, EventHistory>();
        try {
            String eventRecordType = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
            String soql = 'SELECT Id, Campaign.Name, Campaign.Start_Date_Time__c, Campaign.End_Date_Time__c, Campaign.Event_Start_Date_Time__c, Campaign.Event_End_Date_Time__c,';
            soql += 'CampaignId, GuestOf__r.Full_Name__c, Campaign.Private_Campaign__c,' +
                    'RSVPStatus__c, AttendedStatus__c, Attendance_RSVP_Value__c, Campaign.EventStatus__c FROM CampaignMember' +
                    ' WHERE ContactId = :contactId AND Attendance_RSVP_Value__c !=null AND Attendance_RSVP_Value__c!=\'Waitlist\'  AND Campaign.RecordTypeId = :eventRecordType AND Campaign.EventStatus__c != \'Cancelled\' WITH SYSTEM_MODE ';

            soql += ' order by Campaign.Start_Date_Time__c desc NULLS LAST';
            Set<Id> privateCampaignMemberIds = new Set<Id>();
            Set<Id> sharedPrivateCampaignMemberIds = new Set<Id>();
            Set<Id> campaignIds = new Set<Id>();
            List<CampaignMember> campaignMembers = Database.query(soql);
            for(CampaignMember cm : campaignMembers) {
                campaignIds.add(cm.CampaignId);
                if(cm.Campaign.Private_Campaign__c) {
                    privateCampaignMemberIds.add(cm.CampaignId);                
                }
            }
            Set<Id> mrbAttendedLists = new Set<Id>();
            if(!campaignIds.isEmpty()) {
                mrbAttendedLists = getMRBAttendedLists(campaignIds);
            }
            List<UserRecordAccess> userRecordAccessList = [
                SELECT RecordId 
                FROM UserRecordAccess 
                WHERE UserId = :UserInfo.getUserId()
                AND RecordId in :privateCampaignMemberIds 
                AND HasReadAccess = true WITH SYSTEM_MODE];
            for(UserRecordAccess userRecordAccess : userRecordAccessList) {
                sharedPrivateCampaignMemberIds.add(userRecordAccess.Id);           
            }
            List<PermissionSetAssignment> confBriefingPermission = [
                SELECT Id, PermissionSetId, PermissionSet.Name 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :UserInfo.getUserId() 
                AND PermissionSet.Name = 'Contact_Confidential_Briefings' WITH SYSTEM_MODE];
            Set<Id> campaignWithConfBriefings = new Set<Id>();
            if(!confBriefingPermission.isEmpty()) {
                if(!campaignIds.isEmpty()) {
                    for (Confidential_Items__c confItem : [SELECT Id, Campaign__c FROM Confidential_Items__c WHERE Campaign__c in :campaignIds WITH SYSTEM_MODE]) {
                        campaignWithConfBriefings.add(confItem.Campaign__c);
                    }
                }
            }
            for(CampaignMember cm : campaignMembers) {
                if((!cm.Campaign.Private_Campaign__c) || (cm.Campaign.Private_Campaign__c && sharedPrivateCampaignMemberIds.contains(cm.CampaignId)) ) {           
                    EventHistory eh = new EventHistory();
                    eh.eventName = cm.Campaign.Name;
                    if(cm.Campaign.Start_Date_Time__c != null) {
                        eh.startDate = cm.Campaign.Event_Start_Date_Time__c;
                    }
                    if(cm.Campaign.End_Date_Time__c != null) {
                        eh.endDate = cm.Campaign.Event_End_Date_Time__c;
                    }
                    eh.id = cm.Id;
                    eh.guestOfName = cm.GuestOf__r.Full_Name__c;
                    eh.rsvpStatus = cm.RSVPStatus__c;
                    eh.attended = cm.AttendedStatus__c;
                    eh.rsvpAttendedStatus = cm.Attendance_RSVP_Value__c;
                    if(mrbAttendedLists.contains(cm.CampaignId) && FeatureManagement.checkPermission('MRB_Attendance_on_Events')) {
                        eh.mrbAttended = true;
                    } else {
                        eh.mrbAttended = false;
                    }
                    eh.eventStatus = cm.Campaign.EventStatus__c;
                    if(campaignWithConfBriefings.contains(cm.CampaignId)) {
                        eh.isConfidentialBriefings = true;
                    } else {
                        eh.isConfidentialBriefings = false;
                    }
                    events.put(cm.CampaignId, eh);
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return JSON.serialize(events.values());
    }
    
    private static Set<Id> getMRBAttendedLists(Set<Id> campaignIds) {
        Set<Id> mrbAttendedListIds = new Set<Id>();
        try {
            Map<Id, Campaign> listsMap = new Map<Id, Campaign>([
                SELECT Id, HowMRBAttended__c, MRBHosting__c, 
                    (SELECT Id, RSVPStatus__c, AttendedStatus__c 
                    FROM CampaignMembers 
                    WHERE Contact.Founder__c = true LIMIT 1) 
                FROM Campaign 
                WHERE Id IN :campaignIds WITH SYSTEM_MODE
            ]);
            if(!listsMap.isEmpty()) {
                for(Campaign c: listsMap.values()) {
                    if(mrbAttended(c)) mrbAttendedListIds.add (c.Id);
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return mrbAttendedListIds;
    }
    
    private static Boolean mrbAttended(Campaign c) {
        if(
			isStatusYes(c.HowMRBAttended__c) ||
			(!c.CampaignMembers.isEmpty() && mrbListMemberStatusYes(c.CampaignMembers[0]))
		) {
			return true;
		}
        return false;
    }
    
    private static Boolean isStatusYes(String status) {
        if (status != null && status.containsIgnoreCase('yes')) return true;
        return false;
    }
    
    private static Boolean mrbListMemberStatusYes(CampaignMember cm) {
        if((cm.RSVPStatus__c == null || cm.RSVPStatus__c != null && (cm.RSVPStatus__c == 'Pend' || isStatusYes(cm.RSVPStatus__c))) &&
           (cm.AttendedStatus__c == null || (cm.AttendedStatus__c != null && !cm.AttendedStatus__c.contains('Did Not Attend')))) {
            
            return true;
        }
        return false;
    }
   
    public class EventHistory {
        public String eventName {get; set;}
        public String startDate {get; set;}
        public String endDate {get; set;}
        public String guestOfName {get; set;}
        public String id {get; set;}
        public String rsvpStatus {get; set;}
        public String attended {get; set;}
        public Boolean mrbAttended {get; set;}
        public String eventStatus {get; set;}
        public Boolean isConfidentialBriefings {get; set;}
        public String rsvpAttendedStatus {get; set;}
    }
}