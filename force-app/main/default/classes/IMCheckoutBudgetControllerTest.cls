/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 12/31/2024
 * Jira        : IM-50 Checkout Budget
 * Description : Test class for IMCheckoutBudgetController.
 */
@isTest
public class IMCheckoutBudgetControllerTest {
	@TestSetup
	static void setup() {
        Bypass_Automation_Setting__c bypassSetting = new Bypass_Automation_Setting__c();
		bypassSetting.IM_Budget_Trigger__c  = true;
		insert as system bypassSetting;
        
        TestDataFactory.createInitiativeBaseData();
        
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
        
		//Org
		Account testAcc = TestDataFactory.createOrg('test');
        
		//Associated Budget Records
		IM_Budget_Row__c budRow = TestDataFactory.createBudgetRow(budget.Id);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
		IM_Budget_Org__c budgetOrg = TestDataFactory.createBudgetOrg(budget.Id, testAcc.Id);
        
		//ContentVersion for Template
		ContentVersion contentVersionRec = TestDataFactory.createContentVersion();
		ContentVersion contentVer = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionRec.Id WITH SYSTEM_MODE LIMIT 1];
		Template__c templateRec = TestDataFactory.createTemplate(contentVer.ContentDocumentId);
        
		//Comp,SubComp,Geo
		IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
		IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);

		//Budget and budget row - With different categories
        IM_Budget__c budget2 = TestDataFactory.createBudget('Clean Air 1.0', budgetedInitiative.Id, 'Component, Geography', 'Pending Approval');
		IM_Budget_Row__c budRow2 = TestDataFactory.createBudgetRow(budget2.Id);

		//Budget and budget row - Category2
		IM_Budget__c budget3 = TestDataFactory.createBudget('Clean Air 2.0', budgetedInitiative.Id, 'Component, SubComponent', 'Pending Approval');
		IM_Budget_Row__c budRow3 = TestDataFactory.createBudgetRow(budget3.Id);

		//Budget and budget row - Category3
        IM_Budget__c budget4 = TestDataFactory.createBudget('Clean Air 3.0', budgetedInitiative.Id, 'Component, SubComponent, Geography', 'Pending Approval');
		IM_Budget_Row__c budRow4 = TestDataFactory.createBudgetRow(budget4.Id);

		//Budget and budget row - Category5
        IM_Budget__c budget5 = TestDataFactory.createBudget('Clean Air 4.0', budgetedInitiative.Id, 'Geography', 'Pending Approval');
		IM_Budget_Row__c budRow5 = TestDataFactory.createBudgetRow(budget5.Id);

		//Budget and budget row - Category8
        IM_Budget__c budget6 = TestDataFactory.createBudget('Clean Air 5.0', budgetedInitiative.Id, '', 'Pending Approval');
		IM_Budget_Row__c budRow6 = TestDataFactory.createBudgetRow(budget6.Id);

		//Budget with no Rows attached
		IM_Budget__c budget7 = TestDataFactory.createBudget('Clean Air 6.0', budgetedInitiative.Id, '', 'Draft');
	}

	@isTest
	public static void testGetBudgetTemplate() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
		IMCheckoutBudgetController.TemplateWrapper temwrapper = IMCheckoutBudgetController.getBudgetTemplate(testBudget.Id, 'Initiative Budget');
		Assert.isNotNull(temwrapper);
		Test.stopTest();
	}

	@isTest
	public static void testGetBudgetData() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' WITH SYSTEM_MODE];
		IMCheckoutBudgetController.BudgetWrapper budwrapper = IMCheckoutBudgetController.getBudgetData(testBudget.Id);
		Assert.isNotNull(budwrapper);
		Test.stopTest();
	}

	@isTest
	public static void testGetBudCat1() {
		Test.startTest();
		IM_Budget__c budget2 = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air 1.0' AND Budget_Categories__c = 'Component, Geography' WITH SYSTEM_MODE];
		IMCheckoutBudgetController.BudgetWrapper budwrapper = IMCheckoutBudgetController.getBudgetData(budget2.Id);
		Assert.isNotNull(budwrapper);
		Test.stopTest();
	}

	@isTest
	public static void testGetBudgetDataCat3() {
		Test.startTest();
		IM_Budget__c budget3 = [
			SELECT Id, Name
			FROM IM_Budget__c
			WHERE Name = 'Clean Air 2.0' AND Budget_Categories__c = 'Component, SubComponent'
			WITH SYSTEM_MODE
		];
		IMCheckoutBudgetController.BudgetWrapper budwrapper = IMCheckoutBudgetController.getBudgetData(budget3.Id);
		Assert.isNotNull(budwrapper);
		Test.stopTest();
	}

	@isTest
	public static void testgGetBudgetData4() {
		Test.startTest();
		IM_Budget__c budget4 = [
			SELECT Id, Name
			FROM IM_Budget__c
			WHERE Name = 'Clean Air 3.0' AND Budget_Categories__c = 'Component, SubComponent, Geography'
			WITH SYSTEM_MODE
		];
		IMCheckoutBudgetController.BudgetWrapper budwrapper = IMCheckoutBudgetController.getBudgetData(budget4.Id);
		Assert.isNotNull(budwrapper);
		Test.stopTest();
	}

	@isTest
	public static void testGetBudgetData5() {
		Test.startTest();
		IM_Budget__c budget5 = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air 4.0' AND Budget_Categories__c = 'Geography' WITH SYSTEM_MODE];
		IMCheckoutBudgetController.BudgetWrapper budwrapper = IMCheckoutBudgetController.getBudgetData(budget5.Id);
		Assert.isNotNull(budwrapper);
		Test.stopTest();
	}

	@isTest
	public static void testGetBudgetData8() {
		Test.startTest();
		IM_Budget__c budget8 = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air 5.0' AND Budget_Categories__c = '' WITH SYSTEM_MODE];
		IMCheckoutBudgetController.BudgetWrapper budwrapper = IMCheckoutBudgetController.getBudgetData(budget8.Id);
		Assert.isNotNull(budwrapper);
		Test.stopTest();
	}

	@isTest
	public static void testGetBudgetDataExt() {
		Test.startTest();
		IM_Budget__c budgetExt = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air 6.0' WITH SYSTEM_MODE];
		IMCheckoutBudgetController.BudgetWrapper budwrapper = IMCheckoutBudgetController.getBudgetData(budgetExt.Id);
		Assert.isNotNull(budwrapper);
		Test.stopTest();
	}

	@isTest
	public static void testUpdtBudget() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air 6.0' WITH SYSTEM_MODE];
		Boolean result = IMCheckoutBudgetController.updateBudgetCheckoutFields(testBudget.Id);
		Assert.isNotNull(result);
		Test.stopTest();
	}

	@isTest
	public static void testCheckoutInformation() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air 6.0' WITH SYSTEM_MODE];
		String result = IMCheckoutBudgetController.checkoutInformation(testBudget.Id);
		Assert.isNotNull(result);
		Test.stopTest();
	}
}