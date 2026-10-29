@isTest
public with sharing class IMProgramOverviewControllerTest {
	@testSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		Account org = TestDataFactory.createOrg('Test org');

		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
		IM_Announcement__c announcement = TestDataFactory.createAnnouncement(budgetedInitiative);
		announcement.Outlet__c = org.Id;
		announcement.Announcement_Date__c = Date.today();
		insert announcement;

		IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
		IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
		IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
		IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, partner.Id, geography.Id);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
	}

	@isTest
	public static void testGetFoundationData() {
		IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
		IM_Initiative__c parentInitiative = [
			SELECT Id, Name
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air'
		];
		IM_Initiative__c budgetedInitiative = [
			SELECT Id, Name, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		Test.startTest();

		budgetedInitiative.Approved__c = true;
		budgetedInitiative.Approved_Date__c = System.today();
		budgetedInitiative.Parent_Initiative__c = parentInitiative.Id;
		budgetedInitiative.Status__c = 'Ongoing';
		budgetedInitiative.Current_Budget__c = budget.Id;
		update budgetedInitiative;
		List<Foundation_Code__c> foundationCode = [
			SELECT Id
			FROM Foundation_Code__c
		];
		Foundation_Code__c fc = IMProgramOverviewController.getFoundationData(foundationCode[0].Id);
		Test.stopTest();
		Assert.areEqual(foundationCode[0].Id, fc.Id);
	}

	@isTest
	public static void testGetBaseUrl() {
		String baseURL = Environment.getBaseUrl() + '/lightning/n/Program_Overview';
		Test.startTest();
		String fetchedBaseURL = IMProgramOverviewController.getBaseUrl();
		Test.stopTest();
		Assert.areEqual(baseURL, fetchedBaseURL);
	}

	@isTest
	public static void testGetFoundationCode() {
		IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
		IM_Initiative__c parentInitiative = [
			SELECT Id, Name
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air'
		];
		IM_Initiative__c budgetedInitiative = [
			SELECT Id, Name, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		Test.startTest();
			budgetedInitiative.Approved__c = true;
			budgetedInitiative.Approved_Date__c = System.today();
			budgetedInitiative.Parent_Initiative__c = parentInitiative.Id;
			budgetedInitiative.Status__c = 'Ongoing';
			budgetedInitiative.Current_Budget__c = budget.Id;
			update budgetedInitiative;
			List<IM_Initiative__c> initiatives = [
				SELECT Id, Name, Foundation_Code__c
				FROM IM_Initiative__c
				WHERE Id = :budgetedInitiative.Id
			];
			Id fcId = IMProgramOverviewController.getFoundationCode(budgetedInitiative.Id);
		Test.stopTest();
		Assert.areEqual(initiatives[0].Foundation_Code__c, fcId);
	}

	@isTest
	public static void testGetAllFoundationCodes() {
		Test.startTest();
		List<Foundation_Code__c> foundationCode = [
			SELECT Id, Type__c
			FROM Foundation_Code__c
			WHERE Type__c = 'Focus Area'
			LIMIT 1
		];
		Map<Id, List<Foundation_Code__c>> fcToChildMap = IMProgramOverviewController.getAllFoundationCodes();
		Test.stopTest();
		Assert.areEqual(1, fcToChildMap.get(foundationCode[0].Id).size());
	}

	@isTest
	public static void testGetPODataWithFC() {
		List<IM_Initiative__c> parentInitiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air'
		];
		IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
		IM_Initiative__c budgetedInitiative = [
			SELECT Id, Name, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		Test.startTest();

		budgetedInitiative.Approved__c = true;
		budgetedInitiative.Approved_Date__c = System.today();
		budgetedInitiative.Parent_Initiative__c = parentInitiative[0].Id;
		budgetedInitiative.Status__c = 'Ongoing';
		budgetedInitiative.Current_Budget__c = budget.Id;
		update budgetedInitiative;

		List<Foundation_Code__c> foundationCode = [
			SELECT Id, Type__c, Name
			FROM Foundation_Code__c
			WHERE Type__c = 'Focus Area'
			LIMIT 1
		];
		
		Map<Id, List<Foundation_Code__c>> fcToChildMap = IMProgramOverviewController.getAllFoundationCodes();
		IMProgramOverviewController.ProgramOverviewData programOverviewData = IMProgramOverviewController.getProgramOverviewData(
			foundationCode[0].Id,
			fcToChildMap
		);
		Test.stopTest();
		Assert.areEqual(1, programOverviewData.budgetedInitiativeIds.size());
		Assert.areEqual(5, programOverviewData.treeGridData[0].size());
	}

	@isTest
	public static void testGetPODataWithParentInitiative() {
		IM_Initiative__c parentInitiative = [
			SELECT Id, Foundation_Code__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air'
		];
		IM_Budget__c budget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air'];
		IM_Initiative__c budgetedInitiative = [
			SELECT Id, Name, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		

		Test.startTest();
		budgetedInitiative.Approved__c = true;
		budgetedInitiative.Approved_Date__c = System.today();
		budgetedInitiative.Parent_Initiative__c = parentInitiative.Id;
		budgetedInitiative.Status__c = 'Ongoing';
		budgetedInitiative.Current_Budget__c = budget.Id;
		update budgetedInitiative;
		IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(budgetedInitiative);
		insert amendmentInitiative;

		IM_Budget__c amendmentBudget = TestDataFactory.createBudget('Amendment Budget', amendmentInitiative.Id, 'Component', 'Pending Approval');

        amendmentInitiative.Name = 'Clean Air 2.0';
		amendmentInitiative.Current_Budget__c = amendmentBudget.Id;
		update amendmentInitiative;

		Map<Id, List<Foundation_Code__c>> fcToChildMap = IMProgramOverviewController.getAllFoundationCodes();

		IMProgramOverviewController.ProgramOverviewData programOverviewData = IMProgramOverviewController.getProgramOverviewData(
			parentInitiative.Foundation_Code__c,
			fcToChildMap
		);

		Test.stopTest();
		Assert.areEqual(1, programOverviewData.budgetedInitiativeIds.size());
		Assert.areEqual(5, programOverviewData.treeGridData[0].size());
	}

	@isTest
	public static void testBuildAnnouncementRows() {
		IM_Initiative__c budgetedInitiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		List<Id> budgetedIds = new List<Id>{ budgetedInitiative.Id };
		Test.startTest();
		IM_Announcement__c announcement = [
			SELECT Id
			FROM IM_Announcement__c
			LIMIT 1
		];
		List<IMProgramOverviewController.AnnouncementRow> announceRows = IMProgramOverviewController.buildAnnouncementRows(budgetedIds);
		Test.stopTest();
		Assert.areEqual(1, announceRows.size());
	}

	@isTest
	public static void testNestedParentProgramOverviewAlert() {
		Focus_Area__c artsFocusArea = [SELECT Id FROM Focus_Area__c WHERE Name = 'Arts' LIMIT 1];
		Team__c artsTeam = [SELECT Id FROM Team__c WHERE Name = 'Arts' LIMIT 1];
		Foundation_Code__c artsCode = [
			SELECT Id
			FROM Foundation_Code__c
			WHERE Name = 'Arts' AND Type__c = :Assets.FOCUS_AREA
			LIMIT 1
		];
		Id parentRtId = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
			.get(Assets.PARENT_INITIATIVE)
			.getRecordTypeId();

		TriggerFactory.setBypass('IMParentInitiativeHandler');
		TriggerFactory.setBypass('FoundationCodeHandler');

		IM_Initiative__c parentA = new IM_Initiative__c(
			Name = 'Alert Parent A',
			Initiative_Type__c = 'Parent',
			Team__c = artsTeam.Id,
			Focus_Area__c = artsFocusArea.Id,
			RecordTypeId = parentRtId
		);
		insert parentA;

		IM_Initiative__c parentB = new IM_Initiative__c(
			Name = 'Alert Parent B',
			Initiative_Type__c = 'Parent',
			Team__c = artsTeam.Id,
			Focus_Area__c = artsFocusArea.Id,
			Parent_Initiative__c = parentA.Id,
			RecordTypeId = parentRtId,
			Program_Overview_Alert__c = 'Nested parent alert'
		);
		insert parentB;

		Foundation_Code__c parentACode = TestDataFactory.buildFoundationCode(
			'Alert Parent A',
			Assets.PARENT_INITIATIVE,
			artsCode.Id,
			artsFocusArea.Id
		);
		parentACode.Initiative__c = parentA.Id;
		insert parentACode;

		Foundation_Code__c parentBCode = TestDataFactory.buildFoundationCode(
			'Alert Parent B',
			Assets.PARENT_INITIATIVE,
			parentACode.Id,
			artsFocusArea.Id
		);
		parentBCode.Initiative__c = parentB.Id;
		insert parentBCode;

		parentA.Foundation_Code__c = parentACode.Id;
		parentB.Foundation_Code__c = parentBCode.Id;
		update new List<IM_Initiative__c>{ parentA, parentB };

		Test.startTest();
		Map<Id, List<Foundation_Code__c>> fcToChildMap = IMProgramOverviewController.getAllFoundationCodes();
		IMProgramOverviewController.ProgramOverviewData programOverviewData = IMProgramOverviewController.getProgramOverviewData(
			parentA.Foundation_Code__c,
			fcToChildMap
		);
		Test.stopTest();

		IMProgramOverviewController.InitiativeWrapper parentDetailRow = programOverviewData.treeGridData[0][4];
		Assert.areNotEqual('Nested parent alert', parentDetailRow.programOverviewAlert, 'Grandparent row should not take the child parent alert');
		Assert.isFalse(parentDetailRow.children.isEmpty(), 'Parent A should have nested Parent B as a child');
		Assert.isTrue(
			parentDetailRow.children[0].programOverviewAlert != null &&
			parentDetailRow.children[0].programOverviewAlert.contains('Nested parent alert'),
			'Nested parent alert should show when the grandparent is searched'
		);
	}
}