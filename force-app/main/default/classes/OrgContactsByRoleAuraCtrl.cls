public with sharing class OrgContactsByRoleAuraCtrl {

    @TestVisible
    private static Boolean forceExceptionInTest = false;

    @AuraEnabled(cacheable=true)
    public static String getContactsByOrgId(String orgId) {
        try {
            // Test only code to force the catch branch
            if(Test.isRunningTest() && forceExceptionInTest) {
                throw new AuraHandledException('Forced exception for test coverage');
            }
            return JSON.serialize([SELECT Contact_Name__r.Name, Contact_Name__r.Id, Role__c
        						   FROM Employment_History_and_Board_Membership__c
        						   WHERE Organization_Name__c = :orgId]);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields('OrgContactsByRoleAuraCtrl_CLASS_FAILED');
            BBApps_ErrorHandler.logErrors(ex, f);
            return '';
        }
    }
}