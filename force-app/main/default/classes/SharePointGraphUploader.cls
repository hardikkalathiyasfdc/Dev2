public class SharePointGraphUploader {

    // Example endpoint format: 
    // PUT https://graph.microsoft.com/v1.0/sites/{site-id}/drives/{drive-id}/root:/{folder-path}/{file-name}:/content
    
    public static void uploadFileToSharePoint(String contentVersionId, String siteId, String driveId, String folderPath) {
        ContentVersion cv = [
            SELECT Title, FileExtension, VersionData 
            FROM ContentVersion 
            WHERE Id = :contentVersionId 
            LIMIT 1
        ];
        
        String fileName = cv.Title + (String.isNotBlank(cv.FileExtension) ? '.' + cv.FileExtension : '');
        Blob fileBlob = cv.VersionData;
        
        // 2. Obtain Microsoft Graph Access Token 
        String accessToken = getGraphAccessToken();
        if (String.isBlank(accessToken)) {
            System.debug('Failed to retrieve Microsoft Graph Access Token.');
            return;
        }

        //Construct Graph API Endpoint for the file upload
        // If folderPath is empty/root, format as: /drives/{driveId}/root:/{fileName}:/content
        String endpointUrl = 'https://graph.microsoft.com/v1.0/sites/' + siteId + 
                             '/drives/' + driveId + 
                             '/root:/' + (String.isNotBlank(folderPath) ? folderPath + '/' : '') + 
                             EncodingUtil.urlEncode(fileName, 'UTF-8') + ':/content';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('PUT');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/octet-stream');
        req.setHeader('Content-Length', String.valueOf(fileBlob.size()));
        req.setBodyAsBlob(fileBlob);
        req.setTimeout(120000);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                System.debug('File uploaded successfully to SharePoint: ' + res.getBody());
            } else {
                System.debug('Error uploading file: ' + res.getStatusCode() + ' - ' + res.getStatus());
                System.debug('Response: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception during SharePoint callout: ' + e.getMessage());
        }
    }

    private static String getGraphAccessToken() {
        String tenantId = 'YOUR_AZURE_TENANT_ID';
        String clientId = 'YOUR_AZURE_CLIENT_ID';
        String clientSecret = 'YOUR_AZURE_CLIENT_SECRET';
        
        String tokenEndpoint = 'https://microsoftonline.com' + tenantId + '/oauth2/v2.0/token';
        
        String requestBody = 'grant_type=client_credentials' +
                             '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
                             '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') +
                             '&scope=' + EncodingUtil.urlEncode('https://microsoft.com', 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(tokenEndpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('access_token');
        }
        return null;
    }
}