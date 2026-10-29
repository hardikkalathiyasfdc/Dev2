/**
* Author            : Paddy
* Date              : 03/17/2025
* Jira              : IM-124
* Description       : This class is used by IMGeography Trigger.
* Test              : IMGeographyTriggerHandlerTest
*/
public with sharing class IMGeographyTriggerHandler extends TriggerHandler {

    public List<IM_Geography__c> newGeographies;
    public List<IM_Geography__c> oldGeographies;
    public Map<Id, IM_Geography__c> oldMap;
    public Map<Id, IM_Geography__c> newMap;

    public List<IM_Geography__c> geographiesToUpdate = new List<IM_Geography__c>();

    public IMGeographyTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, IM_Geography__c>) Trigger.oldMap, (Map<Id, IM_Geography__c>) Trigger.newMap);
    }

    public IMGeographyTriggerHandler(List<IM_Geography__c> oldGeographyList, List<IM_Geography__c> newGeographyList) {
        newGeographies = newGeographyList;
        oldGeographies = oldGeographyList;
    }

    public IMGeographyTriggerHandler(List<IM_Geography__c> oldGeographyList, List<IM_Geography__c> newGeographyList , Map<Id, IM_Geography__c> oldMap , Map<Id, IM_Geography__c> newMap) {
        newGeographies = newGeographyList;
        oldGeographies = oldGeographyList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void beforeInsert(SObject so) {
        IM_Geography__c geography = (IM_Geography__c)so;
        setExternalId(geography);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        IM_Geography__c newGeography = (IM_Geography__c)so;
        IM_Geography__c oldGeography = (IM_Geography__c)oldSo;

        if(isFieldChanged(newGeography, 'Name')) {
            setExternalId(newGeography);
        }
    }

    private void setExternalId(IM_Geography__c geography) {
        geography.External_Id__c = geography.Budget__c + geography.Name;
    }
}