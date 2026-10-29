/**
 * Description: Controller for handling user preferences related to event table sorting.
 * Test Class: EventTablePreferencesControllerTest
**/
public with sharing class EventTablePreferencesController {

    private static final String ERR_EVENT_TABLE_CONTROLLER = 'EventTablePreferencesController_Failed';
    @TestVisible static Boolean forceException = false;

    @AuraEnabled(cacheable=true)
    public static String getSortPreferences() {
        try {
            if(forceException) throw new AuraHandledException('Forced exception for test');
            List<Custom_User_Preference__c> prefs = [
                SELECT Id, User__c, Event_Sort_Order_JSON__c
                FROM Custom_User_Preference__c
                WHERE User__c = :UserInfo.getUserId()
                LIMIT 1
            ];
            return prefs.isEmpty() || String.isBlank(prefs[0].Event_Sort_Order_JSON__c)
                   ? '[]'
                   : prefs[0].Event_Sort_Order_JSON__c;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_EVENT_TABLE_CONTROLLER));
            return '[]';
        }
    }

    @AuraEnabled
    public static void saveSortPreferences(String sortJson) {
        try {
            if(forceException) throw new AuraHandledException('Forced exception for test');
            List<Custom_User_Preference__c> existingPref = [
                SELECT Id, User__c, Event_Sort_Order_JSON__c
                FROM Custom_User_Preference__c
                WHERE User__c = :UserInfo.getUserId()
                LIMIT 1
            ];
            if(existingPref != null && !existingPref.isEmpty()) {
                existingPref[0].Event_Sort_Order_JSON__c = sortJson;
                BBApps_Crud.doUpdateWithHandling(existingPref, false, ERR_EVENT_TABLE_CONTROLLER);
            } else {
                Custom_User_Preference__c prefs = new Custom_User_Preference__c();
                prefs.User__c = UserInfo.getUserId();
                prefs.Event_Sort_Order_JSON__c = sortJson;
                BBApps_Crud.doInsertWithHandling(prefs, false, ERR_EVENT_TABLE_CONTROLLER);
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_EVENT_TABLE_CONTROLLER));
        }
    }
}