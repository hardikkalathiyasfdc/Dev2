/**
* Author      : Paddy
* Date        : 01/22/2025
* Jira        : IM-94, IM-111
* Description : Trigger for IM_Announcement__c.
* Modified By : 
* Test        : AnnouncementTriggerHandlerTest
*/
trigger IMAnnouncementTrigger on IM_Announcement__c (before Insert, after insert, before update) {
    TriggerFactory.createAndExecuteHandler(IMAnnouncementTriggerHandler.class);
}