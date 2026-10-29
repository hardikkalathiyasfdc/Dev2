/**
* Author : Ravi Bheemreddy
* Description : This class is the trigger handler for Org_Association__c object
* Test   : OrgAssociationTriggerHandlerTest
**/
public without sharing class OrgAssociationTriggerHandler extends TriggerHandler {
    public List<Org_Association__c> newOrgAssociations;
    public List<Org_Association__c> oldOrgAssociations;
    public Map<Id, Org_Association__c> oldMap;
    public Map<Id, Org_Association__c> newMap;
    
    private Set<Id> orgAssociationsWithLookupChange = new Set<Id>();
    private static final String ERR_BULK_AFTER  = 'ORG_ASSOCIATION_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_AND_FINALLY  =  'ORG_ASSOCIATION_TRIGGER_FINAL_FAILED';
    
    public OrgAssociationTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Org_Association__c>)Trigger.oldMap, (Map<Id, Org_Association__c>)Trigger.newMap);
    }
    
    public OrgAssociationTriggerHandler(List<Org_Association__c> oldOrgAssociationList, List<Org_Association__c> newOrgAssociationList, Map<Id, Org_Association__c> oldMap, Map<Id, Org_Association__c> newMap) {
        newOrgAssociations = newOrgAssociationList;
        oldOrgAssociations = oldOrgAssociationList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }
    
    public override void bulkAfter() {
        try{ 
            if (Trigger.isInsert) {
                for (Org_Association__c oa : newOrgAssociations) {
                    orgAssociationsWithLookupChange.add(oa.Id);
                }
            } else if (Trigger.isUpdate) {
                for (Org_Association__c oa : newOrgAssociations) {
                    Org_Association__c oldOa = oldMap.get(oa.Id);
                    
                    if(oa.Association__c != oldOa?.Association__c || 
                       oa.Organization__c != oldOa?.Organization__c) {
                           orgAssociationsWithLookupChange.add(oa.Id);
                       }
                }
            }
        }  catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_BULK_AFTER)); }
    }
    
    public override void afterUpdate(SObject oldSo, SObject so) {
        
    }
    
    public override void andFinally() {
        try{ 
            if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
                if (!orgAssociationsWithLookupChange.isEmpty()) {
                    AccountTriggerHandler.syncOrgAssociationNames(orgAssociationsWithLookupChange);
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,  NEW BBApps_ErrorCustomFields(ERR_AND_FINALLY)); }
    }
}