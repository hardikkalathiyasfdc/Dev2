@isTest
private class EventHistoryGenerationCtrl_Test {

    @testSetup
    static void dataPrep() {
        Contact cnt = new Contact(FirstName='test', LastName='test', Email='test@test1.com', DoNotCall=false);
        Contact cnt1 = new Contact(FirstName='test1', LastName='test1', Email='test1@test1.com', DoNotCall=false);

        insert as system new List<Contact>{cnt, cnt1};


        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;

        Campaign cm1 = new Campaign();
        cm1.Name = 'test campaign1';
        cm1.EventStatus__c = 'Complete';
        cm1.Start_Date_Time__c = DateTime.now().addDays(1);
        cm1.End_Date_Time__c = DateTime.now().addDays(2);
        cm1.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
        insert as system new List<Campaign>{cm, cm1};

        CampaignMember member = new CampaignMember();
        member.ContactId = cnt.Id;
        member.CampaignId = cm.Id;
        member.RSVPStatus__c = 'Yes';
        member.AttendedStatus__c = 'Yes - In Person';
        
        CampaignMember member1 = new CampaignMember();
        member1.ContactId = cnt1.Id;
        member1.CampaignId = cm.Id;
        member1.RSVPStatus__c = 'No';
        member1.AttendedStatus__c = 'Yes - In Person';
        
        CampaignMember member2 = new CampaignMember();
        member2.ContactId = cnt.Id;
        member2.CampaignId = cm1.Id;
        member2.RSVPStatus__c = 'Yes';
        member2.AttendedStatus__c = 'Yes - In Person';
        
        insert as system new List<CampaignMember>{member, member1, member2};

    }

    @isTest
    static void testGetEventHistory() {
        Contact cnt = [SELECT Id FROM Contact WHERE LastName = 'test' WITH SYSTEM_MODE LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', cnt.Id);

        EventHistoryGenerationCtrl ctrl = new EventHistoryGenerationCtrl();
        System.assertEquals(2, ctrl.events.size());
    }
}