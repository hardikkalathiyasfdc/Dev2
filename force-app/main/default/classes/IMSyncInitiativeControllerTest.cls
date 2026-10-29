@isTest
public with sharing class IMSyncInitiativeControllerTest {

    private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{ 'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c' });
	private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
	private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));
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
	public static void testSyncInitiativeException() {
		Test.startTest();
        try {
			IMInitiativeService.sync(null);
            Assert.fail('Should have thrown an Null pointer exception.');
        } catch (Exception ex) {
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
		Test.stopTest();
	}
    
    @isTest
	public static void testSyncInitiative() {
        
        List<IM_Initiative__c> initiatives = [SELECT Name FROM IM_Initiative__c WHERE RecordTypeId = :BUDGETED_INITIATIVE_RECORD_TYPE_ID LIMIT 1];
        
        String cols = EncodingUtil.urlEncode('["id","contig_id"]', 'UTF-8');

		String mockFetchResponse = '{"records":';
		mockFetchResponse += '{"concept_initiative":';
		mockFetchResponse += '[{';
		mockFetchResponse += '    "id":"2087",';
		mockFetchResponse += '    "bgive_im_connection":"IM Managed",';
		mockFetchResponse += '    "brm_id":"' + initiatives[0].Id + '",';
		mockFetchResponse += '    "end_date":"2028-03-31",';
		mockFetchResponse += '    "focus_area":"Arts",';
		mockFetchResponse += '    "initiative_approval_date":"2026-03-17",';
        mockFetchResponse += '	  "initiative_type":"New",';
		mockFetchResponse += '	  "original_initiative_amount":"2000000.0",';
		mockFetchResponse += '    "name":" ' + initiatives[0].Name + '",';
		mockFetchResponse += '    "parent_initiative_1":"null"';
		mockFetchResponse += ' }]';
		mockFetchResponse += '    }';
		mockFetchResponse += '    }';

		String mockModifyResponse = '{"concept_initiative":';
		mockModifyResponse += '{';
		mockModifyResponse += '    "id":"2087",';
		mockModifyResponse += '    "initiative_type":"New",';
		mockModifyResponse += '    "bgive_im_connection":"IM Managed",';
		mockModifyResponse += '    "brm_id":"' + initiatives[0].Id + '",';
		mockModifyResponse += '    "contig_id":"2087"';
		mockModifyResponse += ' }';
		mockModifyResponse += '    }';
        
        Map<String, Object> data = new Map<String, Object>();
        	
		Datetime today = Datetime.now();
		String formattedDate = today.format('yyyy-MM-dd');
		Date futureDate = today.date().addYears(3).addDays(1);
		Datetime myDatetime = futureDate;
		String formattedFutureDate = myDatetime.format('yyyy-MM-dd');
		
		data.put('total_amount', 0.00);
		data.put('initiative_approval_date', null);
		data.put('bgive_im_connection', 'IM Managed');
		data.put('cityview_description', null);
        data.put('cityview_display_name', null);
        data.put('end_date', formattedFutureDate);
        data.put('focus_area', null);
		data.put('brm_id', initiatives[0].Id);
		data.put('name', 'Clean Beach 1.0');
		data.put('original_initiative_amount', null);
		data.put('parent_initiative_1', new Map<String, Object>{'id' => ''});
		data.put('start_date', formattedDate);
		data.put('state', 'draft');
		data.put('strategic_locations', new List<String>{});
		data.put('program_id', null);
		data.put('initiative_type', 'New');
		data.put('updated_by_id', FLUXX_USER_ID);
        
		
		String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');
        
        String colsInitiatives = EncodingUtil.urlEncode('["total_amount","initiative_approval_date","bgive_im_connection","cityview_description","cityview_display_name","end_date","focus_area","ops_planning_contact","brm_id","name","original_initiative_amount","parent_initiative_1","bp_staff_contact","start_date","state","strategic_locations","program_id","initiative_type","locked_by_id"]', 'UTF-8');
		String filterInitiative = '{"group_type":"and","conditions":[["brm_id","starts_with","' + String.valueOf(initiatives[0].Id) + '"]]}';
		String initiativeFilter = EncodingUtil.urlEncode(filterInitiative, 'UTF-8');
        
        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/concept_initiative?page=1&per_page=20&cols=' + colsInitiatives + '&filter=' + initiativeFilter,
			HttpMockRegistry.createSuccessResponse(mockFetchResponse)
		);

        
        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/concept_initiative/2087?cols=' + cols,
			HttpMockRegistry.createSuccessResponse(mockFetchResponse)
		);
        
        HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/concept_initiative/2087?data=' + dataMap + '&cols=' + cols,
			HttpMockRegistry.createSuccessResponse(mockModifyResponse)
		);
        
        Test.startTest();
			IMSyncInitiativeController.syncInitiative(initiatives[0].Id);
		Test.stopTest();
    }
}