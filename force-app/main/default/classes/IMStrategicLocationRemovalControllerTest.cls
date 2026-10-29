/**
 * Author      : Hardik Kalathiya
 * Date        : 10/08/2026
 * Jira        : IM-XXX
 * Description : Test class for IMStrategicLocationRemovalController (mass mark-for-removal invocable).
 */
@isTest
public with sharing class IMStrategicLocationRemovalControllerTest {
	private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();

	private static final String BUDGETED_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.BUDGET_INITIATIVE)
		.getRecordTypeId();

	private static final String INITIATIVE_ASSO_RECORD_TYPE_ID = Schema.SObjectType.Association__c.getRecordTypeInfosByDeveloperName()
		.get(Assets.INITIATIVE)
		.getRecordTypeId();

	@testSetup
	static void setup() {
		Account org = TestDataFactory.createCityViewOrg();
		TestDataFactory.createInitiativeBaseData();
		Focus_Area__c focusArea = [SELECT Id FROM Focus_Area__c WHERE NAME = 'Arts' WITH SYSTEM_MODE LIMIT 1];
		Association__c association = TestDataFactory.getAssociation('Clean Air', focusArea.Id);
		association.RecordTypeId = INITIATIVE_ASSO_RECORD_TYPE_ID;
		insert as system association;
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
		Geo_Area__c geoArea = [SELECT Id, Enabled_For_Grants__c, BP_Active__c FROM Geo_Area__c WHERE Id = :org.Government_Geo_Area__c WITH SYSTEM_MODE LIMIT 1];
		geoArea.Enabled_For_Grants__c = true;
		geoArea.BP_Active__c = true;
		update as system geoArea;
	}

	private static IM_Initiative__c approveInitiative() {
		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID WITH SYSTEM_MODE LIMIT 1];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		Segment__c segment = [SELECT Id FROM Segment__c WITH SYSTEM_MODE LIMIT 1];
		Association__c association = [SELECT Id FROM Association__c WITH SYSTEM_MODE LIMIT 1];

		IM_Initiative__c initiative = [
			SELECT Id, Approved__c, Status__c
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
			LIMIT 1
		];
		initiative.Approved__c = true;
		initiative.Include_in_Projections__c = false;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Segment__c = segment.Id;
		initiative.Approved_Date__c = System.today();
		initiative.CityView_Initiative__c = association.Id;
		update as system initiative;
		return initiative;
	}

	private static IM_Strategic_Locations__c createLocation(Id initiativeId) {
		Account org = [SELECT Id, Government_Geo_Area__c FROM Account WITH SYSTEM_MODE LIMIT 1];
		IM_Strategic_Locations__c location = new IM_Strategic_Locations__c(
			Initiative__c = initiativeId,
			Geo_Area__c = org.Government_Geo_Area__c,
			Notes__c = 'Test Notes'
		);
		insert as system location;
		return location;
	}

	@isTest
	public static void testMarkForRemovalApprovedInitiative() {
		IM_Initiative__c initiative = approveInitiative();
		IM_Strategic_Locations__c location = createLocation(initiative.Id);

		IMStrategicLocationRemovalController.InputWrapper input = new IMStrategicLocationRemovalController.InputWrapper();
		input.ids = new List<Id>{ location.Id };

		Test.startTest();
		List<IMStrategicLocationRemovalController.OutputWrapper> result = IMStrategicLocationRemovalController.markForRemoval(
			new List<IMStrategicLocationRemovalController.InputWrapper>{ input }
		);
		Test.stopTest();

		Assert.areEqual(false, result[0].hasError, 'No error expected. ' + result[0].errorMessage);
		location = [SELECT Review_Status__c, Deleted__c FROM IM_Strategic_Locations__c WHERE Id = :location.Id WITH SYSTEM_MODE];
		Assert.areEqual(Assets.PENDING_REMOVAL, location.Review_Status__c);
		Assert.areEqual(false, location.Deleted__c);
	}

	@isTest
	public static void testMarkForRemovalUnapprovedInitiative() {
		IM_Initiative__c initiative = [
			SELECT Id, Approved__c
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
			LIMIT 1
		];
		IM_Strategic_Locations__c location = createLocation(initiative.Id);

		Test.startTest();
		IMStrategicLocationRemovalController.markRecordsForRemoval(new Set<Id>{ location.Id });
		Test.stopTest();

		List<IM_Strategic_Locations__c> locations = [SELECT Id FROM IM_Strategic_Locations__c WHERE Id = :location.Id WITH SYSTEM_MODE];
		Assert.areEqual(0, locations.size(), 'Location on a non-approved Initiative should be hard deleted.');
	}

	@isTest
	public static void testMarkForRemovalNoIds() {
		IMStrategicLocationRemovalController.InputWrapper input = new IMStrategicLocationRemovalController.InputWrapper();
		input.ids = new List<Id>();

		Test.startTest();
		List<IMStrategicLocationRemovalController.OutputWrapper> result = IMStrategicLocationRemovalController.markForRemoval(
			new List<IMStrategicLocationRemovalController.InputWrapper>{ input }
		);
		Test.stopTest();

		Assert.areEqual(true, result[0].hasError);
		Assert.areEqual(Assets.NO_RECORDS_SELECTED, result[0].errorMessage);
	}

	@isTest
	public static void testMarkForRemovalAlreadyPendingRemoval() {
		IM_Initiative__c initiative = approveInitiative();
		IM_Strategic_Locations__c location = createLocation(initiative.Id);
		IMStrategicLocationRemovalController.markRecordsForRemoval(new Set<Id>{ location.Id });

		IMStrategicLocationRemovalController.InputWrapper input = new IMStrategicLocationRemovalController.InputWrapper();
		input.ids = new List<Id>{ location.Id };

		Test.startTest();
		List<IMStrategicLocationRemovalController.OutputWrapper> result = IMStrategicLocationRemovalController.markForRemoval(
			new List<IMStrategicLocationRemovalController.InputWrapper>{ input }
		);
		Test.stopTest();

		Assert.areEqual(true, result[0].hasError, 'Should report the record is already pending removal.');
		location = [SELECT Review_Status__c, Deleted__c FROM IM_Strategic_Locations__c WHERE Id = :location.Id WITH SYSTEM_MODE];
		Assert.areEqual(Assets.PENDING_REMOVAL, location.Review_Status__c);
	}
}