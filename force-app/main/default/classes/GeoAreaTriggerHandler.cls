public without sharing class GeoAreaTriggerHandler extends TriggerHandler {
    
    public List<Geo_Area__c> newGAs = new List<Geo_Area__c>();
    public List<Geo_Area__c> oldGAs = new List<Geo_Area__c>();
    public Map<Id, SObject> newGAMap = new Map<Id, SObject>();
    public Map<Id, SObject> oldGAMap = new Map<Id, SObject>();
    public Map<Id, CountryWrapper> countryMap = new Map<Id, CountryWrapper>();
    public Map<Id, StateWrapper> stateMap = new Map<Id, StateWrapper>();
    public Map<Id, CityWrapper> cityMap = new Map<Id, CityWrapper>();
    public Map<Id, String> recordTypeIdMap = new Map<Id, String>();
    public Map<Id, Boolean> countryUsesStatesMap = new Map<Id, Boolean>();
    public static Boolean updateTrigger = false;
    public static Boolean insertTrigger = false;

    private static final String ERR_BULK_BEFORE = 'GEO_AREA_TRIGGER_BULK_BEFORE_FAILED';
    private static final String ERR_BULK_AFTER = 'GEO_AREA_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_BEFORE_INSERT = 'GEO_AREA_TRIGGER_BEFORE_INSERT_FAILED';
    private static final String ERR_BEFORE_UPDATE = 'GEO_AREA_TRIGGER_BEFORE_UPDATE_FAILED';
    private static final String ERR_UPDATE_NAME = 'GEO_AREA_TRIGGER_UPDATE_NAME_FAILED';
    private static final String ERR_POPULATE_RECORD_TYPE_ID_MAP = 'GEO_AREA_TRIGGER_POPULATE__RECORD_TYPE_ID_MAP_FAILED';
    private static final String ERR_UPDATE_FAILED = 'GEO_AREA_TRIGGER_POPULATE_TRIGGER__UPDATE_FAILED';


    public GeoAreaTriggerHandler(){
        this(Trigger.old, Trigger.new);
    }

    public GeoAreaTriggerHandler(List<Geo_Area__c> oldGList, List<Geo_Area__c> newGList){
        oldGAs = oldGList;
        newGAs = newGList;
        oldGAMap = Trigger.oldMap;
        newGAMap = Trigger.newMap;
        updateTrigger = Trigger.isUpdate;
        insertTrigger = Trigger.isInsert;
    }

    public override void bulkBefore(){
        // if state, then get parent's (Country) and get the Geo Code
        // if City, then get Grand Parent's(Country) 'BP Uses States' value, code and parent's (State) code
        // if Borough, then get parent's (city) name
        try{
            Set<Id> countrySet = new Set<Id>();
            Set<Id> stateSet = new Set<Id>();
            Set<Id> citySet = new Set<Id>();

            populateRecordTypeIdMap();

            for(Geo_Area__c ga : newGAs){
                String recordTypeName = recordTypeIdMap.get(ga.RecordTypeId);
                if(recordTypeName == 'State' || recordTypeName == 'Dummy_State'){
                    countrySet.add(ga.Parent__c);
                } else if(recordTypeName == 'City'){
                    stateSet.add(ga.Parent__c);
                } else if(recordTypeName == 'Borough'){
                    citySet.add(ga.Parent__c);
                }
            }

            if(stateSet.size() != 0){
                List<Geo_Area__c> stateResultList = [Select id, Geo_Code__c, Geo_Name__c, parent__c from Geo_Area__c where id IN: stateSet];
                for(Geo_Area__c ga : stateResultList){
                    StateWrapper sw = new StateWrapper();
                    sw.geoCode = ga.Geo_Code__c;
                    sw.geoName = ga.Geo_Name__c;
                    sw.country = ga.Parent__c;
                    stateMap.put(ga.id, sw);
                    if(!String.isBlank(ga.Parent__c)){
                        countrySet.add(ga.Parent__c);
                    }
                }
            }

            if(countrySet.size() != 0){
                List<Geo_Area__c> countryResultList = [Select id, Geo_Code__c, Geo_Name__c, BP_Uses_States__c from Geo_Area__c where id IN: CountrySet];
                for(Geo_Area__c ga : countryResultList){
                    CountryWrapper cw = new CountryWrapper();
                    cw.geoCode = ga.Geo_Code__c;
                    cw.geoName = ga.Geo_Name__c;
                    cw.usesStates = ga.BP_Uses_States__c;
                    countryMap.put(ga.id, cw);
                }
            }

            if(citySet.size() != 0){
                List<Geo_Area__c> cityResultList = [Select id, Geo_Name__c from Geo_Area__c where id IN: citySet];
                for(Geo_Area__c ga : cityResultList){
                    CityWrapper cw = new CityWrapper();
                    cw.geoName = ga.Geo_Name__c;
                    cityMap.put(ga.id, cw);
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_BULK_BEFORE) ); }
    }

    public override void bulkAfter() {
        try {
            if(updateTrigger) {
                populateRecordTypeIdMap();
                Set<Id> gaSet = new Set<Id>();
                for(SObject so : newGAMap.values()) {
                    Geo_Area__c newGA = (Geo_Area__c) so;
                    String rtString = recordTypeIdMap.get(newGA.RecordTypeId);
                    if(oldGAMap.containsKey(newGA.Id) && (newGA.Geo_Name__c != ((Geo_Area__c)(oldGAMap.get(newGA.Id))).Geo_Name__c)){
                        if(rtString == 'Country' || rtString == 'State'){
                            gaSet.add(newGA.Id);
                        }
                    }
                    if((rtString == 'Country') && oldGAMap.containsKey(newGA.Id) &&
                       (newGA.BP_Uses_States__c != ((Geo_Area__c)(oldGAMap.get(newGA.Id))).BP_Uses_States__c)){

                        countryUsesStatesMap.put(newGA.Id, newGA.BP_Uses_States__c);
                    }
                }
                if(countryUsesStatesMap.size() > 0) {
                    List<Geo_Area__c> stateActiveUpdateList = [
                        SELECT Id, BP_Active__c, Parent__c
                        FROM Geo_Area__c
                        WHERE Parent__c IN :countryUsesStatesMap.keySet()
                          AND RecordType.Name = 'State'];
                    if(stateActiveUpdateList.size() > 0) {
                        for(Geo_Area__c ga : stateActiveUpdateList){
                            ga.BP_Active__c = countryUsesStatesMap.get(ga.Parent__c);
                            ga.Enabled_For_Grants__c = countryUsesStatesMap.get(ga.Parent__c);
                        }
                        BBApps_Crud.doUpdateWithHandling(stateActiveUpdateList, false, ERR_UPDATE_FAILED);
                    }
                }
                if(gaSet.size() > 0) {
                    BatchGeoAreaUpdate beau = new BatchGeoAreaUpdate(gaSet);
                    database.executebatch(beau, 200);
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_BULK_AFTER) ); }
    }

    public override void beforeInsert(SObject so) {
        try {
            updateName(so);
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_BEFORE_INSERT) ); }
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        try {
            updateName(so);
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_BEFORE_UPDATE) ); }
    }

    private void updateName(SObject so) {
        try {
            Geo_Area__c ga = (Geo_Area__c) so;

            if(recordTypeIdMap.get(ga.RecordTypeId) != 'Continent' && String.isBlank(ga.Parent__c)){
                so.addError('Need a Parent for this record!');
                return;
            }
            String computedName = '';
            if(recordTypeIdMap.get(ga.RecordTypeId) == 'Continent'){
                computedName = ga.Geo_Name__c;
            } else if(recordTypeIdMap.get(ga.RecordTypeId)=='Country'){
                computedName = ga.Geo_Name__c;
            } else if(recordTypeIdMap.get(ga.RecordTypeId)=='State' || recordTypeIdMap.get(ga.RecordTypeId)=='Dummy_State'){
                String countryGeoName = countryMap.get(ga.Parent__c).geoName;
                computedName = ga.Geo_Name__c + ', ' + countryGeoName;
            } else if(recordTypeIdMap.get(ga.RecordTypeId)=='City'){
                String stateGeoName = stateMap.get(ga.Parent__c).geoName;
                String countryGeoName = countryMap.get(stateMap.get(ga.Parent__c).country).geoName;

                computedName = ga.Geo_Name__c + ', ' + stateGeoName + ', ' + countryGeoName;
                if(computedName.length() > 80){
                    computedName = ga.Geo_Name__c + ', ' + countryGeoName;
                }
            } else if(recordTypeIdMap.get(ga.RecordTypeId)=='Borough'){
                computedName = ga.Geo_Name__c + ', ' + cityMap.get(ga.Parent__c).geoName;
            }

            if(computedName.length() > 80){
                ga.Name = computedName.substring(0, 80);
            } else{
                ga.Name = computedName;
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_UPDATE_NAME)  ); }
    }

    private void populateRecordTypeIdMap() {
        try{
            Schema.DescribeSObjectResult dsor = Geo_Area__c.SObjectType.getDescribe();
            List<Schema.RecordTypeInfo> rtList = dsor.getRecordTypeInfos();
            for(Schema.RecordTypeInfo rt : rtList){
                if(rt.isActive()){
                    recordTypeIdMap.put(rt.getRecordTypeId(), rt.getDeveloperName());
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_POPULATE_RECORD_TYPE_ID_MAP) ); }
    }

    class CountryWrapper {
        String geoCode;
        String geoName;
        boolean usesStates;
    }

    class StateWrapper {
        String geoCode;
        String geoName;
        String country;
    }

    class CityWrapper {
        String geoName;
    }
}