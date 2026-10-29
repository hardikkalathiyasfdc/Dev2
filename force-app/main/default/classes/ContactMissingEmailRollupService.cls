/**
 * Author: Nishant Bakhrey
 * Date: 07/07/2026
 * Description: This class is responsible for recalculating the Contacts Missing Email Count rollup field
 * Test: ContactMissingEmailRollupServiceTest
 */
public without sharing class ContactMissingEmailRollupService {

    private static final String ERR_UPDATE_CAMPAIGN_MISSING_EMAIL_ROLLUP = 'Error updating Campaign missing email rollup';
    private static final String ERR_ContactMissingEmailRollupService = 'ContactMissingEmailRollupService_FAILED';

    public static void recalculateForCampaigns(Set<Id> campaignIds) {
        try {
            if(campaignIds == null || campaignIds.isEmpty()) return;
            Map<Id, Integer> campaignIdToMissingCount = new Map<Id, Integer>();
            for(AggregateResult ar : [SELECT CampaignId campaignId, COUNT(Id) missingCount
                                      FROM CampaignMember
                                      WHERE CampaignId IN :campaignIds
                                        AND ContactId != null
                                        AND (Contact_Priority_email__c = null OR Contact_Priority_email__c = '')
                                      WITH SYSTEM_MODE
                                      GROUP BY CampaignId]) {

                campaignIdToMissingCount.put((Id) ar.get('campaignId'), (Integer) ar.get('missingCount'));
            }
            List<Campaign> campaignsToUpdate = new List<Campaign>();
            for(Id campaignId : campaignIds) {
                campaignsToUpdate.add(new Campaign(
                    Id = campaignId,
                    Contacts_Missing_Email_Count__c = campaignIdToMissingCount.containsKey(campaignId)
                                                      ? campaignIdToMissingCount.get(campaignId)
                                                      : 0
                ));
            }
            if(!campaignsToUpdate.isEmpty())
                BBApps_Crud.doUpdateWithHandling(campaignsToUpdate, false, ERR_UPDATE_CAMPAIGN_MISSING_EMAIL_ROLLUP);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_ContactMissingEmailRollupService));
        }
    }

    public static void recalculateForContacts(Set<Id> contactIds) {
        try {
            if(contactIds == null || contactIds.isEmpty()) return;
            Set<Id> campaignIds = new Set<Id>();
            for(CampaignMember cm : [SELECT CampaignId FROM CampaignMember WHERE ContactId IN :contactIds AND CampaignId != null WITH SYSTEM_MODE]) {
                campaignIds.add(cm.CampaignId);
            }
            recalculateForCampaigns(campaignIds);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_ContactMissingEmailRollupService));
        }
    }
}