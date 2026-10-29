/**
* Author      : Ravi
* Date        : 09/10/2026
* Jira        : BRME-6952
* Description : Test class for HighlightSubmitController
*/ 
@IsTest
private class HighlightSubmitControllerTest {

    @TestSetup
    static void setupTestData() {
        Team__c team = TestDataFactory.createTeam('Program Highlights Team');
        TestDataFactory.createMetric('People served', team.Id, 'Count', 1);
        TestDataFactory.createHighlightInteraction(
            'Q1 Program Highlight', team, 'Test highlight description', 'Test leadership description');
    }

    private static Highlight_Interaction__c getHighlight() {
        return [SELECT Id FROM Highlight_Interaction__c LIMIT 1];
    }

    private static void setFlags(
        Id highlightId,
        Boolean programHighlight,
        Boolean cityView,
        Boolean contactInteraction,
        Boolean programMetric
    ) {
        update new Highlight_Interaction__c(
            Id = highlightId,
            Include_In_Program_Highlight__c = programHighlight,
            Include_In_CityView__c = cityView,
            Add_As_Contact_Interaction__c = contactInteraction,
            Submit_Program_Metric__c = programMetric
        );
    }

    @IsTest
    static void testValidateHighlightCheckboxSelection() {
        Highlight_Interaction__c highlight = getHighlight();

        Test.startTest();
        setFlags(highlight.Id, false, false, false, false);
        HighlightSubmitController.ValidationResult noneSelected =
            HighlightSubmitController.validateHighlight(highlight.Id);

        setFlags(highlight.Id, true, false, false, false);
        HighlightSubmitController.ValidationResult programOnly =
            HighlightSubmitController.validateHighlight(highlight.Id);
        Test.stopTest();

        System.assertEquals(false, noneSelected.isValid);
        System.assertEquals(1, noneSelected.errors.size());
        System.assertEquals(true, programOnly.isValid);
        System.assertEquals(0, programOnly.errors.size());
    }

    @IsTest
    static void testValidateHighlightParticipantRules() {
        Highlight_Interaction__c highlight = getHighlight();
        setFlags(highlight.Id, false, true, true, false);

        Test.startTest();
        HighlightSubmitController.ValidationResult missingBoth =
        HighlightSubmitController.validateHighlight(highlight.Id);
        TestDataFactory.createInteractionParticipant(highlight.Id, 'Organization');
        HighlightSubmitController.ValidationResult allPresent =
        HighlightSubmitController.validateHighlight(highlight.Id);
        Test.stopTest();

        System.assertEquals(2, missingBoth.errors.size());
    }

    @IsTest
    static void testValidateHighlightMetricRule() {
        Highlight_Interaction__c highlight = getHighlight();
        Metric__c metric = [SELECT Id FROM Metric__c LIMIT 1];
        setFlags(highlight.Id, true, false, false, true);

        Test.startTest();
        HighlightSubmitController.ValidationResult withoutValues =
            HighlightSubmitController.validateHighlight(highlight.Id);

        TestDataFactory.createMetricValue(metric.Id, highlight.Id, 10, Date.today());
        HighlightSubmitController.ValidationResult withValues =
            HighlightSubmitController.validateHighlight(highlight.Id);
        Test.stopTest();

        System.assertEquals(false, withoutValues.isValid);
        System.assertEquals(1, withoutValues.errors.size());
        System.assertEquals(true, withValues.isValid);
    }

    @IsTest
    static void testSubmitForReviewUpdatesStatusOnlyWhenValid() {
        Highlight_Interaction__c highlight = getHighlight();

        Test.startTest();
        setFlags(highlight.Id, false, false, false, false);
        HighlightSubmitController.ValidationResult blocked =
            HighlightSubmitController.submitForReview(highlight.Id);

        Highlight_Interaction__c stillDraft = [
            SELECT Status__c FROM Highlight_Interaction__c WHERE Id = :highlight.Id
        ];

        setFlags(highlight.Id, true, false, false, false);
        HighlightSubmitController.ValidationResult submitted =
            HighlightSubmitController.submitForReview(highlight.Id);
        Test.stopTest();

        System.assertEquals(false, blocked.isValid);
        System.assertEquals(Assets.DRAFT, stillDraft.Status__c);
        System.assertEquals(true, submitted.isValid);

        Highlight_Interaction__c updated = [
            SELECT Status__c FROM Highlight_Interaction__c WHERE Id = :highlight.Id
        ];
        System.assertEquals(Assets.SUBMITTED, updated.Status__c);
    }

    @IsTest
    static void errorHandlingLogicTest() {
        try {
            HighlightSubmitController.validateHighlight(null);
        } catch (Exception e) {
        }

        try {
            HighlightSubmitController.submitForReview(null);
        } catch (Exception e) {
        }
    }

    private static User createUserWithPermissionSet(String lastName, String permissionSetName) {
        User testUser = TestDataFactory.createUser('Submit', lastName, 'System Administrator Custom');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permissionSet = [
                SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1
            ];
            insert new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = permissionSet.Id
            );
        }
        return testUser;
    }

    @IsTest
    static void testPrivateHighlightSubmitsWithoutIncludeFlags() {
        // BRME-7020: a private highlight may be submitted for review without any include flags (MRB stays optional).
        // Runs as a reviewer so the USER_MODE controller queries enforce real FLS on Private__c.
        User reviewer = createUserWithPermissionSet('PrivateReviewer', 'Highlights_Metrics_Reviewer');
        Team__c team = [SELECT Id FROM Team__c LIMIT 1];
        Id highlightId;

        System.runAs(reviewer) {
            Highlight_Interaction__c privateHighlight = new Highlight_Interaction__c(
                Name = 'Private Board Highlight',
                Team__c = team.Id,
                Description__c = 'Private description',
                Status__c = Assets.DRAFT,
                Private__c = true
            );
            insert privateHighlight;
            highlightId = privateHighlight.Id;

            Test.startTest();
            HighlightSubmitController.ValidationResult result =
                HighlightSubmitController.validateHighlight(privateHighlight.Id);
            HighlightSubmitController.ValidationResult submitted =
                HighlightSubmitController.submitForReview(privateHighlight.Id);
            Test.stopTest();

            System.assertEquals(true, result.isValid,
                'Private highlight should validate without include flags: ' + result.errors);
            System.assertEquals(true, submitted.isValid,
                'Private highlight should submit: ' + submitted.errors);
        }

        Highlight_Interaction__c updated = [
            SELECT Status__c FROM Highlight_Interaction__c WHERE Id = :highlightId
        ];
        System.assertEquals(Assets.SUBMITTED, updated.Status__c);
    }

    @IsTest
    static void testPrivateHighlightWithCityViewFlagFailsValidation() {
        // Validation-rule bypass simulates a data load creating the invalid combination;
        // the controller must still surface a clear error and refuse submission.
        insert new Bypass_Automation_Setting__c(Highlight_Interaction_Validation__c = true);

        User reviewer = createUserWithPermissionSet('PrivateCityViewReviewer', 'Highlights_Metrics_Reviewer');
        Team__c team = [SELECT Id FROM Team__c LIMIT 1];
        Id highlightId;

        System.runAs(reviewer) {
            Highlight_Interaction__c privateHighlight = new Highlight_Interaction__c(
                Name = 'Private CityView Highlight',
                Team__c = team.Id,
                Description__c = 'Private description',
                Status__c = Assets.DRAFT,
                Private__c = true,
                Include_In_CityView__c = true
            );
            insert privateHighlight;
            highlightId = privateHighlight.Id;

            Test.startTest();
            HighlightSubmitController.ValidationResult result =
                HighlightSubmitController.validateHighlight(privateHighlight.Id);
            HighlightSubmitController.ValidationResult submitted =
                HighlightSubmitController.submitForReview(privateHighlight.Id);
            Test.stopTest();

            System.assertEquals(false, result.isValid, 'Private + CityView should be invalid');
            System.assert(result.errors.toString().contains('Private highlights cannot be submitted to CityView'),
                'Expected CityView privacy error: ' + result.errors);
            System.assertEquals(false, submitted.isValid, 'Submit should be blocked for private + CityView');
        }

        Highlight_Interaction__c stillDraft = [
            SELECT Status__c FROM Highlight_Interaction__c WHERE Id = :highlightId
        ];
        System.assertEquals(Assets.DRAFT, stillDraft.Status__c, 'Status must remain Draft');
    }

    @IsTest
    static void testRequestorWithoutPrivateFieldAccessUnaffected() {
        // Requestor has no FLS on Private__c: the controller must keep working exactly as before.
        User requestor = createUserWithPermissionSet('RequestorNoPrivateFLS', 'Highlights_Metrics_Requestor');
        Team__c team = [SELECT Id FROM Team__c LIMIT 1];

        System.runAs(requestor) {
            System.assertEquals(false, Highlight_Interaction__c.Private__c.getDescribe().isAccessible(),
                'Requestor should not have read access on Private__c');

            Highlight_Interaction__c highlight = new Highlight_Interaction__c(
                Name = 'Requestor Highlight',
                Team__c = team.Id,
                Description__c = 'Description',
                Status__c = Assets.DRAFT,
                Include_In_Program_Highlight__c = true
            );
            insert highlight;

            Test.startTest();
            HighlightSubmitController.ValidationResult result =
                HighlightSubmitController.validateHighlight(highlight.Id);
            Test.stopTest();

            System.assertEquals(true, result.isValid,
                'Requestor flow should be unchanged: ' + result.errors);
        }
    }
}