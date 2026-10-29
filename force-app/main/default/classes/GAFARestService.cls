@RestResource(urlMapping='/startGAFASync')
global with sharing class GAFARestService {

    @HttpPost
    global static String startBatch() {
        try {
            Id batchJobId = Database.executeBatch(new GeoAreaFocusAreaBatch(), 200);
            return 'Batch started successfully with Job Id: ' + batchJobId;
        } catch (Exception e) {
            RestResponse res = RestContext.response;
            res.statusCode = 500;
            return 'Error starting batch job: ' + e.getMessage();
        }
    }
}