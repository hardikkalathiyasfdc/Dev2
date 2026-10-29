/********************************************************************************
* Class Name  : CampaignCloneWithMembersController_Test
* Description : Test class for CampaignCloneWithMembersController apex controller.
* Created By  : Slalom Consulting
* Change Log  : Created - 6/10/2019
********************************************************************************/
@isTest
private class CampaignCloneWithMembersController_Test {
    @testSetup static void setup() {
        Account acc = new Account(Name = 'TestAcct');
        insert acc;
        // Create common test contacts
        List<Contact> testCons = new List<Contact>();
        for(Integer i=0;i<25;i++) {
            testCons.add(new Contact(LastName = 'TestCon'+i,AccountId = acc.Id));
        }

        insert testCons;
        // Mark one contact restricted so getRestrictedContactInfo returns a non-zero count.
        testCons[0].Restricted__c = true;
        update testCons[0];

        Campaign camp = new Campaign(Name = 'TestCloneCampaign');
        insert camp;
        List<CampaignMemberStatus> lstCampStatus = new List<CampaignMemberStatus>();
        CampaignMemberStatus campStatus1 = new CampaignMemberStatus(Label = 'SentClone',CampaignId = camp.Id,isDefault = true);
        CampaignMemberStatus campStatus2 = new CampaignMemberStatus(Label = 'RSVPdClone',CampaignId = camp.Id,isDefault = false);
        lstCampStatus.add(campStatus1);
        lstCampStatus.add(campStatus2);
        insert lstCampStatus;
        List<CampaignMember> lstCampMem = new List<CampaignMember>();
        for(Contact con : testCons){
            CampaignMember cm= New CampaignMember(CampaignId=camp.Id, ContactId= con.Id, Status='SentClone', Preferred_Address__c = 'Business', Other_Address__c = 'Test Other address', UB_Notes__c = 'test notes');
            lstCampMem.add(cm);
        }
        insert lstCampMem;
    }

    @isTest static void testMethod1() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCloneCampaign' WITH SYSTEM_MODE LIMIT 1];
        Campaign campIns = new Campaign();
        campIns.Name = 'Test Campaign Clone';
        Test.startTest();
        Id clonedCampId = CampaignCloneWithMembersController.cloneCampaignWithMem(campIns,camp.Id);
        List<CampaignMember> lstCampMems = [Select id from CampaignMember where CampaignId =: clonedCampId WITH SYSTEM_MODE];
        System.assertEquals(lstCampMems.size(),0);

        // Exercise the restricted-contact info check used by the Clone quick action.
        Map<String, Object> info = CampaignCloneWithMembersController.getRestrictedContactInfo(camp.Id);
        System.assertNotEquals(null, info.get('restrictedCount'));
        System.assert(info.containsKey('hasPrivateAccess'));
        // Cover the without-sharing detector used by the info method.
        Integer restrictedMembers = RestrictedRecordDetector.countRestrictedContactsInList(camp.Id);
        System.assertEquals(1, restrictedMembers, 'Should detect the restricted member');
        Test.stopTest();
    }

    @isTest static void testGetFieldsToClone() {
        Test.startTest();
        // Happy path: valid record type/object from custom metadata.
        String fields = CampaignCloneWithMembersController.getFieldsToClone('Pre_Event', 'Campaign');
        // Exception path: invalid record type returns null (caught internally).
        String noConfig = CampaignCloneWithMembersController.getFieldsToClone('No_Such_RT', 'Campaign');
        Test.stopTest();
        System.assertEquals(null, noConfig);
    }
}