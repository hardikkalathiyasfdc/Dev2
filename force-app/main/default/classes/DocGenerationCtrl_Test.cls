@isTest
private without sharing class DocGenerationCtrl_Test {
    
    @isTest
    static void testController() {
        Account acc = TestDataFactory.createOrg('Test Account');
        Campaign camp = TestDataFactory.createCampaigns(1, Assets.CAMPAIGN_RECORDTYPE_TEAMS, true)[0]; 
        List<Contact> contacts = TestDataFactory.createMultipleContacts(acc.Id,2,true);
        contact objcontact = contacts[0];
        objcontact.Restricted__c=true;
        update objcontact;
        ApexPages.currentPage().getParameters().put('listId', camp.Id);
        ApexPages.currentPage().getParameters().put('retURL', '/test');
        ApexPages.currentPage().getParameters().put('docGenerateType', 'multibio');
        ApexPages.currentPage().getParameters().put('showInteraction', 'yes');
        ApexPages.currentPage().getParameters().put('id', objcontact.Id);
        DocGenerationCtrl ctrl = new DocGenerationCtrl();
        
        //Assert the contactIds are set correctly
        System.assertNotEquals(ctrl.contactIds, null, 'Contact IDs should not be null');
        System.assert(ctrl.contactIds.contains(objContact.Id), 'Contact IDs should contain the contact ID');
    }
}