@isTest
public class TaskTriggerHandlerTest {

    @isTest
    public static void testTask() {
        Account acct = TestDataFactory.getOrg('Test Org');
        insert acct;
        Contact cnt = new Contact(AccountId = acct.Id, FirstName = 'Test', LastName = 'lastname');
        insert cnt;

        Test.startTest();
        	Contact chkCnt = [Select Id, Name from Contact where LastName = 'lastname' with SYSTEM_MODE];
            Task tsk = new Task(Subject='Test', whoId = chkCnt.Id);
        	insert tsk;
        	Task chkTask = [Select Id, WhoId_Name__c from Task where Id = :tsk.Id with SYSTEM_MODE];
            System.assert(chkTask.WhoId_Name__c.equalsIgnoreCase(chkCnt.Name));
        Test.stopTest();
    }
}