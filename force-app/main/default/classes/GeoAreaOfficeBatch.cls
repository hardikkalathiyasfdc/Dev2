/**
* Author      : Nishant Bakhrey
* Description : Batch Job to update Office count on GAFA records  
* Test        : GeoAreaOfficeBatchTest
*/
global without sharing class GeoAreaOfficeBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private static final String ERR_START   = 'GEOAREA_OFFICE_START_FAILED';
    private static final String ERR_EXECUTE = 'GEOAREA_OFFICE_EXECUTE_FAILED';
    private static final String ERR_DML     = 'GEOAREA_OFFICE_DML_FAILED';
    private static final String ERR_FINISH  = 'GEOAREA_OFFICE_FINISH_FAILED';
    
    private static final String MSG_START   = 'Unable to start GeoAreaOfficeBatch.';
    private static final String MSG_EXECUTE = 'Failed while executing GeoAreaOfficeBatch chunk.';
    private static final String MSG_FINISH  = 'Failed while finishing GeoAreaOfficeBatch.';
    
    private Map<Id, Integer> cityOfficeCounts    = new Map<Id, Integer>();
    private Map<Id, Integer> stateOfficeCounts   = new Map<Id, Integer>();
    private Map<Id, Integer> countryOfficeCounts = new Map<Id, Integer>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        try {
            return Database.getQueryLocator([
                SELECT Id, Geo_Area__c, Geo_Area__r.Parent__c, Geo_Area__r.Parent__r.Parent__c, Geo_Area__r.Parent__r.Parent__r.Name
                FROM Bloomberg_Office__c
                WHERE Geo_Area__c != NULL
                AND Deleted__c = false WITH SYSTEM_MODE 
            ]);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_START);
            BBApps_ErrorHandler.logErrors(ex, f);
            return Database.getQueryLocator('SELECT Id FROM Bloomberg_Office__c WHERE Id = null WITH SYSTEM_MODE ');
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Bloomberg_Office__c> officeList) {
        try {
            if (officeList.isEmpty()) return;
            
            Set<Id> cityIds = new Set<Id>();
            for (Bloomberg_Office__c office : officeList) {
                cityIds.add(office.Geo_Area__c);
                cityOfficeCounts.put(
                    office.Geo_Area__c,
                    (cityOfficeCounts.get(office.Geo_Area__c) == null ? 1 : cityOfficeCounts.get(office.Geo_Area__c) + 1)
                );
                
                Id stateId = office.Geo_Area__r.Parent__c;
                if (stateId != null) {
                    stateOfficeCounts.put(
                        stateId,
                        (stateOfficeCounts.get(stateId) == null ? 1 : stateOfficeCounts.get(stateId) + 1)
                    );
                }
                
                Id countryId = office.Geo_Area__r.Parent__r.Parent__c;
                if (countryId != null) {
                    Integer count = countryOfficeCounts.get(countryId);
                    countryOfficeCounts.put(
                        countryId,
                        (countryOfficeCounts.get(countryId) == null ? 1 : countryOfficeCounts.get(countryId) + 1) 
                    );
                }
            }         
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_EXECUTE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        try {
            Map<Id, Integer> focusAreaCounts = new Map<Id, Integer>();
            
            for (Id id : countryOfficeCounts.keySet()) {
                focusAreaCounts.put(id, countryOfficeCounts.get(id));
            }
            for (Id id : stateOfficeCounts.keySet()) {
                focusAreaCounts.put(id, stateOfficeCounts.get(id));
            }
            for (Id id : cityOfficeCounts.keySet()) {
                focusAreaCounts.put(id, cityOfficeCounts.get(id));
            }
            
            Map<Id, Geo_Area_Focus_Area__c> existingGAFAs = new Map<Id, Geo_Area_Focus_Area__c>();
            for (Geo_Area_Focus_Area__c gaf : [
                SELECT Id, Geo_Area__c, Office_Count__c
                FROM Geo_Area_Focus_Area__c
                WHERE (Focus_Area__c = null OR Focus_Area_Name__c = 'Other') WITH SYSTEM_MODE 
            ]) {
                existingGAFAs.put(gaf.Geo_Area__c, gaf);
            }
            
            List<Geo_Area_Focus_Area__c> gafasToUpsert = new List<Geo_Area_Focus_Area__c>();
            for (Id geoAreaId : focusAreaCounts.keySet()) {
                Integer count = focusAreaCounts.get(geoAreaId);
                if (existingGAFAs.containsKey(geoAreaId)) {
                    Geo_Area_Focus_Area__c existing = existingGAFAs.get(geoAreaId);
                    existing.Office_Count__c = count;
                    gafasToUpsert.add(existing);
                } else {
                    gafasToUpsert.add(new Geo_Area_Focus_Area__c(
                        Geo_Area__c     = geoAreaId,
                        Office_Count__c = count
                    ));
                }
            }
            
            for (Id geoAreaId : existingGAFAs.keySet()) {
                if (!focusAreaCounts.containsKey(geoAreaId)) {
                    Geo_Area_Focus_Area__c existing = existingGAFAs.get(geoAreaId);
                    existing.Office_Count__c = 0;
                    gafasToUpsert.add(existing);
                }
            }
            
            if (!gafasToUpsert.isEmpty()) {
                BBApps_Crud.doUpsertWithHandling(gafasToUpsert, false, ERR_DML);
            } 
            
            GeoAreaFocusAreaDeleteBatch batchJob = new GeoAreaFocusAreaDeleteBatch();
            Database.executeBatch(batchJob, 20);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_FINISH);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}