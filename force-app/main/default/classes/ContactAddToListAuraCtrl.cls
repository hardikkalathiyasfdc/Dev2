public with sharing class ContactAddToListAuraCtrl {

    private static final String ERR_CLASS_FAILED = 'ContactAddToListAuraCtrl_CLASS_FAILED';
    private static final String ERR_DML_INSERT = 'ContactAddToListAuraCtrl_INSERT_FAILED';

    @AuraEnabled(cacheable=true)
    public static Boolean checkGuestInList(String contactId, String listId) {
        Boolean isExisted = false;
        try {
            List<CampaignMember> members = [SELECT Id
                                            FROM CampaignMember
                                            WHERE ContactId = :contactId
                                              AND CampaignId = :listId];
            if(members.size() > 0) isExisted = true;
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
        return isExisted;

    }

    @AuraEnabled
    public static void createListMember(String contactId, String listId) {
        try {
            CampaignMember member = new CampaignMember();
            member.ContactId = contactId;
            member.CampaignId = listId;
            BBApps_Crud.doInsertWithHandling(member, false, new BBApps_ErrorCustomFields(ERR_DML_INSERT));
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}