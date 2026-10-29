@isTest
private class OrgContactsByRoleAuraCtrl_Test {

    @isTest
    static void testMethod1() {
        // Force the exception path
        OrgContactsByRoleAuraCtrl.forceExceptionInTest = true;

        Test.startTest();
            String result = OrgContactsByRoleAuraCtrl.getContactsByOrgId('someOrgId');
        Test.stopTest();
    }


	@isTest
    static void testContactWithRoleFetch() {
        Account acc = new Account(Name='test acc');
        insert acc;

        Contact cnt = new Contact(FirstName='Test FirstName', LastName='Test LastName');
        insert cnt;

        Employment_History_and_Board_Membership__c history = new Employment_History_and_Board_Membership__c();
        history.Contact_Name__c = cnt.Id;
        history.Organization_Name__c = acc.Id;
        history.Role__c = 'Board Member';

        insert history;

        Test.startTest();
            String result = OrgContactsByRoleAuraCtrl.getContactsByOrgId(acc.Id);
        Test.stopTest();

        System.assert(String.isNotBlank(result));
    }
}