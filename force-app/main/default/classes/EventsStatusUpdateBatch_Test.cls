@isTest
private class EventsStatusUpdateBatch_Test {
    @testSetup
    static void dataPrep() {
        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.EventStatus__c ='Upcoming';
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;


        Campaign cm1 = new Campaign();
        cm1.Name = 'test campaign';
        cm1.Start_Date_Time__c = DateTime.now().addDays(-2);
        cm1.End_Date_Time__c = DateTime.now().addDays(-1);
        cm1.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
        cm1.EventStatus__c ='Upcoming';

        insert new List<Campaign>{cm, cm1};
    }

    @isTest
    static void testMethod1() {
        Test.startTest();

        EventsStatusUpdateBatch batchClass = new EventsStatusUpdateBatch();
        batchClass.execute(null);

        Test.stopTest();
    }
}