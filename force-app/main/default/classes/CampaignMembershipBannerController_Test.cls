@isTest 
public with sharing class CampaignMembershipBannerController_Test {

    @isTest static void testGetMyDomain(){

        Test.startTest();
        CampaignMembershipBannerController.getMyDomain();
        Test.stopTest();
    }
    
    @isTest static void testGetUser(){

        String userId = UserInfo.getUserId();

        Test.startTest();
        User userName = CampaignMembershipBannerController.getUser(userId);
        Test.stopTest();

        System.assertNotEquals(userName, null);
    }
    
    @isTest static void testGetContact(){
        
        // Create Data
		Contact newContact =  new Contact();
		newContact.LastName = 'Test Contact';
	    insert newContact;

        Test.startTest();
        Contact contactName = CampaignMembershipBannerController.getContact(newContact.Id);
        Test.stopTest();

        System.assertNotEquals(contactName, null);
    }
    
    @isTest static void testGetCampDetails(){

        //Create Data
        Campaign newCampaign = new Campaign();
        newCampaign.Name = 'Campaign Test Name';
        newCampaign.Description = 'Campaign Test Description';
        newCampaign.Enable_Contact_Alert_Banner__c = true;
        newCampaign.End_Date_Time__c = System.Now();
        insert newCampaign;

        Account newAccount =  new Account();
		newAccount.Name = 'Test Account';
	    insert newAccount;
        
        Contact newContact =  new Contact();
		newContact.LastName = 'Test Contact';
        newContact.AccountId = newAccount.Id;
	    insert newContact;

        CampaignMember cm = new CampaignMember();
        cm.ContactId = newContact.Id;
        cm.CampaignId = newCampaign.Id;
        insert cm;

        Test.startTest();
        CampaignMembershipBannerController.isActiveCampaignMemberReturn resultC = CampaignMembershipBannerController.isActiveCampaignMember(newContact.Id, 'Contact');
        CampaignMembershipBannerController.isActiveCampaignMemberReturn resultA = CampaignMembershipBannerController.isActiveCampaignMember(newContact.Id, 'Account');
        
        Test.stopTest();

        System.assertNotEquals(resultC, null);
        System.assertNotEquals(resultA, null);

    }
}