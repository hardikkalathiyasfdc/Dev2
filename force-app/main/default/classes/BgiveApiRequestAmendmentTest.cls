/**
* Author      : Paddy
* Date        : 06/22/2025
* Jira        : IM-203
* Description : Test class for BgiveApiRequestAmendment.
* Modified By : Gauri on 12/23/25 to improve code coverage
*/
@isTest
public with sharing class BgiveApiRequestAmendmentTest {

	private static Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{ 'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c' });
	private static String FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
	private static String FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));

	@isTest
	private static void testCreateAmendment() {
		Test.startTest();
			String requestId = '123456';

			String cols = EncodingUtil.urlEncode('["id","amount_recommended_local","end_date"]', 'UTF-8');

			Map<String, Object> data = new Map<String, Object>();
			data.put('amendment_type', 'Grant Amendment');
			data.put('end_date', String.valueOf(Date.today()));
			data.put('amount_recommended_local', '200000');
			data.put('state', 'update');
			data.put('bgive_im_connection', 'IM Managed');
			data.put('request_id', requestId);
			data.put('updated_by_id', FLUXX_USER_ID);
			data.put('created_by_id', FLUXX_USER_ID);
			String dataMap = EncodingUtil.urlEncode(JSON.serialize(data), 'UTF-8');

            String mockResponse = '{"request_amendment":';
			mockResponse += '{';
			mockResponse += '    "id":"4567",';
			mockResponse += '    "amount_recommended_local":"200000"';
			mockResponse += ' }';
			mockResponse += '    }';

			HttpMockRegistry.mockCallout(
				'callout:' + FLUXX_NAMED_CRED,
				'/api/rest/v2/request_amendment?data=' + dataMap + '&cols=' + cols,
				HttpMockRegistry.createSuccessResponse(mockResponse)
			);

            Map<String, Object> amendmentDetails = new Map<String, Object>();
                amendmentDetails.put('amendment_type', 'Grant Amendment');
                amendmentDetails.put('end_date', String.valueOf(Date.today()));
                amendmentDetails.put('amount_recommended_local', '200000');
                amendmentDetails.put('state', 'update');
                amendmentDetails.put('bgive_im_connection', 'IM Managed');
            Map<String,Object> responseData = new BgiveAPIRequestAmendment().createAmendment(requestId, amendmentDetails);
        	Assert.areEqual('4567', responseData.get('AmendmentBgiveID'));
			Assert.areEqual('200000', responseData.get('AmendmentFutureAmountLocal'));
		Test.stopTest();
	}

	@isTest
	private static void testCreateAmendmentException() {
		Test.startTest();
			String requestId = '';
			Map<String, Object> amendmentDetails = new Map<String, Object>();
            try{
				Map<String,Object> responseData = new BgiveAPIRequestAmendment().createAmendment(requestId, amendmentDetails);
			}catch(Exception e){
				Assert.areEqual('BgiveAPIRequestAmendmentException:[]: BGive Grant Id cannot be null.', String.valueOf(e));
			}
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

		String filter = '{"group_type":"and","conditions":[["request_id","eq","123456"],["original","eq","0"]]}';
		String finalFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

		String amendmentSort = EncodingUtil.urlEncode('[["created_at","asc"]]', 'UTF-8');

		String cols = EncodingUtil.urlEncode('["id","request_id","state","original"]', 'UTF-8');

		HttpMockRegistry.mockCallout(
			'callout:' + FLUXX_NAMED_CRED,
			'/api/rest/v2/request_amendment?page=1&per_page=20&cols=' + cols + '&filter=' + finalFilter + '&sort=' + amendmentSort, 
			HttpMockRegistry.createSuccessResponse(mockResponseBody)
		);

		Test.startTest();
		BgiveApiRequestAmendment requestAmendment = new BgiveApiRequestAmendment();
		List<Object> amendments = requestAmendment.getAmendmentsByRequestId('123456');
		Test.stopTest();
		Assert.areEqual('123456', ((Map<String, Object>)amendments[0]).get('id'));
	}

	@isTest
	public static void testGetOpenAmendmentsByRequestId() {
		
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
		BgiveApiRequestAmendment requestAmendment = new BgiveApiRequestAmendment();
		List<Object> amendments = requestAmendment.getOpenAmendmentsByRequestId('123456');
		Test.stopTest();
		Assert.areEqual('123456', ((Map<String, Object>)amendments[0]).get('id'));
	}
}