/**
* Author      : Ravi Bheemreddy
* Description : Controller class for CityView filters component
* Test        : CityViewFiltersControllerTest
*/
public with sharing class CityViewFiltersController {

    // ---- Error Codes ----
    private static final String ERR_GET_GEOAREAS_BY_FILTERS = 'CITYVIEW_FILTERS_GET_GEOAREAS_BY_FILTERS_FAILED';
    private static final String ERR_GET_OFFICES             = 'CITYVIEW_FILTERS_GET_OFFICES_FAILED';
    private static final String ERR_GET_GCOM_GEOAREAS       = 'CITYVIEW_FILTERS_GET_GCOM_GEOAREAS_FAILED';
    private static final String ERR_GET_GEOAREAIDS          = 'CITYVIEW_FILTERS_GET_GEOAREAIDS_FAILED';

    // ---- Error Messages ----
    private static final String MSG_GET_GEOAREAS_BY_FILTERS = 'Unable to fetch Geo Areas by filters.';
    private static final String MSG_GET_OFFICES             = 'Unable to fetch offices.';
    private static final String MSG_GET_GCOM_GEOAREAS       = 'Unable to fetch GCOM Geo Areas.';
    private static final String MSG_GET_GEOAREAIDS          = 'Unable to fetch Geo Area Ids.';

    @AuraEnabled(cacheable=true)
    public static List<Id> getGeoAreasByFilters(List<Id> initiativeIds, List<String> focusAreaNames,
                                                List<Id> selectedContinentsIds, List<Id> selectedCountriesIds) {
        try {
            Set<Id> geoAreaIds = new Set<Id>();
            Set<Id> associationIds = new Set<Id>();
            if(!initiativeIds.isEmpty()) {
                List<Association__c> associations = [
                    SELECT Id, FC_Focus_Area__c
                    FROM Association__c
                    WHERE Id IN :initiativeIds
                      AND Deleted__c = false
                    WITH SECURITY_ENFORCED
                ];
                for(Association__c assoc : associations) {
                    associationIds.add(assoc.Id);
                }
                if(!associationIds.isEmpty()) {
                    List<Org_Association__c> orgAssociations = [
                        SELECT Organization__r.Government_Geo_Area__c, Organization__r.Government_Geo_Area__r.Parent__c,
                               Organization__r.Government_Geo_Area__r.Parent__r.Parent__c
                        FROM Org_Association__c
                        WHERE Association__c IN :associationIds
                          AND Organization__r.Government_Geo_Area__c != null
                          AND Deleted__c = false
                          AND Association__r.Deleted__c = false
                        WITH SECURITY_ENFORCED
                    ];
                    for(Org_Association__c orgAssoc : orgAssociations) {
                        geoAreaIds.add(orgAssoc.Organization__r.Government_Geo_Area__c);
                    }
                }
            } else {
                List<Geo_Area_Focus_Area__c> geoAreaFocusAreas = [
                    SELECT Geo_Area__c
                    FROM Geo_Area_Focus_Area__c
                    WHERE Focus_Area_Name__c IN :focusAreaNames
                      AND (Association_Count__c > 0
                        OR Grant_Association_Count__c > 0
                        OR Geo_Area__r.RecordType.DeveloperName = :Assets.GEO_AREA_RECORDTYPE_STATE)
                      AND Geo_Area__r.Deleted__c = false
                    WITH SECURITY_ENFORCED
                ];
                for(Geo_Area_Focus_Area__c gaf : geoAreaFocusAreas) {
                    geoAreaIds.add(gaf.Geo_Area__c);
                }
            }
            if(geoAreaIds.isEmpty()) return new List<Id>();
            if(!selectedContinentsIds.isEmpty() || !selectedCountriesIds.isEmpty()) {
                List<String> orConditions = new List<String>();
                if(!selectedContinentsIds.isEmpty()) {
                    orConditions.add('(Parent__r.Parent__r.Parent__c IN :selectedContinentsIds OR Parent__r.Parent__c IN :selectedContinentsIds OR Parent__c IN :selectedContinentsIds)');
                }
                if(!selectedCountriesIds.isEmpty()) {
                    orConditions.add('(Parent__c IN :selectedCountriesIds OR Parent__r.Parent__c IN :selectedCountriesIds OR Id IN :selectedCountriesIds)');
                }
                String whereClause = 'WHERE Id IN :geoAreaIds AND BP_Active__c = true AND Deleted__c = false AND (' + String.join(orConditions, ' OR ') + ')';
                List<Geo_Area__c> geoAreas = Database.query('SELECT Id FROM Geo_Area__c ' + whereClause + ' WITH SECURITY_ENFORCED');
                geoAreaIds = new Set<Id>();
                for(Geo_Area__c ga : geoAreas) {
                    geoAreaIds.add(ga.Id);
                }
            }
            return new List<Id>(geoAreaIds);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_GEOAREAS_BY_FILTERS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException('Error fetching geo areas by filters' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Bloomberg_Office__c> getOffices() {
        try {
            return [
                SELECT Id, Name, Geo_Area__c, Address__c, Geo_Area__r.Name, Geo_Area__r.Coordinates__c,
                       Geo_Area__r.Coordinates__latitude__s, Geo_Area__r.Coordinates__longitude__s,
                       Geo_Area__r.Association_Count__c, Geo_Area__r.Has_GCOM_Association__c,
                       Geo_Area__r.Cultural_Access_Count__c, Geo_Area__r.Interaction_Count__c, Geo_Area__r.Office_Count__c
                FROM Bloomberg_Office__c
                WHERE Geo_Area__r.Coordinates__latitude__s != null
                  AND Geo_Area__r.Coordinates__longitude__s != null
                  AND Deleted__c = false
                WITH SECURITY_ENFORCED
            ];
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_OFFICES);
            BBApps_ErrorHandler.logErrors(ex, f);
            return new List<Bloomberg_Office__c>();
        }
    }

    @AuraEnabled
    public static List<Id> getGeoAreaIds(Id selectedId, String searchBy) {
        try {
            List<Id> geoAreaIds = new List<Id>();
            if(searchBy == Assets.BP_WORK_FILTER) {
                Association__c association = [
                    SELECT Id, FC_Focus_Area__c
                    FROM Association__c
                    WHERE Id = :selectedId
                      AND Deleted__c = false
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if(association != null && String.isNotBlank(association.FC_Focus_Area__c)) {
                    geoAreaIds = getGeoAreasByFilters(
                        new List<Id>{ selectedId },
                        new List<String>{ association.FC_Focus_Area__c },
                        new List<Id>(),
                        new List<Id>()
                    );
                }
            } else if(searchBy == Assets.GEO_AREA_RECORDTYPE_COUNTRY || searchBy == Assets.GEO_AREA_RECORDTYPE_STATE) {
                List<String> focusAreas = new List<String>();
                for(Focus_Area__c fca : [SELECT Id, Name FROM Focus_Area__c WITH SECURITY_ENFORCED]) {
                    focusAreas.add(fca.Name);
                }
                geoAreaIds = getGeoAreasByFilters(
                    new List<Id>(),
                    focusAreas,
                    new List<Id>(),
                    new List<Id>{ selectedId }
                );
                geoAreaIds.add(selectedId);
            }
            return geoAreaIds;
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_GEOAREAIDS);
            BBApps_ErrorHandler.logErrors(ex, f);
            return new List<Id>();
        }
    }
}