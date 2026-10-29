/**
* Author :
* Date : 11/26/2024
* JIRA : BRME-5549
* Description : Handles bulk updates of Tag__c names and syncs them to related Tag_Junction__c records.
* Test : TagsCmpControllerTest
* Change Log 

**/

public without sharing class TagTriggerHandler extends TriggerHandler {
    private List<Tag__c> oldTagsList;
    private List<Tag__c> newTagsList;

    private static final String ERR_BULK_AFTER = 'TAG_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_UPDATE_NAMES = 'TAG_TRIGGER_UPDATE_NAMES_FAILED';
    
    public TagTriggerHandler() {
        this(Trigger.old, Trigger.new); 
    }
    
    public TagTriggerHandler(List<Tag__c> oldList, List<Tag__c> newList) {
        oldTagsList = oldList;
        newTagsList = newList;
    }
    
    public override void bulkAfter() {
        try {
            TriggerFactory.removeBypass('TagsTriggerHandler');
            updateNames();
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BULK_AFTER);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    private void updateNames() {
        if (!Trigger.isAfter || !Trigger.isUpdate) {
            return;
        }
        Map<Id, Tag__c> updatedNames = new Map<Id, Tag__c>();
        for(Tag__c tag : newTagsList) {
            if(isFieldChanged(tag, 'Name')) {
                updatedNames.put(tag.Id, tag);
            }
        }
        if (updatedNames.isEmpty()) {
            return;
        }
        List<Tag_Junction__c> juncList = [
            SELECT Id, Tag__c
            FROM Tag_Junction__c
            WHERE Tag__c IN :updatedNames.keySet() WITH SYSTEM_MODE
        ];
        for(Tag_Junction__c junc : juncList) {
            junc.Name = updatedNames.get(junc.Tag__c).Name;
        }
        TriggerFactory.setBypass('TagTriggerHandler');
        BBApps_Crud.doUpdateWithHandling(juncList, false, ERR_UPDATE_NAMES);
    }
}