public class MergeDuplicateRecordDeletion {

    private static final String ERR_DELETE_RECORDS_DUPLICATE_EMP_HISTORY = 'DELETE_DuplicateEmpHistory_RECORDS_FAILED';
    private static final String ERR_DELETE_RECORDS_DUPLICATE_TagJunctions = 'DELETE_DuplicateTagJunctions_RECORDS_FAILED';
    private static final String ERR_DELETE_RECORDS_DUPLICATE_TagJunctionsForAccount = 'DELETE_DuplicateTagJunctionsForAccount_RECORDS_FAILED';
    
    private static final String ERR_CLASS_FAILED = 'MergeDuplicateRecordDeletion_CLASS_FAILED';

    public static void deleteDuplicateTagJunctions( List<Id> contactIds) {
        try {
            List<Tag_Junction__c> recordsToDelete = new List<Tag_Junction__c>();
            // Query for existing Tag_Junction__c records related to the Contacts in Trigger.new
            Map<String, Tag_Junction__c> existingTagsMap = new Map<String, Tag_Junction__c>();
            for(Tag_Junction__c rec : [SELECT Contact__c, Tag__r.Name FROM Tag_Junction__c WHERE Contact__c IN :contactIds]) {
                String key = rec.Contact__c + '-' + rec.Tag__r.Name;
                if(!existingTagsMap.containsKey(key)) {
                    existingTagsMap.put(key,rec);
                } else {
                    recordsToDelete.add(rec);
                }
            }
            if(!recordsToDelete.isEmpty())
                BBApps_Crud.doDeleteWithHandling(recordsToDelete, false, new BBApps_ErrorCustomFields(ERR_DELETE_RECORDS_DUPLICATE_TagJunctions));
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    public static void deleteDuplicateTagJunctionsForAccount(List<Id> accountIds) {
        try {
            List<Tag_Junction__c> recordsToDelete = new List<Tag_Junction__c>();
            // Query for existing Tag_Junction__c records related to the Accounts in Trigger.new
            Map<String, Tag_Junction__c> existingTagsMap = new Map<String, Tag_Junction__c>();
            for(Tag_Junction__c rec : [SELECT Account__c, Tag__r.Name FROM Tag_Junction__c WHERE Account__c IN :accountIds]) {
                String key = rec.Account__c + '-' + rec.Tag__r.Name;
                if(!existingTagsMap.containsKey(key)) {
                    existingTagsMap.put(key,rec);
                } else {
                    recordsToDelete.add(rec);
                }
            }
            if(!recordsToDelete.isEmpty())
                BBApps_Crud.doDeleteWithHandling(recordsToDelete, false, new BBApps_ErrorCustomFields(ERR_DELETE_RECORDS_DUPLICATE_TagJunctionsForAccount));
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    public static void deleteDuplicateEmpHistory(List<Id> contactIds) {
        try {
            List<Employment_History_and_Board_Membership__c> recordsToDelete = new List<Employment_History_and_Board_Membership__c>();
            // Query for existing Tag_Junction__c records related to the Contacts in Trigger.new
            Map<String, Employment_History_and_Board_Membership__c> existingTagsMap = new Map<String, Employment_History_and_Board_Membership__c>();
            for (Employment_History_and_Board_Membership__c rec : [SELECT Business_Email__c, Office_Phone__c, Mobile_Phone__c, Notes__c, Title__c, From__c, 
                                                                          To__c, Contact_Name__c, Source_Record_ID__c, Role__c, Organization_Name__c 
                                                                   FROM Employment_History_and_Board_Membership__c
                                                                   WHERE Contact_Name__c IN :contactIds AND Business_Email__c = null 
                                                                     AND Role__c= null AND Office_Phone__c = null AND Mobile_Phone__c = null
                                                                     AND To__c=null AND Title__c = null AND From__c = null AND Source_Record_ID__c = null]) {
                                                                    
                String key = rec.Contact_Name__c + '-' + rec.Role__c + '-' + rec.Organization_Name__c;
                if(!existingTagsMap.containsKey(key)) {
                    existingTagsMap.put(key,rec);
                } else if(rec.Business_Email__c == null && rec.Office_Phone__c == null && 
                          rec.Mobile_Phone__c == null && rec.To__c == null && rec.Notes__c == null && 
                          rec.Title__c == null && rec.From__c == null && rec.Source_Record_ID__c == null) {

                    recordsToDelete.add(rec);
                }
            }
            if(!recordsToDelete.isEmpty())
                BBApps_Crud.doDeleteWithHandling(recordsToDelete, false, new BBApps_ErrorCustomFields(ERR_DELETE_RECORDS_DUPLICATE_EMP_HISTORY));
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}