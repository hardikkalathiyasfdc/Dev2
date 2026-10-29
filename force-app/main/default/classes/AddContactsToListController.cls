public with sharing class AddContactsToListController {
    
    public String tagIdsString {get; set;}
    public List<Tag__c> selectedTags;
    private static final String ERR_CLASS_FAILED = 'AddContactsToListController_CLASS_FAILED';
    
    public AddContactsToListController(ApexPages.StandardSetController cntlr) {
        selectedTags = cntlr.getSelected();
        tagIdsString = '';
        Set<Id> tagIds = new Set<Id>();  
        for(Tag__c tag : selectedTags) {
            tagIdsString += tag.Id + ',';
            tagIds.add(tag.Id);
        }
        tagIdsString = tagIdsString.removeEnd(',');
    } 
    
    @auraEnabled
    public static void addContactsToListfromTag(String tagIds,String listValue, Boolean newList) {
        try {
            Set<Id> tagIdsSet = new Set<Id> ();
            Set<String> tagNames = new Set<String>();
            Id newListId;
            for(String tag: tagIds.split(',')) {
                tagIdsSet.add(tag);
            }
            Set<Id> existingListMemberContacts = new Set<Id> ();
            Set<Id> tagRelatedContacts = new Set<Id> ();
            for (Tag_Junction__c tag: [Select Id, Contact__c, Tag__r.Name from Tag_Junction__c where Tag__c IN: tagIdsSet]) {
                tagRelatedContacts.add(tag.Contact__c);
                tagNames.add(tag.Tag__r.Name);
            }
            if(newList) {
                newListId = createNewList(listValue);
            } else {
                newListId = listValue;
                for(CampaignMember member: [Select Id, ContactId from CampaignMember where CampaignId =: newListId]) {
                    existingListMemberContacts.add(member.ContactId);
                }
            }
            AddCampaignMemberBatch objbatch = new AddCampaignMemberBatch(existingListMemberContacts,tagRelatedContacts, tagNames, newListId);
            Database.executeBatch(objbatch, 500);
        } catch(Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CLASS_FAILED);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    @auraEnabled
    public static void addContactsToList(String currentListId, String listValue, Boolean newList) {
        AddContactToListBatch objbatch = new AddContactToListBatch(currentListId, listValue,  newList);
        Database.executeBatch(objbatch, 500);
    }

    public static Id createNewList(String name) {
        Campaign c = new Campaign(
            Name=name,
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('BP_Campaign').getRecordTypeId()
        );
        insert c;
        return c.id;
    }
}