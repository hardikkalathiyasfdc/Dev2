/**
 * Author      : Hardik Kalathiya
 * Date        : 10/12/2026
 * Jira        : BRME-6823
 * Description : Test class for IMStrategicLocationRemovalActionCtrl (row quick action).
 */
@isTest
public with sharing class IMStrategicLocationRemovalActionCtrlTest {
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
	public static void testMarksPendingRemovalOnApprovedInitiative() {
		IM_Initiative__c initiative = approveInitiative();
		IM_Strategic_Locations__c location = createLocation(initiative.Id);

		Test.startTest();
		IMStrategicLocationRemovalActionCtrl.RemovalResult result = IMStrategicLocationRemovalActionCtrl.markForRemoval(location.Id);
		Test.stopTest();

		Assert.areEqual(false, result.hasError, 'No error expected. ' + result.errorMessage);
		Assert.areEqual(false, result.deleted, 'Approved Initiative location should be marked, not deleted.');
		location = [SELECT Review_Status__c, Deleted__c FROM IM_Strategic_Locations__c WHERE Id = :location.Id WITH SYSTEM_MODE];
		Assert.areEqual(Assets.PENDING_REMOVAL, location.Review_Status__c);
		Assert.areEqual(false, location.Deleted__c);
	}

	@isTest
	public static void testHardDeletesOnNonApprovedInitiative() {
		IM_Initiative__c initiative = [
			SELECT Id, Approved__c
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
			LIMIT 1
		];
		IM_Strategic_Locations__c location = createLocation(initiative.Id);
		Id locationId = location.Id;

		Test.startTest();
		IMStrategicLocationRemovalActionCtrl.RemovalResult result = IMStrategicLocationRemovalActionCtrl.markForRemoval(locationId);
		Test.stopTest();

		Assert.areEqual(false, result.hasError, 'No error expected. ' + result.errorMessage);
		Assert.areEqual(true, result.deleted, 'Non-approved Initiative location should be hard deleted.');
		List<IM_Strategic_Locations__c> locations = [SELECT Id FROM IM_Strategic_Locations__c WHERE Id = :locationId WITH SYSTEM_MODE];
		Assert.areEqual(0, locations.size(), 'Record should be deleted.');
	}

	@isTest
	public static void testNullIdReturnsError() {
		Test.startTest();
		IMStrategicLocationRemovalActionCtrl.RemovalResult result = IMStrategicLocationRemovalActionCtrl.markForRemoval(null);
		Test.stopTest();

		Assert.areEqual(true, result.hasError, 'Null Id should return an error.');
	}

	@isTest
	public static void testAlreadyPendingRemovalReturnsError() {
		IM_Initiative__c initiative = approveInitiative();
		IM_Strategic_Locations__c location = createLocation(initiative.Id);
		// Mark it Pending Removal first so the second call hits the already-pending branch
		IMStrategicLocationRemovalController.markRecordsForRemoval(new Set<Id>{ location.Id });

		Test.startTest();
		IMStrategicLocationRemovalActionCtrl.RemovalResult result = IMStrategicLocationRemovalActionCtrl.markForRemoval(location.Id);
		Test.stopTest();

		Assert.areEqual(true, result.hasError, 'Already pending removal should return an error.');
		Assert.areEqual(false, result.deleted);
	}

	@isTest
	public static void testRecordNotFoundReturnsError() {
		IM_Initiative__c initiative = approveInitiative();
		IM_Strategic_Locations__c location = createLocation(initiative.Id);
		Id locationId = location.Id;
		delete as system location;

		Test.startTest();
		IMStrategicLocationRemovalActionCtrl.RemovalResult result = IMStrategicLocationRemovalActionCtrl.markForRemoval(locationId);
		Test.stopTest();

		Assert.areEqual(true, result.hasError, 'A deleted record should return Record not found.');
	}
}