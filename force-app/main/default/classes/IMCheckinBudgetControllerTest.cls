/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 05/19/2025
 * Jira        : IM-106 Checkin Budget
 * Description : Test class for IMCheckinBudgetController.
 */
@isTest
private class IMCheckinBudgetControllerTest {
	@TestSetup
	static void setup() {
		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c testBudget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Draft');
		//Funding Source
		IM_Funding_Source__c testFundingSource = TestDataFactory.createFundingPartner(testBudget.Id);
		//Associated Budget Row
		IM_Budget_Row__c budRow = TestDataFactory.createBudgetRow(testBudget.Id);
		//ContentVersion
		ContentVersion contentVersionRec = TestDataFactory.createContentVersion();
		ContentVersion contentVer = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionRec.Id WITH SYSTEM_MODE LIMIT 1];
		Template__c templateRec = TestDataFactory.createTemplate(contentVer.ContentDocumentId);
		//Org
		Account testAcc = TestDataFactory.createOrg('JHU');
		IM_Budget_Org__c budgetOrg = TestDataFactory.createBudgetOrg(testBudget.Id, testAcc.Id);
		//Comp,SubComp,Geo
		IM_Component__c component = TestDataFactory.createComponent(testBudget.Id);
		IM_Component__c subComponent = TestDataFactory.createSubComponent(testBudget.Id, component.Id);
		IM_Geography__c geography = TestDataFactory.createGeography(testBudget.Id);
	}

	@IsTest
	private static void getBudgetTest() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		testBudget.Status__c = 'Approved';
		update as system testBudget;
		IMCheckinBudgetController.BudgetWrapper budwrapper = IMCheckinBudgetController.getBudget(testBudget.Id);
		Assert.isNotNull(budwrapper);
		Test.stopTest();
	}

	@IsTest
	private static void getTotalAmountsByPartnerGates() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		IM_Budget_Row__c budRow = [SELECT Id FROM IM_Budget_Row__c WHERE Budget__c = :testBudget.Id WITH SYSTEM_MODE];
		IM_Funding_Source__c testFundingSource = [SELECT Id FROM IM_Funding_Source__c WHERE Budget__c = :testBudget.Id WITH SYSTEM_MODE];
		//Gates
		budRow.Partner_Fund__c = testFundingSource.Id;
		update as system budRow;
		IMCheckinBudgetController.TotalAmountWrapper totalAmountWrapperGates = IMCheckinBudgetController.getTotalAmountsByPartner(testBudget.Id);
		Assert.isNotNull(totalAmountWrapperGates);
		//Agerup
		testFundingSource.Partner__c = 'Agerup';
		update as system testFundingSource;
		budRow.Partner_Fund__c = testFundingSource.Id;
		update as system budRow;
		IMCheckinBudgetController.TotalAmountWrapper totalAmountWrapperAgerup = IMCheckinBudgetController.getTotalAmountsByPartner(testBudget.Id);
		Assert.isNotNull(totalAmountWrapperAgerup);
		//DFAT
		testFundingSource.Partner__c = 'DFAT';
		update as system testFundingSource;
		budRow.Partner_Fund__c = testFundingSource.Id;
		update as system budRow;
		IMCheckinBudgetController.TotalAmountWrapper totalAmountWrapperDFAT = IMCheckinBudgetController.getTotalAmountsByPartner(testBudget.Id);
		Assert.isNotNull(totalAmountWrapperDFAT);
		//BP Money
		budRow.Partner_Fund__c = null;
		update as system budRow;
		IMCheckinBudgetController.TotalAmountWrapper totalAmountWrapperBp = IMCheckinBudgetController.getTotalAmountsByPartner(testBudget.Id);
		Assert.isNotNull(totalAmountWrapperBp);
		Test.stopTest();
	}

	@IsTest
	private static void getBudgetTemplate() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		ContentVersion contentVer = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'File Name' WITH SYSTEM_MODE LIMIT 1];
		IMCheckinBudgetController.TemplateWrapper templateWrapper = IMCheckinBudgetController.getBudgetTemplate(testBudget.Id, contentVer.ContentDocumentId);
		Assert.isNotNull(templateWrapper);
		Test.stopTest();
	}

	@IsTest
	private static void deleteBudgetFile() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		ContentVersion contentVer = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'File Name' WITH SYSTEM_MODE LIMIT 1];
		Boolean result = IMCheckinBudgetController.deleteBudgetFile(contentVer.ContentDocumentId);
		Assert.isTrue(result);
		Test.stopTest();
	}

	@IsTest
	private static void fetchOrgMapping() {
        IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
        List<String> orgNamesList = new List<String>();
		orgNamesList.add('JHU');
		Test.startTest();
            Map<String, Account> orgMap = IMCheckinBudgetController.fetchOrgMapping(orgNamesList, testBudget.Id);
            Assert.isNotNull(orgMap);
		Test.stopTest();
	}

	@IsTest
	private static void saveBudget() {
		Test.startTest();
		IM_Budget__c testBudget = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Beach 1.0' WITH SYSTEM_MODE];
		Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'JHU' WITH SYSTEM_MODE];
		Map<String, Object> orgMapping = new Map<String, Object>();
		OrgMapping.put(testAccount.Name, (Object) testAccount.Id);
		String partnerFundName = [SELECT Name, Partner__c FROM IM_Funding_Source__c WHERE Budget__c = :testBudget.Id WITH SYSTEM_MODE]?.Name;
		//Comp, SubComp, Geo, Partner, Payee, SubPartner
		List<Object> compList = new List<Object>();
		compList.add('Comp1');
		List<Object> subCompList = new List<Object>();
		subCompList.add('SubComp1');
		List<Object> geoList = new List<Object>();
		geoList.add('Geo1');
		Map<Object, Object> subCompMapping = new Map<Object, Object>();
		subCompMapping.put((Object) 'SubComp1', (Object) 'Comp1');
		List<Object> idList = new List<Object>();
		idList.add(testAccount.Id);
		//Budget Rows
		List<Object> budgetRows = new List<Object>();
		Map<Object, Object> budgetRowfieldMap = new Map<Object, Object>();
		budgetRowfieldMap.put((Object) 'Component__c', (Object) 'Comp1');
		budgetRowfieldMap.put((Object) 'SubComponent__c', (Object) 'SubComp1');
		budgetRowfieldMap.put((Object) 'Partner__c', (Object) 'JHU');
		budgetRowfieldMap.put((Object) 'Sub_Partner__c', (Object) 'JHU');
		budgetRowfieldMap.put((Object) 'Payee_Fiscal_Sponsor__c', (Object) 'JHU');
		budgetRowfieldMap.put((Object) 'Geography__c', (Object) 'Geo1');
		budgetRowfieldMap.put((Object) 'Partner_Fund__c', (Object) partnerFundName);
		budgetRows.add((Object) budgetRowfieldMap);
		//Fill Data Map
		Map<String, Object> dataMap = new Map<String, Object>();
		dataMap.put('Components', (Object) compList);
		dataMap.put('SubComponents', (Object) subCompList);
		dataMap.put('Geographies', (Object) geoList);
		dataMap.put('SubComponentMapping', (Object) subCompMapping);
		dataMap.put('Partners', (Object) idList);
		dataMap.put('SubPartners', (Object) idList);
		dataMap.put('Payee', (Object) idList);
		dataMap.put('OrgMapping', (Object) orgMapping);
		dataMap.put('BudgetRows', budgetRows);
		Boolean result = IMCheckinBudgetController.saveBudget(testBudget.Id, dataMap);
		Assert.isNotNull(result);
		Test.stopTest();
	}
    
    @IsTest
	private static void testGetAccountAKA() {
        Account jhuOrg = [SELECT AKA__C FROM Account WHERE Name = 'JHU' WITH SYSTEM_MODE];
		Test.startTest();
            String akaName = IMCheckinBudgetController.getAccountAKA(jhuOrg.Id);
            Assert.areEqual('JHU', jhuOrg.AKA__c);
		Test.stopTest();
	}
}