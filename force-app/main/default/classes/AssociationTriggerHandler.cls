/**
 * Author : Ravi Bheemreddy
 * Date   : 11/17/2025
 * Description : This class is the trigger handler for Association__c object
 * Test   : AssociationTriggerHandlerTest
 **/
public without sharing class AssociationTriggerHandler extends TriggerHandler {
	
    public List<Association__c> newAssociations;
    public List<Association__c> oldAssociations;
    public Map<Id, Association__c> oldMap;
    public Map<Id, Association__c> newMap;
    
    private Set<Id> associationsWithNameChange = new Set<Id> ();
    
    public AssociationTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Association__c>)Trigger.oldMap, (Map<Id, Association__c>)Trigger.newMap);
    }
    
    public AssociationTriggerHandler(List<Association__c> oldAssociationList, List<Association__c> newAssociationList, Map<Id, Association__c> oldMap, Map<Id, Association__c> newMap) {
        newAssociations = newAssociationList;
        oldAssociations = oldAssociationList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    
    public override void bulkAfter() {
        if (trigger.isUpdate) {
            for (Association__c a : newAssociations) {
                if(a.Name != oldMap.get(a.Id)?.Name) {
                    associationsWithNameChange.add(a.Id);
                }
            }
        }
    }
    
    public override void andFinally() {
        if(Trigger.isAfter) {
            if (!associationsWithNameChange.isEmpty()) {
                AccountTriggerHandler.syncOrgAssociationNames(associationsWithNameChange);
            }
        }
    }
}