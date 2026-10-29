@isTest
public with sharing class IMGrantTriggerHandlerTest {
	private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();

	private static final String BUDGETED_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.BUDGET_INITIATIVE)
		.getRecordTypeId();

	@testSetup
	static void setup() {
		Account org = TestDataFactory.createOrg('Test org');
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');
        IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
		IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
		IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, partner.Id, geography.Id);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
	}

	@isTest
	public static void testIMGrantDelete() {
		Test.startTest();
		List<IM_Initiative__c> parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID LIMIT 1];
		List<IM_Initiative__c> initiative = [SELECT Id FROM IM_Initiative__c WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID LIMIT 1];
		List<IM_Budget__c> budget = [SELECT Id FROM IM_Budget__c WHERE Initiative__c = :initiative[0].Id];
		initiative[0].Approved__c = true;
		initiative[0].Parent_Initiative__c = parentInitiative[0].Id;
		initiative[0].Status__c = 'Ongoing';
		initiative[0].Current_Budget__c = budget[0].Id;
		initiative[0].Approved_Date__c = System.today();
		update initiative;
		List<IM_Grant__c> imGrant = [SELECT Id FROM IM_Grant__c LIMIT 1];
		delete imGrant;
		List<IM_Budget_Row__c> budgetRows = [SELECT Id FROM IM_Budget_Row__c LIMIT 1];
		Test.stopTest();
		Assert.areEqual(0, budgetRows.size());
	}
    
    @isTest
	public static void testTotalNotApplicableAmount() {
		Test.startTest();
		List<IM_Initiative__c> parentInitiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
			LIMIT 1
		];
		List<IM_Initiative__c> initiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			LIMIT 1
		];
		List<IM_Budget__c> budget = [
			SELECT Id
			FROM IM_Budget__c
			WHERE Initiative__c = :initiative[0].Id
		];
		initiative[0].Approved__c = true;
		initiative[0].Approved_Date__c = System.today();
		initiative[0].Parent_Initiative__c = parentInitiative[0].Id;
		initiative[0].Status__c = 'Ongoing';
		initiative[0].Current_Budget__c = budget[0].Id;
		update initiative;
		List<IM_Budget_Grant__c> budgetGrant = [
			SELECT Id, IM_Grant__c
			FROM IM_Budget_Grant__c
			LIMIT 1
		];
		List<IM_Grant__c> imGrant = [
			SELECT Id, Bgive_IM_Connection__c, Funded_By_Multiple_Initiatives__c
			FROM IM_Grant__c
			WHERE Id = :budgetGrant[0].IM_Grant__c
		];
		imGrant[0].Bgive_IM_Connection__c = 'Not Applicable';
		imGrant[0].Funded_By_Multiple_Initiatives__c = 'No';
		update imGrant;
        
        List<IM_Budget__c> updatedBudget = [
			SELECT Total_Not_Applicable_Amount__c
			FROM IM_Budget__c
			WHERE Initiative__c = :initiative[0].Id
		];
		Test.stopTest();
		Assert.isNotNull(updatedBudget[0].Total_Not_Applicable_Amount__c);
	}
    
    @isTest
	public static void testIncludeForeignCurrency() {
		Test.startTest();
		List<IM_Initiative__c> parentInitiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
			LIMIT 1
		];
		List<IM_Initiative__c> initiative = [
			SELECT Id
			FROM IM_Initiative__c
			WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID
			LIMIT 1
		];
		List<IM_Budget__c> budget = [
			SELECT Id
			FROM IM_Budget__c
			WHERE Initiative__c = :initiative[0].Id
		];
		initiative[0].Approved__c = true;
		initiative[0].Approved_Date__c = System.today();
		initiative[0].Parent_Initiative__c = parentInitiative[0].Id;
		initiative[0].Status__c = 'Ongoing';
		initiative[0].Current_Budget__c = budget[0].Id;
		update initiative;
		List<IM_Budget_Grant__c> budgetGrant = [
			SELECT Id, IM_Grant__c
			FROM IM_Budget_Grant__c
			LIMIT 1
		];
        Currency__c nonUSD = TestDataFactory.createCurrency('EUR');
		List<IM_Grant__c> imGrant = [
			SELECT Id, Bgive_IM_Connection__c, Funded_By_Multiple_Initiatives__c
			FROM IM_Grant__c
			WHERE Id = :budgetGrant[0].IM_Grant__c
		];
		imGrant[0].Currency__c = nonUSD.Id;
		imGrant[0].Funded_By_Multiple_Initiatives__c = 'No';
		update imGrant;
        
        List<IM_Budget__c> updatedBudget = [
			SELECT Include_Foreign_Currency__c
			FROM IM_Budget__c
			WHERE Initiative__c = :initiative[0].Id
		];
		Test.stopTest();
		Assert.isTrue(updatedBudget[0].Include_Foreign_Currency__c);
	}
}