/**
* Author      : Ravi Bheemreddy
* Description : Test class for GeoAreaFocusAreaScheduler
*/
@isTest
public with sharing class GeoAreaFocusAreaSchedulerTest {
    
    @isTest
    static void testSchedulerExecution() {
        GeoAreaFocusAreaScheduler scheduler = new GeoAreaFocusAreaScheduler();
        
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, JobType, Status
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex' 
            WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC
        ];
        
        System.assert(!jobs.isEmpty(), 'Batch job should be queued');
        System.assertEquals('BatchApex', jobs[0].JobType);
    }    
}