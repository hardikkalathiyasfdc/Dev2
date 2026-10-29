/**
* Author : Neha Gire
* Date   : 10/02/2024
* Jira   : IM-25
* Description : This class provides generalized methods to mock Http callouts.
*/

/**
 * A registry built around the Salesforce Mocking API that allows declarative mocking of HTTP callouts. Mocks responses
 * can be registered either for a specific endpoint and path or for all paths on an endpoint, with the former taking
 * precedence.
 */
@IsTest
public without sharing class HttpMockRegistry {

	// Default mock response for HTTP requests
	public static final HttpResponse DEFAULT_MOCK_RESPONSE = createSuccessResponse('Default mock response');

	// A registry of callout mocks, keyed by endpoint
	public static Map<String, CalloutMockConfig> calloutMocks { private get; private set; }

	// Static initialization
	static {
		calloutMocks = new Map<String, CalloutMockConfig>();
		Test.setMock(HttpCalloutMock.class, new CalloutResponder());
	}


	//==================================================================================================================
	// Callout mocking
	//==================================================================================================================

	/**
	 * Mocks out a callout endpoint to return the default mock response for all requests.
	 * @param endpoint A callout endpoint
	 * endpoint and path
	 */
	public static void mockCallout(String endpoint) {
        System.debug('mockCallout1');
		getCalloutMockConfig(endpoint).setDefaultResponse(DEFAULT_MOCK_RESPONSE);
	}

	/**
	 * Mocks out a callout endpoint to return a given mock response by default for all requests.
	 * @param endpoint A callout endpoint
	 * @param response An HttpResponse to return whenever an HTTP request is sent to the provided
	 * endpoint and path
	 */
	public static void mockCallout(String endpoint, HttpResponse response) {
        System.debug('mockCallout2');
		getCalloutMockConfig(endpoint).setDefaultResponse(response);
	}

	/**
	 * Mocks out a callout endpoint to return a specified response for all requests to a particular path.
	 * @param endpoint A callout endpoint
	 * @param path The specific path on the given endpoint to mock
	 * @param response An HttpResponse to return whenever an HTTP request is sent to the provided
	 * endpoint and path
	 */
	public static void mockCallout(String endpoint, String path, HttpResponse mockResponse) {
        System.debug('mockCallout3');
		getCalloutMockConfig(endpoint).setResponse(path, mockResponse);
	}

	/**
	 * Mocks out a callout endpoint to return a specified responses for particular paths.
	 * @param endpoint A callout endpoint
	 * @param mockResponses A map of mock responses, keyed by the path for which they should
	 * be returned
	 */
	public static void mockCallout(String endpoint, Map<String, HttpResponse> mockResponses) {
		System.debug('mockCallout4');
        CalloutMockConfig mockConfig = getCalloutMockConfig(endpoint);
		for (String path : mockResponses.keySet()) {
			mockConfig.setResponse(path, mockResponses.get(path));
		}
	}

	/**
	 * Creates an HTTP success response with a given body.
	 * @param body Response body
	 * @return A 200 response with the given response body
	 */
	public static HttpResponse createSuccessResponse(String body) {
        System.debug('createSuccessResponse');
        System.debug(body);
		return createResponse(200, 'OK', body);
	}

	/**
	 * Creates an HTTP response with a given status and body.
	 * @param statusCode Response status code
	 * @param status Response status message
	 * @param body Response body
	 * @return A response with given status and body
	 */
	public static HttpResponse createResponse(Integer statusCode, String status, String body) {
		HttpResponse response = new HttpResponse();
		response.setStatusCode(statusCode);
		response.setStatus(status);
		response.setBody(body);
        system.debug(response);
		return response;
	}

	/**
	 * Returns the mock configuration for a given callout endpoint. If none has been established, it will be created
	 * and added to the configuration map.
	 * @param endpoint The endpoint for which to retrieve/create the mock configuration
	 */
	private static CalloutMockConfig getCalloutMockConfig(String endpoint) {
		CalloutMockConfig mockConfig = calloutMocks.get(endpoint);
		if (mockConfig == null) {
			mockConfig = new CalloutMockConfig();
			calloutMocks.put(endpoint, mockConfig);
		}
		return mockConfig;
	}


	//==================================================================================================================
	// Mock configs
	//==================================================================================================================

	/**
	 * A class to house the configuration of a mocked HTTP callout.
	 */
	private without sharing class CalloutMockConfig {
		public Map<String, HttpResponse> responses { get; set; }
		public HttpResponse defaultResponse { get; set; }

		/**
		 * Constructor.
		 */
		public CalloutMockConfig() {
			this.responses = new Map<String, HttpResponse>();
			this.defaultResponse = DEFAULT_MOCK_RESPONSE;
		}

		/**
		 * Configures the response for a specific path.
		 * @param path An HTTP service request path
		 * @param An HTTP response to return for the given path
		 */
		public void setResponse(String path, HttpResponse response) {
            System.debug('setResponse');
            System.debug(path +'::'+response);
			System.debug('resp'+response.getBody());
			responses.put(path, response);
		}

		/**
		 * Configures the default response for all paths.
		 * @param An HTTP response to return for all paths that aren't explicetly configured
		 */
		public void setDefaultResponse(HttpResponse defaultResponse) {
            System.debug('setDefaultResponse');
			this.defaultResponse = defaultResponse;

		}

		/**
		 * Returns a mock response for the given path.
		 * @param path An HTTP service request path
		 * @return A mock HTTP response for the given path
		 */
		public HttpResponse getResponse(String path) {
            System.debug(path);
            System.debug(responses);
			System.debug(responses.get(path));
			HttpResponse response = responses.get(path);
			return (response != null) ? response : defaultResponse;
		}
	}


	//==================================================================================================================
	// HttpCalloutMock responder
	//==================================================================================================================

	/**
	 * An implementation of HttpCalloutMock used to repond to all HTTP requests.
	 */
	private class CalloutResponder implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			// Split request endpoint into base and path
			String base = request.getEndpoint().substringBefore('/');
			String path = '/'+request.getEndpoint().substringAfter('/');

			System.debug(String.format(
				'Mocking response for callout endpoint \'\'{0}\'\' on path \'\'{1}\'\'',
				new String[] { base, path }
			));

			// Get mock configuration for endpoint
			// If no mock response registered
			CalloutMockConfig mockConfig = calloutMocks.get(base);
			if (mockConfig == null) {
				throw new UnmockedCalloutException(String.format(
					'No mock response registered for callout to endpoint \'\'{0}\'\'',
					new String[] { base }
				));
			}

			// Find appropriate response in registry
            System.debug(mockConfig);
			HttpResponse response = mockConfig.getResponse(path);
			System.debug('Response: ' + response.getBody());
			return response;
		}
	}

	//==================================================================================================================
	// Exceptions
	//==================================================================================================================

	// Exception thrown when a callout is intercepted that has not been properly mocked
	public class UnmockedCalloutException extends Exception {}
}