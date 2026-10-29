/**
* Author      : Ravi Bheemreddy
* Description : Batch Job to create Geo_Area_Focus_Area__c records upon data sync from Tableau
* Test        : GeoAreaFocusAreaBatchTest
*/
global without sharing class GeoAreaFocusAreaBatch implements Database.Batchable<SObject> {

    private static final String ERR_START          = 'GAFAB_START_FAILED';
    private static final String ERR_EXECUTE        = 'GAFAB_EXECUTE_FAILED';
    private static final String ERR_PROCESS_COUNTS = 'GAFAB_PROCESS_COUNTS_FAILED';
    private static final String ERR_UPSERT         = 'GAFAB_UPSERT_FAILED';
    private static final String ERR_FINISH         = 'GAFAB_FINISH_FAILED';

    private static final String MSG_START          = 'Unable to start GeoAreaFocusAreaBatch.';
    private static final String MSG_EXECUTE        = 'Failed while executing GeoAreaFocusAreaBatch chunk.';
    private static final String MSG_PROCESS_COUNTS = 'Failed while aggregating counts for Geo/Focus Areas.';
    private static final String MSG_UPSERT         = 'Failed while upserting Geo_Area_Focus_Area__c records.';
    private static final String MSG_FINISH         = 'Failed while finishing GeoAreaFocusAreaBatch.';

    private Map<String, Id> focusAreaMap = new Map<String, Id>();
    private Map<Id, Map<Id, CountWrapper>> geoAreaCounts = new Map<Id, Map<Id, CountWrapper>>();
    private Map<Id, CountWrapper> otherCounts = new Map<Id, CountWrapper>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id FROM Account WHERE Government_Geo_Area__c != NULL'
        );
    }

    global void execute(Database.BatchableContext BC, List<Account> accountList) {
        try {
            focusAreaMap.clear();
            for(Focus_Area__c fa : CityViewController.getCityViewFocusAreas()) {
                focusAreaMap.put(fa.Name, fa.Id);
            }
            if(accountList.isEmpty()) return;
            Set<Id> orgIds = new Set<Id>();
            for(Account acc : accountList) orgIds.add(acc.Id);
            processCounts(orgIds, true);
            processCounts(orgIds, false);
            processGrantAssociationCount(orgIds);
            upsertGeoAreaFocusAreas();
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    public void processCounts(Set<Id> orgIds, Boolean isOrgAssociation) {
        try {
            if(isOrgAssociation) {
                List<Org_Association__c> orgAssociations = [
                    SELECT Organization__r.Government_Geo_Area__c, Association__r.Foundation_Coding__r.Level_1__c,
                    Association__r.CityView_Name_Override__c, Association__r.Name, RecordType.DeveloperName
                    FROM Org_Association__c
                    WHERE Organization__c IN :orgIds
                    AND Organization__r.Restricted__c = FALSE
                    AND Organization__r.Government_Geo_Area__r.Deleted__c = FALSE
                    AND Association__r.Active__c = TRUE
                    AND Association__r.Publish_to_CityView__c = TRUE
                    AND Association__r.Deleted__c = FALSE
                    AND Association__r.RecordType.DeveloperName IN (:Assets.ASSOCIATION_RECORDTYPE_INITIATIVE, :Assets.ASSOCIATION_RECORDTYPE_STANDARD)
                    AND RecordType.DeveloperName NOT IN (:Assets.ORG_ASSOCIATION_RECORDTYPE_GRANT)
                    AND Deleted__c = FALSE
                ];
                Map<Id, Map<String, Set<String>>> dedupMap = new Map<Id, Map<String, Set<String>>>();
                for(Org_Association__c oa : orgAssociations) {
                    Id geoId = oa.Organization__r.Government_Geo_Area__c;
                    String focusAreaName = oa.Association__r.Foundation_Coding__r.Level_1__c;
                    String associationName = oa.Association__r.CityView_Name_Override__c != '' && oa.Association__r.CityView_Name_Override__c != null
                        ? oa.Association__r.CityView_Name_Override__c
                        : oa.Association__r.Name;
                    if(geoId == null || associationName == null) continue;
                    if(!dedupMap.containsKey(geoId)) {
                        dedupMap.put(geoId, new Map<String, Set<String>>());
                    }
                    if(!dedupMap.get(geoId).containsKey(focusAreaName)) {
                        dedupMap.get(geoId).put(focusAreaName, new Set<String>());
                    }
                    dedupMap.get(geoId).get(focusAreaName).add(associationName);
                }
                for(Id geoId : dedupMap.keySet()) {
                    for(String focusAreaName : dedupMap.get(geoId).keySet()) {
                        Integer count = dedupMap.get(geoId).get(focusAreaName).size();
                        Id focusAreaId = focusAreaMap.get(focusAreaName);
                        if(focusAreaId == null) {
                            if(!otherCounts.containsKey(geoId)) {
                                otherCounts.put(geoId, new CountWrapper());
                            }
                            otherCounts.get(geoId).associationCount += count;
                            continue;
                        }
                        if(!geoAreaCounts.containsKey(geoId)) {
                            geoAreaCounts.put(geoId, new Map<Id, CountWrapper>());
                        }
                        if(!geoAreaCounts.get(geoId).containsKey(focusAreaId)) {
                            geoAreaCounts.get(geoId).put(focusAreaId, new CountWrapper());
                        }
                        geoAreaCounts.get(geoId).get(focusAreaId).associationCount += count;
                    }
                }
            } else {
                String query =
                    'SELECT Organization__r.Government_Geo_Area__c geoId, ' +
                    'Foundation_Coding__r.Level_1__c focusAreaName, COUNT(Id) cnt ' +
                    'FROM Interaction__c ' +
                    'WHERE Organization__c IN :orgIds ' +
                    'AND CityView_Review_Status__c = \'Publish to CityView\' ' +
                    'AND Private_Interaction__c = FALSE ' +
                    'AND RecordType.DeveloperName = \'Recent_Engagement\' ' +
                    'GROUP BY Organization__r.Government_Geo_Area__c, Foundation_Coding__r.Level_1__c';
                for(AggregateResult ar : Database.query(query)) {
                    Id geoId = (Id)ar.get('geoId');
                    String focusAreaName = (String)ar.get('focusAreaName');
                    Integer count = (Integer)ar.get('cnt');
                    Id focusAreaId = focusAreaMap.get(focusAreaName);
                    if(focusAreaId == null) {
                        if(!otherCounts.containsKey(geoId)) {
                            otherCounts.put(geoId, new CountWrapper());
                        }
                        otherCounts.get(geoId).interactionCount += count;
                        continue;
                    }
                    if(!geoAreaCounts.containsKey(geoId)) {
                        geoAreaCounts.put(geoId, new Map<Id, CountWrapper>());
                    }
                    if(!geoAreaCounts.get(geoId).containsKey(focusAreaId)) {
                        geoAreaCounts.get(geoId).put(focusAreaId, new CountWrapper());
                    }
                    geoAreaCounts.get(geoId).get(focusAreaId).interactionCount += count;
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_PROCESS_COUNTS);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    public void processGrantAssociationCount(Set<Id> orgIds){
        List<Org_Association__c> grantAssociations = [
            SELECT Organization__r.Government_Geo_Area__c,
            Association__r.Foundation_Coding__r.Level_1__c,
            Association__r.CityView_Name_Override__c,
            Association__r.Name,
            RecordType.DeveloperName
            FROM Org_Association__c
            WHERE Organization__c IN :orgIds
            AND Organization__r.Restricted__c = FALSE
            AND Organization__r.Government_Geo_Area__r.Deleted__c = FALSE
            AND Association__r.Active__c = TRUE
            AND Association__r.Publish_to_CityView__c = TRUE
            AND Association__r.Deleted__c = FALSE
            AND Association__r.RecordType.DeveloperName IN (:Assets.ASSOCIATION_RECORDTYPE_INITIATIVE, :Assets.ASSOCIATION_RECORDTYPE_STANDARD)
            AND RecordType.DeveloperName = :Assets.ORG_ASSOCIATION_RECORDTYPE_GRANT
            AND Deleted__c = FALSE
        ];

        Map<Id, Map<String, Set<String>>> grantDedup = new Map<Id, Map<String, Set<String>>>();

        for (Org_Association__c oa : grantAssociations) {
            Id geoId = oa.Organization__r.Government_Geo_Area__c;
            String focusAreaName = oa.Association__r.Foundation_Coding__r.Level_1__c;
            String associationName =
                (oa.Association__r.CityView_Name_Override__c != null && oa.Association__r.CityView_Name_Override__c != '')
                ? oa.Association__r.CityView_Name_Override__c
                : oa.Association__r.Name;

            if (geoId == null || associationName == null) continue;

            if (!grantDedup.containsKey(geoId)) {
                grantDedup.put(geoId, new Map<String, Set<String>>());
            }
            if (!grantDedup.get(geoId).containsKey(focusAreaName)) {
                grantDedup.get(geoId).put(focusAreaName, new Set<String>());
            }

            grantDedup.get(geoId).get(focusAreaName).add(associationName);
        }

        for (Id geoId : grantDedup.keySet()) {
            for (String focusAreaName : grantDedup.get(geoId).keySet()) {
                Integer count = grantDedup.get(geoId).get(focusAreaName).size();
                Id focusAreaId = focusAreaMap.get(focusAreaName);

                if (focusAreaId == null) {
                    if (!otherCounts.containsKey(geoId)) {
                        otherCounts.put(geoId, new CountWrapper());
                    }
                    otherCounts.get(geoId).grantAssociationCount += count;
                    continue;
                }

                if (!geoAreaCounts.containsKey(geoId)) {
                    geoAreaCounts.put(geoId, new Map<Id, CountWrapper>());
                }
                if (!geoAreaCounts.get(geoId).containsKey(focusAreaId)) {
                    geoAreaCounts.get(geoId).put(focusAreaId, new CountWrapper());
                }

                geoAreaCounts.get(geoId).get(focusAreaId).grantAssociationCount += count;
            }
        }
    }

    private void upsertGeoAreaFocusAreas() {
        try {
            List<Geo_Area_Focus_Area__c> recordsToUpsert = new List<Geo_Area_Focus_Area__c>();
            Map<String, Geo_Area_Focus_Area__c> existingRecords = new Map<String, Geo_Area_Focus_Area__c>();
            Map<Id, Geo_Area_Focus_Area__c> existingGeoAreaRecords = new Map<Id, Geo_Area_Focus_Area__c>();

            for(Geo_Area_Focus_Area__c gaf : [
                SELECT Id, Geo_Area__c, Focus_Area__c, Association_Count__c, Interaction_Count__c
                FROM Geo_Area_Focus_Area__c
            ]) {
                if(gaf.Geo_Area__c != null && gaf.Focus_Area__c != null) {
                    String key = gaf.Geo_Area__c + '-' + gaf.Focus_Area__c;
                    existingRecords.put(key, gaf);
                } else {
                    existingGeoAreaRecords.put(gaf.Geo_Area__c, gaf);
                }
            }

            for(Id geoId : geoAreaCounts.keySet()) {
                for(Id focusAreaId : geoAreaCounts.get(geoId).keySet()) {
                    CountWrapper counts = geoAreaCounts.get(geoId).get(focusAreaId);

                    String key = geoId + '-' + focusAreaId;
                    Geo_Area_Focus_Area__c gafRecord = existingRecords.get(key);

                    if(gafRecord != null) {
                        gafRecord.Association_Count__c = counts.associationCount;
                        gafRecord.Interaction_Count__c = counts.interactionCount;
                        gafRecord.Grant_Association_Count__c  = counts.grantAssociationCount;
                    } else {
                        gafRecord = new Geo_Area_Focus_Area__c(
                            Geo_Area__c = geoId,
                            Focus_Area__c = focusAreaId,
                            Association_Count__c = counts.associationCount,
                            Interaction_Count__c = counts.interactionCount,
                            Grant_Association_Count__c  = counts.grantAssociationCount
                        );
                    }
                    recordsToUpsert.add(gafRecord);
                }
            }

            for(Id geoId : otherCounts.keySet()) {
                CountWrapper counts = otherCounts.get(geoId);
                if(existingGeoAreaRecords.containsKey(geoId)) {
                    Geo_Area_Focus_Area__c gafRecord = existingGeoAreaRecords.get(geoId);
                    gafRecord.Association_Count__c = counts.associationCount;
                    gafRecord.Interaction_Count__c = counts.interactionCount;
                    gafRecord.Grant_Association_Count__c  = counts.grantAssociationCount;
                    recordsToUpsert.add(gafRecord);
                    continue;
                }

                Geo_Area_Focus_Area__c gafRecord = new Geo_Area_Focus_Area__c(
                    Geo_Area__c = geoId,
                    Focus_Area__c = null,
                    Association_Count__c = counts.associationCount,
                    Interaction_Count__c = counts.interactionCount,
                    Grant_Association_Count__c  = counts.grantAssociationCount
                );
                recordsToUpsert.add(gafRecord);
            }
            if(!recordsToUpsert.isEmpty()) {
                BBApps_Crud.doUpsertWithHandling(recordsToUpsert, false, ERR_UPSERT);
            }
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_UPSERT);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    global void finish(Database.BatchableContext BC) {
        GeoAreaCulturalAccessBatch batchJob = new GeoAreaCulturalAccessBatch();
        Database.executeBatch(batchJob, 20);

        GeoAreaGCOMBatch gcomBatchJob = new GeoAreaGCOMBatch();
        Database.executeBatch(gcomBatchJob);
    }

    public class CountWrapper {
        public Integer associationCount = 0;
        public Integer interactionCount = 0;
        public Integer grantAssociationCount = 0;
    }
}