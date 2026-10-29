/**
* Author            : Paddy
* Date              : 03/17/2025
* Jira              : IM-124
* Description       : This class is used by IMComponent Trigger.
* Test              : IMComponentTriggerHandlerTest
*/
public with sharing class IMComponentTriggerHandler extends TriggerHandler {

    public List<IM_Component__c> newComponents;
    public List<IM_Component__c> oldComponents;
    public Map<Id, IM_Component__c> oldMap;
    public Map<Id, IM_Component__c> newMap;

    public IMComponentTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, IM_Component__c>) Trigger.oldMap, (Map<Id, IM_Component__c>) Trigger.newMap);
    }

    public IMComponentTriggerHandler(List<IM_Component__c> oldComponentList, List<IM_Component__c> newComponentList) {
        newComponents = newComponentList;
        oldComponents = oldComponentList;
    }

    public IMComponentTriggerHandler(List<IM_Component__c> oldComponentList, List<IM_Component__c> newComponentList , Map<Id, IM_Component__c> oldMap , Map<Id, IM_Component__c> newMap) {
        newComponents = newComponentList;
        oldComponents = oldComponentList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void beforeInsert(SObject so) {
        IM_Component__c component = (IM_Component__c)so;
        if(Assets.COMPONENT.equalsIgnoreCase(component.Type__c)) {
            setComponentExternalId(component);
        }
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        IM_Component__c newComponent = (IM_Component__c)so;
        IM_Component__c oldComponent = (IM_Component__c)oldSo;

        if(Assets.COMPONENT.equalsIgnoreCase(newComponent.Type__c) && (isFieldChanged(newComponent, Assets.NAME_FIELD) || isFieldChanged(newComponent, Assets.BUDGET_FIELD))) {
            setComponentExternalId(newComponent);
        }
    }

    public override void bulkBefore() {
        Set<Id> subComponentsParentIds = new Set<Id>();
        Set<Id> subComponentsIds = new Set<Id>();
        for(IM_Component__c newComponent : newComponents) {
            if(Assets.SUB_COMPONENT.equalsIgnoreCase(newComponent.Type__c)) {
                if(Trigger.isInsert) {
                    setSubComponentExternalId(newComponent);
                } else if (Trigger.isUpdate && (isFieldChanged(newComponent, Assets.NAME_FIELD) || isFieldChanged(newComponent, Assets.BUDGET_FIELD) || isFieldChanged(newComponent, Assets.PARENT_COMPONENT_FIELD)) ) {
                    setSubComponentExternalId(newComponent);
                } 
            }
        }
    }

    private void setComponentExternalId(IM_Component__c component) {
        component.External_Id__c = component.Budget__c + component.Name;
    }
    
    private void setSubComponentExternalId(IM_Component__c component) {
        String externalId = component.Budget__c + (String)component.Parent_Component__c + component.Name;
        component.External_Id__c = externalId;
    }
}