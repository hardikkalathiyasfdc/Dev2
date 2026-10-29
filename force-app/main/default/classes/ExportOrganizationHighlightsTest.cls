@isTest
public class ExportOrganizationHighlightsTest {

    @isTest
    public static void testExportOrganizationHighlights() {
        Campaign campaignWithMembers = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, true)[0];
       	Account acct = TestDataFactory.createOrg('Test Account');
       	List<Contact> contacts = TestDataFactory.createMultipleContacts(acct.Id, 1, true);
        List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(campaignWithMembers,contacts, true);
       	RecordType touchpointRecType = [Select Id, Name from Recordtype where DeveloperName = 'Touchpoint' with SYSTEM_MODE];
       	Interaction__c interaction =  new Interaction__c();
       	interaction.Name = 'Test interaction';
        interaction.List__c = campaignWithMembers.Id;
       	interaction.RecordTypeId = touchpointRecType.Id;
        interaction.Interaction_Date__c = system.today();
       	interaction.Contact__c = contacts[0].Id;
        interaction.Teams__c = TestDataFactory.createTeam('Other').Id;
       	Database.insert(interaction);
        DateTime todate = system.now();
        Date fromDate = date.valueOf(todate.addMonths(-12));

        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<Campaign>{campaignWithMembers});
        ExportOrganizationHighlightsController cntrl = new ExportOrganizationHighlightsController(stdSetController);
        Set<String> orgIds = new Set<String>{acct.Id};
        ExportOrganizationHighlightsController.OrganizationHighlightWrapper orgWrapper = ExportOrganizationHighlightsController.getOrganizationHighlightsByOrgIds(orgIds, ExportOrganizationHighlightsController.ONLY_PUBLISHED_CITYVIEW,fromDate,system.today());
		ExportOrganizationHighlightsController.OrganizationHighlightWrapper orgWrapper1 = ExportOrganizationHighlightsController.getOrganizationHighlights(acct.Id, ExportOrganizationHighlightsController.ONLY_PUBLISHED_CITYVIEW,fromDate,system.today());
        ExportOrganizationHighlightsController.OrganizationHighlightWrapper orgWrapper2 = ExportOrganizationHighlightsController.getAllOrganizationHighlights(ExportOrganizationHighlightsController.ONLY_PUBLISHED_CITYVIEW, acct.Id,fromDate,system.today());
    }

    @isTest
    public static void testExportOrganizationHighlightsWithException() {
        ExportOrganizationHighlightsController.forceException = true;
        Campaign campaignWithMembers = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, true)[0];
       	Account acct = TestDataFactory.createOrg('Test Account');
       	List<Contact> contacts = TestDataFactory.createMultipleContacts(acct.Id, 1, true);
        List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(campaignWithMembers,contacts, true);
       	RecordType touchpointRecType = [Select Id, Name from Recordtype where DeveloperName = 'Touchpoint' with SYSTEM_MODE];
       	Interaction__c interaction =  new Interaction__c();
       	interaction.Name = 'Test interaction';
        interaction.List__c = campaignWithMembers.Id;
       	interaction.RecordTypeId = touchpointRecType.Id;
        interaction.Interaction_Date__c = system.today();
       	interaction.Contact__c = contacts[0].Id;
        interaction.Teams__c = TestDataFactory.createTeam('Other').Id;
       	Database.insert(interaction);
        DateTime todate = system.now();
        Date fromDate = date.valueOf(todate.addMonths(-12));

        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<Campaign>{campaignWithMembers});
        ExportOrganizationHighlightsController cntrl = new ExportOrganizationHighlightsController(stdSetController);
        Set<String> orgIds = new Set<String>{acct.Id};
        ExportOrganizationHighlightsController.OrganizationHighlightWrapper orgWrapper = ExportOrganizationHighlightsController.getOrganizationHighlightsByOrgIds(orgIds, ExportOrganizationHighlightsController.ONLY_PUBLISHED_CITYVIEW,fromDate,system.today());
		ExportOrganizationHighlightsController.OrganizationHighlightWrapper orgWrapper1 = ExportOrganizationHighlightsController.getOrganizationHighlights(acct.Id, ExportOrganizationHighlightsController.ONLY_PUBLISHED_CITYVIEW,fromDate,system.today());
        ExportOrganizationHighlightsController.OrganizationHighlightWrapper orgWrapper2 = ExportOrganizationHighlightsController.getAllOrganizationHighlights(ExportOrganizationHighlightsController.ONLY_PUBLISHED_CITYVIEW, acct.Id,fromDate,system.today());
    }
}