@isTest
private class EmployeeDirectoryCtrl_Test {
    
    @isTest
    static void testDataFetching() {
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
        
        Contact cnt = new Contact();
        cnt.FirstName = 'bill';
        cnt.LastName = 'bar';
        cnt.AccountId = acc.Id;
        
        Contact cnt1 = new Contact();
        cnt1.FirstName = 'sam';
        cnt1.LastName = 'stock';

        insert new List<Contact>{cnt, cnt1};
            
        EmployeeDirectoryCtrl ctrl = new EmployeeDirectoryCtrl();
        ctrl.getOfficeInfo();
        ctrl.getContacts();
        ctrl.getContactsWillett();
        
        Test.StartTest();
        EmployeeDirectoryCtrl ctrl1 = new EmployeeDirectoryCtrl();
        EmployeeDirectoryCtrl.forceException = true;
        ctrl1.getOfficeInfo();
        ctrl1.getContacts();
        ctrl1.getContactsWillett();
        Test.StopTest();
    }
}