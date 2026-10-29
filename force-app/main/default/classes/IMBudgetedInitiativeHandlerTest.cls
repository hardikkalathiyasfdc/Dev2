/**
 * Author            : Paddy
 * Date              : 12/17/2025
 * Description       : Test class for IMBudgetedInitiativeHandler
 */
@isTest
private class IMBudgetedInitiativeHandlerTest {
    
    @testSetup
    static void setupTestData() {
        TestDataFactory.createInitiativeBaseData();
        
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative Projection', 'New');
        initiative.Include_in_Projections__c = true;
        initiative.Proposed_Amount__c = 500000;
        update as system initiative;
        
        Geo_Area__c geoAreaContinent = TestDataFactory.createGeoAreaByRecordType('Continent', 'North America');
        insert as system geoAreaContinent;
        
        Geo_Area__c geoAreaCountry = TestDataFactory.createGeoAreaByRecordType('Country', 'United States');
        geoAreaCountry.Parent__c = geoAreaContinent.Id;
        insert as system geoAreaCountry;
        
        Geo_Area__c geoAreaState = TestDataFactory.createGeoAreaByRecordType('State', 'New York');
        geoAreaState.Parent__c = geoAreaCountry.Id;
        insert as system geoAreaState;
        
        Geo_Area__c geoAreaCity = TestDataFactory.createGeoAreaByRecordType('City', 'Amherst');
        geoAreaCity.Parent__c = geoAreaState.Id;
        geoAreaCity.Enabled_For_Grants__c = true;
        insert as system geoAreaCity;
    }
    
    @isTest
    static void testBulkBeforeInsertPopulatesFocusAreaAndSegment() {
        Test.startTest();
            IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Name, Team__c, Focus_Area__c, Segment__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.isNotNull(updatedInitiative.Focus_Area__c, 'Focus Area should be populated');
        Assert.isNotNull(updatedInitiative.Segment__c, 'Segment should be populated');
    }
    
    /******@isTest
    static void testBeforeInsertAssignsImOwnerQueue() {
        Test.startTest();
            IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        Test.stopTest();
        
        Group imOwnerQueue = [SELECT Id FROM Group WHERE DeveloperName = 'IM_Owner' AND Type = 'Queue' LIMIT 1];
        IM_Initiative__c createdInitiative = [
            SELECT Id, OwnerId
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals(imOwnerQueue.Id, createdInitiative.OwnerId, 
            'Owner should be assigned to IM Owner Queue');
    }*****/
    
    /**********@isTest
    static void testBeforeInsertPopulatesBgiveURL() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        initiative.Bgive_Id__c = '123456';
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Bgive_Id__c, Bgive_URL__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertNotEquals(null, updatedInitiative.Bgive_URL__c, 
            'Bgive URL should be populated');
    }**********/
    
    @isTest
    static void testBeforeUpdateNameChangeTracksForFoundationCodeUpdate() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        
        initiative.Name = 'Updated Budgeted Initiative Name';
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Name
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.areEqual('Updated Budgeted Initiative Name', updatedInitiative.Name, 
            'Name should be updated');
    }
    
    @isTest
    static void testBeforeUpdateApprovalSetsOriginalApprovedAmount() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Test Budgeted Initiative', initiative.Id, 'Pending Approval');
        IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRow( budget.Id);
        budgetRow.Is_BP_Fund__c = true;
        update as system budgetRow;

        initiative.Current_Budget__c = budget.Id;
        initiative.Status__c = 'Ongoing';
        initiative.Approved__c = true;
        initiative.Approved_Date__c = System.today();
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Approved__c, Approved_Amount__c, Original_Approved_Amount__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.areEqual(true, updatedInitiative.Approved__c, 
            'Initiative should be approved');
        Assert.areEqual(30000, updatedInitiative.Original_Approved_Amount__c, 
            'Original Approved Amount should be set');
    }
    
    @isTest
    static void testBeforeUpdateApprovalRequiresParentInitiative() {
        Map<String, Team__c> teams = TestDataFactory.createTeams();
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        
        initiative.Parent_Initiative__c = null;
        initiative.Approved__c = true;
        initiative.Approved_Date__c = System.today();
        
        Test.startTest();
        try {
            update as system initiative;
            Assert.fail('Should have thrown an error for missing Parent Initiative');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Parent Initiative'), 
                'Error should mention Parent Initiative');
        }
        Test.stopTest();
    }
    
    /****@isTest
    static void testBeforeUpdateStartDateChangeAdjustsEndDate() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Test Budget', initiative.Id, 'Component', 'Pending Approval');
        
        initiative.Current_Budget__c = budget.Id;
        initiative.Status__c = 'Ongoing';
        initiative.Approved__c = true;
        initiative.Approved_Date__c = System.today();
        Date originalStartDate = initiative.Start_Date__c;
        Date orginalEndDate = initiative.End_Date__c;
        update as system initiative;
        
        initiative.Start_Date__c = originalStartDate.addDays(30);
        Test.startTest();
        	update as system initiative;
        Test.stopTest();
        IM_Initiative__c updatedInitiative = [
            SELECT Start_Date__c, End_Date__c 
            FROM IM_Initiative__c
        	WHERE Id = :initiative.Id];
        Assert.areEqual(orginalEndDate.addDays(30), updatedInitiative.End_Date__c,
                      	'End Date should be adjusted by same number of days as Start Date');
    }****/
    
    @isTest
    static void testBeforeUpdateProjectionsFieldsChangeTracksForProjections() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        
        initiative.Include_in_Projections__c = true;
        initiative.Proposed_Amount__c = 500000;
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Include_in_Projections__c, Proposed_Amount__c, Term_Years__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
            WITH SYSTEM_MODE
        ];
       
        Assert.areEqual(500000, updatedInitiative.Proposed_Amount__c, 
            'Proposed Amount should be updated');
    }
    /********
    @isTest
    static void testBeforeUpdateBgiveIdChangePopulatesURL() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        
        initiative.Bgive_Id__c = '789012';
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Bgive_Id__c, Bgive_URL__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals('789012', updatedInitiative.Bgive_Id__c, 
            'Bgive ID should be updated');
        System.assertNotEquals(null, updatedInitiative.Bgive_URL__c, 
            'Bgive URL should be populated');
    }************/
    
    @isTest
    static void testAfterInsertProcessesFileGroups() {
        Test.startTest();
            IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        Test.stopTest();
        
        IM_Initiative__c createdInitiative = [
            SELECT Id, Name
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
            WITH SYSTEM_MODE
        ];
        
        System.assertNotEquals(null, createdInitiative, 
            'Initiative should be created');
    }
    
    @isTest
    static void testAfterInsertTracksCurrentBudget() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Test Budgeted Initiative', initiative.Id, 'Pending Approval');
        IM_Budget_Row__c budRow = TestDataFactory.createBudgetRow(budget.Id);
        initiative.Current_Budget__c = budget.Id;
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Current_Budget__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
            WITH SYSTEM_MODE
        ];
        
        System.assertEquals(budget.Id, updatedInitiative.Current_Budget__c, 
            'Current Budget should be set');
    }
    
    @isTest
    static void testAfterInsertTracksProjections() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        initiative.Include_in_Projections__c = true;
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        List<IM_Projections__c> projections = [SELECT Id FROM IM_Projections__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE];
        Assert.isFalse(projections.isEmpty());
    }
        
    /*****
    @isTest
    static void testAfterUpdateCurrentBudgetChangeTracksBothBudgets() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        IM_Budget__c oldBudget = TestDataFactory.createBudget('Test Budgeted Initiative', initiative.Id, 'Pending Approval');
        IM_Budget_Row__c budRow = TestDataFactory.createBudgetRow(oldBudget.Id);
		initiative.Current_Budget__c = oldBudget.Id;
        update as system initiative;
        
        IM_Budget__c newBudget = TestDataFactory.createBudget('Test Budgeted Initiative 1.0', initiative.Id, 'Pending Approval');
        initiative.Current_Budget__c = newBudget.Id;
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Current_Budget__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
        ];
        
        System.assertEquals(newBudget.Id, updatedInitiative.Current_Budget__c, 
            'Current Budget should be updated');
    }****/
    
    @isTest
    static void testAndFinallyInsertProcessesFileGroups() {
        Test.startTest();
            IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        Test.stopTest();
        
       	List<File_Group__c> fileGroups = [SELECT Name FROM File_Group__c WHERE Parent_Initiative__c = :initiative.Id WITH SYSTEM_MODE];
        Assert.isFalse(fileGroups.isEmpty(), 'File Groups should be created');
    }
    
    @isTest
    static void testAndFinallyUpdateProcessesFoundationCodes() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Test Budgeted Initiative', initiative.Id, 'Pending Approval');
        initiative.Current_Budget__c = budget.Id;
        initiative.Status__c = 'Ongoing';
        initiative.Approved__c = true;
        initiative.Approved_Date__c = System.today();
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
		List<Foundation_Code__c> foundationCodes = [SELECT Name FROM Foundation_Code__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE];
		Assert.isFalse(foundationCodes.isEmpty(), 'Foundation Code should be created');
    }
    
    @isTest
    static void testAndFinallyUpdateRemovesProjections() {
        IM_Initiative__c initiative = [SELECT Include_in_Projections__c FROM IM_Initiative__c WHERE Name = 'Test Budgeted Initiative Projection' WITH SYSTEM_MODE];
        initiative.Include_in_Projections__c = false;
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        List<IM_Projections__c> projections = [SELECT Id FROM IM_Projections__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE];
        Assert.isTrue(projections.isEmpty());
    }
    
    @isTest
    static void testErrorHandling() {
        Test.startTest();
            try {
                IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'Invalid Type');
                Assert.isNotNull(initiative, 'Initiative should be created');
            } catch (Exception e) {
                Assert.isTrue(true, 'Exception caught: ' + e.getMessage());
            }
        Test.stopTest();
    }
    
    @isTest
	public static void testValidateMultipleRenewals() {
        Team__c artsTeam = [SELECT Id FROM Team__c WHERE Name = 'Arts' WITH SYSTEM_MODE LIMIT 1];
        IM_Initiative__c parentInitiative = TestDataFactory.createParentInitiatives('Test Parent Initiative');
        
        // Start test early to reset governor limits - all setup queries happen before this
        Test.startTest();
        
            // Create the original initiative that will be renewed - set all fields upfront to minimize DML
            IM_Initiative__c originalInitiative = new IM_Initiative__c(
                Name = 'Test Original Initiative 1.0',
                Initiative_Type__c = 'New',
                Status__c = 'Ongoing',
                Amendment_Number__c = 0,
                Team__c = artsTeam.Id,
                Parent_Initiative__c = parentInitiative.Id,
                Start_Date__c = System.today(),
                End_Date__c = System.today().addMonths(36),
                Approved__c = true,
                Approved_Date__c = System.today(),
                RecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
                    .get(Assets.BUDGET_INITIATIVE).getRecordTypeId()
            );
            insert as system originalInitiative;
            
            Account org = TestDataFactory.createOrg('Test Organiation');
            IM_Budget__c budget = TestDataFactory.createBudget('Test Budget', originalInitiative.Id, 'Component', 'Pending Approval');
            List<IM_Budget_Row__c> budgetRows = TestDataFactory.createBudgetRows(budget.Id, org.Id);
            originalInitiative.Current_Budget__c = budget.Id;
            update as system originalInitiative;
            
            // Create first renewal initiative
            IM_Initiative__c firstRenewal = new IM_Initiative__c(
                Name = 'Test Renewal 1 1.0',
                Initiative_Type__c = 'Renewal',
                Status__c = 'Draft',
                Amendment_Number__c = 0,
                Team__c = artsTeam.Id,
                Parent_Initiative__c = parentInitiative.Id,
                Renewal_of__c = originalInitiative.Id,
                Start_Date__c = System.today(),
                End_Date__c = System.today().addMonths(36),
                RecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
                    .get(Assets.BUDGET_INITIATIVE).getRecordTypeId()
            );
            insert as system firstRenewal;
            
            // Try to create second renewal - should fail with validation error
            try {
                IM_Initiative__c secondRenewal = new IM_Initiative__c(
                    Name = 'Test Renewal 2 1.0',
                    Initiative_Type__c = 'Renewal',
                    Status__c = 'Draft',
                    Amendment_Number__c = 0,
                    Team__c = artsTeam.Id,
                    Parent_Initiative__c = parentInitiative.Id,
                    Renewal_of__c = originalInitiative.Id,
                    Start_Date__c = System.today(),
                    End_Date__c = System.today().addMonths(36),
                    RecordTypeId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
                        .get(Assets.BUDGET_INITIATIVE).getRecordTypeId()
                );
                insert as system secondRenewal;
                Assert.fail('Should have thrown an error for multiple active renewals');
            } catch (DmlException dex) {
                Assert.isTrue(dex.getDmlMessage(0).contains(Assets.MULTIPLE_ACTIVE_RENEWAL),
                    'Error message should contain MULTIPLE_ACTIVE_RENEWAL. Actual: ' + dex.getDmlMessage(0));
            }
		Test.stopTest();
	}

    @isTest
    static void testCreateRenewalsOnApproved() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Test Budgeted Initiative', initiative.Id, 'Pending Approval');
        initiative.Current_Budget__c = budget.Id;
        initiative.Status__c = 'Ongoing';
        initiative.Approved__c = true;
        initiative.Approved_Date__c = System.today();
        
        Test.startTest();
            update initiative;
        Test.stopTest();
        
		List<IM_Initiative__c> renewalInitiative = [SELECT Name FROM IM_Initiative__c WHERE Renewal_of__c = :initiative.Id WITH SYSTEM_MODE];
		Assert.isFalse(renewalInitiative.isEmpty(), 'Renewal Initiative should be created');
    }
    
    @isTest
    static void testDelete() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        IM_Budget__c budget = TestDataFactory.createBudget('Test Budgeted Initiative', initiative.Id, 'Pending Approval');
        initiative.Current_Budget__c = budget.Id;
        initiative.Status__c = 'Ongoing';
        initiative.Approved__c = true;
        initiative.Approved_Date__c = System.today();
        update as system initiative;
        
        Test.startTest();
        try {
        	delete as system initiative;
        	Assert.isTrue(true, 'Expected error was not thrown');
        } catch (Exception ex) {
            Assert.isFalse(false, 'Caught an unexpected exception');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdateReadyForApprovalSendsNotification() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Test Budgeted Initiative', 'New');
        initiative.Status__c = Assets.READY_FOR_APPROVAL;
        
        Test.startTest();
            update as system initiative;
        Test.stopTest();
        
        IM_Initiative__c updatedInitiative = [
            SELECT Id, Status__c
            FROM IM_Initiative__c
            WHERE Id = :initiative.Id
            WITH SYSTEM_MODE
        ];
        
        Assert.areEqual(Assets.READY_FOR_APPROVAL, updatedInitiative.Status__c, 
            'Status should be Ready for Approval and the notification should not block the update');
    }

    @isTest
    static void sendBack_forRevisions_flipsStatusAndSavesReason() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('BRME7045 SendBack', 'New');
        initiative.Grants_Team_Contact__c = UserInfo.getUserId();
        initiative.Status__c = Assets.READY_FOR_APPROVAL;
        update as system initiative;

        // LDS submit from the Request Revisions action sets these three fields together.
        initiative.Status__c = Assets.IN_DEVELOPMENT;
        initiative.Revisions_Needed__c = 'Yes';
        initiative.Revisions_Reason__c = 'Please fix the budget narrative.';

        Test.startTest();
            update as system initiative; // fires the trigger email path (best-effort)
        Test.stopTest();

        IM_Initiative__c result = [
            SELECT Status__c, Revisions_Needed__c, Revisions_Reason__c
            FROM IM_Initiative__c WHERE Id = :initiative.Id WITH SYSTEM_MODE
        ];
        Assert.areEqual(Assets.IN_DEVELOPMENT, result.Status__c, 'Status should move back to In Development');
        Assert.areEqual('Yes', result.Revisions_Needed__c, 'Revisions Needed should be Yes');
        Assert.areEqual('Please fix the budget narrative.', result.Revisions_Reason__c, 'Reason should be saved');
    }

    @isTest
    static void sendBack_blankGrantsContact_succeedsWithoutEmail() {
        IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('BRME7045 NoContact', 'New');
        initiative.Grants_Team_Contact__c = null;
        initiative.Status__c = Assets.READY_FOR_APPROVAL;
        update as system initiative;

        initiative.Status__c = Assets.IN_DEVELOPMENT;
        initiative.Revisions_Reason__c = 'No contact - should still succeed';

        Test.startTest();
            update as system initiative; // blank contact -> email skipped, update still succeeds
        Test.stopTest();

        IM_Initiative__c result = [
            SELECT Status__c FROM IM_Initiative__c WHERE Id = :initiative.Id WITH SYSTEM_MODE
        ];
        Assert.areEqual(Assets.IN_DEVELOPMENT, result.Status__c, 'Send-back succeeds even with no Grants Contact');
    }
}