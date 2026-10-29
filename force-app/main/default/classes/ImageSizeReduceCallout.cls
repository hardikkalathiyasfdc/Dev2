public without sharing class ImageSizeReduceCallout {
    private final static String END_POINT = System.Label.Image_Call_Out_URL;
    private final static String TOKEN = System.Label.Image_Call_Out_Token;

    private static final String ERR_UPDATE_REDUCE_IMAGE_DATA= 'IMAGE_SIZE_REDUCE_CALL_OUT_UPDATE_REDUCE_IMAGE_DATA_FAILED';
    private static final String ERR_CALL_OUT= 'IMAGE_SIZE_REDUCE_CALL_OUT_CALL_OUT_FAILED';

    @future (callout=true)
    public static void updateReduceImageData(Id contId) {
        try{

            List<Contact> cnts = [SELECT Bio_Photo__c, ReducedImage__c
                                  FROM Contact
                                  WHERE Id =: contId];
            if( cnts.size() > 0 ) {
                Contact cnt = cnts[0];
                String decodedURL = UtilityClass.getPhotoURL(cnt.Bio_Photo__c);

                if( decodedURL != '' && decodedURL.contains('bbrm')) {
                    String response = callout(decodedURL);
                    if( response != '' ) {
                        cnt.ReducedImage__c = response;
                        cnt.BioPhotoUpdated__c = false;
                    }
                }
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.AllowSave = true;
                Database.SaveResult results = Database.update(cnt, dml);
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_update_reduce_image_data) );
        }
    }

    public static String callout(String url) {
        PageReference page = new PageReference( url );
        Blob b = Blob.valueOf('test');
        if( !Test.isRunningTest() ) {
            b = page.getContent();
        }

        String imageData = EncodingUtil.base64Encode(b);

        ImageInfo info = new ImageInfo();
        info.data = imageData;

        Http h = new Http();

        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(END_POINT);
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Basic '+ EncodingUtil.base64Encode(Blob.valueOf(TOKEN)));
        req.setCompressed(true);

        req.setbody(JSON.serialize(info));
        // Send the request, and return a response
        String result = '';
        try{
            HttpResponse res = h.send(req);

            if( res.getStatusCode() == 200 ) {
                ImageInfo resImageInfo = (ImageInfo)JSON.deserialize(res.getBody(), ImageInfo.class);
                result = resImageInfo.data;
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_CALL_OUT) );
        }
        return result;
    }

    public class ImageInfo {
        public String data {get;set;}
    }
}