/**
* Author      : Paddy
* Date        : 12/27/2024
* Jira        : IM-85
* Description : Test class for SegmentTeamTriggerHandler.
* Modified By : 
*/
@isTest
public with sharing class SegmentTeamTriggerHandlerTest {
    
    @TestSetup
    static void setup() {
        Bypass_Automation_Setting__c bypassSetting = new Bypass_Automation_Setting__c();
        bypassSetting.Segment_Team_Validation__c = true;
        insert as system bypassSetting;
        
        Team__c team = TestDataFactory.createTeam('Team');
        Team__c team1 = TestDataFactory.createTeam('Team1');

        Segment__c segment = TestDataFactory.createSegment('Segment');
        Segment__c segment1 = TestDataFactory.createSegment('Segment1');
        List<Segment__c> segments = new List<Segment__c>{segment, segment1};
        insert as system segments;

        Segment_Team__c segmentTeam = TestDataFactory.createSegmentTeam(team1.Id, segment1.Id);
        insert as system segmentTeam;
    }

    @isTest
    public static void testSegmentTeamNameInsert() {
        Team__c team = [SELECT Name FROM Team__c WHERE Name = 'Team' WITH SYSTEM_MODE];
        Segment__c segment = [SELECT Name FROM Segment__c WHERE Name = 'Segment' WITH SYSTEM_MODE];
        Segment_Team__c segmentTeam = TestDataFactory.createSegmentTeam(team.Id, segment.Id);
        Test.startTest();
            insert as system segmentTeam;
            Segment_Team__c insertedSegmentTeam = [SELECT Name FROM Segment_Team__c WHERE Id = :segmentTeam.Id WITH SYSTEM_MODE];
            Assert.areEqual('Segment - Team', insertedSegmentTeam.Name);
        Test.stopTest();
    }

    @isTest
    public static void testSegmentTeamNameUpdate() {
        Team__c team = [SELECT Name FROM Team__c WHERE Name = 'Team' WITH SYSTEM_MODE];
        Segment__c segment = [SELECT Name FROM Segment__c WHERE Name = 'Segment' WITH SYSTEM_MODE];
        Segment_Team__c segmentTeam = [SELECT Name FROM Segment_Team__c WHERE Name = 'Segment1 - Team1' WITH SYSTEM_MODE];
        Test.startTest();
            segmentTeam.Segment__c = segment.Id;
            segmentTeam.Team__c = team.Id;
            update as system segmentTeam;
            Segment_Team__c updatedSegmentTeam = [SELECT Name from Segment_Team__c WHERE Id = :segmentTeam.Id WITH SYSTEM_MODE];
            Assert.areEqual('Segment - Team', updatedSegmentTeam.Name);
        Test.stopTest();
    }
}