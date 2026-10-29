/********************************************************************************
* Class Name  : AddCampaignMemberController_Test
* Description : Test class for AddCampaignMember apex controller.
* Created By  : Slalom Consulting
* Change Log  : Created - 5/15/2019
********************************************************************************/
@isTest
private class AddCampaignMemberController_Test {
	@testSetup static void setup() {
		Account acc = new Account(Name = 'TestAcct');
		insert acc;
        Account acc2 = new Account(Name = 'None');
		insert acc2;
        // Create common test contacts
        List<Contact> testCons = new List<Contact>();
        for(Integer i=0;i<25;i++) {
            testCons.add(new Contact(LastName = 'TestCon'+i,AccountId = acc.Id));
        }

        for(Integer i=25;i<50;i++) {
            testCons.add(new Contact(LastName = 'TestCon'+i,AccountId = acc.Id,Bloomberg_Philanthropies_Board_Member__c = true, Categories__c = 'Education;Nonprofit'));
        }
        insert testCons;

        Campaign camp = new Campaign(Name = 'TestCampaign');
        insert camp;
        List<CampaignMemberStatus> lstCampStatus = new List<CampaignMemberStatus>();
		CampaignMemberStatus campStatus1 = new CampaignMemberStatus(Label = 'SentTest',CampaignId = camp.Id,isDefault = true);
        CampaignMemberStatus campStatus2 = new CampaignMemberStatus(Label = 'RSVPdTest',CampaignId = camp.Id,isDefault = false);
        lstCampStatus.add(campStatus1);
        lstCampStatus.add(campStatus2);
        insert lstCampStatus;
    }

    @isTest static void testMethod1() {
        // Get test campaign by using a SOQL query
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaign' WITH SYSTEM_MODE LIMIT 1];
        List<Contact> lstCon = [Select Id from Contact where LastName Like 'TestCon%' WITH SYSTEM_MODE LIMIT 10];
        List<String> selectedRecs = new List<String>();
        for(Contact con : lstCon){
        	selectedRecs.add(con.Id+'-'+'1');
        }
        List<String> categories = new List<String>();
        categories.add('Education');
        categories.add('Nonprofit');
        Test.startTest();
            List <String> getMultiPiklistValues = AddCampaignMemberController.getMultiPiklistValues();
            Map<String,String> calcMapFldLabelFldPath = AddCampaignMemberController.calcMapFldLabelFldPath();
            AddCampaignMemberController.addMemContact(selectedRecs,camp.Id);
        	List<AddCampaignMemberController.wrapperClass> initMethod = AddCampaignMemberController.initMethod();
        	initMethod[0].selectedFldLabel = 'LastName';
        	initMethod[0].searchTextVal = 'Test';
        	initMethod[1].selectedFldLabel = 'AccountId';
        	initMethod[1].searchTextVal = 'Test';
        	initMethod[2].selectedFldLabel = 'Bloomberg_Philanthropies_Board_Member__c';
        	initMethod[2].boardMem = true;
        	initMethod[3].selectedFldLabel = 'Categories__c';
        	initMethod[3].lstSelectedCategories = categories;
        	List < Contact > getContacts = AddCampaignMemberController.getContacts(initMethod,'10','1',camp.Id);
        	List<CampaignMember> cmList = CampaignMembersAuraController.getCampaignMembers(lstCon[0].Id, true);
            List<ListOrganization__c> orgList = CampaignMembersAuraController.getListOrganizations(lstCon[0].Id);
        system.assert(orgList.isEmpty());
        System.assertEquals(1, cmList.size());
        Test.stopTest();
    }

    @isTest static void testMethod2() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaign' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        	List<AddCampaignMemberController.wrapperClass> initMethod = AddCampaignMemberController.initMethod();
        	initMethod[0].selectedFldLabel = 'LastName';
        	initMethod[0].searchTextVal = 'Test';
        	initMethod[1].selectedFldLabel = 'AccountId';
        	initMethod[1].searchTextVal = 'Test';
        	initMethod[2].selectedFldLabel = 'Bloomberg_Philanthropies_Board_Member__c';
        	initMethod[2].boardMem = false;
        	initMethod[3].selectedFldLabel = 'CreatedDate';
        	initMethod[3].startDate = '2019-05-05';
        	initMethod[3].endDate = '2019-12-12';
        	List < Contact > getContacts = AddCampaignMemberController.getContacts(initMethod,'10','1',camp.Id);
        Test.stopTest();
    }

	@isTest static void testMethod3() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaign' WITH SYSTEM_MODE LIMIT 1];
        List<Contact> lstCon = [Select Id from Contact where Name Like 'TestCon%' WITH SYSTEM_MODE LIMIT 10];
		Test.startTest();
        	AddCampaignMemberController.addMemContactBasic(lstCon,camp.Id);
        	reUsableMultiSelectLookupCtrl.fetchLookUpValues('Test','Contact',lstCon);
        Test.stopTest();
    }
}