/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 06/30/2025
 * Jira        : IM-143
 * Description : Test class for IMAllocationService
 */
@IsTest
public class IMAllocationServiceTest {
	//Mock Response
	public class MockResponseGenerator implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse resp = new HttpResponse();
			if (req.getEndpoint().contains('/request_transaction')) {
				resp.setHeader('Content-Type', 'application/json');
				resp.setStatusCode(200);
				List<Object> existingPayments = new List<Object>{
					new Map<String, Object>{
						'request_id' => (Object) new List<Object>{
							new Map<String, Object>{
								'id' => 's1',
								'foundation_initiatives' => (Object) new List<Object>{ 'Arts|Test Initiative 1.0', 'Public Health|Test Initiative 2.0' }
							}
						},
						'id' => 'a1'
					}
				};
				String mockJson = JSON.serialize(new Map<String, Object>{ 'records' => new Map<String, Object>{ 'request_transaction' => existingPayments } });
				resp.setBody(mockJson);
			} else {
				resp.setHeader('Content-Type', 'application/json');
				resp.setStatusCode(200);
				List<Object> existingPayments = new List<Object>{
					new Map<String, Object>{ 'payment_allocation_relationship' => (Object) new List<Object>{ new Map<String, Object>{ 'id' => 's1' } } }
				};
				String mockJson = JSON.serialize(new Map<String, Object>{ 'records' => new Map<String, Object>{ 'machine_model' => existingPayments } });
				resp.setBody(mockJson);
			}
			return resp;
		}
	}

	@IsTest
	private static void getAllAllocationsByPayments() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
		String bgiveGrantId = 'a123b45';
		Map<String, Object> resultMap = IMAllocationService.createAllocations(bgiveGrantId);
		Assert.isNotNull(resultMap, 'resultMap is not Empty');
		Test.stopTest();
	}
}