@isTest
public with sharing class IMGrantServiceTest {

	private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{ 'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c' });
	private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
	private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));

	private static String colsGrant = EncodingUtil.urlEncode(
		'["funded_by_multiple_initiatives","amount_recommended_local","fx_type_id","brm_id","program_organization_id","bgive_im_connection","locked_by_id"]',
		'UTF-8'
	);
	private static String colsModify = EncodingUtil.urlEncode(
		'["contig_id","state","amount_recommended_local","project_title_internal","grant_begins_at","grant_closed_at","program_organization_id","program_org_name"]',
		'UTF-8'
	);
	private static String colsPayment = EncodingUtil.urlEncode('["id","contig_id","migrate_id","amount_due_local","amount_paid_local"]', 'UTF-8');
	private static String colsRelation = EncodingUtil.urlEncode('{"request_id":["foundation_initiatives"]}', 'UTF-8');

	@TestSetup
	static void setup() {
        insert new Bypass_Automation_Setting__c(Foundation_Code_Trigger__c=true);
        TestDataFactory.createInitiativeBaseData();
		Account org = TestDataFactory.createOrg('Test org');
        
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Air', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Air', budgetedInitiative.Id, 'Component', 'Pending Approval');
		
        IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, null, partner.Id, null);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
	}

	@isTest
	public static void testSyncBgiveManaged() {

		// Combine queries to reduce SOQL count
		List<IM_Initiative__c> initiatives = [
			SELECT Id, Name, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c
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
		update initiative;

        List<IM_Grant__c> imGrants = [
			SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c
			FROM IM_Grant__c
			LIMIT 1
		];
		imGrants[0].Bgive_IM_Connection__c = 'Bgive Managed';
		imGrants[0].Bgive_Id__c = '123456';
		imGrants[0].Bgive_Contig_Id__c = '1234';
		update imGrants[0];

		String cols = EncodingUtil.urlEncode(
			'["id","brm_id","contig_id","state","funded_by_multiple_initiatives","bgive_im_connection","project_title_internal","grant_begins_at","grant_closed_at","program_organization_id","program_org_name"]',
			'UTF-8'
		);

		String colsAmendment = EncodingUtil.urlEncode(
			'["id","request_id","state","original"]',
			'UTF-8'
		);

		String colsAmendmentModify = EncodingUtil.urlEncode(
			'["id","bgive_im_connection"]',
			'UTF-8'
		);

		String mockFetchResponse = '{"grant_request":{';
		mockFetchResponse += '"id":"123456",';
		mockFetchResponse += '"state":"draft",';
		mockFetchResponse += '"program_organization_id":9014,';
		mockFetchResponse += '"contig_id":"1234",';
		mockFetchResponse += '"brm_id":"",';
		mockFetchResponse += '"funded_by_multiple_initiatives":"No",';
		mockFetchResponse += '"bgive_im_connection":"Bgive Managed",';
		mockFetchResponse += '"project_title_internal":"Test title",';
		mockFetchResponse += '"grant_begins_at":"2025-01-01T00:00:00",';
		mockFetchResponse += '"grant_closed_at":"2025-12-31T00:00:00",';
		mockFetchResponse += '"program_org_name":"Test Org"';
		mockFetchResponse += '}}';

		String mockModifyResponse = '{"grant_request":{';
		mockModifyResponse += '"id":"123456",';
		mockModifyResponse += '"state":"draft",';
		mockModifyResponse += '"program_organization_id":9014,';
		mockModifyResponse += '"funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '"bgive_im_connection":"Bgive Managed",';
		mockModifyResponse += '"project_title_internal":"Test title",';
		mockModifyResponse += '"brm_id":"' + imGrants[0].Id + '",';
		mockModifyResponse += '"contig_id":"1234",';
		mockModifyResponse += '"grant_begins_at":"2025-01-01T00:00:00",';
		mockModifyResponse += '"grant_closed_at":"2025-12-31T00:00:00",';
		mockModifyResponse += '"program_org_name":"Test Org",';
		mockModifyResponse += '"amount_recommended_local":300000';
		mockModifyResponse += '}}';

		String mockResponseBody = '{"records":';
		mockResponseBody += '{"request_amendment":';
		mockResponseBody += '[{';
		mockResponseBody += '    "id":"34567",';
		mockResponseBody += '    "bgive_im_connection":"Bgive Managed"';
		mockResponseBody += ' }]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';

		Map<String, Object> data = new Map<String, Object>();
		data.put('brm_id', imGrants[0].id);
		data.put('bgive_im_connection', 'Bgive Managed');
		data.put('funded_by_multiple_initiatives', 'No');
		data.put('updated_by_id', FLUXX_USER_ID);
		String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

		Map<String, Object> dataMapAmendment = new Map<String, Object>();
		dataMapAmendment.put('bgive_im_connection', 'Bgive Managed');
		dataMapAmendment.put('updated_by_id', FLUXX_USER_ID);
		String dataMapAmendmentStr = EncodingUtil.urlEncode(JSON.serialize(dataMapAmendment), 'UTF-8');

		String filter = '{"group_type":"and","conditions":[["request_id","eq","123456"],["state","not-eq","approved"],["state","not-eq","declined"],["state","not-eq","rejected"],["original","eq","0"]]}';
		String amendmentFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

		String amendmentSort = EncodingUtil.urlEncode('[["created_at","asc"]]', 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?cols=' + cols,
			HttpMockRegistry.createSuccessResponse(mockFetchResponse)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?data=' + dataMap + '&cols=' + cols,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_amendment?page=1&per_page=20&cols=' + colsAmendment + '&filter=' + amendmentFilter + '&sort=' + amendmentSort,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_amendment/34567?data=' + dataMapAmendmentStr + '&cols=' + colsAmendmentModify,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		Test.startTest();
		IMGrantService.sync(imGrants[0].Id, 'Bgive Managed');
		Test.stopTest();
		
		IM_Grant__c imGrantUpdated = [
			SELECT Id, Bgive_Status__c, Bgive_Id__c, Bgive_Contig_Id__c
			FROM IM_Grant__c
			WHERE Id = :imGrants[0].Id
			LIMIT 1
		];
		
		Assert.areEqual('123456', imGrantUpdated.Bgive_Id__c, 'Bgive_Id__c should be updated');
		Assert.areEqual('1234', imGrantUpdated.Bgive_Contig_Id__c, 'Bgive_Contig_Id__c should be updated');
	}

	@isTest
	public static void testSyncIMManaged() {
		Fund__c fund = TestDataFactory.createFund('Personal');

		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air'];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];

		IM_Initiative__c initiative = [
			SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
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
			'","model_theme_id": "BP Grant/SPA","bbg_department_on_behalf_of": "78BF - Philanthropies","request_type": "Grant","state": "Draft","type_of_support": "Mission Support","grant_agreement_required": "No","type_of_agreement": "","is_this_grant_restricted": "Restricted","political_campaign_expenses": "No","lobbying_advocacy": "No"},"request_transaction": [{"id":0,"amount_due_local":300000,"due_at":"2025-07-29","fund":"' +
			fund.Id +
			'","gl_account":"BP-000000","is_this_payment_restricted":"Restricted","isFundingPartnerRequired":false,"partnerFundDisabled":true,"request_id":"","state":"new","type_of_payment":"Pending","type_of_support":"Mission Support"}]}';
		update imGrants[0];

		String mockResponseBody = '{"records":';
		mockResponseBody += '{"request_transaction":';
		mockResponseBody += '[{';
		mockResponseBody += '    "id":"123456",';
		mockResponseBody += '    "migrate_id":"123456_0",';
		mockResponseBody += '    "amount_due_local":"300000",';
		mockResponseBody += '    "contig_id":"1234",';
		mockResponseBody += '    "request_id":[{"id":"123456","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockResponseBody += ' }]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';

		String mockModifyResponse = '{"grant_request":';
		mockModifyResponse += '{';
		mockModifyResponse += '    "id":"123456",';
		mockModifyResponse += '    "state":"draft",';
		mockModifyResponse += '    "program_organization_id":9014,';
		mockModifyResponse += '    "funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '    "bgive_im_connection":"IM Managed",';
		mockModifyResponse += '    "project_title_internal":"Test title",';
        mockModifyResponse += '		"grant_begins_at":"2025-01-01T00:00:00",';
		mockModifyResponse += '		"grant_closed_at":"2025-12-31T00:00:00",';
		mockModifyResponse += '    "brm_id":"' + imGrants[0].Id + '",';
		mockModifyResponse += '    "contig_id":"1234"';
		mockModifyResponse += ' }';
		mockModifyResponse += '    }';

		String mockGrantResponse = '{"records":';
		mockGrantResponse += '{"grant_request":';
		mockGrantResponse += '[{';
		mockGrantResponse += '    "id":"123456",';
		mockGrantResponse += '    "state":"draft",';
		mockGrantResponse += '    "program_organization_id":"9014",';
		mockGrantResponse += '    "contig_id":"1234",';
		mockGrantResponse += '    "brm_id":"' + imGrants[0].Id + '"';
		mockGrantResponse += ' }]';
		mockGrantResponse += '    }';
		mockGrantResponse += '    }';
        
        // New Map
        Map<String, Object> dataGrant = new Map<String, Object>();
        dataGrant.put('funded_by_multiple_initiatives', 'No');
		dataGrant.put('amount_recommended_local', 0.00);
		dataGrant.put('fx_type_id', '');
		dataGrant.put('brm_id', imGrants[0].Id);
		dataGrant.put('program_organization_id', null);
		dataGrant.put('bgive_im_connection', 'IM Managed');
		dataGrant.put('updated_by_id', FLUXX_USER_ID);
		String dataMapGrantFetch = EncodingUtil.urlEncode(JSON.serialize(dataGrant), 'UTF-8');

		Map<String, Object> dataPayments = new Map<String, Object>();
		dataPayments.put('fx_type_id', '');
		dataPayments.put('funded_by_multiple_initiatives', 'No');
		dataPayments.put('bgive_im_connection', 'IM Managed');
		dataPayments.put('amount_recommended_local', 0);
		dataPayments.put('program_organization_id', null);
		dataPayments.put('amount_requested_local', 0);
		dataPayments.put('updated_by_id', FLUXX_USER_ID);
		String dataMapPayments = EncodingUtil.urlEncode(JSON.serialize(dataPayments), 'UTF-8');

		Map<String, Object> dataPaymentsCreate = new Map<String, Object>();
		dataPaymentsCreate.put('amount_due_local', 300000);
		dataPaymentsCreate.put('due_at', '2025-07-29');
		dataPaymentsCreate.put('fund', 'Personal');
		dataPaymentsCreate.put('gl_account', 'BP-000000');
		dataPaymentsCreate.put('is_this_payment_restricted', 'Restricted');
		dataPaymentsCreate.put('request_id', '123456');
		dataPaymentsCreate.put('state', 'new');
		dataPaymentsCreate.put('type_of_payment', 'Pending');
		dataPaymentsCreate.put('type_of_support', 'Mission Support');
		dataPaymentsCreate.put('migrate_id', '123456_0');
		dataPaymentsCreate.put('updated_by_id', FLUXX_USER_ID);
		dataPaymentsCreate.put('created_by_id', FLUXX_USER_ID);
		String dataMapPaymentsCreate = EncodingUtil.urlEncode(JSON.serialize(dataPaymentsCreate), 'UTF-8');

		String colsPaymentCreate = EncodingUtil.urlEncode('["id","contig_id"]', 'UTF-8');

		String filter = '{"group_type":"and","conditions":[["brm_id","starts_with","' + String.valueOf(imGrants[0].Id) + '"]]}';
		String grantFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

		String filterPayments = '{"group_type":"and","conditions":[["request_id","eq","123456"]]}';
		String paymentFilter = EncodingUtil.urlEncode(filterPayments, 'UTF-8');
        
		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?page=1&per_page=50&cols=' + colsPayment + '&relation=' + colsRelation + '&filter=' + paymentFilter,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request?page=1&per_page=20&cols=' + colsGrant + '&filter=' + grantFilter,
			HttpMockRegistry.createSuccessResponse(mockGrantResponse)
		);
      
        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?data=' + dataMapGrantFetch + '&cols=' + colsModify,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?data=' + dataMapPaymentsCreate + '&cols=' + colsPaymentCreate,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		Test.startTest();
		IMGrantService.sync(imGrants[0].Id, Assets.SINGLE_CREATE);
		Test.stopTest();
		List<IM_Grant__c> imGrantsUpdated = [
			SELECT Id, Bgive_Status__c, Bgive_Id__c, Bgive_Contig_Id__c
			FROM IM_Grant__c
		];
		Assert.areEqual('123456', imGrantsUpdated[0].Bgive_Id__c);
		Assert.areEqual('1234', imGrantsUpdated[0].Bgive_Contig_Id__c);
	}

	@isTest
	public static void testSyncIMManagedPartial() {
		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air'];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];

		IM_Initiative__c initiative = [
			SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;

		initiative.Bgive_Id__c = '1234';
		update initiative;
		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Funded_By_Multiple_Initiatives__c = 'Yes';
		imGrants[0].Bgive_Id__c = '123456';
		update imGrants[0];
		String mockResponseBody = '{"records":';
		mockResponseBody += '{"request_transaction":';
		mockResponseBody += '[{';
		mockResponseBody += '    "id":"123456",';
		mockResponseBody += '    "migrate_id":"123456_0",';
		mockResponseBody += '    "amount_due_local":"300000",';
		mockResponseBody += '    "contig_id":"1234",';
		mockResponseBody += '    "request_id":[{"id":"123456","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockResponseBody += ' }]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';

		String mockAllocationResponse = '{"mac_model_type_dyn_allocation":';
		mockAllocationResponse += '{';
		mockAllocationResponse += '    "id":"123456",';
		mockAllocationResponse += '    "contig_id":"1234"';
		mockAllocationResponse += ' }';
		mockAllocationResponse += '    }';

		String mockGrantResponse = '{"records":';
		mockGrantResponse += '{"grant_request":';
		mockGrantResponse += '[{';
		mockGrantResponse += '    "id":"123456",';
		mockGrantResponse += '    "state":"draft",';
		mockGrantResponse += '    "program_organization_id":"9014",';
		mockGrantResponse += '    "contig_id":"1234",';
		mockGrantResponse += '    "brm_id":"' + imGrants[0].Id + '"';
		mockGrantResponse += ' }]';
		mockGrantResponse += '    }';
		mockGrantResponse += '    }';

		String mockModifyResponse = '{"grant_request":';
		mockModifyResponse += '{';
		mockModifyResponse += '    "id":"123456",';
		mockModifyResponse += '    "state":"draft",';
		mockModifyResponse += '    "program_organization_id":9014,';
		mockModifyResponse += '    "funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '    "bgive_im_connection":"IM Managed",';
		mockModifyResponse += '    "project_title_internal":"Test title",';
        mockModifyResponse += '    "program_org_name":"Test Org",';
		mockModifyResponse += '    "brm_id":"' + imGrants[0].Id + '",';
		mockModifyResponse += '    "contig_id":"1234"';
		mockModifyResponse += ' }';
		mockModifyResponse += '    }';

		String mockResponseInitiative = '{"records":';
		mockResponseInitiative += '{"concept_initiative":';
		mockResponseInitiative += '[{';
		mockResponseInitiative += '    "id":"123456",';
		mockResponseInitiative += '    "migrate_id":"123456_0",';
		mockResponseInitiative += '    "amount_due_local":"300000",';
		mockResponseInitiative += '    "contig_id":"1234",';
		mockResponseInitiative += '    "request_id":[{"id":"123456","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockResponseInitiative += ' }]';
		mockResponseInitiative += '    }';
		mockResponseInitiative += '    }';

		Map<String, Object> paymentAllocation = new Map<String, Object>();
		paymentAllocation.put('id', '123456');
		List<String> listStr = new List<String>();
		listStr.add('Test Initiative');
		Map<String, Object> dataAllocation = new Map<String, Object>();
		dataAllocation.put('payment_allocation_relationship', paymentAllocation);
		dataAllocation.put('amount_allocated', '300000');
		dataAllocation.put('migrate_id', '123456_123456');
		dataAllocation.put('foundation_initiatives', listStr);
		dataAllocation.put('updated_by_id', FLUXX_USER_ID);
		dataAllocation.put('created_by_id', FLUXX_USER_ID);
		String dataMapAllocation = EncodingUtil.urlEncode(JSON.serialize(dataAllocation), 'UTF-8');

		Map<String, Object> data = new Map<String, Object>();	
		data.put('funded_by_multiple_initiatives', 'Yes');
		data.put('amount_recommended_local', 0.00);
		data.put('fx_type_id', '');
		data.put('brm_id', imGrants[0].Id);
		data.put('program_organization_id', null);
		data.put('bgive_im_connection', 'IM Managed');
		data.put('updated_by_id', FLUXX_USER_ID);
		String dataMapGrant = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

		String colsAllocation = EncodingUtil.urlEncode('["id","contig_id","migrate_id"]', 'UTF-8');
		String colsAllocationRelation = EncodingUtil.urlEncode('{"payment_allocation_relationship":["id"]}', 'UTF-8');
		String colsAllocationCreate = EncodingUtil.urlEncode('["id","contig_id"]', 'UTF-8');

		String filter = '{"group_type":"and","conditions":[["brm_id","starts_with","' + String.valueOf(imGrants[0].Id) + '"]]}';
		String grantFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

		String filterPayments = '{"group_type":"and","conditions":[["request_id","eq","123456"]]}';
		String paymentFilter = EncodingUtil.urlEncode(filterPayments, 'UTF-8');

		String filterAllocation = '{"group_type":"or","conditions":[["payment_allocation_relationship","eq","123456"]]}';
		String allocationFilter = EncodingUtil.urlEncode(filterAllocation, 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?page=1&per_page=50&cols=' + colsPayment + '&relation=' + colsRelation + '&filter=' + paymentFilter,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/mac_model_type_dyn_allocation?page=1&per_page=50&cols=' +
				colsAllocation +
				'&relation=' +
				colsAllocationRelation +
				'&filter=' +
				allocationFilter,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/mac_model_type_dyn_allocation?data=' + dataMapAllocation + '&cols=' + colsAllocationCreate,
			HttpMockRegistry.createSuccessResponse(mockAllocationResponse)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request?page=1&per_page=20&cols=' + colsGrant + '&filter=' + grantFilter,
			HttpMockRegistry.createSuccessResponse(mockGrantResponse)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?data=' + dataMapGrant + '&cols=' + colsModify,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		Test.startTest();
		IMGrantService.sync(imGrants[0].Id, Assets.PARTIAL_FIRST_ALLOCATION);
		Test.stopTest();
		List<IM_Grant__c> imGrantsUpdated = [
			SELECT Id, Sync_Error__c
			FROM IM_Grant__c
		];
		Assert.areEqual(null, imGrantsUpdated[0].Sync_Error__c);
	}
    
    @isTest
	public static void testIMManagedPartialSubsequent() {
		Fund__c fund = TestDataFactory.createFund('Personal');

		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air'];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];

		IM_Initiative__c initiative = [
			SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;

		initiative.Bgive_Id__c = '1234';
		update initiative;
		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
        imGrants[0].Funded_By_Multiple_Initiatives__c = 'Yes';
		imGrants[0].Data_JSON__c =
			'{"IM_Grant__c": {"initiative_relationship": "' +
			initiative.Bgive_Id__c +
			'","foundation_initiatives": "' +
			initiative.Foundation_Code__r.Foundation_Code__c +
			'","model_theme_id": "BP Grant/SPA","bbg_department_on_behalf_of": "78BF - Philanthropies","request_type": "Grant","state": "Draft","type_of_support": "Mission Support","grant_agreement_required": "No","type_of_agreement": "","is_this_grant_restricted": "Restricted","political_campaign_expenses": "No","lobbying_advocacy": "No"},"request_transaction": [{"id":0,"amount_due_local":300000,"due_at":"2025-07-29","fund":"' +
			fund.Id +
			'","gl_account":"BP-000000","is_this_payment_restricted":"Restricted","isFundingPartnerRequired":false,"partnerFundDisabled":true,"request_id":"","state":"new","type_of_payment":"Pending","type_of_support":"Mission Support"}]}';
		update imGrants[0];

		String mockModifyResponse = '{"grant_request":';
		mockModifyResponse += '{';
		mockModifyResponse += '    "id":"123456",';
		mockModifyResponse += '    "state":"draft",';
		mockModifyResponse += '    "program_organization_id":9014,';
		mockModifyResponse += '    "funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '    "bgive_im_connection":"IM Managed",';
		mockModifyResponse += '    "project_title_internal":"Test title",';
        mockModifyResponse += '		"grant_begins_at":"2025-01-01T00:00:00",';
		mockModifyResponse += '		"grant_closed_at":"2025-12-31T00:00:00",';
		mockModifyResponse += '    "brm_id":"' + imGrants[0].Id + '",';
		mockModifyResponse += '    "contig_id":"1234"';
		mockModifyResponse += ' }';
		mockModifyResponse += '    }';

		String mockGrantResponse = '{"records":';
		mockGrantResponse += '{"grant_request":';
		mockGrantResponse += '[{';
		mockGrantResponse += '    "id":"123456",';
		mockGrantResponse += '    "state":"draft",';
		mockGrantResponse += '    "program_organization_id":"9014",';
		mockGrantResponse += '    "contig_id":"1234",';
		mockGrantResponse += '    "brm_id":"' + imGrants[0].Id + '"';
		mockGrantResponse += ' }]';
		mockGrantResponse += '    }';
		mockGrantResponse += '    }';
        
        Map<String, Object> data = new Map<String, Object>();
		data.put('funded_by_multiple_initiatives', 'Yes');
		data.put('amount_recommended_local', 0.00);
		data.put('fx_type_id', '');
		data.put('brm_id', imGrants[0].Id);
		data.put('program_organization_id', null);
		data.put('bgive_im_connection', 'IM Managed');
		data.put('updated_by_id', FLUXX_USER_ID);
		String dataMapGrant = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

		String filter = '{"group_type":"and","conditions":[["brm_id","starts_with","' + String.valueOf(imGrants[0].Id) + '"]]}';
		String grantFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request?page=1&per_page=20&cols=' + colsGrant + '&filter=' + grantFilter,
			HttpMockRegistry.createSuccessResponse(mockGrantResponse)
		);
        
        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?data=' + dataMapGrant + '&cols=' + colsModify,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		Test.startTest();
		IMGrantService.sync(imGrants[0].Id, Assets.PARTIAL_SUBSEQUENT_ALLOCATION);
		Test.stopTest();
		List<IM_Grant__c> imGrantsUpdated = [
			SELECT Id, Bgive_Status__c, Bgive_Id__c, Bgive_Contig_Id__c
			FROM IM_Grant__c
		];
		Assert.areEqual('123456', imGrantsUpdated[0].Bgive_Id__c);
		Assert.areEqual('1234', imGrantsUpdated[0].Bgive_Contig_Id__c);
	}

	@isTest
	public static void testSyncPartialException() {
		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air'];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];

		IM_Initiative__c initiative = [
			SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;

		initiative.Bgive_Id__c = '1234';
		update initiative;
		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Funded_By_Multiple_Initiatives__c = 'Yes';
		imGrants[0].Bgive_Id__c = '123456';
		update imGrants[0];

		String mockModifyResponse = '{"grant_request":';
		mockModifyResponse += '{';
		mockModifyResponse += '    "id":"123456",';
		mockModifyResponse += '    "state":"draft",';
		mockModifyResponse += '    "program_organization_id":"9014",';
		mockModifyResponse += '    "funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '    "bgive_im_connection":"IM Managed",';
		mockModifyResponse += '    "project_title_internal":"Test title",';
		mockModifyResponse += '    "brm_id":"' + imGrants[0].Id + '",';
		mockModifyResponse += '    "contig_id":"1234"';
		mockModifyResponse += ' }';
		mockModifyResponse += '    }';

		Map<String, Object> data = new Map<String, Object>();
		data.put('amount_requested_local', 0);
		data.put('updated_by_id', FLUXX_USER_ID);
		String dataMapGrant = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?data=' + dataMapGrant + '&cols=' + colsGrant,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		Test.startTest();
		try{
			IMGrantService.sync(imGrants[0].Id, Assets.PARTIAL_FIRST_ALLOCATION);
		}catch(Exception e){
			Assert.areEqual(true, String.isNotBlank(e.getMessage()));
		}
		Test.stopTest();
	}

	@isTest
	public static void testGetBgiveGrantUsingContigId() {
		String cols = EncodingUtil.urlEncode(
			'["id","state","program_organization_id","brm_id","contig_id","program_id","program_org_name","amount_recommended_local","funded_by_multiple_initiatives","bgive_im_connection","project_title_internal","grant_begins_at","grant_closed_at","fx_type_id","granted"]',
			'UTF-8'
		);

		BGiveFilterCondition contigIdCondition = new BGiveFilterCondition('contig_id', BGiveFilterCondition.Operator.EQ, '1234');
		BGiveApiFilter filter = new BGiveApiFilter();
		filter.addCondition(contigIdCondition);
		String filterCondition = EncodingUtil.urlEncode(filter.getFilterString(), 'UTF-8');

		String mockResponseBody = '{"records":';
		mockResponseBody += '{"grant_request":';
		mockResponseBody += '[{';
		mockResponseBody += '    "id":"123456",';
		mockResponseBody += '    "state":"draft",';
		mockResponseBody += '    "program_organization_id":"9014",';
		mockResponseBody += '    "contig_id":"1234",';
		mockResponseBody += '    "brm_id":""';
		mockResponseBody += ' }]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';
		Test.startTest();

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request?page=1&per_page=20&cols=' + cols + '&filter=' + filterCondition,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		Map<String, Object> grantrequest = IMGrantService.getBgiveGrantUsingContigId('1234');

		Test.stopTest();
		Assert.areEqual('1234', grantrequest.get('contig_id'));
	}

	@isTest
	public static void testUnlink() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];
		// Combine queries to reduce SOQL count
		List<IM_Initiative__c> initiatives = [
			SELECT Id, Name, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c
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
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;
		initiative.Bgive_Id__c = '1234';
		update initiative;
		List<IM_Budget_Grant__c> budgetGrant = [
			SELECT Id, IM_Grant__c, Budget_Amount_USD__c
			FROM IM_Budget_Grant__c
			LIMIT 1
		];

		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c, Budget_Amount_USD__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Bgive_Id__c = '123456';
		update imGrants;
		String cols = EncodingUtil.urlEncode('["id","brm_id","bgive_im_connection","marked_for_decline","marked_for_delete"]', 'UTF-8');

		Map<String, Object> data = new Map<String, Object>();
		data.put('brm_id', '');
		data.put('bgive_im_connection', new List<String>{});
		data.put('updated_by_id', FLUXX_USER_ID);
		String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

		String mockResponseBody = '{"grant_request":';
		mockResponseBody += '{';
		mockResponseBody += '    "id":"123456",';
		mockResponseBody += '    "state":"draft",';
		mockResponseBody += '    "program_organization_id":"9014",';
		mockResponseBody += '    "funded_by_multiple_initiatives":"No",';
		mockResponseBody += '    "bgive_im_connection":"IM Managed",';
		mockResponseBody += '    "project_title_internal":"Test title",';
		mockResponseBody += '    "brm_id": "",';
		mockResponseBody += '    "contig_id":"1234"';
		mockResponseBody += ' }';
		mockResponseBody += '    }';

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?data=' + dataMap + '&cols=' + cols,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);
		Test.startTest();
		IMGrantService.unlink(imGrants[0], budgetGrant[0], 'Unlink');
		Test.stopTest();
		List<IM_Grant__c> imGrantsUpdated = [
			SELECT Id, Bgive_Id__c, Deleted__c
			FROM IM_Grant__c
		];
		Assert.areEqual(false, imGrantsUpdated[0].Deleted__c);
	}

	@isTest
	public static void testUnlinkZeroAmount() {
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];
		List<IM_Initiative__c> initiatives = [
			SELECT Id, Name, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c
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
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;

		initiative.Bgive_Id__c = '1234';
		update initiative;

		List<IM_Budget_Grant__c> budgetGrant = [
			SELECT Id, IM_Grant__c, Budget_Amount_USD__c
			FROM IM_Budget_Grant__c
			LIMIT 1
		];
		budgetGrant[0].Budget_Amount_USD__c = 0;
		update budgetGrant[0];

		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c, Budget_Amount_USD__c FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Bgive_Id__c = '123456';
		update imGrants;

		String cols = EncodingUtil.urlEncode('["id","brm_id","bgive_im_connection","marked_for_decline","marked_for_delete"]', 'UTF-8');

		Map<String, Object> data = new Map<String, Object>();
		data.put('brm_id', '');
		data.put('bgive_im_connection', new List<String>{});
		Datetime myDateTime = datetime.now();
		String markedForFields = myDateTime.format('yyyy/MM/dd') + ', ' + UserInfo.getUserEmail();
		data.put('marked_for_delete', markedForFields);
		data.put('updated_by_id', FLUXX_USER_ID);
		String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

		String mockResponseBody = '{"grant_request":';
		mockResponseBody += '{';
		mockResponseBody += '    "id":"123456",';
		mockResponseBody += '    "state":"draft",';
		mockResponseBody += '    "program_organization_id":"9014",';
		mockResponseBody += '    "funded_by_multiple_initiatives":"No",';
		mockResponseBody += '    "bgive_im_connection":"IM Managed",';
		mockResponseBody += '    "project_title_internal":"Test title",';
		mockResponseBody += '    "brm_id": "",';
		mockResponseBody += '    "contig_id":"1234"';
		mockResponseBody += ' }';
		mockResponseBody += '    }';

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?data=' + dataMap + '&cols=' + cols,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);
		Test.startTest();
		IMGrantService.unlink(imGrants[0], budgetGrant[0], 'Delete');
		Test.stopTest();
		List<IM_Grant__c> imGrantsUpdated = [
			SELECT Id, Bgive_Id__c, Deleted__c
			FROM IM_Grant__c
		];
		Assert.areEqual(true, imGrantsUpdated[0].Deleted__c);
	}

	@isTest
	public static void testSyncFromBgive() {
		Fund__c fund = TestDataFactory.createFund('Personal');

		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air'];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];

		IM_Initiative__c initiative = [
			SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;

		initiative.Bgive_Id__c = '1234';
		update initiative;
		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c, Bgive_Amount_Local__c, Bgive_Grantee_Name__c, 
										Amendment_Bgive_Id__c, Amendment_Future_End_Date__c, Amendment_Future_Amount_Local__c
										FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Bgive_Id__c = '123456';
		update imGrants[0];

		String mockResponseBody = '{"records":';
		mockResponseBody += '{"request_amendment":';
		mockResponseBody += '[{';
		mockResponseBody += '    "id":"34567",';
		mockResponseBody += '    "bgive_im_connection":"Bgive Managed",';
		mockResponseBody += '    "state":"draft",';
		mockResponseBody += '    "end_date":"2025-12-31T00:00:00",';
		mockResponseBody += '    "amount_recommended_local":1000';
		mockResponseBody += ' }]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';

		String mockModifyResponse = '{"grant_request":';
		mockModifyResponse += '{';
		mockModifyResponse += '    "id":"123456",';
		mockModifyResponse += '    "state":"ongoing",';
		mockModifyResponse += '    "program_organization_id":9014,';
		mockModifyResponse += '    "funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '    "bgive_im_connection":"IM Managed",';
		mockModifyResponse += '    "project_title_internal":"Test title",';
        mockModifyResponse += '		"grant_begins_at":"2025-01-01T00:00:00",';
		mockModifyResponse += '		"grant_closed_at":"2025-12-31T00:00:00",';
		mockModifyResponse += '    "brm_id":"' + imGrants[0].Id + '",';
		mockModifyResponse += '    "contig_id":"1234"';
		mockModifyResponse += ' }';
		mockModifyResponse += '    }';

		String colsRefresh = EncodingUtil.urlEncode('["id","state","program_organization_id","brm_id","contig_id","program_id","program_org_name","amount_recommended_local","funded_by_multiple_initiatives","bgive_im_connection","project_title_internal","grant_begins_at","grant_closed_at","fx_type_id","granted"]', 'UTF-8');

		String colsAmendment = EncodingUtil.urlEncode('["id","request_id","state","original"]', 'UTF-8');

		String filter = '{"group_type":"and","conditions":[["request_id","eq","123456"],["state","not-eq","approved"],["state","not-eq","declined"],["state","not-eq","rejected"],["original","eq","0"]]}';
		String amendmentFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

		String amendmentSort = EncodingUtil.urlEncode('[["created_at","asc"]]', 'UTF-8');

        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_amendment?page=1&per_page=20&cols=' + colsAmendment + '&filter=' + amendmentFilter + '&sort=' + amendmentSort,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);
      
        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?' + 'cols=' + colsRefresh,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		Test.startTest();
		IMGrantService.syncFromBgive(imGrants[0]);
		Test.stopTest();
		List<IM_Grant__c> imGrantsUpdated = [
			SELECT Id, Bgive_Status__c, Bgive_Id__c, Bgive_Contig_Id__c
			FROM IM_Grant__c
		];
		Assert.areEqual('Ongoing', imGrantsUpdated[0].Bgive_Status__c);
	}

	@isTest
	public static void testSyncFromBgiveException() {
		Fund__c fund = TestDataFactory.createFund('Personal');

		IM_Initiative__c parentInitiative = [SELECT Id FROM IM_Initiative__c WHERE Name = 'Clean Air'];
		IM_Budget__c budget = [SELECT Id FROM IM_Budget__c WHERE Name = 'Clean Air'];

		IM_Initiative__c initiative = [
			SELECT Id, Foundation_Code__r.Foundation_Code__c, Bgive_Id__c
			FROM IM_Initiative__c
			WHERE Name = 'Clean Air 1.0'
		];
		initiative.Approved__c = true;
		initiative.Approved_Date__c = System.today();
		initiative.Parent_Initiative__c = parentInitiative.Id;
		initiative.Status__c = 'Ongoing';
		initiative.Current_Budget__c = budget.Id;

		initiative.Bgive_Id__c = '1234';
		update initiative;
		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c, Bgive_IM_Connection__c, Bgive_Id__c, Bgive_Contig_Id__c, Bgive_Amount_Local__c, Bgive_Grantee_Name__c, 
										Amendment_Bgive_Id__c, Amendment_Future_End_Date__c, Amendment_Future_Amount_Local__c
										FROM IM_Grant__c];
		imGrants[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrants[0].Bgive_Id__c = '123456';
		update imGrants[0];

		String mockModifyResponse = '{"grant_request":';
		mockModifyResponse += '{';
		mockModifyResponse += '    "id":"123456",';
		mockModifyResponse += '    "state":"ongoing",';
		mockModifyResponse += '    "program_organization_id":9014,';
		mockModifyResponse += '    "funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '    "bgive_im_connection":"IM Managed",';
		mockModifyResponse += '    "project_title_internal":"Test title",';
        mockModifyResponse += '		"grant_begins_at":"2025-01-01T00:00:00",';
		mockModifyResponse += '		"grant_closed_at":"2025-12-31T00:00:00",';
		mockModifyResponse += '    "brm_id":"' + imGrants[0].Id + '",';
		mockModifyResponse += '    "contig_id":"1234"';
		mockModifyResponse += ' }';
		mockModifyResponse += '    }';

		String colsRefresh = EncodingUtil.urlEncode('["id","state","program_organization_id","brm_id","contig_id","program_id","program_org_name","amount_recommended_local","funded_by_multiple_initiatives","bgive_im_connection","project_title_internal","grant_begins_at","grant_closed_at","fx_type_id","granted"]', 'UTF-8');
      
        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/12345?' + 'cols=' + colsRefresh,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		Test.startTest();
		try{
			IMGrantService.syncFromBgive(imGrants[0]);
		}catch(Exception e){
			Assert.areEqual(true, String.isNotBlank(e.getMessage()));
		}
		Test.stopTest();
	}

	@isTest
	public static void testSyncPartnerWithBGive() {
		// Combine queries to reduce SOQL count
		List<IM_Initiative__c> initiatives = [
			SELECT Id, Name, Approved__c, Approved_Date__c, Parent_Initiative__c, Status__c, Current_Budget__c
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
		List<IM_Budget_Grant__c> budgetGrant = [
			SELECT Id, IM_Grant__c
			FROM IM_Budget_Grant__c
			LIMIT 1
		];
		List<IM_Grant__c> imGrant = [
			SELECT Id, Partner_Org__r.Bgive_Id__c, Bgive_Id__c
			FROM IM_Grant__c
			WHERE Id = :budgetGrant[0].IM_Grant__c
		];
		imGrant[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrant[0].Funded_By_Multiple_Initiatives__c = 'No';
		imGrant[0].Bgive_Id__c = '123456';
		update imGrant;

		String mockModifyResponse = '{"grant_request":{';
		mockModifyResponse += '"id":"123456",';
		mockModifyResponse += '"state":"draft",';
		mockModifyResponse += '"program_organization_id":9014,';
		mockModifyResponse += '"funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '"bgive_im_connection":"Bgive Managed",';
		mockModifyResponse += '"brm_id":"' + imGrant[0].Id + '",';
		mockModifyResponse += '"contig_id":"1234",';
		mockModifyResponse += '"program_org_name":"Test Org",';
		mockModifyResponse += '"amount_recommended_local":300000';
		mockModifyResponse += '}}';

		String cols = EncodingUtil.urlEncode('["id","brm_id","contig_id","program_organization_id","program_org_name"]', 'UTF-8');

		Map<String, Object> data = new Map<String, Object>();
		data.put('program_organization_id', null);
		data.put('updated_by_id', FLUXX_USER_ID);
		String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?data=' + dataMap + '&cols=' + cols,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);

		Test.startTest();
		IMGrantService.syncPartnerWithBGive(imGrant[0].Id);
		Test.stopTest();
		List<IM_Grant__c> imGrantsUpdated = [
			SELECT Id, Bgive_Program_Organization_Id__c
			FROM IM_Grant__c LIMIT 1
		];
		Assert.areEqual('9014', imGrantsUpdated[0].Bgive_Program_Organization_Id__c);
	}
}