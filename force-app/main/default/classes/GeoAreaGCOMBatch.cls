/**
* Author      : Ravi Bheemreddy
* Description : Batch class that updates Geo_Area__c records with a flag if the Geo Area has atleast on GCOM related Association
* Test        : GeoAreaGCOMBatchTest
*/
global without sharing class GeoAreaGCOMBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final String ERR_BATCH_JOB_FAILED   = 'GEOAREA_GCOM_BATCH_JOB_FAILED';
    private static final String ERR_UPDATE_FAILED      = 'GEOAREA_GCOM_UPDATE_FAILED';

    private static final String MSG_BATCH_JOB_FAILED   = 'GeoAreaGCOMBatch job failed.';
    private static final String MSG_UPDATE_FAILED      = 'Failed while updating Geo Area GCOM flags.';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            return Database.getQueryLocator([
                SELECT Id, Government_Geo_Area__c
                FROM Account
                WHERE Government_Geo_Area__c != null WITH SYSTEM_MODE
            ]);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null WITH SYSTEM_MODE');
        }
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            Set<Id> geoAreaIds = new Set<Id>();

            for (Account acct : (List<Account>)scope) {
                if (acct.Government_Geo_Area__c != null) {
                    geoAreaIds.add(acct.Government_Geo_Area__c);
                }
            }

            if (geoAreaIds.isEmpty()) return;

            Set<Id> geoAreaIdsWithGCOM = new Set<Id>();

            for (Org_Association__c assoc : [
                SELECT Organization__r.Government_Geo_Area__c
                FROM Org_Association__c
                WHERE RecordType.DeveloperName = 'GCOM'
                AND Association__r.Active__c = TRUE
                AND Association__r.Deleted__c = FALSE 
                AND Association__r.Publish_to_CityView__c = TRUE
                AND Organization__r.Government_Geo_Area__c IN :geoAreaIds
                AND Deleted__c = false WITH SYSTEM_MODE
            ]) {
                Id geoId = assoc.Organization__r != null ? assoc.Organization__r.Government_Geo_Area__c : null;
                if (geoId != null) {
                    geoAreaIdsWithGCOM.add(geoId);
                }
            }

            List<Geo_Area__c> geoAreas = [
                SELECT Id, Has_GCOM_Association__c
                FROM Geo_Area__c
                WHERE Id IN :geoAreaIds WITH SYSTEM_MODE
            ];

            List<Geo_Area__c> geoAreasToUpdate = new List<Geo_Area__c>();

            for (Geo_Area__c geo : geoAreas) {
                Boolean shouldBeFlagged = geoAreaIdsWithGCOM.contains(geo.Id);
                if (geo.Has_GCOM_Association__c != shouldBeFlagged) {
                    geo.Has_GCOM_Association__c = shouldBeFlagged;
                    geoAreasToUpdate.add(geo);
                }
            } 

            if (!geoAreasToUpdate.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(geoAreasToUpdate, false, ERR_UPDATE_FAILED);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BATCH_JOB_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}