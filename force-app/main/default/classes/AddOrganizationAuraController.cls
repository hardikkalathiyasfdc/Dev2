/**
@Description: This class is used in Add organizations button on list to add multiple Organizations at once
**/
public with sharing class AddOrganizationAuraController {

    private static final String ERR_CREATE_LIST_ORGS = 'AOAC_CREATE_LIST_ORGS_FAILED';

    @AuraEnabled
    public static void createListOrganizations(String orgs, String listId) {
        try {
            List<Account> accounts = (List<Account>)JSON.deserialize(orgs, List<Account>.class);

            List<ListOrganization__c> listOrgs = new List<ListOrganization__c>();
            for( Account acct: accounts ) {
                ListOrganization__c tmpOrg = new ListOrganization__c();
                tmpOrg.List__c = listId;
                tmpOrg.Organization__c = acct.Id;
                tmpOrg.Unique__c = listId + '-' + acct.Id;

                listOrgs.add(tmpOrg);
            }

            if(!listOrgs.isEmpty()) {
                BBApps_Crud.doUpsertWithHandling(listOrgs, false, ERR_CREATE_LIST_ORGS);
            }

        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CREATE_LIST_ORGS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(ex.getMessage());
        }
    }
}