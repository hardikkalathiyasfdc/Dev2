@isTest
public class ListCollaboratorBatch_Test {
	private final static String CAMP_REC = 'Events';
    @testSetup
    static void dataSetup () {
        List<Campaign> campaignList = new List<Campaign> ();
        Campaign testCamp = TestDataFactory.getList('test list', CAMP_REC);
        testCamp.End_Date_Time__c = System.now().addDays(-8);
    	campaignList.add(testCamp);
        
        Campaign testCamp2 = TestDataFactory.getList('test list2', CAMP_REC);
        testCamp2.End_Date_Time__c = System.now().addDays(-4);
    	campaignList.add(testCamp2);
        
        insert as system campaignList;
        
        List<Collaborator__c> collaboratorList = new List<Collaborator__c> ();
        User u = [Select Id from user where FirstName = 'Sudhir' WITH SYSTEM_MODE LIMIT 1];
        Collaborator__c c1 = new Collaborator__c (
        	List__c = testCamp.Id,
            Access_Level__c = 'Read',
            Collaborator__c = u.id
        );
        
        collaboratorList.add(c1);
        
        Collaborator__c c2 = new Collaborator__c (
        	List__c = testCamp2.Id,
            Access_Level__c = 'Read',
            Collaborator__c = u.Id
        );
        
        collaboratorList.add(c2);
        
        insert as system collaboratorList;
    }
    
    @isTest
    static void deleteCollaboratorPositiveTest () {
        Campaign list1 = [Select Id from Campaign where Name = 'test list' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        ListCollaboratorBatch b = new ListCollaboratorBatch(); 
      	Database.executeBatch(b, 200);
        Test.stopTest();
        
        System.assertEquals(0, [Select Id from Collaborator__c where List__c =: list1.Id WITH SYSTEM_MODE].size());
    }
    
    @isTest
    static void deleteCollaboratorNegativeTest () {
        Campaign list1 = [Select Id from Campaign where Name = 'test list2' WITH SYSTEM_MODE LIMIT 1];
        Test.startTest();
        ListCollaboratorBatch b = new ListCollaboratorBatch(); 
      	Database.executeBatch(b, 200);
        Test.stopTest();
        
        System.assertEquals(1, [Select Id from Collaborator__c where List__c =: list1.Id WITH SYSTEM_MODE].size());
    }
    
    @isTest
    static void schedularTest () {
        Campaign list1 = [Select Id from Campaign where Name = 'test list2' WITH SYSTEM_MODE LIMIT 1];
        ListCollaboratorBatchSchedulable scc = new ListCollaboratorBatchSchedulable ();
        SchedulableContext sc = null;
        Test.startTest();
        scc.execute(sc);
        Test.stopTest();
        
        System.assertEquals(1, [Select Id from Collaborator__c where List__c =: list1.Id WITH SYSTEM_MODE].size());
    }
}