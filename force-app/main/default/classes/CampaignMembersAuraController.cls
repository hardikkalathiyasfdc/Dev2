public with sharing class CampaignMembersAuraController {

    private static final String ERR_CLASS_FAILED = 'CampaignMembersAuraController_CLASS_FAILED';
	
	@AuraEnabled
    public static List<CampaignMember> getCampaignMembers(Id contactId, Boolean isActive) {
        List<CampaignMember> returnList = new List<CampaignMember>();
        try {
            String Guestlist_RECORD_TYPE_ID = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
                .get('GuestList')
                .getRecordTypeId();
            String EVENT_RECORD_TYPE_ID = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
                .get('Pre_Event')
                .getRecordTypeId();
            return [SELECT Id, Campaign.Name 
                    FROM CampaignMember 
                    WHERE ContactId = :contactId 
                      AND Campaign.isActive = :isActive 
                      AND Campaign.RecordTypeId != :Guestlist_RECORD_TYPE_ID 
                      AND Campaign.RecordTypeID != :EVENT_RECORD_TYPE_ID];
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return returnList;
    }

    @AuraEnabled(cacheable=true)
    public static List<ListOrganization__c> getListOrganizations(String organizationId) {
        List<ListOrganization__c> returnList = new List<ListOrganization__c>();
        try {
            return [SELECT Id, List__r.Name 
                    FROM ListOrganization__c 
                    WHERE Organization__c = :organizationId 
                      AND List__r.isActive = true];
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return returnList;
    }
}