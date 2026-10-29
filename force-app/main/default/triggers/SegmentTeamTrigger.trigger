/**
* Author      : Paddy
* Date        : 12/27/2024
* Jira        : IM-85
* Description : Trigger for Segment_Team__c.
* Modified By : 
* Test        : SegmentTeamTriggerHandlerTest
*/
trigger SegmentTeamTrigger on Segment_Team__c (after update, before update, before insert, after insert, before delete, after delete) {
    TriggerFactory.createAndExecuteHandler(SegmentTeamTriggerHandler.class);
}