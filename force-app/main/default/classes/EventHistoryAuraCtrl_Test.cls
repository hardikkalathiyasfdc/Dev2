@isTest
private without sharing class EventHistoryAuraCtrl_Test {
    @testSetup
    static void dataPrep() {
        Contact cnt = new Contact(FirstName='test', LastName='test', Email='test@test1.com', DoNotCall=false);
        insert as system new List<Contact>{cnt};
        
        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
        cm.Private_Campaign__c = FALSE;
        cm.MRBHosting__c = FALSE;
        insert as system cm;
        
        CampaignMember member = new CampaignMember(
            ContactId = cnt.Id,
            CampaignId = cm.Id,
            RSVPStatus__c = 'Yes',
            AttendedStatus__c = 'Yes - In Person'
        );
        insert as system new List<CampaignMember>{member};
    }


    @isTest
    static void testGuestEvents() {
        Contact cnt = [SELECT Id FROM Contact WHERE LastName = 'test' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
            String result = EventHistoryAuraCtrl.getEventsByContact(cnt.Id);
            System.assert(String.isNotBlank(result));

            Boolean isAccess = EventHistoryAuraCtrl.getEventPrintButtonAccess(); 
            System.assertEquals(true, isAccess);
        Test.stopTest();
    }
}