/**
* Author      : Ravi Bheemreddy
* Description : Main controller class for CityView
* Test        : CityViewControllerTest
*/
public with sharing class CityViewController {
    public static List<String> geoAreaRecordTypes = new List<String> {
        Assets.GEOAREARECORDTYPECITY,
            Assets.GEOAREARECORDTYPECOUNTRY,
            Assets.GEOAREARECORDTYPESTATE
            };
                
                @AuraEnabled(cacheable=true)
                public static List<Geo_Area_Focus_Area__c> getCityViewMarkersData() {
                    return [ 
                        SELECT Id, Geo_Area__c, Geo_Area__r.Parent__c, Geo_Area__r.Parent__r.Parent__c,
                        Geo_Area__r.Coordinates__c, Geo_Area__r.Coordinates__latitude__s, 
                        Geo_Area__r.Coordinates__longitude__s, Geo_Area__r.Name, Geo_Area__r.Short_Name__c, 
                        Focus_Area__c, Focus_Area_Name__c, Color_Code__c, Weight__c, 
                        Geo_Area__r.RecordType.Name, Geo_Area__r.Association_Count__c, 
                        Geo_Area__r.Cultural_Access_Count__c, Geo_Area__r.Interaction_Count__c, 
                        Geo_Area__r.Office_Count__c, Association_Count__c,Grant_Association_Count__c,Geo_Area__r.Grant_Association_Count__c,
                        Geo_Area__r.Has_GCOM_Association__c
                        FROM Geo_Area_Focus_Area__c
                        WHERE Geo_Area__r.Coordinates__latitude__s != null 
                        AND Geo_Area__r.Coordinates__longitude__s != null 
                        AND Geo_Area__r.Deleted__c = false
                        AND Geo_Area__r.BP_Active__c = true
                        AND Focus_Area_Name__c != 'Other'
                        AND (
                            (Geo_Area__r.RecordType.DeveloperName IN :geoAreaRecordTypes 
                             AND (Association_Count__c > 0 OR Grant_Association_Count__c > 0))
                            OR Geo_Area__r.RecordType.DeveloperName = :Assets.GEOAREARECORDTYPESTATE
                        )
                        WITH SYSTEM_MODE
                    ];
                    
                }
    
    @AuraEnabled(cacheable=true)
    public static Geo_Area__c getGeoArea(String geoAreaId) {
        return [ 
            SELECT Id, RecordType.Name
            FROM Geo_Area__c 
            WHERE Id = :geoAreaId 
            AND Deleted__c = false
            AND BP_Active__c = true
            WITH USER_MODE
            LIMIT 1
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Focus_Area__c> getCityViewFocusAreas() {
        return [SELECT Id, Name, Sort_Order__c 
                FROM Focus_Area__c 
                WHERE Enabled_for_CityView__c = TRUE 
                WITH SYSTEM_MODE
                ORDER BY Sort_Order__c ASC];
    }
}