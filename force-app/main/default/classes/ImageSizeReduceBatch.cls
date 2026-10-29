global without sharing class ImageSizeReduceBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {
    public String query;

    private static final String ERR_EXCUTE = 'IMAGE_SIZE_REDUCE_BATCH_EXCUTE_FAILED';

    global ImageSizeReduceBatch() {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Contact> scope) {
        List<Contact> contacts = new List<Contact>();
        for( Contact cnt: scope ) {
            if( String.isNotBlank(cnt.Bio_Photo__c) ) {
                String imageData = '';
                try {
                    String decodedURL = UtilityClass.getPhotoURL(cnt.Bio_Photo__c);

                    if( (decodedURL != '' && decodedURL.contains('bbrm')) || Test.isRunningTest()) {
                        String response = ImageSizeReduceCallout.callout(decodedURL);
                        if( response != '' ) {
                            cnt.ReducedImage__c = response;
                            cnt.BioPhotoUpdated__c = false;
                            contacts.add(cnt);
                        }
                    }
                } catch( Exception ex) {
                    BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_EXCUTE) );

                    System.debug(ex.getMessage());
                }
            }
        }
        List<Database.SaveResult> results = Database.update(contacts, false);
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext SC) {
        ImageSizeReduceBatch batch = new ImageSizeReduceBatch();
        batch.query = 'SELECT Id, Bio_Photo__c, ReducedImage__c FROM Contact WHERE BioPhotoUpdated__c = true';
        Database.executeBatch(batch, 50);
    }
}