/**
 * Description: This is the Apex controller for Add To List LWC component for Organization object. 
 * Author: Nishant Bakhrey
 * Test Class: OrganizationAddToListControllerTest
**/
public class OrganizationAddToListController {
     
    private static final String ERR_CLASS_FAILED = 'OrganizationAddToListAuraCtrl_CLASS_FAILED';
    private static final String ERR_DML_INSERT = 'OrganizationAddToListAuraCtrl_INSERT_FAILED';

    @AuraEnabled(cacheable=true)
    public static Boolean checkOrgInList(String orgId, String listId) {
        Boolean isExistingMember = false;
        try {
            List<ListOrganization__c> members = [SELECT Id 
                                                 FROM ListOrganization__c
                                                 WHERE Organization__c = :orgId
                                                   AND List__c = :listId];
            if(members.size() > 0) isExistingMember = true;
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return isExistingMember;
    }

    @AuraEnabled
    public static void createListOrganizationMember(String orgId, String listId) {
        try {
            ListOrganization__c newMember = new ListOrganization__c();
            newMember.Organization__c = orgId;
            newMember.List__c = listId;
            BBApps_Crud.doInsertWithHandling(newMember, false, new BBApps_ErrorCustomFields(ERR_DML_INSERT));
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}