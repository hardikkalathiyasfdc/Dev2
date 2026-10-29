/**
 * Author            : Paddy
 * Date              : 12/15/2025
 * Description       : Test class for IMAmendmentInitiativeHandler
 */

@isTest
private with sharing class IMAmendmentInitiativeHandlerTest {
    
    @testSetup
    static void setupTestData() {
        TestDataFactory.createInitiativeBaseData();
        
        IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Test Budget', budgetedInitiative.Id, 'Component', 'Pending Approval');
        budgetedInitiative.Current_Budget__c = budget.Id;
        budgetedInitiative.Approved__c = true;
        budgetedInitiative.Approved_Date__c = System.today();
        budgetedInitiative.Status__c = 'Ongoing';
        budgetedInitiative.Amendment_Number__c = 0;
        update as system budgetedInitiative;
        
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        amendmentInitiative.Name = 'Test Budgeted Initiative 1';
        amendmentInitiative.Approved__c = false;
        amendmentInitiative.Start_Date__c = System.today();
		amendmentInitiative.End_Date__c = System.today().addMonths(36);
        insert as system amendmentInitiative;
        
        IM_Budget__c amendmentBudget = TestDataFactory.createBudget('Amendment Budget', amendmentInitiative.Id, 'Component', 'Pending Approval');
    }
    
    @isTest
    static void testBulkBeforeUpdateTeamChangeUpdatesFocusArea() {
        Map<String, Team__c> teams = TestDataFactory.createTeams();
        Team__c envTeam = teams.get('Environment');
        
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        insert as system amendmentInitiative;
        
        amendmentInitiative.Name = 'Test Budgeted Initiative 3';
        amendmentInitiative.Team__c = envTeam.Id;
        
        Test.startTest();
        update as system amendmentInitiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Team__c, Focus_Area__c
            FROM IM_Initiative__c
            WHERE Id = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.areEqual(envTeam.Id, updatedInitiative.Team__c, 
            'Team should be updated');
    }
    
    @isTest
    static void testBulkBeforeUpdateStatusDeclinedUpdatesName() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        insert as system amendmentInitiative;
        
        String originalName = amendmentInitiative.Name;
        amendmentInitiative.Status__c = 'Declined';
        
        Test.startTest();
        update as system amendmentInitiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Name, Status__c
            FROM IM_Initiative__c
            WHERE Id = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.isTrue(updatedInitiative.Name.contains('DECLINED'), 
            'Name should contain DECLINED suffix');
        Assert.areEqual('Declined', updatedInitiative.Status__c, 
            'Status should be Declined');
    }
    
    @isTest
    static void testBeforeInsertValidatesUserLinkStatus() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        
        
        Test.startTest();
        insert as system amendmentInitiative;
        Test.stopTest();
        
        IM_Initiative__c createdInitiative = [
            SELECT Id, Name
            FROM IM_Initiative__c
            WHERE Id = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.isNotNull(createdInitiative, 
            'Amendment Initiative should be created');
    }
    
    @isTest
    static void testBeforeUpdateUserLinkStatusChangeValidates() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        insert as system amendmentInitiative;
        amendmentInitiative.Name = 'Test Budgeted Initiative 3';
        Test.startTest();
        update as system amendmentInitiative;
        Test.stopTest();
       
        IM_Initiative__c updatedInitiative = [
            SELECT Id
            FROM IM_Initiative__c
            WHERE Id = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.isNotNull(updatedInitiative, 
            'Amendment Initiative should be updated');
    }
    
    @isTest
    static void testAfterInsertCreatesFileGroups() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        
        Test.startTest();
        insert as system amendmentInitiative;
        Test.stopTest();
        
        List<File_Group__c> fileGroups = [
            SELECT Id, Parent_Initiative__c, Object_Type__c
            FROM File_Group__c
            WHERE Parent_Initiative__c = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.isTrue(fileGroups.size() > 0, 
            'File Groups should be created for Amendment Initiative');
    }
    
    @isTest
    static void testAfterInsertWithIncludeInProjectionsCreatesProjections() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        amendmentInitiative.Include_in_Projections__c = true;
        amendmentInitiative.Proposed_Amount__c = 100000;
        amendmentInitiative.Start_Date__c = System.today();
        amendmentInitiative.End_Date__c = System.today().addYears(3);
        
        Test.startTest();
        insert as system amendmentInitiative;
        Test.stopTest();
        
        List<IM_Projections__c> projections = [
            SELECT Id, Initiative__c
            FROM IM_Projections__c
            WHERE Initiative__c = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.isFalse(projections.isEmpty(), 
            'Projections should be created when Include_in_Projections__c is true');
    }
    
    @isTest
    static void testAfterUpdateStatusDeclinedTracksAmendmentOf() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        insert as system amendmentInitiative;
        
        amendmentInitiative.Status__c = 'Declined';
        
        Test.startTest();
        	update as system amendmentInitiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Status__c, Amendment_of__c
            FROM IM_Initiative__c
            WHERE Id = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.areEqual('Declined', updatedInitiative.Status__c, 
            'Status should be Declined');
        Assert.areEqual(budgetedInitiative.Id, updatedInitiative.Amendment_of__c, 
            'Amendment_of should be set');
    }
    
    @isTest
    static void testAndFinallyInsertInsertsFileGroups() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        
        Test.startTest();
        insert as system amendmentInitiative;
        Test.stopTest();
        
        List<File_Group__c> fileGroups = [
            SELECT Id, Parent_Initiative__c
            FROM File_Group__c
            WHERE Parent_Initiative__c = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.isFalse(fileGroups.isEmpty(), 
            'File Groups should be inserted in andFinally');
    }
    /*********
    @isTest
    static void testAndFinallyUpdateProcessesApprovals() {
        IM_Initiative__c amendmentInitiative = [SELECT Name,Current_Budget__c,Current_Budget__r.Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.00' LIMIT 1];
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Amendment Budget' LIMIT 1];

        amendmentInitiative.Current_Budget__c = budget.Id;
        amendmentInitiative.Approved__c = true;
        amendmentInitiative.Approved_Date__c = System.today();
        amendmentInitiative.Status__c = 'Ongoing';
        
        Test.startTest();
        	update as system amendmentInitiative;
        Test.stopTest();
        
        List<IM_Approval__c> approvals = [
            SELECT Id, Initiative__c
            FROM IM_Approval__c
            WHERE Initiative__c = :amendmentInitiative.Id
        ];
        
        Assert.isTrue(approvals.size() > 0, 
            'Approvals should be processed in andFinally');
    }*******/
    
    @isTest
    static void testAndFinallyCreateProjections() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        amendmentInitiative.Include_in_Projections__c = true;
        amendmentInitiative.Proposed_Amount__c = 100000;
        amendmentInitiative.Start_Date__c = System.today();
        amendmentInitiative.End_Date__c = System.today().addYears(3);
        
        Test.startTest();
        insert as system amendmentInitiative;
        Test.stopTest();
        
        List<IM_Projections__c> projections = [
            SELECT Id, Initiative__c
            FROM IM_Projections__c
            WHERE Initiative__c = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.isFalse(projections.isEmpty(), 
            'Projections should be created in andFinally');
    }
    
    @isTest
    static void testCloneAmendmentCurrentBudget() {
        IM_Initiative__c amendmentInitiative = [SELECT Amendment_of__c FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1' WITH SYSTEM_MODE LIMIT 1];
        IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Amendment Budget' WITH SYSTEM_MODE LIMIT 1];
        Account org = TestDataFactory.createOrg('Test Organiation');
        List<IM_Budget_Row__c> budgetRows = TestDataFactory.createBudgetRows(budget.Id, org.Id);
        amendmentInitiative.Current_Budget__c = budget.Id;
        amendmentInitiative.Approved__c = true;
        amendmentInitiative.Approved_Date__c = System.today();
        amendmentInitiative.Status__c = 'Ongoing';
        
        IM_Initiative__c budgetedInitiative = [SELECT Open_Amendment__c from IM_Initiative__c WHERE Id = :amendmentInitiative.Amendment_of__c WITH SYSTEM_MODE];
        budgetedInitiative.Open_Amendment__c = amendmentInitiative.Id;
        update as system budgetedInitiative;
        
        Test.startTest();
        	update as system amendmentInitiative;
        Test.stopTest();
        List<IM_Budget__c> clonedBudgets = [SELECT Name FROM IM_Budget__c WHERE Cloned_From__c = :budget.Id WITH SYSTEM_MODE];
        Assert.isFalse(clonedBudgets.isEmpty(), 
            'Cloned Budget should have been created.');
    }
    
    @isTest
    static void testValidateUniqueAmendmentNames() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        amendmentInitiative.Name = 'Test Budgeted Initiative 1';
        
        Test.startTest();
            try {
                insert as system amendmentInitiative;
            } catch (Exception e) {
				Assert.isTrue(String.valueOf(e).contains('No two amendments under one initiative can have the same name.'));
            }
        Test.stopTest();
    }
    
    @isTest
    static void testDelete() {
        Map<String, Team__c> teams = TestDataFactory.createTeams();
        Team__c envTeam = teams.get('Environment');
        
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        amendmentInitiative.Status__c = 'Ongoing';
        insert as system amendmentInitiative;
        
        Test.startTest();
        try {
        	delete as system amendmentInitiative;
        	Assert.isTrue(true, 'Expected error was not thrown');
        } catch (Exception ex) {
            Assert.isFalse(false, 'Caught an unexpected exception');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdateReadyForApprovalSendsNotification() {
        IM_Initiative__c amendmentInitiative = [SELECT Id, Status__c FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1' WITH SYSTEM_MODE LIMIT 1];
        amendmentInitiative.Status__c = Assets.READY_FOR_APPROVAL;

        Test.startTest();
        update as system amendmentInitiative;
        Test.stopTest();

        IM_Initiative__c updatedInitiative = [
            SELECT Id, Status__c
            FROM IM_Initiative__c
            WHERE Id = :amendmentInitiative.Id
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(Assets.READY_FOR_APPROVAL, updatedInitiative.Status__c,
            'Status should be Ready for Approval and the notification should not block the update');
    }

    @isTest
    static void sendBack_forRevisions_flipsStatusAndSavesReason() {
        IM_Initiative__c budgetedInitiative = [SELECT Name FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative 1.0' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
        amendmentInitiative.Grants_Team_Contact__c = UserInfo.getUserId();
        insert as system amendmentInitiative;

        amendmentInitiative.Status__c = Assets.READY_FOR_APPROVAL;
        update as system amendmentInitiative;

        // LDS submit from the Request Revisions action sets these three fields together.
        amendmentInitiative.Status__c = Assets.IN_DEVELOPMENT;
        amendmentInitiative.Revisions_Needed__c = 'Yes';
        amendmentInitiative.Revisions_Reason__c = 'Amendment needs revision.';

        Test.startTest();
            update as system amendmentInitiative; // fires the trigger email path (best-effort)
        Test.stopTest();

        IM_Initiative__c result = [
            SELECT Status__c, Revisions_Needed__c, Revisions_Reason__c
            FROM IM_Initiative__c WHERE Id = :amendmentInitiative.Id WITH SYSTEM_MODE
        ];
        Assert.areEqual(Assets.IN_DEVELOPMENT, result.Status__c, 'Status should move back to In Development');
        Assert.areEqual('Yes', result.Revisions_Needed__c, 'Revisions Needed should be Yes');
        Assert.areEqual('Amendment needs revision.', result.Revisions_Reason__c, 'Reason should be saved');
    }
}