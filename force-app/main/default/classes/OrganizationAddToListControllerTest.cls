@isTest
public class OrganizationAddToListControllerTest {

    @TestSetup
    static void dataPrep() {
        Account acc = TestDataFactory.createOrg('Test Org');
        Campaign camp = TestDataFactory.createCampaign('Test Campaign');
    }

    @isTest
    static void testCheckGuestInList_ReturnsTrue_WhenMemberExists() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        ListOrganization__c newMember = new ListOrganization__c();
            newMember.Organization__c = acc.Id;
            newMember.List__c = camp.Id;
        insert newMember;
        Test.startTest();
        Boolean result = OrganizationAddToListController.checkOrgInList(acc.Id, camp.Id);
        Test.stopTest();
        System.assertEquals(true, result, 'Method should return true when ListOrganization__c exists.');
    }

    @isTest
    static void testCreateListMember_InsertsListOrganizationMember() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Test.startTest();
        OrganizationAddToListController.createListOrganizationMember(acc.Id, camp.Id);
        Test.stopTest();
        List<ListOrganization__c> members = [
            SELECT Id, Organization__c, List__c
            FROM ListOrganization__c
            WHERE Organization__c = :acc.Id
              AND List__c = :camp.Id
        ]; 
        System.assertEquals(1, members.size());
    }
    
    @isTest
    static void testCheckGuestInList_TriggersCatchBlock_OnInvalidIds() {
        String invalidAccountId = 'notAnId';
        String invalidCampaignId = 'alsoBad';
        Test.startTest();
        Boolean result = OrganizationAddToListController.checkOrgInList(invalidAccountId, invalidCampaignId);
        Test.stopTest();
        System.assertEquals(false, result, 'Method should safely return false when query fails and hits catch.');
    }

    @isTest
    static void testCreateListMember_TriggersCatchBlock_OnInvalidCampaignId() {
        Account acc = new Account(Name = 'ForErrorTest');
        insert acc;
        Id validAccountId = acc.Id;
        String invalidCampaignId = 'badId';
        Test.startTest();
        OrganizationAddToListController.createListOrganizationMember(validAccountId, invalidCampaignId);
        Test.stopTest();
        List<ListOrganization__c> members = [
            SELECT Id
            FROM ListOrganization__c
            WHERE Organization__c = :validAccountId
        ];
        System.assertEquals(0, members.size());
    }
}