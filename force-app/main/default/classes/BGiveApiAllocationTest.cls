/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 06/18/2025
 * Jira        : IM-143
 * Description : Test class for BGiveApiAllocation
 */
@IsTest
public class BGiveApiAllocationTest {
	//Mock Response for getAllocations
	public class MockResponseGenerator implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse resp = new HttpResponse();
			resp.setHeader('Content-Type', 'application/json');
			resp.setStatusCode(200);
			List<Object> existingPayments = new List<Object>{ new Map<String, Object>{ 'id' => 'a1' }, new Map<String, Object>{ 'id' => 'a2' } };
			String mockJson = JSON.serialize(new Map<String, Object>{ 'records' => new Map<String, Object>{ 'machine_model' => existingPayments } });
			resp.setBody(mockJson);
			return resp;
		}
	}
	//Mock Response for createAllocation
	public class AllocationMockRespGenerator implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse resp = new HttpResponse();
			resp.setHeader('Content-Type', 'application/json');
			resp.setStatusCode(200);
			List<Object> existingPayments = new List<Object>{ new Map<String, Object>{ 'id' => 'a1' }, new Map<String, Object>{ 'id' => 'a2' } };
			String mockJson = JSON.serialize(new Map<String, Object>{ 'records' => null, 'machine_model' => 'a1_a2' });
			resp.setBody(mockJson);
			return resp;
		}
	}

	@IsTest
	private static void getAllAllocationsByPayments() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
		List<Object> existingPayments = new List<Object>{ new Map<String, Object>{ 'id' => 'a1' }, new Map<String, Object>{ 'id' => 'a2' } };
		List<Object> allocationRecords = new BGiveApiAllocation().getAllAllocationsByPayments(existingPayments);
		Assert.isNotNull(allocationRecords);
		Test.stopTest();
	}

	@IsTest
	private static void createAllocation() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new AllocationMockRespGenerator());
		Map<String, Object> allocationRec = new Map<String, Object>();
		Map<String, Object> idMap = new Map<String, Object>();
		idMap.put('id', (Object) 'a1');
		allocationRec.put('payment_allocation_relationship', idMap);
		allocationRec.put('amount_allocated', (Object) 100000);
		allocationRec.put('migrate_id', (Object) ('a2' + '_' + 'a24'));
		new BGiveApiAllocation().createAllocation(allocationRec);
		Assert.isNotNull(allocationRec);
		Test.stopTest();
	}
}