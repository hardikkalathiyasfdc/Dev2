@isTest
public with sharing class IMStrategicLocationsTriggerHandlerTest {
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

	@isTest
	public static void testStrategicLocationCreate() {
		List<IM_Initiative__c> parentInitiative = [
			SELECT Id, Foundation_Code__c
			FROM IM_Initiative__c
			WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
		];

		Account org = [SELECT Id, Government_Geo_Area__c FROM Account WITH SYSTEM_MODE LIMIT 1];
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		List<Segment__c> segment = [SELECT Id FROM Segment__c WITH SYSTEM_MODE LIMIT 1];
		List<Geo_Area__c> geoArea = [SELECT Id, DAMA_Id__c FROM Geo_Area__c WHERE Id = :org.Government_Geo_Area__c WITH SYSTEM_MODE LIMIT 1];
		List<Association__c> association = [SELECT Id FROM Association__c WITH SYSTEM_MODE LIMIT 1];

		IM_Initiative__c initiative = [
			SELECT Id, Approved__c, Include_in_Projections__c, Status__c, Current_Budget__c, Segment__c, Approved_Date__c, Team__c
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
			LIMIT 1
		];

		initiative.Approved__c = true;
		initiative.Include_in_Projections__c = false;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget[0].Id;
		initiative.Parent_Initiative__c = parentInitiative[0].Id;
		initiative.Segment__c = segment[0].Id;
		initiative.Segment__c = segment[0].Id;
		initiative.Approved_Date__c = System.today();
		initiative.CityView_Initiative__c = association[0].Id;
		update as system initiative;

		Test.startTest();
		IM_Strategic_Locations__c strategicLocation = TestDataFactory.createStrategicLocation(initiative.Id, geoArea[0].Id);
		strategicLocation.Review_Status__c = '';
		update as system strategicLocation;
		Test.stopTest();
		List<Org_Association__c> orgAssociations = [SELECT Id FROM Org_Association__c WITH SYSTEM_MODE];
		Assert.areEqual(false, orgAssociations.isEmpty());
	}

	@isTest
	public static void testCreateStrategicLocationForApprovedInitiative() {
		List<IM_Initiative__c> parentInitiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
		];
		Account org = [SELECT Id, Government_Geo_Area__c FROM Account WITH SYSTEM_MODE LIMIT 1];
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WITH SYSTEM_MODE LIMIT 1];
		List<Segment__c> segment = [SELECT Id FROM Segment__c WITH SYSTEM_MODE LIMIT 1];
		List<Geo_Area__c> geoArea = [SELECT Id FROM Geo_Area__c WHERE Id = :org.Government_Geo_Area__c WITH SYSTEM_MODE LIMIT 1];
		List<Association__c> association = [SELECT Id FROM Association__c WITH SYSTEM_MODE LIMIT 1];

		IM_Initiative__c initiative = [
			SELECT Id, Name, Approved__c, Status__c, Current_Budget__c, Segment__c, Approved_Date__c
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
			LIMIT 1
		];
		initiative.Approved__c = true;
		initiative.Include_in_Projections__c = false;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget[0].Id;
		initiative.Parent_Initiative__c = parentInitiative[0].Id;
		initiative.Segment__c = segment[0].Id;
		initiative.Approved_Date__c = System.today();
		initiative.CityView_Initiative__c = association[0].Id;
		update as system initiative;

		Test.startTest();
		IM_Strategic_Locations__c strategicLocation = new IM_Strategic_Locations__c(
			Initiative__c = initiative.Id,
			Geo_Area__c = geoArea[0].Id,
			Notes__c = 'Test Notes'
		);
		insert as system strategicLocation;
		Test.stopTest();

		strategicLocation = [
			SELECT Review_Status__c, Deleted__c
			FROM IM_Strategic_Locations__c
			WHERE Id = :strategicLocation.Id
			WITH SYSTEM_MODE
		];
		Assert.areEqual(Assets.PENDING_ADDITION, strategicLocation.Review_Status__c);
		Assert.areEqual(false, strategicLocation.Deleted__c);
	}

	@isTest
	public static void testCreateStrategicLocationForUnapprovedInitiative() {
		IM_Initiative__c initiative = [
			SELECT Id, Name, Approved__c
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			WITH SYSTEM_MODE
			LIMIT 1
		];
		Account org = [SELECT Id, Government_Geo_Area__c FROM Account WITH SYSTEM_MODE LIMIT 1];

		Test.startTest();
		IM_Strategic_Locations__c strategicLocation = new IM_Strategic_Locations__c(
			Initiative__c = initiative.Id,
			Geo_Area__c = org.Government_Geo_Area__c,
			Notes__c = 'Test Notes'
		);
		insert as system strategicLocation;
		Test.stopTest();

		strategicLocation = [
			SELECT Review_Status__c, Deleted__c
			FROM IM_Strategic_Locations__c
			WHERE Id = :strategicLocation.Id
			WITH SYSTEM_MODE
		];
		Assert.isNull(strategicLocation.Review_Status__c, 'Review Status should be left blank for a non-approved Initiative.');
		Assert.areEqual(false, strategicLocation.Deleted__c, 'Deleted should remain false for a non-approved Initiative.');
	}
}