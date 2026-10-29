@isTest
public with sharing class IMGrantViewControllerTest {
	private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();

	private static final String BUDGETED_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.BUDGET_INITIATIVE)
		.getRecordTypeId();

	private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{ 'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c', 'Fluxx_Base_URL__c' });
	private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
	private static String FLUXX_BASE_URL = String.valueOf(envAttributeMap.get('Fluxx_Base_URL__c'));
	private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));
	

	private static String colsPayment = EncodingUtil.urlEncode('["id","contig_id","migrate_id","amount_due_local","amount_paid_local"]', 'UTF-8');
	private static String colsRelation = EncodingUtil.urlEncode('{"request_id":["foundation_initiatives"]}', 'UTF-8');

	@testSetup
	static void setup() {
		Account org = TestDataFactory.createOrg('Test org');

		TestDataFactory.createInitiativeBaseData();
		IM_Initiative__c budgetedInitiative = TestDataFactory.createBudgetedInitiative('Clean Beach', 'New');
		IM_Budget__c budget = TestDataFactory.createBudget('Clean Beach 1.0', budgetedInitiative.Id, 'Component', 'Pending Approval');

		IM_Component__c component = TestDataFactory.createComponent(budget.Id);
		IM_Budget_Org__c partner = TestDataFactory.createBudgetOrg(budget.Id, org.Id);
		IM_Budget_Row__c budgetRow = TestDataFactory.createBudgetRowWithData(budget.Id, component.Id, null, partner.Id, null);
		IM_Budget_Period__c budgetPeriod = TestDataFactory.createBudgetPeriods(budget.Id);
	}

	@isTest
	public static void testGetBudgetGrant() {
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
			SELECT Id
			FROM IM_Budget_Grant__c
			LIMIT 1
		];
		IM_Budget_Grant__c createdBudgetGrant = IMGrantViewController.getBudgetGrant(budgetGrant[0].Id);
		Test.stopTest();
		Assert.areEqual(budgetGrant[0].Id, createdBudgetGrant.Id);
	}

	@isTest
	public static void testGetBudgetGrantException() {
		Test.startTest();
		try {
			List<IM_Initiative__c> parentInitiative = [
				SELECT Id
				FROM IM_Initiative__c
				WHERE RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
				LIMIT 1
			];
			IM_Budget_Grant__c createdBudgetGrant = IMGrantViewController.getBudgetGrant(parentInitiative[0].Id);
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
		Test.stopTest();
	}

	@isTest
	public static void testUpdateBudgetGrant() {
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
			SELECT Id, Budget_Amount_USD__c
			FROM IM_Budget_Grant__c
			LIMIT 1
		];
		budgetGrant[0].Budget_Amount_USD__c = 400000;
		IMGrantViewController.updateBudgetGrant(budgetGrant[0]);
		List<IM_Budget_Grant__c> updatedBudgetGrant = [
			SELECT Id, Budget_Amount_USD__c
			FROM IM_Budget_Grant__c
			LIMIT 1
		];
		Test.stopTest();
		Assert.areEqual(400000, updatedBudgetGrant[0].Budget_Amount_USD__c);
	}

	@isTest
	public static void testGetIMGrant() {
		TestDataFactory.createCurrency('USD');
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
		List<IM_Grant__c> createdImGrant = [
			SELECT Id
			FROM IM_Grant__c
			WHERE Id = :budgetGrant[0].IM_Grant__c
		];
		IM_Grant__c imGrant = IMGrantViewController.getIMGrant(budgetGrant[0].IM_Grant__c, true);
		Test.stopTest();
		Assert.areEqual(createdImGrant[0].Id, imGrant.Id);
	}

	@isTest
	public static void testGetIMGrantByBgiveId() {
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
		imGrant[0].Bgive_IM_Connection__c = 'IM Managed';
		imGrant[0].Funded_By_Multiple_Initiatives__c = 'No';
		imGrant[0].Bgive_Id__c = '1234';
		update imGrant;
		IM_Grant__c imGrantByBgiveId = IMGrantViewController.getIMGrantByBgiveId('1234');
		Test.stopTest();
		Assert.areEqual(imGrant[0].Id, imGrantByBgiveId.Id);
	}

	@isTest
	public static void testDeleteIMGrant() {
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
			SELECT Id
			FROM IM_Grant__c
			WHERE Id = :budgetGrant[0].IM_Grant__c
		];
		delete budgetGrant[0];
		IMGrantViewController.deleteIMGrant(imGrant[0]);
		List<IM_Grant__c> deletedImGrant = [
			SELECT Id, Deleted__c
			FROM IM_Grant__c
			WHERE Id = :budgetGrant[0].IM_Grant__c
		];
		Test.stopTest();
		Assert.areEqual(true, deletedImGrant[0].Deleted__c);
	}

	@isTest
	public static void testUpdateIMGrant() {
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
		IMGrantViewController.updateIMGrant(imGrant[0]);
		List<IM_Grant__c> updatedImGrant = [
			SELECT Id, Bgive_IM_Connection__c, Funded_By_Multiple_Initiatives__c
			FROM IM_Grant__c
			WHERE Id = :budgetGrant[0].IM_Grant__c
		];
		Test.stopTest();
		Assert.areEqual('Not Applicable', updatedImGrant[0].Bgive_IM_Connection__c);
		Assert.areEqual('No', updatedImGrant[0].Funded_By_Multiple_Initiatives__c);
	}

	@isTest
	public static void testGetCurrency() {
		TestDataFactory.createCurrency('USD');
		List<Currency__c> currencyRec = [SELECT Id FROM Currency__c LIMIT 1];
		Test.startTest();
		Currency__c currRecord = IMGrantViewController.getCurrency(currencyRec[0].Id);
		List<Currency__c> currencyRecord = [SELECT Id FROM Currency__c LIMIT 1];
		Test.stopTest();
		Assert.areEqual(currencyRec[0].Id, currencyRecord[0].Id);
	}

	@isTest
	public static void testGetCurrencyException() {
		TestDataFactory.createCurrency('USD');
		List<IM_Initiative__c> initiatives = [
			SELECT Id
			FROM IM_Initiative__c
			LIMIT 1
		];
		Test.startTest();
		try {
			Currency__c currRecord = IMGrantViewController.getCurrency(initiatives[0].Id);
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
		Test.stopTest();
	}

	@isTest
	public static void testGetUSDCurrencyException() {
		TestDataFactory.createCurrency('USD');
		List<Currency__c> currencyRec = [SELECT Id FROM Currency__c LIMIT 1];
		delete currencyRec[0];
		Test.startTest();
		try {
			Currency__c currRecord = IMGrantViewController.getUSDCurrency();
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
		Test.stopTest();
	}

	@isTest
	public static void testGetCurrencyByBgiveId() {
		TestDataFactory.createCurrency('USD');
		List<Currency__c> currencyRec = [
			SELECT Id, Bgive_Id__c
			FROM Currency__c
			LIMIT 1
		];
		Test.startTest();
		Currency__c currRecord = IMGrantViewController.getCurrencyByBgiveId('1234');
		List<Currency__c> currencyRecord = [
			SELECT Id, Bgive_Id__c
			FROM Currency__c
			LIMIT 1
		];
		Test.stopTest();
		Assert.areEqual(currencyRec[0].Id, currencyRecord[0].Id);
	}

	@isTest
	public static void testGetCurrencyByBgiveIdException() {
		try {
			TestDataFactory.createCurrency('USD');
			List<Currency__c> currencyRec = [
				SELECT Id, Bgive_Id__c
				FROM Currency__c
				LIMIT 1
			];
			currencyRec[0].Bgive_Id__c = '';
			update currencyRec[0];
			Test.startTest();
			Currency__c currRecord = IMGrantViewController.getCurrencyByBgiveId('1234');
			Test.stopTest();
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
	}

	@isTest
	public static void testGetFiscalSponsor() {
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
		List<IM_Budget_Row__c> budgetRows = [
			SELECT Id, Name
			FROM IM_Budget_Row__c
			WHERE Budget_Grant__c = :budgetGrant[0].Id
		];
		IM_Budget_Row__c budgetRow = IMGrantViewController.getFiscalSponsor(budgetGrant[0].Id);
		Test.stopTest();
		Assert.areEqual(budgetRows[0].Id, budgetRow.Id);
	}

	@isTest
	public static void testGetFund() {
		TestDataFactory.createFund('Personal');
		List<Fund__c> funds = [SELECT Id, Name FROM Fund__c LIMIT 1];
		Test.startTest();
		Fund__c fundRecord = IMGrantViewController.getFund(funds[0].Id);
		Test.stopTest();
		Assert.areEqual(funds[0].Name, fundRecord.Name);
	}

	@isTest
	public static void testGetFundException() {
		try {
			List<IM_Initiative__c> initiatives = [
				SELECT Id
				FROM IM_Initiative__c
				LIMIT 1
			];
			Test.startTest();
			Fund__c fund = IMGrantViewController.getFund(initiatives[0].Id);
			Test.stopTest();
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
	}

	@isTest
	public static void testGetPersonalFund() {
		TestDataFactory.createFund('Personal');
		List<Fund__c> funds = [
			SELECT Id
			FROM Fund__c
			WHERE Name = 'Personal'
			LIMIT 1
		];
		Test.startTest();
		Id fundId = IMGrantViewController.getPersonalFund();
		Test.stopTest();
		Assert.areEqual(funds[0].Id, fundId);
	}

	@isTest
	public static void testGetContact() {
		User userRec = TestDataFactory.createUser('Testing', 'User');
		List<Account> org = [SELECT Id FROM Account LIMIT 1];
		Contact contact = TestDataFactory.createContact(org[0].Id, 'Test Contact');
		contact.Bgive_Id__c = '345';
		contact.BRM_User__c = userRec.Id;
		update contact;
		Test.startTest();
		List<User> user = [
			SELECT Id, FirstName, LastName
			FROM User
			WHERE FirstName = 'Testing'
			LIMIT 1
		];
		Contact contactRec = IMGrantViewController.getContact(user[0].Id);
		List<Contact> contacts = [
			SELECT Id
			FROM Contact
			WHERE BRM_User__c = :user[0].Id
			LIMIT 1
		];
		Test.stopTest();
		Assert.areEqual(contacts[0].Id, contactRec.Id);
	}

	@isTest
	public static void testGetBgiveGrant() {
		BGiveFilterCondition contigIdCondition = new BGiveFilterCondition('contig_id', BGiveFilterCondition.Operator.EQ, '1234');
		BGiveApiFilter filter = new BGiveApiFilter();
		filter.addCondition(contigIdCondition);
		String filterCondition = EncodingUtil.urlEncode(filter.getFilterString(), 'UTF-8');

		String cols = EncodingUtil.urlEncode(
			'["id","state","program_organization_id","brm_id","contig_id","program_id","program_org_name","amount_recommended_local","funded_by_multiple_initiatives","bgive_im_connection","project_title_internal","grant_begins_at","grant_closed_at","fx_type_id","granted"]',
			'UTF-8'
		);

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
		Map<String, Object> grantrequest = IMGrantViewController.getBgiveGrant('1234');
		Test.stopTest();
		Assert.areEqual('1234', grantrequest.get('contig_id'));
	}

	@isTest
	public static void testPushToBGiveException() {
		Test.startTest();
		try {
			IMGrantViewController.pushToBGive('1234', Assets.SINGLE_CREATE);
		} catch (Exception e) {
			Assert.isNotNull(String.valueOf(e));
		}
		Test.stopTest();
	}

	@isTest
	public static void testCreateRequestAmendmentException() {
		Test.startTest();
		try {
			Map<String, Object> amendmentDetails = new Map<String, Object>();
			amendmentDetails.put('amendment_type', 'Grant Amendment');
			amendmentDetails.put('end_date', String.valueOf(Date.today()));
			amendmentDetails.put('amount_recommended_local', '200000');
			amendmentDetails.put('state', 'update');
			amendmentDetails.put('bgive_im_connection', 'IM Managed');
			Map<String, Object> requestAmendment = IMGrantViewController.createRequestAmendment('1234', amendmentDetails);
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
		Test.stopTest();
	}

	@isTest
	public static void testUnlinkGrantsException() {
		Test.startTest();
		try {
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
			List<IM_Grant__c> createdImGrant = [
				SELECT Id
				FROM IM_Grant__c
				WHERE Id = :budgetGrant[0].IM_Grant__c
			];
			IMGrantViewController.unlinkGrant(createdImGrant[0], budgetGrant[0], 'Unlink');
		} catch (Exception e) {
			Assert.areEqual('System.AuraHandledException: Script-thrown exception', String.valueOf(e));
		}
		Test.stopTest();
	}

	@isTest
	public static void testGetPicklistValues() {
		Test.startTest();
		Map<String, List<String>> picklistValues = IMGrantViewController.getPicklistValues();
		Assert.areEqual(true, picklistValues.containsKey('bgive_im_connection'));
		Test.stopTest();
	}

	@isTest
	public static void testGetBgiveGrantURL() {
		Test.startTest();
		String bgiveGrantURL = IMGrantViewController.getBgiveGrantURL();
		Assert.areEqual(FLUXX_BASE_URL+'/show/requests/', bgiveGrantURL);
		Test.stopTest();
	}

	@isTest
	public static void testGetPaymentsByRequestId() {

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

		String filterPayments = '{"group_type":"and","conditions":[["request_id","eq","123456"]]}';
		String paymentFilter = EncodingUtil.urlEncode(filterPayments, 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_transaction?page=1&per_page=50&cols=' + colsPayment + '&relation=' + colsRelation + '&filter=' + paymentFilter,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		Test.startTest();
		List<Object> payments = IMGrantViewController.getPaymentsByRequestId('123456');
		Test.stopTest();
		Assert.areEqual('123456', ((Map<String, Object>)payments[0]).get('id'));
	}

	@isTest
	public static void testSendEmail() {
        IM_Grant__c imGrant = TestDataFactory.createIMGrant();
        imGrant.Bgive_IM_Connection__c = 'IM Managed';
		imGrant.Funded_By_Multiple_Initiatives__c = 'No';
		imGrant.Bgive_Id__c = '123456';
		imGrant.Bgive_Contig_Id__c = '123456';
		update imGrant;
		Test.startTest();
		IMGrantViewController.sendEmail(imGrant, '123456', IMGrantViewController.getBgiveGrantURL());
		Test.stopTest();
	}

	@isTest
	public static void testGetAmendmentsByRequestId() {
		String mockResponseBody = '{"records":';
		mockResponseBody += '{"request_amendment":';
		mockResponseBody += '[{';
		mockResponseBody += '    "id":"123456",';
		mockResponseBody += '    "migrate_id":"123456_0",';
		mockResponseBody += '    "amount_due_local":"300000",';
		mockResponseBody += '    "contig_id":"1234",';
		mockResponseBody += '    "request_id":[{"id":"123456","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockResponseBody += ' }]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';

		String filter = '{"group_type":"and","conditions":[["request_id","eq","123456"],["state","not-eq","approved"],["state","not-eq","declined"],["state","not-eq","rejected"],["original","eq","0"]]}';
		String finalFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

		String amendmentSort = EncodingUtil.urlEncode('[["created_at","asc"]]', 'UTF-8');

		String cols = EncodingUtil.urlEncode('["id","request_id","state","original"]', 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_amendment?page=1&per_page=20&cols=' + cols + '&filter=' + finalFilter + '&sort=' + amendmentSort, 
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		Test.startTest();
		List<Object> amendments = IMGrantViewController.getAmendmentsByRequestId('123456');
		Test.stopTest();
		Assert.areEqual('123456', ((Map<String, Object>)amendments[0]).get('id'));
	}

	@isTest
	public static void testRefresh() {
        IM_Grant__c imGrant = TestDataFactory.createIMGrant();
        imGrant.Bgive_IM_Connection__c = 'IM Managed';
		imGrant.Funded_By_Multiple_Initiatives__c = 'No';
		imGrant.Bgive_Id__c = '123456';
		update imGrant;

		String mockFetchResponse = '{"grant_request":';
		mockFetchResponse += '{';
		mockFetchResponse += '    "id":"123456",';
		mockFetchResponse += '    "state":"ongoing",';
		mockFetchResponse += '    "program_organization_id":9014,';
		mockFetchResponse += '    "funded_by_multiple_initiatives":"No",';
		mockFetchResponse += '    "bgive_im_connection":"IM Managed",';
		mockFetchResponse += '    "project_title_internal":"Test title",';
        mockFetchResponse += '    "program_org_name":"Test Org",';
		mockFetchResponse += '    "brm_id":"' + imGrant.Id + '",';
		mockFetchResponse += '    "contig_id":"1234"';
		mockFetchResponse += ' }';
		mockFetchResponse += '    }';

		String mockResponseBody = '{"records":';
		mockResponseBody += '{"request_amendment":';
		mockResponseBody += '[{';
		mockResponseBody += '    "id":"123456",';
		mockResponseBody += '    "migrate_id":"123456_0",';
		mockResponseBody += '    "amount_due_local":"300000",';
		mockResponseBody += '    "contig_id":"1234",';
		mockResponseBody += '    "request_id":[{"id":"123456","foundation_initiatives":["Arts|Test Initiative"]}]';
		mockResponseBody += ' }]';
		mockResponseBody += '    }';
		mockResponseBody += '    }';

		String filter = '{"group_type":"and","conditions":[["request_id","eq","123456"],["state","not-eq","approved"],["state","not-eq","declined"],["state","not-eq","rejected"],["original","eq","0"]]}';
		String finalFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

		String colsFetch = EncodingUtil.urlEncode('["id","state","program_organization_id","brm_id","contig_id","program_id","program_org_name","amount_recommended_local","funded_by_multiple_initiatives","bgive_im_connection","project_title_internal","grant_begins_at","grant_closed_at","fx_type_id","granted"]', 'UTF-8');
		String cols = EncodingUtil.urlEncode('["id","request_id","state","original"]', 'UTF-8');

		String amendmentSort = EncodingUtil.urlEncode('[["created_at","asc"]]', 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/grant_request/123456?cols=' + colsFetch,
			HttpMockRegistry.createSuccessResponse(mockFetchResponse)
		);

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_amendment?page=1&per_page=20&cols=' + cols + '&filter=' + finalFilter + '&sort=' + amendmentSort,
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		Test.startTest();
		IMGrantViewController.refresh(imGrant);

		List<IM_Grant__c> imGrantsUpdated = [
			SELECT Id, Bgive_Status__c, Bgive_Id__c, Bgive_Contig_Id__c
			FROM IM_Grant__c
		];
		Assert.areEqual('Ongoing', imGrantsUpdated[0].Bgive_Status__c);
		Test.stopTest();
	}

	@isTest
	public static void testGetNonBudgetGrant() {
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
		List<IM_Initiative__c> initiatives = [SELECT Id, Name FROM IM_Initiative__c WHERE Name = 'Clean Beach Miscellaneous' LIMIT 1];
		List<IM_Grant__c> imGrants = [SELECT Id FROM IM_Grant__c LIMIT 1];
		IM_Non_Budget_Grant__c nonBg = TestDataFactory.createNonBudgetGrant(initiatives[0].Id, imGrants[0].Id);
		IM_Non_Budget_Grant__c nonBudgetGrant = IMGrantViewController.getNonBudgetGrant(nonBg.Id);
		Test.stopTest();
		Assert.areEqual(nonBg.Id, nonBudgetGrant.Id);
	}

	@isTest
	public static void testGetPartnerChangeDetails() {
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
		List<IM_Grant__c> imGrants = [SELECT Id, Funded_By_Multiple_Initiatives__c FROM IM_Grant__c LIMIT 1];
		List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c LIMIT 1];
		Map<String, Object> imGrantChildren = IMGrantViewController.getPartnerChangeDetails(imGrants[0]);
		Map<Id, IM_Budget_Grant__c> budgetGrantsMap = (Map<Id, IM_Budget_Grant__c>)imGrantChildren.get('budgetGrants');
		Test.stopTest();
		Assert.areEqual(true, budgetGrantsMap.containsKey(budgetGrants[0].Id));
	}

	@isTest
	public static void testValidatePartner() {
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
		List<Id> budgetIds = new List<Id>();
		budgetIds.add(budget[0].Id);
		Account org = TestDataFactory.createOrg('Test org new');
		org.Bgive_Id__c = '5678';
		update org;
		List<IM_Budget_Grant__c> budgetGrants = [SELECT Id FROM IM_Budget_Grant__c LIMIT 1];
		Map<String, Object> isPartnerValid = IMGrantViewController.validatePartner(budgetGrants[0], org.Id, budgetIds);
		Test.stopTest();
		Assert.areEqual(true, (Boolean)isPartnerValid.get('isBlinked'));
	}

	@isTest
	public static void testChangePartner() {
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
		List<Id> budgetIds = new List<Id>();
		budgetIds.add(budget[0].Id);
		Account org = TestDataFactory.createOrg('Test org new');
		org.Bgive_Id__c = '5678';
		update org;
		List<IM_Grant__c> imGrants = [SELECT Id FROM IM_Grant__c LIMIT 1];
		List<IM_Budget_Org__c> budgetOrgs = [
			SELECT Id, Name, Organization__c, Type__c, Deleted__c, Budget__c
			FROM IM_Budget_Org__c
			WHERE Budget__c IN :budgetIds AND Organization__c = :org.Id AND Type__c = 'Partner'
		];
		Map<Id, IM_Budget_Grant__c> budgetGrantsMap = new Map<Id, IM_Budget_Grant__c>([SELECT Id, Deleted__c, Is_Active__c, Budget__c, Budget__r.Checked_Out_By__c, Budget_Org__c, Unique_Identifier__c FROM IM_Budget_Grant__c LIMIT 1]);
		Boolean isPartnerChanged = IMGrantViewController.changePartner(imGrants[0], budgetGrantsMap, org.Id, 'TO-1', budgetOrgs, budgetIds);
		Test.stopTest();
		Assert.areEqual(true, isPartnerChanged);
	}

	@isTest
	public static void testSyncPartnerWithBGive() {
        IM_Grant__c imGrant = TestDataFactory.createIMGrant();
        imGrant.Bgive_IM_Connection__c = 'IM Managed';
		imGrant.Funded_By_Multiple_Initiatives__c = 'No';
		imGrant.Bgive_Id__c = '123456';
		update imGrant;

		String mockModifyResponse = '{"grant_request":{';
		mockModifyResponse += '"id":"123456",';
		mockModifyResponse += '"state":"draft",';
		mockModifyResponse += '"program_organization_id":9014,';
		mockModifyResponse += '"funded_by_multiple_initiatives":"No",';
		mockModifyResponse += '"bgive_im_connection":"Bgive Managed",';
		mockModifyResponse += '"brm_id":"' + imGrant.Id + '",';
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
		IMGrantViewController.syncPartnerWithBGive(imGrant.Id);
		IM_Grant__c imGrantsUpdated = [

			SELECT Id, Bgive_Program_Organization_Id__c
			FROM IM_Grant__c WHERE Id = :imGrant.Id
		];
		Assert.areEqual('9014', imGrantsUpdated.Bgive_Program_Organization_Id__c);
		Test.stopTest();
	}

	@isTest
	public static void testGetFoundationInitiative() {
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
			SELECT Id
			FROM IM_Budget_Grant__c
			LIMIT 1
		];
		IM_Budget_Grant__c fetchedBudgetGrant = IMGrantViewController.getFoundationInitiative(budgetGrant[0].Id);
		Test.stopTest();
		Assert.areEqual(budgetGrant[0].Id, fetchedBudgetGrant.Id);
	}
}