@isTest
public with sharing class CityViewWeatherControllerTest {

    class WeatherHttpMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"forecasts":[{"dayOfWeek":"Monday","narrative":"Sunny"}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testGetWeatherData_Success() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new WeatherHttpMockSuccess());
            Double lat = 40.7128;
            Double lon = -74.0060;
            Map<String, Object> result = CityViewWeatherController.getWeatherData(lat, lon);
        Test.stopTest();
    }
}