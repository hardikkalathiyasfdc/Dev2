@isTest
private class EmploymentHistoryBoardMemTrigger_Test {

    @isTest
    static void validateInserts() {
        Test.StartTest();
        Account acct = getAcct();
        Contact con = getCon();
        Employment_History_and_Board_Membership__c emp1 = new Employment_History_and_Board_Membership__c(
            Organization_Name__c = acct.Id,
            Contact_Name__c = con.Id,
            Role__c = 'Board Member',
            Employment_Start_Date__c = Date.newInstance(2026, 1, 1),
            Employment_End_Date__c = Date.newInstance(2027, 1, 1)
        );
        insert emp1;
        delete emp1;
        Test.StopTest();
    }

    @isTest
    static void validateUpdates() {
        Test.StartTest();
        Account acct = getAcct();
        Contact con = getCon();
        Employment_History_and_Board_Membership__c emp1 = new Employment_History_and_Board_Membership__c(
            Organization_Name__c = acct.Id,
            Contact_Name__c = con.Id,
            Role__c = 'Board Member'
        );
        insert emp1;
        emp1.Role__c = 'Board Member';
        emp1.Employment_Start_Date__c = Date.newInstance(2026, 1, 1);
        emp1.Employment_End_Date__c = Date.newInstance(2027, 1, 1);
        update emp1;
        delete emp1;
        Test.StopTest();
    }

    private static Account getAcct() {
        return [SELECT Name, Id FROM Account WITH SYSTEM_MODE LIMIT 1];
    }

    private static Contact getCon() {
        return [SELECT FirstName, LastName, AccountId FROM Contact WITH SYSTEM_MODE LIMIT 1];
    }

    @TestSetup
    private static void dataSetup() {
        Account a = TestDataFactory.getOrg('Bloomberg Philanthropies');
        insert a;
        Contact c = TestDataFactory.getContact('Last');
        c.AccountId = a.Id;
        insert c;
    }
}