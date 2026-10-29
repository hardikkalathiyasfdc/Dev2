/**
 * Author            : Paddy
 * Date              : 09/11/2026
 * Jira              : BRME-6957
 * Description       : Test class for HighlightInteractionTriggerHandler.
 */
@isTest
private class HighlightInteractionTriggerHandlerTest {

	private static final String REVIEWER_LAST_NAME = 'MetricsReviewer';
	private static final String REVIEWER_PERMISSION_SET = 'Highlights_Metrics_Reviewer';
	private static final String REVIEWER_PROFILE = 'System Administrator Custom';

    @TestSetup
	static void setupData() {
		User reviewer = TestDataFactory.createUser('Metrics', REVIEWER_LAST_NAME, REVIEWER_PROFILE);
		System.runAs(new User(Id = UserInfo.getUserId())) {
			PermissionSet reviewerPermission = [
				SELECT Id FROM PermissionSet WHERE Name = :REVIEWER_PERMISSION_SET LIMIT 1
			];
			insert new PermissionSetAssignment(
				AssigneeId = reviewer.Id,
				PermissionSetId = reviewerPermission.Id
			);
		}

		Team__c artsTeam = TestDataFactory.createTeam('Arts');
        Highlight_Interaction__c highlightInteraction = TestDataFactory.createHighlightInteraction('September Highlights', artsTeam, 'Highlight description text', 'Leadership highlight description');
        Contact contact = TestDataFactory.createMayorContact();
        TestDataFactory.createInteraction(contact.Id, 'Test Description', 'Arts',null);
	}

	private static User getReviewerUser() {
		return [
			SELECT Id
			FROM User
			WHERE LastName = :REVIEWER_LAST_NAME
			WITH SYSTEM_MODE
			LIMIT 1
		];
	}

	@isTest
	static void testCityViewLeadershipDescription() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Status__c, Description__c, CityView_Highlight_Description__c, Leadership_Highlight_Description__c
			FROM Highlight_Interaction__c
            WITH SYSTEM_MODE
			LIMIT 1
		];

		Test.startTest();
            highlight.Status__c = Assets.SUBMITTED;
            update as system highlight;
		Test.stopTest();

		Highlight_Interaction__c updatedHighlight = [
			SELECT CityView_Highlight_Description__c, Leadership_Highlight_Description__c, Description__c
			FROM Highlight_Interaction__c
			WHERE Id = :highlight.Id
            WITH SYSTEM_MODE
		];
		Assert.areEqual(
			updatedHighlight.Description__c,
			updatedHighlight.CityView_Highlight_Description__c,
			'CityView highlight description should copy from Description on submit'
		);
		Assert.areEqual(
			updatedHighlight.Description__c,
			updatedHighlight.Leadership_Highlight_Description__c,
			'Leadership highlight description should copy from Description on submit'
		);
	}

	@isTest
	static void testMRBDescription() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Include_As_MRB_Highlight__c 
			FROM Highlight_Interaction__c
            WITH SYSTEM_MODE
			LIMIT 1
		];
		
		Test.startTest();
            highlight.Include_As_MRB_Highlight__c = true;
            update as system highlight;
		Test.stopTest();

		Highlight_Interaction__c updatedHighlight = [
			SELECT MRB_Highlight_Description__c, Leadership_Highlight_Description__c
			FROM Highlight_Interaction__c
			WHERE Id = :highlight.Id
            WITH SYSTEM_MODE
		];
		Assert.areEqual(
			updatedHighlight.Leadership_Highlight_Description__c,
			updatedHighlight.MRB_Highlight_Description__c,
			'MRB highlight description should copy from Leadership when Include As MRB is set and MRB is blank'
		);
	}

	@isTest
	static void testMRBDescriptionNoUpdate() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Include_As_MRB_Highlight__c, Leadership_Highlight_Description__c, MRB_Highlight_Description__c
			FROM Highlight_Interaction__c
            WITH SYSTEM_MODE
			LIMIT 1
		];
		String existingMrbDescription = 'Existing MRB description';
		highlight.Leadership_Highlight_Description__c = 'Leadership highlight description';
		highlight.MRB_Highlight_Description__c = 'Existing MRB description';
		update as system highlight;

		Test.startTest();
            highlight.Include_As_MRB_Highlight__c = true;
            update as system highlight;
		Test.stopTest();

		Highlight_Interaction__c updatedHighlight = [
			SELECT MRB_Highlight_Description__c
			FROM Highlight_Interaction__c
			WHERE Id = :highlight.Id
            WITH SYSTEM_MODE
		];
		Assert.areEqual(
			existingMrbDescription,
			updatedHighlight.MRB_Highlight_Description__c,
			'Existing MRB highlight description should not be overwritten'
		);
	}

	@isTest
	static void testProcessOrgAndContactInteractions() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Status__c, Publish_To_CityView__c, Description__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Account org = TestDataFactory.createOrg('Highlight Org');
		Contact contact = TestDataFactory.createContact(org.Id, 'Highlight');
		TestDataFactory.createInteractionParticipant(
			highlight.Id,
			'Organization',
			org.Id,
			null,
			'Org participant description'
		);
		TestDataFactory.createInteractionParticipant(
			highlight.Id,
			'Contact',
			null,
			contact.Id,
			null
		);

		Test.startTest();
			System.runAs(getReviewerUser()) {
				highlight.Status__c = 'Reviewed';
				highlight.Publish_To_CityView__c = true;
				highlight.CityView_Highlight_Description__c = 'CityView Org participant description';
				update as system highlight;
			}
		Test.stopTest();

		List<Interaction__c> interactions = [
			SELECT Id, Name, Description__c, Organization__c, Contact__c, Highlight_Interaction__c,
				Interaction_Type__c, CityView_Review_Status__c, RecordType.DeveloperName
			FROM Interaction__c
			WHERE Highlight_Interaction__c = :highlight.Id
			WITH SYSTEM_MODE
		];
		Assert.areEqual(2, interactions.size(), 'One interaction should be created per participant');

		Boolean hasOrgInteraction = false;
		Boolean hasContactInteraction = false;
		for (Interaction__c interaction : interactions) {
			Assert.areEqual('Program Highlight', interaction.Interaction_Type__c);
			Assert.areEqual('Publish to CityView', interaction.CityView_Review_Status__c);
			Assert.areEqual(highlight.Id, interaction.Highlight_Interaction__c);
			if (interaction.Organization__c == org.Id) {
				hasOrgInteraction = true;
				Assert.areEqual('CityView Org participant description', interaction.Description__c);
				Assert.areEqual('Recent_Engagement', interaction.RecordType.DeveloperName);
			}
			if (interaction.Contact__c == contact.Id) {
				hasContactInteraction = true;
			}
		}
		Assert.isTrue(hasOrgInteraction, 'Organization interaction should be created');
		Assert.isTrue(hasContactInteraction, 'Contact interaction should be created');
	}

	@isTest
	static void testLatestMetricValuePopulatedOnSubmit() {
		Team__c artsTeam = [SELECT Id FROM Team__c WITH SYSTEM_MODE LIMIT 1];
		Highlight_Interaction__c highlight = [
			SELECT Id, Status__c, Submit_Program_Metric__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Metric__c metric = TestDataFactory.createMetric('People Served', artsTeam.Id, 'Participants', 1);
		Metric_Value__c metricValue = TestDataFactory.createMetricValue(
			metric.Id,
			highlight.Id,
			10,
			Date.today()
		);

		Test.startTest();
			highlight.Submit_Program_Metric__c = true;
			highlight.Status__c = Assets.SUBMITTED;
			update as system highlight;
		Test.stopTest();

		Metric__c updatedMetric = [
			SELECT Latest_Metric_Value__c
			FROM Metric__c
			WHERE Id = :metric.Id
			WITH SYSTEM_MODE
		];
		Assert.areEqual(
			metricValue.Id,
			updatedMetric.Latest_Metric_Value__c,
			'Latest Metric Value should point to the value submitted on this highlight'
		);
	}

	@isTest
	static void testLatestMetricValueNotOverwrittenByOlderValue() {
		Team__c artsTeam = [SELECT Id FROM Team__c WITH SYSTEM_MODE LIMIT 1];
		Highlight_Interaction__c highlight = [
			SELECT Id, Status__c, Submit_Program_Metric__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Highlight_Interaction__c priorHighlight = TestDataFactory.createHighlightInteraction(
			'October Highlights',
			artsTeam,
			'Prior highlight description',
			'Prior leadership description'
		);
		Metric__c metric = TestDataFactory.createMetric('People Served', artsTeam.Id, 'Participants', 1);
		Metric_Value__c newerValue = TestDataFactory.createLatestMetricValue(
			metric.Id,
			priorHighlight.Id,
			25,
			Date.today().addDays(10)
		);
		TestDataFactory.createMetricValue(metric.Id, highlight.Id, 10, Date.today());

		Test.startTest();
			highlight.Submit_Program_Metric__c = true;
			highlight.Status__c = Assets.SUBMITTED;
			update as system highlight;
		Test.stopTest();

		Metric__c updatedMetric = [
			SELECT Latest_Metric_Value__c
			FROM Metric__c
			WHERE Id = :metric.Id
			WITH SYSTEM_MODE
		];
		Assert.areEqual(
			newerValue.Id,
			updatedMetric.Latest_Metric_Value__c,
			'Latest Metric Value should stay on the newer dated value'
		);
	}

	@isTest
	static void testProcessFileGroups() {
		Test.startTest();
			Team__c artsTeam = TestDataFactory.createTeam('Arts');
        	Highlight_Interaction__c highlightInteraction = TestDataFactory.createHighlightInteraction('September Highlights', artsTeam, 'Highlight description text', 'Leadership highlight description');
			List<File_Group__c> fileGroups = [SELECT Id FROM File_Group__c 
						WHERE Highlight__c = :highlightInteraction.Id 
						WITH SYSTEM_MODE
					];
		Test.stopTest();
		Assert.isTrue(!fileGroups.isEmpty(), 'File Group records should have been created.');
	}

	@isTest
	static void testParticipantDescriptionAndInteractionLinkedOnReview() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Status__c, Include_In_CityView__c, Publish_To_CityView__c, CityView_Highlight_Description__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Account org = TestDataFactory.createOrg('Highlight Org');
		TestDataFactory.createInteractionParticipant(
			highlight.Id,
			'Organization',
			org.Id,
			null,
			'Original participant description'
		);

		highlight.CityView_Highlight_Description__c = 'CityView description text';
		update as system highlight;

		Test.startTest();
			System.runAs(getReviewerUser()) {
				highlight.Status__c = Assets.REVIEWED;
				highlight.Include_In_CityView__c = true;
				highlight.Publish_To_CityView__c = true;
				update as system highlight;
			}
		Test.stopTest();

		Interaction_Participant__c updatedParticipant = [
			SELECT Description__c, Interaction__c
			FROM Interaction_Participant__c
			WHERE Highlight__c = :highlight.Id
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Assert.areEqual(
			'CityView description text',
			updatedParticipant.Description__c,
			'Participant description should sync from the CityView highlight description on review'
		);
		Assert.isNotNull(
			updatedParticipant.Interaction__c,
			'Participant should be linked to the Interaction created for it'
		);
	}

	@isTest
	static void testParticipantDescriptionNotSyncedWhenCityViewNotIncluded() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Status__c, Include_In_CityView__c, CityView_Highlight_Description__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Account org = TestDataFactory.createOrg('Highlight Org');
		TestDataFactory.createInteractionParticipant(
			highlight.Id,
			'Organization',
			org.Id,
			null,
			'Original participant description'
		);

		highlight.CityView_Highlight_Description__c = 'CityView description text';
		update as system highlight;

		Test.startTest();
			highlight.Status__c = Assets.REVIEWED;
			highlight.Include_In_CityView__c = false;
			update as system highlight;
		Test.stopTest();

		Interaction_Participant__c updatedParticipant = [
			SELECT Description__c, Interaction__c
			FROM Interaction_Participant__c
			WHERE Highlight__c = :highlight.Id
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Assert.areEqual(
			'Original participant description',
			updatedParticipant.Description__c,
			'Participant description should not change when Include In CityView is unchecked'
		);
		Assert.isNull(
			updatedParticipant.Interaction__c,
			'No Interaction should be linked when the highlight is not published to CityView'
		);
	}

	@isTest
	static void testPrivateHighlightCannotBeSelectedForCityView() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Private__c, Include_In_CityView__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];

		highlight.Private__c = true;
		highlight.Include_In_CityView__c = true;

		String errorMessage;
		Test.startTest();
			try {
				update as system highlight;
			} catch (DmlException ex) {
				errorMessage = ex.getMessage();
			}
		Test.stopTest();

		Assert.isNotNull(errorMessage, 'Selecting a private highlight for CityView should be rejected');
		Assert.isTrue(
			errorMessage.contains('Private highlights cannot be submitted to CityView'),
			'Unexpected error message: ' + errorMessage
		);
	}

	@isTest
	static void testPrivateHighlightCannotBePublishedToCityView() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Private__c, Publish_To_CityView__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];

		highlight.Private__c = true;
		highlight.Publish_To_CityView__c = true;

		String errorMessage;
		Test.startTest();
			try {
				update as system highlight;
			} catch (DmlException ex) {
				errorMessage = ex.getMessage();
			}
		Test.stopTest();

		Assert.isNotNull(errorMessage, 'Publishing a private highlight to CityView should be rejected');
		Assert.isTrue(
			errorMessage.contains('Private highlights cannot be submitted to CityView'),
			'Unexpected error message: ' + errorMessage
		);
	}

	@isTest
	static void testCityViewHighlightCannotBeMadePrivate() {
		Highlight_Interaction__c highlight = [
			SELECT Id, Private__c, Include_In_CityView__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];

		highlight.Include_In_CityView__c = true;
		update as system highlight;

		highlight.Private__c = true;

		String errorMessage;
		Test.startTest();
			try {
				update as system highlight;
			} catch (DmlException ex) {
				errorMessage = ex.getMessage();
			}
		Test.stopTest();

		Assert.isNotNull(errorMessage, 'Marking an existing CityView highlight private should be rejected');
		Assert.isTrue(
			errorMessage.contains('Private highlights cannot be submitted to CityView'),
			'Unexpected error message: ' + errorMessage
		);
	}

	@isTest
	static void testPrivateHighlightSkipsCityViewProcessingWhenValidationBypassed() {
		// Simulates data-load/API paths that bypass the validation rule: the trigger must still not publish private highlights.
		insert new Bypass_Automation_Setting__c(Highlight_Interaction_Validation__c = true);

		Highlight_Interaction__c highlight = [
			SELECT Id, Status__c, Publish_To_CityView__c, Private__c
			FROM Highlight_Interaction__c
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Account org = TestDataFactory.createOrg('Private Highlight Org');
		TestDataFactory.createInteractionParticipant(
			highlight.Id,
			'Organization',
			org.Id,
			null,
			'Org participant description'
		);

		Test.startTest();
			highlight.Status__c = Assets.REVIEWED;
			highlight.Publish_To_CityView__c = true;
			highlight.Private__c = true;
			update as system highlight;
		Test.stopTest();

		List<Interaction__c> interactions = [
			SELECT Id
			FROM Interaction__c
			WHERE Highlight_Interaction__c = :highlight.Id
			WITH SYSTEM_MODE
		];
		Assert.areEqual(0, interactions.size(), 'No Interaction records should be auto-created for a private highlight');

		Interaction_Participant__c participant = [
			SELECT Interaction__c, Description__c
			FROM Interaction_Participant__c
			WHERE Highlight__c = :highlight.Id
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Assert.isNull(participant.Interaction__c, 'Participant should not be linked to an Interaction for a private highlight');
		Assert.areEqual(
			'Org participant description',
			participant.Description__c,
			'Participant description should not be synced from the CityView description for a private highlight'
		);
	}

	@isTest
	static void testReviewerPermissionSetGrantsPrivateFieldAccess() {
		// Pins the BRME-7020 FLS contract; requires the updated Highlights_Metrics_Reviewer permission set in the org.
		PermissionSet reviewerPermissionSet = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = :REVIEWER_PERMISSION_SET
			LIMIT 1
		];

		List<FieldPermissions> fieldPermissions = [
			SELECT PermissionsRead, PermissionsEdit
			FROM FieldPermissions
			WHERE ParentId = :reviewerPermissionSet.Id
			AND Field = 'Highlight_Interaction__c.Private__c'
		];

		Assert.areEqual(1, fieldPermissions.size(), 'Reviewer permission set should contain the Private__c field permission');
		Assert.isTrue(fieldPermissions[0].PermissionsRead, 'Reviewer should have read access on Private__c');
		Assert.isTrue(fieldPermissions[0].PermissionsEdit, 'Reviewer should have edit access on Private__c');
	}
}