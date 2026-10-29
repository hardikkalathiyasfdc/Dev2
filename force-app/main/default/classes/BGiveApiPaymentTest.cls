/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 06/23/2025
 * Jira        : IM-143
 * Description : Test class for BGiveApiPayment
 */
@IsTest
public class BGiveApiPaymentTest {
	//Mock Respons for getAllPayments
	public class MockResponseGenerator implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse resp = new HttpResponse();
			resp.setHeader('Content-Type', 'application/json');
			resp.setStatusCode(200);
			List<Object> existingPayments = new List<Object>{ new Map<String, Object>{ 'id' => 'a1' }, new Map<String, Object>{ 'id' => 'a2' } };
			String mockJson = JSON.serialize(new Map<String, Object>{ 'records' => new Map<String, Object>{ 'request_transaction' => existingPayments } });
			resp.setBody(mockJson);
			return resp;
		}
	}
	//Mock Response for createPayment
	public class PaymentMockRespGenerator implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse resp = new HttpResponse();
			resp.setHeader('Content-Type', 'application/json');
			resp.setStatusCode(200);
			List<Object> existingPayments = new List<Object>{ new Map<String, Object>{ 'id' => 'a1' }, new Map<String, Object>{ 'id' => 'a2' } };
			String mockJson = JSON.serialize(new Map<String, Object>{ 'records' => null, 'request_transaction' => 'a1_a2' });
			resp.setBody(mockJson);
			return resp;
		}
	}

	@TestSetup
	static void setup() {
		Fund__c testFund = TestDataFactory.createFund('Partner');
	}

	@IsTest
	private static void getAllPayments() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
		String bgiveGrantId = 'a123b45';
		List<Object> paymentRecords = new BGiveApiPayment().getAllPayments(bgiveGrantId);
		Assert.isNotNull(paymentRecords);
		Test.stopTest();
	}

	@IsTest
	private static void createPayment() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new PaymentMockRespGenerator());
		String bgiveGrantId = 'a123b45';
		Fund__c fund = [SELECT Id FROM Fund__c LIMIT 1];
		Map<String, Object> paymentRec = new Map<String, Object>{ 'id' => (Object) 'a1', 'fund' => (Object) fund.Id };
		new BGiveApiPayment().createPayment(paymentRec, bgiveGrantId);
		Assert.isNotNull(paymentRec);
		Test.stopTest();
	}
}