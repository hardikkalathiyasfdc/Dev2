/**
* Author      : Hardik Kalathiya
* Date        : 04/14/2025
* Jira        : BRME-5847
* Description : Calculates and updates the total GAFA (Geo Area Focus Area) weight for each Geo Area with focus areas using batch processing.
* Test        : GeoAreaWeightBatchTest
*/
global without sharing class GeoAreaWeightBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final String ERR_START   = 'GEOAREA_WEIGHT_START_FAILED';
    private static final String ERR_EXECUTE = 'GEOAREA_WEIGHT_EXECUTE_FAILED';
    private static final String ERR_DML     = 'GEOAREA_WEIGHT_UPDATE_FAILED';
    private static final String ERR_FINISH  = 'GEOAREA_WEIGHT_FINISH_FAILED';

    private static final String MSG_START   = 'Unable to start GeoAreaWeightBatch.';
    private static final String MSG_EXECUTE = 'Failed while executing GeoAreaWeightBatch chunk.';
    private static final String MSG_FINISH  = 'Failed while finishing GeoAreaWeightBatch.';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([
                SELECT Id FROM Geo_Area__c WHERE Geo_Area_Focus_Area_Count__c > 0 WITH SYSTEM_MODE
            ]);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_START);
            BBApps_ErrorHandler.logErrors(ex, f);
            return Database.getQueryLocator('SELECT Id FROM Geo_Area__c WHERE Id = null WITH SYSTEM_MODE');
        }
    }

    global void execute(Database.BatchableContext BC, List<Geo_Area__c> geoAreas) {
        try {
            if (geoAreas.isEmpty()) return;

            Set<Id> geoAreaIds = new Map<Id, Geo_Area__c>(geoAreas).keySet();
        // Map to store weight sums
            Map<Id, Decimal> geoAreaToWeightMap = new Map<Id, Decimal>();

        // Query and aggregate GAFA weights
            for (AggregateResult ar : [
                SELECT Geo_Area__c geoId, SUM(Weight__c) totalWeight
                FROM Geo_Area_Focus_Area__c 
                WHERE Geo_Area__c IN :geoAreaIds AND Weight__c > 0 WITH SYSTEM_MODE
                GROUP BY Geo_Area__c 
            ]) {
                geoAreaToWeightMap.put((Id) ar.get('geoId'), (Decimal) ar.get('totalWeight'));
            }

        // Prepare updates
            List<Geo_Area__c> geoUpdates = new List<Geo_Area__c>();
            for (Geo_Area__c ga : geoAreas) {
                Decimal weight = geoAreaToWeightMap.containsKey(ga.Id) ? geoAreaToWeightMap.get(ga.Id) : 0;
                ga.GAFA_Weight__c = weight;
                geoUpdates.add(ga);
            }

            if (!geoUpdates.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(geoUpdates, false, ERR_DML);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_EXECUTE);
        }
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}