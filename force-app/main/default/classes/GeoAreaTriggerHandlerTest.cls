@isTest
private class GeoAreaTriggerHandlerTest {
    private static testMethod void createGeoAreasTest(){
        Map<String, Id> recordTypeIdMap = new Map<String, Id>();
        Schema.DescribeSObjectResult dsor = Geo_Area__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> rtList = dsor.getRecordTypeInfos();  
        for(Schema.RecordTypeInfo rt : rtList){
            if(rt.isActive()){
                recordTypeIdMap.put(rt.getDeveloperName(), rt.getRecordTypeId());
            }
        }  
        
        Geo_Area__c contGC = new Geo_Area__c(Geo_Name__c='North America', Geo_Code__c='NA', DAMA_Id__c='1', recordTypeId = recordTypeIdMap.get('Continent'));
        insert as system contGC;
        Geo_Area__c counGC = new Geo_Area__c(Geo_Name__c='United States of America', Geo_Code__c='USA', DAMA_Id__c='2', recordTypeId = recordTypeIdMap.get('Country'), parent__c=contGC.Id);
        insert as system counGC;
        counGC.Geo_Name__c = 'USA1';
        update as system counGC;
        Geo_Area__c stateGC = new Geo_Area__c(Geo_Name__c='New York', Geo_Code__c='NA', DAMA_Id__c='3', recordTypeId = recordTypeIdMap.get('State'), parent__c=counGC.Id);
        insert as system stateGC;
        Geo_Area__c cityGC = new Geo_Area__c(Geo_Name__c='Huntington', Geo_Code__c='NA', DAMA_Id__c='4', recordTypeId = recordTypeIdMap.get('City'), parent__c=stateGC.Id);
        insert as system cityGC;
        Geo_Area__c boroGC = new Geo_Area__c(Geo_Name__c='Brooklyn', Geo_Code__c='NA', DAMA_Id__c='5', recordTypeId = recordTypeIdMap.get('Borough'), parent__c=cityGC.Id);
        insert as system boroGC;
    }
}