public with sharing class OfficeInfoAuraCtrl {

    @TestVisible
    private static Boolean forceExceptionInTest = false;

    @AuraEnabled(cacheable=true)
    public static String getOfficeInfo() {
        try {
            // Test only code to force the catch branch
            if (Test.isRunningTest() && forceExceptionInTest) {
                throw new AuraHandledException('Forced exception for test coverage');
            }
            return JSON.serialize([
                SELECT OfficeName__c, OfficePhone__c, Email__c, CellPhone__c, Order__c
                FROM BPOfficeInfo__mdt
                WHERE HomePageEligible__c = true
            ]);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields('OfficeInfoAuraCtrl_CLASS_FAILED');
            BBApps_ErrorHandler.logErrors(ex, f);
            return '';
        }
    }
}