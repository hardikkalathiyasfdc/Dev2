/**
* Author      : Ravi Bheemreddy  
* Description : Batch Job to update Cultural Access data count on GAFA records  
* Test        : GeoAreaCulturalAccessBatchTest
*/
global without sharing class GeoAreaCulturalAccessBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private static final String ERR_START   = 'GAFAB_CULTURAL_ACCESS_START_FAILED';
    private static final String ERR_EXECUTE = 'GAFAB_CULTURAL_ACCESS_EXECUTE_FAILED';
    private static final String ERR_DML     = 'GAFAB_CULTURAL_ACCESS_DML_FAILED';
    private static final String ERR_FINISH  = 'GAFAB_CULTURAL_ACCESS_FINISH_FAILED';
    
    private static final String MSG_START   = 'Unable to start GeoAreaCulturalAccessBatch.';
    private static final String MSG_EXECUTE = 'Failed while executing GeoAreaCulturalAccessBatch chunk.';
    private static final String MSG_FINISH  = 'Failed while finishing GeoAreaCulturalAccessBatch.';
    
    Map<Id, Integer> rolledCounts = new Map<Id, Integer>();
    
    public static List<String> orgGeoAreaTypes = new List<String>{
        Assets.ORGGEOAREACULTURALACCESS,
            Assets.ORGGEOAREACULTURALIMPLICIT
            };    
                
                global Database.QueryLocator start(Database.BatchableContext BC) {
                    try {
                        return Database.getQueryLocator([
                            SELECT Id, Government_Geo_Area__c 
                            FROM Account 
                            WHERE Government_Geo_Area__c != NULL
                            AND Government_Geo_Area__r.RecordType.DeveloperName = :Assets.GEOAREARECORDTYPECITY WITH SYSTEM_MODE 
                        ]);
                    } catch (Exception ex) {
                        BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_START);
                        BBApps_ErrorHandler.logErrors(ex, f);
                        return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null WITH SYSTEM_MODE ');
                    }
                }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        try {
            Set<Id> geoAreaIds = new Set<Id>();
            for (Account acc : scope) {
                if (acc.Government_Geo_Area__c != null) {
                    geoAreaIds.add(acc.Government_Geo_Area__c);
                }
            }
            if (geoAreaIds.isEmpty()) return;
            
            List<Org_Geo_Area__c> orgGeoAreaRecords = [
                SELECT Id,
                Geo_Area__c,
                Geo_Area__r.Parent__c,
                Geo_Area__r.Parent__r.Parent__c
                FROM Org_Geo_Area__c
                WHERE Type__c IN :orgGeoAreaTypes
                AND Deleted__c = FALSE
                AND Geo_Area__c IN :geoAreaIds WITH SYSTEM_MODE 
            ];
            
            for (Org_Geo_Area__c rec : orgGeoAreaRecords) {
                
                Id cityId    = rec.Geo_Area__c;
                Id stateId   = rec.Geo_Area__r != null ? rec.Geo_Area__r.Parent__c : null;
                Id countryId = (rec.Geo_Area__r != null && rec.Geo_Area__r.Parent__r != null)
                    ? rec.Geo_Area__r.Parent__r.Parent__c
                    : null;
                
                if (cityId != null) {
                    Integer cityCount = rolledCounts.get(cityId) == null ? 1 : rolledCounts.get(cityId) + 1;
                    rolledCounts.put(cityId, cityCount);
                }
                
                if (stateId != null && countryId != null) {
                    Integer stateCount = rolledCounts.get(stateId) == null ? 1 : rolledCounts.get(stateId) + 1;
                    Integer countryCount = rolledCounts.get(countryId) == null ? 1 : rolledCounts.get(countryId) + 1;
                    
                    rolledCounts.put(stateId, stateCount);
                    rolledCounts.put(countryId, countryCount);
                }
            }
            if (rolledCounts.isEmpty()) return;
            
            Map<Id, Geo_Area_Focus_Area__c> existingMap = new Map<Id, Geo_Area_Focus_Area__c>();
            for (Geo_Area_Focus_Area__c gaf : [
                SELECT Id, Geo_Area__c, Cultural_Access_Count__c
                FROM Geo_Area_Focus_Area__c
                WHERE Focus_Area__c = null WITH SYSTEM_MODE 
            ]) {
                existingMap.put(gaf.Geo_Area__c, gaf);
            }
            
            List<Geo_Area_Focus_Area__c> upserts = new List<Geo_Area_Focus_Area__c>();
            for (Id gaId : rolledCounts.keySet()) {
                Integer count = rolledCounts.get(gaId);
                if (existingMap.containsKey(gaId)) {
                    Geo_Area_Focus_Area__c rec = existingMap.get(gaId);
                    rec.Cultural_Access_Count__c = count;
                    upserts.add(rec);
                } else {
                    upserts.add(new Geo_Area_Focus_Area__c(
                        Geo_Area__c = gaId,
                        Cultural_Access_Count__c = count
                    ));
                }
            }
            
            for (Id gaId : existingMap.keySet()) {
                if (!rolledCounts.containsKey(gaId)) {
                    Geo_Area_Focus_Area__c rec = existingMap.get(gaId);
                    rec.Cultural_Access_Count__c = 0;
                    upserts.add(rec);
                }
            }
            
            if (!upserts.isEmpty()) {
                BBApps_Crud.doUpsertWithHandling(upserts, false, ERR_DML);
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        try {
            GeoAreaOfficeBatch officeBatchJob = new GeoAreaOfficeBatch();
            Database.executeBatch(officeBatchJob);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_FINISH);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}