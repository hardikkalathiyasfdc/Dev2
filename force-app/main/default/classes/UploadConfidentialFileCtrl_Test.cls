@isTest
private class UploadConfidentialFileCtrl_Test {
    @isTest
    static void testController() {
        
        Account acc = new Account(Name='Test');
        insert acc;
        
        Test.startTest();
        
        ApexPages.CurrentPage().getparameters().put('id', acc.Id);
        UploadConfidentialFileCtrl ctrl = new UploadConfidentialFileCtrl();
        
        Test.stopTest();
        System.assertEquals('Test', ctrl.title);
        System.assertEquals(acc.Id, ctrl.currentRecordId);
    }
}