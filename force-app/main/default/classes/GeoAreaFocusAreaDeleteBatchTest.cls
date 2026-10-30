/**
* Author      : Ravi Bheemreddy
* Description : Test class for GeoAreaFocusAreaDeleteBatch
*/
@isTest
public class GeoAreaFocusAreaDeleteBatchTest {
	
    @testSetup 
    static void dataSetup () {
        insert TestDataFactory.createGafa();
    }
    
    @isTest
    static void testDeleteBatch () {
        System.assertEquals(1, [Select Id from Geo_Area_Focus_Area__c].size());
        Test.startTest();
        GeoAreaFocusAreaBatch batchJob = new GeoAreaFocusAreaBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Geo_Area_Focus_Area__c WITH SYSTEM_MODE];
        System.assertEquals(0, count);
    }
}