/**
* Author      : Paddy
* Date        : 12/27/2024
* Jira        : IM-85
* Description : This class is Trigger handler class for Segment_Team__c	.
* Modified By : 
* Test        : SegmentTeamTriggerHandlerTest
*/
public with sharing class SegmentTeamTriggerHandler extends TriggerHandler {

    public List<Segment_Team__c> newSegmentTeams;
    public List<Segment_Team__c> oldSegmentTeams;
    public Map<Id, Segment_Team__c> oldMap;
    public Map<Id, Segment_Team__c> newMap;
    public Map<Id, Segment__c> segments;
    public Map<Id, Team__c> teams;
    
    private static final String ERR_BULK_BEFORE = 'SEGMENT_TEAM_TRIGGER_BULK_BEFORE_FAILED';

    public SegmentTeamTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Segment_Team__c>) Trigger.oldMap, (Map<Id, Segment_Team__c>) Trigger.newMap);
    }

    public SegmentTeamTriggerHandler(List<Segment_Team__c> oldSegmentTeamList, List<Segment_Team__c	> newSegmentTeamList) {
        newSegmentTeams = newSegmentTeamList;
        oldSegmentTeams = oldSegmentTeamList;
    }
    
    public SegmentTeamTriggerHandler(List<Segment_Team__c> oldSegmentTeamList, List<Segment_Team__c	> newSegmentTeamList , Map<Id, Segment_Team__c> oldMap , Map<Id, Segment_Team__c	> newMap){
        newSegmentTeams = newSegmentTeamList;
        oldSegmentTeams = oldSegmentTeamList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void beforeInsert(SObject so) {
        Segment_Team__c segmentTeam = (Segment_Team__c)so;
        segmentTeam.Name = segments.get(segmentTeam.Segment__c).Name + ' - ' + teams.get(segmentTeam.Team__c).Name;
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Segment_Team__c curSegmentTeam = (Segment_Team__c) so;
        if( isFieldChanged(curSegmentTeam, 'Segment__c') || isFieldChanged(curSegmentTeam, 'Team__c')) {
            curSegmentTeam.Name = segments.get(curSegmentTeam.Segment__c).Name + ' - ' + teams.get(curSegmentTeam.Team__c).Name;
        }
    }

    public override void bulkBefore() {
        try {
            Set<Id> segmentIds = new Set<Id>();
            Set<Id> teamIds = new Set<Id>();
            for(Segment_Team__c segmentTeam : newSegmentTeams) {
                segmentIds.add(segmentTeam.Segment__c);
                teamIds.add(segmentTeam.Team__c);
            }

            segments = new Map<Id, Segment__c>([SELECT Name FROM Segment__c WHERE Id in :segmentIds WITH SYSTEM_MODE]);
            teams = new Map<Id, Team__c>([SELECT Name FROM Team__c WHERE Id in :teamIds WITH SYSTEM_MODE]);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BULK_BEFORE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}