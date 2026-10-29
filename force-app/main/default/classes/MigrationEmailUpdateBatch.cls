global without sharing class MigrationEmailUpdateBatch implements Database.Batchable<sObject> {
    public String query;
    private final String BLOOMBERG_ORG = '@bloomberg.org';
	private final String BLOOMBERG_NET = '@bloomberg.net';
    private final String INVALID = '.invalid';
    private Boolean isSandbox = UtilityClass.isSandbox();

    private static final String ERR_START   = 'MEUB_START_FAILED';
    private static final String ERR_EXECUTE = 'MEUB_EXECUTE_FAILED';

    global MigrationEmailUpdateBatch() {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            return Database.getQueryLocator([SELECT Email, Business_Email_2__c, Personal_Email_2__c, Alternate_Email__c, Web_Email__c
                                            FROM Contact]);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_START));
            return null;
        }
    }

    global void execute(Database.BatchableContext BC, list<Contact> scope) {
        try {
            if( Test.isRunningTest() ) {
                isSandbox = true;
            }

            for( Contact cnt: scope ) {
                if( String.isNotEmpty(cnt.Email) && !cnt.Email.endsWith(BLOOMBERG_ORG) && !cnt.Email.endsWith(BLOOMBERG_NET) &&
                    !cnt.Email.endsWith(INVALID) && isSandbox ) {
                    cnt.Email = cnt.Email + '.invalid';
                }
                if( String.isNotEmpty(cnt.Business_Email_2__c) && !cnt.Business_Email_2__c.endsWith(BLOOMBERG_ORG) &&
                   !cnt.Business_Email_2__c.endsWith(BLOOMBERG_NET) && !cnt.Business_Email_2__c.endsWith(INVALID) && isSandbox ) {
                    cnt.Business_Email_2__c = cnt.Business_Email_2__c + '.invalid';
                }
                if( String.isNotEmpty(cnt.Personal_Email_2__c) && !cnt.Personal_Email_2__c.endsWith(BLOOMBERG_ORG) &&
                  !cnt.Personal_Email_2__c.endsWith(BLOOMBERG_NET) && !cnt.Personal_Email_2__c.endsWith(INVALID) && isSandbox ) {
                    cnt.Personal_Email_2__c = cnt.Personal_Email_2__c + '.invalid';
                }
                if( String.isNotEmpty(cnt.Alternate_Email__c) && !cnt.Alternate_Email__c.endsWith(BLOOMBERG_ORG) &&
                  !cnt.Alternate_Email__c.endsWith(BLOOMBERG_NET) && !cnt.Alternate_Email__c.endsWith(INVALID) && isSandbox ) {
                    cnt.Alternate_Email__c = cnt.Alternate_Email__c + '.invalid';
                }
                if( String.isNotEmpty(cnt.Web_Email__c) && !cnt.Web_Email__c.endsWith(BLOOMBERG_ORG) &&
                  !cnt.Web_Email__c.endsWith(BLOOMBERG_NET) && !cnt.Web_Email__c.endsWith(INVALID) && isSandbox ) {
                    cnt.Web_Email__c = cnt.Web_Email__c + '.invalid';
                }
            }

            BBApps_Crud.doUpdateWithHandling(scope, false, ERR_EXECUTE);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_EXECUTE));
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}