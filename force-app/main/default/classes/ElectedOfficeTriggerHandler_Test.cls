@isTest
private class ElectedOfficeTriggerHandler_Test {

	@isTest
    static void testCustomHistoryTracking() {
    	Contact cnt = new Contact(FirstName='test', LastName='test');
    	insert cnt;

    	Test.startTest();
        ElectedOffice__c eo = new ElectedOffice__c();
        eo.ElectedStatus__c = 'Active';
        eo.MRBContributions__c = 'test MRB';
        eo.Contact__c = cnt.Id;

        insert eo;

        eo.IEActivity__c = 'Beyond Carbon';

        update eo;

        Test.stopTest();
        List<Custom_History__c> history = [SELECT Id FROM Custom_History__c where Record_Id__c =: eo.Id];
        System.assertEquals(2, history.size());
    }
}