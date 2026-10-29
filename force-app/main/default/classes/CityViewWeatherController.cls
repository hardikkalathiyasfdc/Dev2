/**
* Author      : Nishant Bakhrey
* Date        : 06/15/2025
* Jira        : BRME-5882
* Description : Handles Weather.com API Call to fetch weather and local time data for CityView
* Test        : CityViewWeatherControllerTest
*/
public without sharing class CityViewWeatherController {

    // ---- Error Codes ----
    private static final String ERR_GET_WEATHER = 'CVWC_GET_WEATHER_FAILED';

    // ---- Error Messages ----
    private static final String MSG_GET_WEATHER = 'Failed while retrieving weather data from Weather.com API.';

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getWeatherData(Double latitude, Double longitude) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
            String path = envSetting.Weather_API_URL__c + '/wx/forecast/daily/5day?geocode=' + latitude + ',' + longitude + 
                          '&format=json&units=e&language=en-US&apiKey=' + envSetting.Weather_API_Key__c;
            request.setEndpoint(path);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            Map<String, Object> weatherData;
            if (response.getStatusCode() == 200) {
                weatherData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                result.put('weather', weatherData);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_WEATHER));
            throw new AuraHandledException(MSG_GET_WEATHER);
        }
        return result;
    }
}