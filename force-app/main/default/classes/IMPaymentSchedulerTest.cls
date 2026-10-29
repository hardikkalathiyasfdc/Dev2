/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 06/16/2025
 * Jira        : IM-133 Bgive Payment Section
 * Description : Test class for IMPaymentScheduler
 */
@IsTest
private class IMPaymentSchedulerTest {

	@TestSetup
	static void setup() {
        TestDataFactory.createInitiativeBaseData();
		Account org = TestDataFactory.createOrg('Test org');
		
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
		
        IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Component__c subComponent = TestDataFactory.createSubComponent(budget.Id, component.Id);
		IM_Geography__c geography = TestDataFactory.createGeography(budget.Id);
		IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, subComponent.Id, partner.Id, geography.Id);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
		IM_Funding_Source__c fundingSource = TestDataFactory.createFundingPartner(budget.Id);
		Fund__c fundPartnerBFF = TestDataFactory.createFund('Partner-BFF');
	}

	@IsTest
	private static void getPaymentRows() {
		Test.startTest();

		Fund__c fund = TestDataFactory.createFund('Personal');
		IM_Initiative__c parentInitiative = [
			SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air'
		];

		IM_Initiative__c initiative = [
			SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];

		IM_Budget__c budget = [
			SELECT Id, Name
			FROM IM_Budget__c
			WHERE Name = 'Clean Air'
		];
		initiative.Bgive_Id__c = '1234';
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;
		update initiative;
		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Data_JSON__c =
			'{"IM_Grant__c": {"initiative_relationship": "' +
			initiative.Bgive_Id__c +
			'","foundation_initiatives": "' +
			initiative.Foundation_Code__r.Foundation_Code__c +
			'","model_theme_id": "BP Grant/SPA","bbg_department_on_behalf_of": "78BF - Philanthropies","request_type": "Grant","state": "Draft","type_of_support": "Mission Support","grant_agreement_required": "No","type_of_agreement": "","is_this_grant_restricted": "Restricted","political_campaign_expenses": "No","lobbying_advocacy": "No"},"request_transaction": [{"id":0,"amount_due_local":300000,"due_at":"2025-07-29","fund":"' +
			fund.Id +
			'","gl_account":"BP-000000","is_this_payment_restricted":"Restricted","isFundingPartnerRequired":false,"partnerFundDisabled":true,"request_id":"","state":"new","type_of_payment":"Pending","type_of_support":"Mission Support"}],"totalAmountsMap":{"Gates":0,"Agerup":0,"DFAT":0,"BP":2000000,"TotalGrantAmount":2000000}}';
		update imGrants[0];
		List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c WHERE IM_Grant__c = :imGrants[0].Id];
		IMPaymentScheduler.PaymentScheduleNode result = IMPaymentScheduler.getPaymentRows(
			budgetGrants[0].Id,
			'2025-07-29',
			'2026-07-29',
			fund.Id,
			'Mission Support',
			'No',
			true,
			'2025-07-29', 
			false
		);
		Test.stopTest();
		Assert.areEqual(1, result.allPayments.size());
		Assert.areEqual(2000000, result.totalBpMoney);
		Assert.areEqual(2000000, result.totalGrantMoney);
	}

	@IsTest
	private static void testGetPaymentRows_NoDataJson() {
		Test.startTest();
            Fund__c fundPersonal = TestDataFactory.createFund('Personal');
            IM_Initiative__c parentInitiative = [
                SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
                FROM IM_Initiative__c
                WHERE Name = 'Clean Air'
            ];

            IM_Initiative__c initiative = [
                SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
                FROM IM_Initiative__c
                WHERE Name = 'Clean Air 1.0'
            ];

            IM_Budget__c budget = [
                SELECT Id, Name
                FROM IM_Budget__c
                WHERE Name = 'Clean Air'
            ];
		initiative.Bgive_Id__c = '1234';
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;
		update initiative;
		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		update imGrants[0];
		List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c WHERE IM_Grant__c = :imGrants[0].Id];
		IMPaymentScheduler.PaymentScheduleNode result = IMPaymentScheduler.getPaymentRows(
			budgetGrants[0].Id,
			'2025-07-29',
			'2026-07-29',
			fundPersonal.Id,
			'Mission Support',
			'No',
			true,
			'2025-07-29',
			true
		);
		Test.stopTest();
		Assert.areEqual(2, result.allPayments.size());
		Assert.areEqual(200000.0, result.totalBpMoney);
		Assert.areEqual(200000.0, result.totalGrantMoney);
	}

	@IsTest
	private static void testGetGlAccountLogic() {
		Test.startTest();
		String corpAccount = IMPaymentScheduler.getGlAccount('Corp Internal', null);
		String bpAccount = IMPaymentScheduler.getGlAccount('BP Foundation', null);
		Test.stopTest();
		Assert.areEqual('710000', corpAccount);
		Assert.areEqual('BP-000000', bpAccount);
	}

	@IsTest
	private static void testGetPartnerFunds() {
		Test.startTest();
		List<Fund__c> partnerFundBFF = [SELECT Id FROM Fund__c WHERE Name = 'Partner-BFF'];
		List<Fund__c> partnerFunds = IMPaymentScheduler.getPartnerFunds();
		Test.stopTest();
		Assert.areEqual(1, partnerFunds.size());
		Assert.areEqual(partnerFundBFF[0].Id, partnerFunds[0].Id);
	}
}