/********************************************************************************
* Class Name  : EditMemberContactsController_Test
* Description : Test class for EditMemberContactsController apex controller.
* Created By  : Slalom Consulting
* Change Log  : Created - 7/21/2019
********************************************************************************/
@isTest
private class EditMemberContactsController_Test {
    @testSetup static void setup() {
        Account acc = new Account(Name = 'TestAcct');
        insert acc;

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
        List<CampaignMember> lstCampMems = new List<CampaignMember>();
        for(Integer i=0;i<25;i++){
            CampaignMember newMember = new CampaignMember(ContactId = testCons[i].id, status='Sent', campaignid = camp.id);
            lstCampMems.add(newMember);
        }
        insert lstCampMems;
    }

    @isTest static void testMethod1() {
        // Get test campaign by using a SOQL query
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaign' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        List < Contact > lstCons = EditMemberContactsController.getContactsToEdit(camp.Id);
        for(Contact con : lstCons){
            con.MailingState = 'NJ';
        }
        if(lstCons != null && lstCons.size()>0){
            lstCons[0].MailingState = '';
        }
        try{
            EditMemberContactsController.validateContacts(lstCons);
            if(lstCons != null && lstCons.size()>0){
                lstCons[0].Salutation = 'test';
            }
            EditMemberContactsController.validateContacts(lstCons);
            Boolean creatable =   EditMemberContactsController.validateCreateInteractionAccess();
        }catch(Exception ex){}
        EditMemberContactsController.updateContacts(lstCons,camp.Id);
        Test.stopTest();
    }

    @isTest static void testMethod2() {
        // Get test campaign by using a SOQL query
        EditMemberContactsController.forceException = true;
        Campaign camp = [SELECT Id FROM Campaign WHERE Name='TestCampaign' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        List < Contact > lstCons = EditMemberContactsController.getContactsToEdit(camp.Id);
        Boolean creatable =   EditMemberContactsController.validateCreateInteractionAccess();
        if(lstCons != null && lstCons.size()>0){
            for(Contact con : lstCons){
                con.MailingState = 'NJ';
            }
            lstCons[0].MailingState = '';
        }
        try{
            EditMemberContactsController.validateContacts(lstCons);
            if(lstCons != null && lstCons.size()>0){
                lstCons[0].Salutation = 'test';
            }
            EditMemberContactsController.validateContacts(lstCons);
        }catch(Exception ex){}
        EditMemberContactsController.updateContacts(lstCons,camp.Id);
        Test.stopTest();
    }
}