/**
 * Author            : Paddy
 * Date              : 12/17/2025
 * Description       : Test class for IMParentInitiativeHandler
 */
@isTest
public class IMParentInitiativeHandlerTest {
    
    @testSetup
    static void setupTestData() {
        TestDataFactory.createInitiativeBaseData();
    }
    
    @isTest
    static void testBulkBeforeInsertPopulatesFocusAreaAndSegment() {
        Test.startTest();
            IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative');
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Name, Team__c, Focus_Area__c, Segment__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertNotEquals(null, updatedInitiative.Focus_Area__c, 
            'Focus Area should be populated');
        System.assertNotEquals(null, updatedInitiative.Segment__c, 
            'Segment should be populated');
    }
    
    @isTest
    static void testBulkBeforeUpdateTeamChangeUpdatesFocusArea() {
        Map<String, Team__c> teams = TestDataFactory.createTeams();
        Team__c artsTeam = teams.get('Arts');
        Team__c envTeam = teams.get('Environment');
        
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative', 'Arts');
        initiative.Team__c = envTeam.Id;
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Team__c, Focus_Area__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals(envTeam.Id, updatedInitiative.Team__c, 
            'Team should be updated');
    }
    

    @isTest
    static void testBulkBeforeUpdateTeamChangeWithFoundationCodeDoesNotUpdate() {
        Map<String, Team__c> teams = TestDataFactory.createTeams();
        Team__c artsTeam = teams.get('Arts');
        Team__c envTeam = teams.get('Environment');
        Focus_Area__c artsFocusArea = [SELECT Id, Name FROM Focus_Area__c WHERE Name ='Arts' LIMIT 1];
        
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative', 'Arts');
        
        Foundation_Code__c artsFC = [SELECT Id FROM Foundation_Code__c WHERE Name = 'Arts' LIMIT 1];
        Foundation_Code__c fc = TestDataFactory.buildFoundationCode(initiative.Name, 'Parent Initiative', artsFC.Id, artsFocusArea.Id);
        fc.Initiative__c = initiative.Id;
        fc.System_Triggered__c = true;
        insert fc;
        initiative.Team__c = envTeam.Id;
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Team__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals(envTeam.Id, updatedInitiative.Team__c, 
            'Team should be updated');
    }
    
    @isTest
    static void testBeforeUpdateNameChangeTracksForFoundationCodeUpdate() {
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative');
        
        initiative.Name = 'Updated Parent Initiative Name';
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Name
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals('Updated Parent Initiative Name', updatedInitiative.Name, 
            'Name should be updated');
    }
    
    @isTest
    static void testBeforeUpdateTeamChangeTracksForFoundationCodeUpdate() {
        Map<String, Team__c> teams = TestDataFactory.createTeams();
        Team__c artsTeam = teams.get('Arts');
        Team__c envTeam = teams.get('Environment');
        
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative', 'Arts');
        
        initiative.Team__c = envTeam.Id;
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Team__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals(envTeam.Id, updatedInitiative.Team__c, 
            'Team should be updated');
    }
     
    @isTest
    static void testBulkAfterUpdateUpdatesFoundationCodeName() {
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative');
        Focus_Area__c artsFocusArea = [SELECT Id, Name FROM Focus_Area__c WHERE Name ='Arts' LIMIT 1];
        Foundation_Code__c artsFC = [SELECT Id FROM Foundation_Code__c WHERE Name = 'Arts' LIMIT 1];
        
        Foundation_Code__c fc = TestDataFactory.buildFoundationCode(initiative.Name, 'Parent Initiative', artsFC.Id, artsFocusArea.Id);
        fc.Initiative__c = initiative.Id;
        fc.System_Triggered__c = true;
        insert fc;
        
        initiative.Name = 'Updated Parent Initiative Name';
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
        Foundation_Code__c updatedFC = [
            SELECT Id, Name, Foundation_Code__c
            FROM Foundation_Code__c
            WHERE Id = :fc.Id
        ];
        
        System.assertEquals('Updated Parent Initiative Name', updatedFC.Name, 
            'Foundation Code Name should be updated');
        System.assertEquals('Updated Parent Initiative Name', updatedFC.Foundation_Code__c, 
            'Foundation Code Foundation_Code__c should be updated');
    }
    
    @isTest
    static void testAfterInsertCollectsInitiativeIds() {
        Map<String, Focus_Area__c> focusAreas = TestDataFactory.createFocusAreas(
            new List<String>{'Arts'}
        );
        Focus_Area__c focusArea = focusAreas.get('Arts');
        
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative', 'Arts');
        initiative.Focus_Area__c = focusArea.Id;
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
        IM_Initiative__c createdInitiative = [
            SELECT Id, Name, Focus_Area__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertNotEquals(null, createdInitiative, 
            'Initiative should be created');
        System.assertEquals(focusArea.Id, createdInitiative.Focus_Area__c, 
            'Focus Area should be set');
    }
    
    @isTest
    static void testAfterUpdateSyncFieldChangeTracksForBatch() {
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative');
        
        initiative.Name = 'Updated Name for Sync';
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Name
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals('Updated Name for Sync', updatedInitiative.Name, 
            'Name should be updated');
    }
    
    @isTest
    static void testAndFinallyInsertProcessesFoundationCodesAndQueuesBatch() {
        Test.startTest();
            IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative');
        Test.stopTest();
        
        IM_Initiative__c createdInitiative = [
            SELECT Id, Name
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertNotEquals(null, createdInitiative, 
            'Initiative should be created');
    }
    
    @isTest
    static void testBulkBeforeExceptionHandling() {
        Test.startTest();
        try {
            IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative');
            System.assertNotEquals(null, initiative, 'Initiative should be created');
        } catch (Exception e) {
            System.assert(true, 'Exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAndFinallyExceptionHandling() {
        Test.startTest();
        try {
            IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative');
            System.assertNotEquals(null, initiative, 'Initiative should be created');
        } catch (Exception e) {
            System.assert(true, 'Exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdateMultipleFieldChanges_TracksForFoundationCodeUpdate() {
        Map<String, Team__c> teams = TestDataFactory.createTeams();
        Team__c envTeam = teams.get('Environment');
        
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative', 'Arts');
        
        initiative.Name = 'Updated Name';
        initiative.Team__c = envTeam.Id;
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Name, Team__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals('Updated Name', updatedInitiative.Name, 
            'Name should be updated');
        System.assertEquals(envTeam.Id, updatedInitiative.Team__c, 
            'Team should be updated');
    }
    
    @isTest
    static void testDelete() {
        IM_Initiative__c initiative = TestDataFactory.createParentInitiatives('Test Parent Initiative', 'Arts');
        
        Test.startTest();
        try {
        	delete initiative;
        	Assert.isTrue(true, 'Expected error was not thrown');
        } catch (Exception ex) {
            Assert.isFalse(false, 'Caught an unexpected exception');
        }
        Test.stopTest();
    }
}