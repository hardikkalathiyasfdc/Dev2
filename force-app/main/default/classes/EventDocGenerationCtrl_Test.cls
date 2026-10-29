@isTest
private without sharing class EventDocGenerationCtrl_Test {

    @isTest
    static void testEventsGeneration() {

        Campaign cm = new Campaign();
        cm.Name = 'test campaign';
        cm.Start_Date_Time__c = DateTime.now().addDays(1);
        cm.End_Date_Time__c = DateTime.now().addDays(2);
        cm.RecordTypeId = EventMangementAuraCtrl.EVENT_RECORD_TYPE_ID;
        insert cm;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('last', String.valueOf(Date.today()));
        EventDocGenerationCtrl ctrl = new EventDocGenerationCtrl();
        Test.stopTest();
    }
}