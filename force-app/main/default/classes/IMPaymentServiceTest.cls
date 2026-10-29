/**
 * Author      : Sai Bhargav Thotakura
 * Date        : Jun 27th 2025
 * Jira        : IM-134
 * Description : Test Class for IMPaymentService
 */
@IsTest
public class IMPaymentServiceTest {
	private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{ 'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c' });
	private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
	private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));

	private static String colsGrant = EncodingUtil.urlEncode(
		'["fx_type_id","funded_by_multiple_initiatives","brm_id","bgive_im_connection","amount_requested_local","program_organization_id"]',
		'UTF-8'
	);
	private static String colsModify = EncodingUtil.urlEncode(
		'["contig_id","state","amount_recommended_local","project_title_internal","grant_begins_at","grant_closed_at"]',
		'UTF-8'
	);
	private static String colsPayment = EncodingUtil.urlEncode('["id","contig_id","migrate_id","amount_due_local","amount_paid_local"]', 'UTF-8');
	private static String colsRelation = EncodingUtil.urlEncode('{"request_id":["foundation_initiatives"]}', 'UTF-8');

	@TestSetup
	static void setup() {
        insert new Bypass_Automation_Setting__c(Foundation_Code_Trigger__c=true);
		TestDataFactory.createInitiativeBaseData();
		Account org = TestDataFactory.createOrg('JHU');

		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');

		IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, null, partner.Id, null);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
	}

	@isTest
	public static void testcreatePaymentsPartial() {
		Fund__c fund = TestDataFactory.createFund('Personal');
		List<IM_Initiative__c> initiatives = [
			SELECT Id, Name, Bgive_Id__c, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c, Foundation_Code__r.Foundation_Code__c
			FROM IM_Initiative__c
			WHERE Name IN ('Clean Air', 'Clean Air 1.0')
		];
		IM_Initiative__c parentInitiative = null;
		IM_Initiative__c initiative = null;
		for (IM_Initiative__c init : initiatives) {
			if (init.Name == 'Clean Air') {
				parentInitiative = init;
			} else if (init.Name == 'Clean Air 1.0') {
				initiative = init;
			}
		}
		// Combine budget and grant queries
		List<IM_Budget__c> budgets = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
		
		IM_Budget__c budget = budgets.isEmpty() ? null : budgets[0];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;
		initiative.Bgive_Id__c = '1234';
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
			'","gl_account":"BP-000000","is_this_payment_restricted":"Restricted","isFundingPartnerRequired":false,"partnerFundDisabled":true,"request_id":"","state":"new","type_of_payment":"Pending","type_of_support":"Mission Support"}]}';
		update imGrants[0];

		String mockResponseBody = '{"records":';
		mockResponseBody += '{"request_transaction":';
		mockResponseBody += '[{';
		mockResponseBody += '    "id":"1234",';
		mockResponseBody += '    "migrate_id":"123456_0",';
		mockResponseBody += '    "amount_due_local":"300000",';
		mockResponseBody += '    "contig_id":"1234",';
		mockResponseBody += '    "request_id":[{"id":"1234","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockResponseBody += ' }]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';

		String mockCreateResponse = '{"request_transaction":';
		mockCreateResponse += '{';
		mockCreateResponse += '    "id":"1234",';
		mockCreateResponse += '    "migrate_id":"123456_0",';
		mockCreateResponse += '    "amount_due_local":"300000",';
		mockCreateResponse += '    "contig_id":"1234",';
		mockCreateResponse += '    "request_id":[{"id":"1234","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockCreateResponse += ' }';
		mockCreateResponse += '    }';

		Map<String, Object> dataPaymentsCreate = new Map<String, Object>();
		dataPaymentsCreate.put('amount_due_local', 300000);
		dataPaymentsCreate.put('due_at', '2025-07-29');
		dataPaymentsCreate.put('fund', 'Personal');
		dataPaymentsCreate.put('gl_account', 'BP-000000');
		dataPaymentsCreate.put('is_this_payment_restricted', 'Restricted');
		dataPaymentsCreate.put('request_id', '1234');
		dataPaymentsCreate.put('state', 'new');
		dataPaymentsCreate.put('type_of_payment', 'Pending');
		dataPaymentsCreate.put('type_of_support', 'Mission Support');
		dataPaymentsCreate.put('migrate_id', '1234_0');
		dataPaymentsCreate.put('updated_by_id', FLUXX_USER_ID);
		dataPaymentsCreate.put('created_by_id', FLUXX_USER_ID);
		String dataMapPaymentsCreate = EncodingUtil.urlEncode(JSON.serialize(dataPaymentsCreate), 'UTF-8');

		String colsPaymentCreate = EncodingUtil.urlEncode('["id","contig_id"]', 'UTF-8');

		String filterPayments = '{"group_type":"and","conditions":[["request_id","eq","1234"]]}';
		String paymentFilter = EncodingUtil.urlEncode(filterPayments, 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?page=1&per_page=50&cols=' + colsPayment + '&relation=' + colsRelation + '&filter=' + paymentFilter,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?data=' + dataMapPaymentsCreate + '&cols=' + colsPaymentCreate,
			HttpMockRegistry.createSuccessResponse(mockCreateResponse)
		);
		Test.startTest();
		Map<String, Object> dataJsonMap = (Map<String, Object>) JSON.deserializeUntyped(imGrants[0].Data_JSON__c);
		List<Object> paymentsList = (List<Object>) dataJsonMap.get(Assets.BGIVE_PAYMENT_NAME);
		Map<String, Object> result = IMPaymentService.createPayments(initiative.Bgive_Id__c, paymentsList);
		Test.stopTest();
		Assert.areEqual(null, result.get('Data_JSON__c'));
		Assert.areEqual(true, result.get('allPaymentsCreated'));
	}

	@isTest
	public static void testcreatePaymentsAll() {
		Fund__c fund = TestDataFactory.createFund('Personal');
		// Combine queries to reduce SOQL count
		List<IM_Initiative__c> initiatives = [
			SELECT Id, Name, Bgive_Id__c, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c, Foundation_Code__r.Foundation_Code__c
			FROM IM_Initiative__c
			WHERE Name IN ('Clean Air', 'Clean Air 1.0')
		];
		IM_Initiative__c parentInitiative = null;
		IM_Initiative__c initiative = null;
		for (IM_Initiative__c init : initiatives) {
			if (init.Name == 'Clean Air') {
				parentInitiative = init;
			} else if (init.Name == 'Clean Air 1.0') {
				initiative = init;
			}
		}
		// Combine budget and grant queries
		List<IM_Budget__c> budgets = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
		
		IM_Budget__c budget = budgets.isEmpty() ? null : budgets[0];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;
		initiative.Bgive_Id__c = '1234';
		update initiative;

		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Data_JSON__c =
			'{"IM_Grant__c": {"initiative_relationship": "' +
			initiative.Bgive_Id__c +
			'","foundation_initiatives": "' +
			initiative.Foundation_Code__r.Foundation_Code__c +
			'","model_theme_id": "BP Grant/SPA","bbg_department_on_behalf_of": "78BF - Philanthropies","request_type": "Grant","state": "Draft",' +
			'"type_of_support": "Mission Support","grant_agreement_required": "No","type_of_agreement": "","is_this_grant_restricted": "Restricted",' +
			'"political_campaign_expenses": "No","lobbying_advocacy": "No"},"request_transaction": [{"id":0,"amount_due_local":300000,"due_at":"2025-07-29","fund":"' +
			fund.Id +
			'","gl_account":"BP-000000","is_this_payment_restricted":"Restricted","isFundingPartnerRequired":false,"partnerFundDisabled":true,' +
			'"request_id":"","state":"new","type_of_payment":"Pending","type_of_support":"Mission Support"}]}';
		update imGrants[0];

		String mockResponseBody = '{"records":';
		mockResponseBody += '{"request_transaction":';
		mockResponseBody += '[';
		mockResponseBody += ' ]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';

		String mockCreateResponse = '{"request_transaction":';
		mockCreateResponse += '{';
		mockCreateResponse += '    "id":"1234",';
		mockCreateResponse += '    "migrate_id":"123456_0",';
		mockCreateResponse += '    "amount_due_local":"300000",';
		mockCreateResponse += '    "contig_id":"1234",';
		mockCreateResponse += '    "request_id":[{"id":"1234","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockCreateResponse += ' }';
		mockCreateResponse += '    }';

		Map<String, Object> dataPaymentsCreate = new Map<String, Object>();
		dataPaymentsCreate.put('amount_due_local', 300000);
		dataPaymentsCreate.put('due_at', '2025-07-29');
		dataPaymentsCreate.put('fund', 'Personal');
		dataPaymentsCreate.put('gl_account', 'BP-000000');
		dataPaymentsCreate.put('is_this_payment_restricted', 'Restricted');
		dataPaymentsCreate.put('request_id', '1234');
		dataPaymentsCreate.put('state', 'new');
		dataPaymentsCreate.put('type_of_payment', 'Pending');
		dataPaymentsCreate.put('type_of_support', 'Mission Support');
		dataPaymentsCreate.put('migrate_id', '1234_0');
		dataPaymentsCreate.put('updated_by_id', FLUXX_USER_ID);
		dataPaymentsCreate.put('created_by_id', FLUXX_USER_ID);
		String dataMapPaymentsCreate = EncodingUtil.urlEncode(JSON.serialize(dataPaymentsCreate), 'UTF-8');

		String colsPaymentCreate = EncodingUtil.urlEncode('["id","contig_id"]', 'UTF-8');

		String filterPayments = '{"group_type":"and","conditions":[["request_id","eq","1234"]]}';
		String paymentFilter = EncodingUtil.urlEncode(filterPayments, 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?page=1&per_page=50&cols=' + colsPayment + '&relation=' + colsRelation + '&filter=' + paymentFilter,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?data=' + dataMapPaymentsCreate + '&cols=' + colsPaymentCreate,
			HttpMockRegistry.createSuccessResponse(mockCreateResponse)
		);
		Test.startTest();
		Map<String, Object> dataJsonMap = (Map<String, Object>) JSON.deserializeUntyped(imGrants[0].Data_JSON__c);
		List<Object> paymentsList = (List<Object>) dataJsonMap.get(Assets.BGIVE_PAYMENT_NAME);
		Map<String, Object> result = IMPaymentService.createPayments(initiative.Bgive_Id__c, paymentsList);
		Test.stopTest();
		Assert.areEqual(null, result.get('Data_JSON__c'));
		Assert.areEqual(true, result.get('allPaymentsCreated'));
	}

	@isTest
	public static void testcreatePaymentsException() {
		Fund__c fund = TestDataFactory.createFund('Personal');
		List<IM_Initiative__c> initiatives = [
			SELECT Id, Name, Bgive_Id__c, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c, Foundation_Code__r.Foundation_Code__c
			FROM IM_Initiative__c
			WHERE Name IN ('Clean Air', 'Clean Air 1.0')
		];
		IM_Initiative__c parentInitiative = null;
		IM_Initiative__c initiative = null;
		for (IM_Initiative__c init : initiatives) {
			if (init.Name == 'Clean Air') {
				parentInitiative = init;
			} else if (init.Name == 'Clean Air 1.0') {
				initiative = init;
			}
		}
		// Combine budget and grant queries
		List<IM_Budget__c> budgets = [SELECT Id, Name FROM IM_Budget__c WHERE Name = 'Clean Air' LIMIT 1];
		
		IM_Budget__c budget = budgets.isEmpty() ? null : budgets[0];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;
		initiative.Bgive_Id__c = '1234';
		update initiative;

		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Data_JSON__c =
			'{"IM_Grant__c": {"initiative_relationship": "' +
			initiative.Bgive_Id__c +
			'","foundation_initiatives": "' +
			initiative.Foundation_Code__r.Foundation_Code__c +
			'","model_theme_id": "BP Grant/SPA","bbg_department_on_behalf_of": "78BF - Philanthropies","request_type": "Grant","state": "Draft",' +
			'"type_of_support": "Mission Support","grant_agreement_required": "No","type_of_agreement": "","is_this_grant_restricted": "Restricted",' +
			'"political_campaign_expenses": "No","lobbying_advocacy": "No"},"request_transaction": [{"id":0,"amount_due_local":300000,"due_at":"2025-07-29","fund":"' +
			fund.Id +
			'","gl_account":"BP-000000","is_this_payment_restricted":"Restricted","isFundingPartnerRequired":false,"partnerFundDisabled":true,' +
			'"request_id":"","state":"new","type_of_payment":"Pending","type_of_support":"Mission Support"}]}';
		update imGrants[0];

		String mockCreateResponse = '{"request_transaction":';
		mockCreateResponse += '{';
		mockCreateResponse += '    "id":"1234",';
		mockCreateResponse += '    "migrate_id":"123456_0",';
		mockCreateResponse += '    "amount_due_local":"300000",';
		mockCreateResponse += '    "contig_id":"1234",';
		mockCreateResponse += '    "request_id":[{"id":"1234","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockCreateResponse += ' }';
		mockCreateResponse += '    }';

		String filterPayments = '{"group_type":"and","conditions":[["request_id","eq","1234"]]}';
		String paymentFilter = EncodingUtil.urlEncode(filterPayments, 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?page=1&per_page=50&cols=' + colsPayment + '&relation=' + colsRelation + '&filter=' + paymentFilter,
			HttpMockRegistry.createSuccessResponse(mockCreateResponse)
		);

		Test.startTest();
		Map<String, Object> dataJsonMap = (Map<String, Object>) JSON.deserializeUntyped(imGrants[0].Data_JSON__c);
		List<Object> paymentsList = (List<Object>) dataJsonMap.get(Assets.BGIVE_PAYMENT_NAME);
		Map<String, Object> result = IMPaymentService.createPayments(initiative.Bgive_Id__c, paymentsList);
		Test.stopTest();
		Assert.areEqual(true, result.get('Errors') != null);
	}
}