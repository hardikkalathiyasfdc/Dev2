/**
 * Author      : Paddy
 * Date        : 5/19/2025
 * Jira        : IM-203
 * Description : Test class for IMClone.
 * ChangeLog   :
 */
@isTest
public with sharing class IMCloneTest {
	private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();

	@TestSetup
	static void setup() {
		//Bypass Strategic Location Trigger
		Bypass_Automation_Setting__c bypassSetting = new Bypass_Automation_Setting__c();
		bypassSetting.IM_Strategic_Location_Trigger__c = true;
		bypassSetting.IM_Strategic_Location_Validation__c = true;
		insert bypassSetting;

		TestDataFactory.createInitiativeBaseData();
        Account org = TestDataFactory.createOrg('Test Organiation');
        
		IM_Initiative__c initiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', initiative.Id, 'Component', 'Pending Approval');

        IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
		IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
        IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, partner.Id, geography.Id);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);

		TestDataFactory.createFundingPartner(budget.Id);

		Geo_Area__c geoArea = TestDataFactory.createGeoArea();
		geoArea.Enabled_for_Grants__c = true;
		geoArea.DAMA_Id__c = '1655842';
		insert as system geoArea;

		TestDataFactory.createStrategicLocation(initiative.Id, geoArea.Id);
	}

	@isTest
	public static void testCloneBudget() {
		IM_Initiative__c initiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE LIMIT 1];
		List<IM_Geography__c> geographies = [SELECT Id FROM IM_Geography__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
		List<IM_Component__c> components = [SELECT Id FROM IM_Component__c WHERE Budget__c = :budget.Id AND Type__c = 'Component' WITH SYSTEM_MODE];
		List<IM_Component__c> subComponents = [SELECT Id FROM IM_Component__c WHERE Budget__c = :budget.Id AND Type__c = 'SubComponent' WITH SYSTEM_MODE];
		List<IM_Budget_Org__c> budgetOrgs = [SELECT Id FROM IM_Budget_Org__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];
		List<IM_Funding_Source__c> fundingPartners = [SELECT Id FROM IM_Funding_Source__c WHERE Budget__c = :budget.Id WITH SYSTEM_MODE];

		Test.startTest();
		IM_Budget__c clonedBudget = IMClone.cloneBudget(budget.Id, initiative.Id, Assets.AMENDMENT_CREATE);
		List<IM_Geography__c> clonedGeographies = [SELECT Id FROM IM_Geography__c WHERE Budget__c = :clonedBudget.Id WITH SYSTEM_MODE];
		List<IM_Component__c> clonedComponents = [SELECT Id FROM IM_Component__c WHERE Budget__c = :clonedBudget.Id AND Type__c = 'Component' WITH SYSTEM_MODE];
		List<IM_Component__c> clonedSubComponents = [SELECT Id FROM IM_Component__c WHERE Budget__c = :clonedBudget.Id AND Type__c = 'SubComponent' WITH SYSTEM_MODE];
		List<IM_Budget_Org__c> clonedBudgetOrgs = [SELECT Id FROM IM_Budget_Org__c WHERE Budget__c = :clonedBudget.Id WITH SYSTEM_MODE];
		List<IM_Funding_Source__c> clonedFundingPartners = [SELECT Id FROM IM_Funding_Source__c WHERE Budget__c = :clonedBudget.Id WITH SYSTEM_MODE];

		Assert.areEqual(geographies.size(), clonedGeographies.size());
		Assert.areEqual(clonedBudget.Cloned_From__c, budget.Id);
		Test.stopTest();
	}

	@isTest
	public static void testCloneStrategicLocations() {
		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Beach' WITH SYSTEM_MODE];
		IM_Initiative__c initiative = [SELECT Id, Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE LIMIT 1];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;
		
		Test.startTest();
        update as system initiative;
		IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(initiative);
		insert as system amendmentInitiative;
		List<IM_Strategic_Locations__c> strategicLocations = [SELECT Id FROM IM_Strategic_Locations__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE];

		IMClone.cloneStrategicLocations(initiative.Id, amendmentInitiative.Id);
		List<IM_Strategic_Locations__c> clonedStrategicLocations = [SELECT Id FROM IM_Strategic_Locations__c WHERE Initiative__c = :amendmentInitiative.Id WITH SYSTEM_MODE];

		Assert.areEqual(strategicLocations.size(), clonedStrategicLocations.size());
		Test.stopTest();
	}

	@isTest
	public static void testCloneApprovals() {
		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Beach' WITH SYSTEM_MODE];
		IM_Initiative__c initiative = [SELECT Id, Name FROM IM_Initiative__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE LIMIT 1];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;

		Test.startTest();
            update as system initiative;
            IM_Initiative__c amendmentInitiative = TestDataFactory.buildAmendmentInitiative(initiative);
            insert as system amendmentInitiative;
            IM_Approval__c imApproval = TestDataFactory.buildApproval('AJ', System.today(), amendmentInitiative.Id);
            insert as system imApproval;
            IMClone.cloneApprovals(amendmentInitiative.Id, initiative.Id);
            List<IM_Approval__c> clonedApprovals = [SELECT Id, Approver__c FROM IM_Approval__c WHERE Initiative__c = :initiative.Id WITH SYSTEM_MODE];
            Assert.areEqual(2, clonedApprovals.size());
		Test.stopTest();
	}
}