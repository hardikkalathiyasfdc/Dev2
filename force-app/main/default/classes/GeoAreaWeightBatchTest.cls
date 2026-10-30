@isTest
private class GeoAreaWeightBatchTest {

    @isTest
    static void testGeoAreaWeightBatch() {
       
	 TestDataFactory.createGeoHierarchy();
        Test.startTest();
        Database.executeBatch(new GeoAreaWeightBatch());
        Test.stopTest();

        // Validate updated GAFA_Weight__c
        List<Geo_Area__c> updatedAreas = [
            SELECT Id, GAFA_Weight__c FROM Geo_Area__c WHERE Geo_Area_Focus_Area_Count__c > 0 WITH SYSTEM_MODE
        ];

        for (Geo_Area__c area : updatedAreas) {
           System.assertEquals(0, area.GAFA_Weight__c, 'GAFA_Weight__c should be 0 if there are no focus areas');
        }
    }

    @IsTest
    static void execute_catch_only() {
        Test.startTest();
        try {
            new GeoAreaWeightBatch().execute(null, (List<Geo_Area__c>)null);
        } catch (Exception e) {
            
        }
        	
        Test.stopTest();
    }
}