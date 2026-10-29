/**
* Author      : Paddy
* Date        : 01/22/2025
* Jira        : IM-94, IM-111
* Description : This class is Trigger handler class for IM_Announcement__c.
* ChangeLog   :  Paddy on 02/05/2025: IM-111: added method setAnnouncementName, processFileLinks
* Test        : IMAnnouncementTriggerHandlerTest
*/
public with sharing class IMAnnouncementTriggerHandler extends TriggerHandler {

    public List<IM_Announcement__c> newAnnouncements;
    public List<IM_Announcement__c> oldAnnouncements;
    public Map<Id, IM_Announcement__c> oldMap;
    public Map<Id, IM_Announcement__c> newMap;
    private static List<File_Group__c> fileGroupsToInsert = new List<File_Group__c>();

    private static Set<Id> initiativeIds = new Set<Id>();
    private static Map<Id, IM_Announcement__c> fileLinkAnnouncements = new Map<Id, IM_Announcement__c>();

    public IMAnnouncementTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, IM_Announcement__c>) Trigger.oldMap, (Map<Id, IM_Announcement__c>) Trigger.newMap);
    }

    public IMAnnouncementTriggerHandler(List<IM_Announcement__c> oldAnnouncementList, List<IM_Announcement__c   > newAnnouncementList) {
        newAnnouncements = newAnnouncementList;
        oldAnnouncements = oldAnnouncementList;
    }
    
    public IMAnnouncementTriggerHandler(List<IM_Announcement__c> oldAnnouncementList, List<IM_Announcement__c   > newAnnouncementList , Map<Id, IM_Announcement__c> oldMap , Map<Id, IM_Announcement__c > newMap){
        newAnnouncements = newAnnouncementList;
        oldAnnouncements = oldAnnouncementList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void afterInsert(SObject so) {
        IM_Announcement__c announcement = (IM_Announcement__c)so;
        processFileGroups(announcement);
    }

    public override void bulkBefore() {
        if(Trigger.isInsert) {
            for (IM_Announcement__c announcement : newAnnouncements) {
                initiativeIds.add(announcement.Initiative__c);
            }
        } else if (Trigger.isUpdate) {
            for (IM_Announcement__c announcement : newAnnouncements) {
                if(isFieldChanged(announcement, Assets.ANNOUNCEMENT_DATE) ||
                        isFieldChanged(announcement, Assets.OUTLET)) {
                    initiativeIds.add(announcement.Initiative__c);
                }
            }
        }
        if(!initiativeIds.isEmpty()) {
            setAnnouncementName(newAnnouncements);
        }
    }

    public override void bulkAfter() {
        if(Trigger.isInsert) {
            for (IM_Announcement__c announcement : newAnnouncements) {
                if(String.isNotBlank(announcement.Announcement_Link__c)) {
                    fileLinkAnnouncements.put(announcement.Id, announcement);
                }
            }
        }
    }

    public override void andFinally() {
            if(Trigger.isAfter) {
                if(Trigger.isInsert) {
                insert as system fileGroupsToInsert;
                    if(!fileLinkAnnouncements.isEmpty()) {
                        processFileLinks(fileGroupsToInsert, fileLinkAnnouncements);
                    }
                }
            }
        }

    /**
    * Description : Method to create new FileGroup records after insert.
    * Parameters : announcement IM_Announcement__c
    * Return Type : void
    */
    private static void processFileGroups(IM_Announcement__c announcement) {
        fileGroupsToInsert.add(
            new File_Group__c(
                Announcement__c  = announcement.Id,
                Object_Type__c = Assets.ANNOUNCEMENT,
                Category__c = Assets.COMMUNICATIONS
            )
        );
    }

    /**
    * Description : Method to create new FileLink records after insert.
    * Parameters  : List<File_Group__c> fileGroups, Map<Id, IM_Announcement__c> announcements
    * Return Type : void
    */
    private static void processFileLinks(List<File_Group__c> fileGroups, Map<Id, IM_Announcement__c> announcements) {
        List<File_Link__c> fileLinks = new List<File_Link__c>();
        for(File_Group__c fg : fileGroups) {
            IM_Announcement__c announcement = announcements.get(fg.Announcement__c);
            fileLinks.add(new File_Link__c(Name = announcement.Name, File_Group__c = fg.Id, 
                Link_URL__c = announcement.Announcement_Link__c));
        }
        insert as system fileLinks;
    }

    /**
    * Description : Method to set Announcement name before insert or update.
    * Parameters  : List<IM_Announcement__c> newAnnouncements
    * Return Type : void
    */
    private static void setAnnouncementName(List<IM_Announcement__c> newAnnouncements) {
        Map<Id, IM_Initiative__c> initiatives = new Map<Id, IM_Initiative__c>(
                [SELECT Name FROM IM_Initiative__c WHERE Id IN :initiativeIds
                WITH SYSTEM_MODE]);
        for (IM_Announcement__c announcement : newAnnouncements) {
            String initiativeName = '';
            if(String.isNotBlank(announcement.Initiative__c) && initiatives.containsKey(announcement.Initiative__c)) {
                initiativeName = ' ' + ((IM_Initiative__c)initiatives.get(announcement.Initiative__c)).Name;
            }
            announcement.Name = IMUtil.truncateFieldValue(78, announcement.Announcement_Date__c.format() + initiativeName, '', '');
        }
    }
}