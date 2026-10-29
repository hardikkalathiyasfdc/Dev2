/**
* Author      : Ravi Bheemreddy
* Description : Batch class that removes outdated Geo_Area_Focus_Area__c records based on the latest Association data
* Test        : GeoAreaFocusAreaDeleteBatchTest
*/
global without sharing class GeoAreaFocusAreaDeleteBatch implements Database.Batchable<SObject>, Database.Stateful {
    public static List<String> orgGeoAreaTypes = new List<String>{
        Assets.ORGGEOAREACULTURALACCESS,
            Assets.ORGGEOAREACULTURALIMPLICIT
            };

                global Database.QueryLocator start(Database.BatchableContext BC) {
                    return Database.getQueryLocator([
                        SELECT Id, Geo_Area__c, Focus_Area__c FROM Geo_Area_Focus_Area__c
                    ]);
                }

    global void execute(Database.BatchableContext BC, List<Geo_Area_Focus_Area__c> gafList) {
        Set<Id> geoAreaIds = new Set<Id>();
        for (Geo_Area_Focus_Area__c gaf : gafList) {
            if (gaf.Geo_Area__c != null) {
                geoAreaIds.add(gaf.Geo_Area__c);
            }
        }

        if (geoAreaIds.isEmpty()) return;

        Set<String> validKeys = new Set<String>();
        Set<Id> geoAreasWithOtherCounts = new Set<Id>();
        Set<Id> validGeoAreasWithCulturalAccess = new Set<Id>();
        Set<Id> validGeoAreasWithOffices = new Set<Id>();

        Map<String, Id> focusAreaMap = new Map<String, Id>();
        for (Focus_Area__c fa : CityViewController.getCityViewFocusAreas()) {
            focusAreaMap.put(fa.Name, fa.Id);
        }

        for (AggregateResult ar : [
            SELECT Organization__r.Government_Geo_Area__c geoId, Association__r.Foundation_Coding__r.Level_1__c faName
            FROM Org_Association__c
            WHERE Organization__r.Government_Geo_Area__c IN :geoAreaIds
            AND Organization__r.Restricted__c = FALSE
            AND Organization__r.Government_Geo_Area__r.Deleted__c = FALSE
            AND Association__r.Active__c = TRUE
            AND Association__r.Publish_to_CityView__c = TRUE
            AND Association__r.Deleted__c = FALSE
            AND Association__r.RecordType.DeveloperName IN ('Standard', 'Initiative')
            AND Deleted__c = FALSE
            GROUP BY Organization__r.Government_Geo_Area__c, Association__r.Foundation_Coding__r.Level_1__c
        ]) {
            Id geoId = (Id) ar.get('geoId');
            String faName = (String) ar.get('faName');
            if (geoId != null && String.isNotBlank(faName)) {
                if (focusAreaMap.containsKey(faName)) {
                    validKeys.add(geoId + '-' + focusAreaMap.get(faName));
                } else {
                    geoAreasWithOtherCounts.add(geoId);
                }
            }
        }

        for (AggregateResult ar : [
            SELECT Organization__r.Government_Geo_Area__c geoId, Foundation_Coding__r.Level_1__c faName
            FROM Interaction__c
            WHERE Organization__r.Government_Geo_Area__c IN :geoAreaIds
            AND CityView_Review_Status__c = 'Publish to CityView'
            AND RecordType.DeveloperName = 'Recent_Engagement'
            GROUP BY Organization__r.Government_Geo_Area__c, Foundation_Coding__r.Level_1__c
        ]) {
            Id geoId = (Id) ar.get('geoId');
            String faName = (String) ar.get('faName');
            if (geoId != null && String.isNotBlank(faName)) {
                if (focusAreaMap.containsKey(faName)) {
                    validKeys.add(geoId + '-' + focusAreaMap.get(faName));
                } else {
                    geoAreasWithOtherCounts.add(geoId);
                }
            }
        }

        for (Org_Geo_Area__c rec : [
            SELECT Geo_Area__c, Geo_Area__r.Parent__c, Geo_Area__r.Parent__r.Parent__c FROM Org_Geo_Area__c
            WHERE Type__c IN: orgGeoAreaTypes
            AND Geo_Area__c IN: geoAreaIds
        ]) {
            if (rec.Geo_Area__c != null) {
                validGeoAreasWithCulturalAccess.add(rec.Geo_Area__c);
                validGeoAreasWithCulturalAccess.add(rec.Geo_Area__r.Parent__c);
                validGeoAreasWithCulturalAccess.add(rec.Geo_Area__r.Parent__r.Parent__c);
            }
        }

        for (Bloomberg_Office__c office : [
            SELECT Id, Geo_Area__c, Geo_Area__r.Parent__c, Geo_Area__r.Parent__r.Parent__c
            FROM Bloomberg_Office__c
            WHERE Geo_Area__c != NULL
        ]) {
            validGeoAreasWithOffices.add(office.Geo_Area__c);
            if (office.Geo_Area__r.Parent__c != null) validGeoAreasWithOffices.add(office.Geo_Area__r.Parent__c);
            if (office.Geo_Area__r.Parent__r.Parent__c != null) validGeoAreasWithOffices.add(office.Geo_Area__r.Parent__r.Parent__c);
        }

        List<Geo_Area_Focus_Area__c> toDelete = new List<Geo_Area_Focus_Area__c>();
        for (Geo_Area_Focus_Area__c gaf : gafList) {
            String key = gaf.Geo_Area__c + '-' + gaf.Focus_Area__c;
            Boolean isNullFocusArea = gaf.Focus_Area__c == null;

            Boolean isValidNullFocus =
                isNullFocusArea &&
                (
                    geoAreasWithOtherCounts.contains(gaf.Geo_Area__c) ||
                    validGeoAreasWithCulturalAccess.contains(gaf.Geo_Area__c) ||
                    validGeoAreasWithOffices.contains(gaf.Geo_Area__c)
                );

            Boolean isValid = !isNullFocusArea && validKeys.contains(key);

            if (!isValid && !isValidNullFocus) {
                toDelete.add(gaf);
            }
        }

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    global void finish(Database.BatchableContext BC) {
        GeoAreaWeightBatch batchGeoAreaWeightJob = new GeoAreaWeightBatch();
        Database.executeBatch(batchGeoAreaWeightJob);
    }
}