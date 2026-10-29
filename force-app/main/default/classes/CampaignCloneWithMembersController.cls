/********************************************************************************
* Class Name  : CampaignCloneWithMembersController
* Description : This class is used by CampaignCloneWithMembers lightning component to
*               auto clone Campaign Member records on cloning the campaign.    
* Created By  : Slalom Consulting 
* Change Log  : Created - 6/7/2019
********************************************************************************/
public with sharing class CampaignCloneWithMembersController {

    public static Id LIST_EVENT_RECORD_TYPE_ID = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Pre_Event').getRecordTypeId();
    private static final String ERR_CLASS_FAILED = 'CampaignCloneWithMembersController_CLASS_FAILED';
    
    @AuraEnabled
    public static Id cloneCampaignWithMem(Campaign campIns, Id campId) {
        try {
            Campaign record = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Campaign WHERE Id = :campId WITH SYSTEM_MODE LIMIT 1]; 
            String fieldString = getFieldsToClone(record.RecordType.DeveloperName, 'Campaign');
            String queryString = 'SELECT ' + fieldString + ' FROM Campaign WHERE Id = :campId'; 
            Campaign campaignRecord = Database.query(queryString, AccessLevel.SYSTEM_MODE);
            Campaign newCamp = campaignRecord.clone(false, true, false, false);
            newCamp.Name = campIns.Name;
            newCamp.Description = campIns.Description;
            insert as system newCamp;
            CampaignCloneWithMembersBatch objbatch = 
                new CampaignCloneWithMembersBatch(campId, newCamp, record.RecordType.DeveloperName, 'CampaignMember');
            Database.executeBatch(objbatch, 500);
            return newCamp.Id;
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
            return '';
        }
    }

    public static String getFieldsToClone(String RecordTypeName, String objectName) {
        String fieldString;
        try {

            Manage_Record_Clone__mdt config = [
                SELECT FieldsToClone__c,ObjectApiName__c,RecordTypeName__c 
                FROM Manage_Record_Clone__mdt 
                WHERE RecordTypeName__c = :RecordTypeName  
                AND ObjectApiName__c = :objectName WITH SYSTEM_MODE 
                LIMIT 1];
            List<String> fieldsToClone = new List<String>();
            if(config != null && String.isNotBlank(config.FieldsToClone__c)) {
                fieldsToClone = config.FieldsToClone__c.split(',');
            }
            //Construct a dynamic SOQL query for the record with only the specified fields
            fieldString = String.join(fieldsToClone, ',');
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return fieldString;
    }

    /**
     * @description Returns the restricted (Private) contact count for the given list and
     * whether the running user has the Private_Name_Fields custom permission. Used by the
     * Clone quick action to warn before cloning a list that contains private contacts.
     */
    @AuraEnabled
    public static Map<String, Object> getRestrictedContactInfo(Id campId) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            // Count restricted members WITHOUT sharing: the Campaign is Private sharing, so a
            // user who can see the list but not its restricted Contacts would otherwise get 0
            // and never see the warning. Detection must ignore record-level sharing.
            Integer restrictedCount = RestrictedRecordDetector.countRestrictedContactsInList(campId);
            Boolean hasPrivateAccess = FeatureManagement.checkPermission('Private_Name_Fields');
            result.put('restrictedCount', restrictedCount);
            result.put('hasPrivateAccess', hasPrivateAccess);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
            result.put('restrictedCount', 0);
            result.put('hasPrivateAccess', false);
        }
        return result;
    }
}