/**
* Author :
* Date : 11/26/2024
* JIRA : BRME-5549
* Description : Manages Tag_Junction__c triggers to update tag names, validate duplicates, and sync tag IDs with related contacts.
* Test : TagsCmpControllerTest

**/
public with sharing class TagsTriggerHandler extends TriggerHandler {

    // ---- Error Codes ----
    private static final String ERR_BULK_BEFORE              = 'TAGS_BULK_BEFORE_FAILED';
    private static final String ERR_BULK_AFTER               = 'TAGS_BULK_AFTER_FAILED';
    private static final String ERR_BEFORE_INSERT            = 'TAGS_BEFORE_INSERT_FAILED';
    private static final String ERR_UPDATE_NAMES             = 'TAGS_UPDATE_NAMES_FAILED';
    private static final String ERR_UPDATE_CONTACT_TAG_IDS   = 'TAGS_UPDATE_CONTACT_TAG_IDS_FAILED';
    private static final String ERR_REMOVE_CONTACT_TAG_IDS   = 'TAGS_REMOVE_CONTACT_TAG_IDS_FAILED';
    private static final String ERR_VALIDATE_DUPE            = 'TAGS_VALIDATE_DUPE_FAILED';
    private static final String ERR_GET_CONTACT_TAGS         = 'TAGS_GET_CONTACT_TAGS_FAILED';
    private static final String ERR_AND_FINALLY              = 'TAGS_AND_FINALLY_FAILED';
    private static final String ERR_INSERT_FEEDLIST          = 'TAGS_INSERT_FEEDLIST_FAILED';

    private List<Tag_Junction__c> oldTagsList;
    private List<Tag_Junction__c> newTagsList;
    private Map<Id, Map<Id, Tag__c>> contactToTagsMap;
    public List<Tag_Junction__c> addedMemberList = new List<Tag_Junction__c>();
    public List<Tag_Junction__c> deletedMemberList = new List<Tag_Junction__c>();
    
    public TagsTriggerHandler() {
        this(Trigger.old, Trigger.new);
    }
    
    public TagsTriggerHandler(List<Tag_Junction__c> oldList, List<Tag_Junction__c> newList) {
        oldTagsList = oldList;
        newTagsList = newList;
    }
    
    public override void bulkBefore() {
        try {
            contactToTagsMap = getContactToTagsMap();
            validateDupeTags();
            updateNames();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_BEFORE));
            throw ex;
        }
    }
    
    public override void bulkAfter() {
        try {
            updateContactTagIdFields();
            onDeleteRemoveContactTagIdFields();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_AFTER));
            throw ex;
        }
    }
    
    public override void beforeInsert(SObject so) {
        try {
            Tag_Junction__c tagJunc = (Tag_Junction__c) so;
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BEFORE_INSERT));
            throw ex;
        }
    }

    public override void afterInsert(SObject so) {
        Tag_Junction__c lo = (Tag_Junction__c)so;
        addedMemberList.add(lo);
    }

    public override void beforeDelete(SObject so) {
        Tag_Junction__c lo = (Tag_Junction__c)so;
        deletedMemberList.add(lo);
    }

    public override void andFinally() {
        try {
            createNewMemberFeeds();
            deleteNewMemberFeeds();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AND_FINALLY));
        }
    }

    private void createNewMemberFeeds() {
        if(addedMemberList.isEmpty()) return;
        List<FeedItem> feedsList = new List<FeedItem>();
        for(Tag_Junction__c lo : addedMemberList) {
            FeedItem newFeed = new FeedItem();
            if(lo.Account__c != null) {
                newFeed.ParentId = lo.Account__c;
            } else if(lo.Contact__c != null) {
                newFeed.ParentId = lo.Contact__c;
            }
            newFeed.Title = Assets.ADDED_TITLE;
            newFeed.Body = lo.Name + ' added to ' + newFeed.ParentId + ' | ' + lo.Tag__c;
            feedsList.add(newFeed);
        }
        BBApps_Crud.doInsertWithHandling((List<SObject>)feedsList, false, new BBApps_ErrorCustomFields(ERR_INSERT_FEEDLIST));
    } 

    private void deleteNewMemberFeeds() {
        if(deletedMemberList.isEmpty()) return;
        List<FeedItem> feedsList = new List<FeedItem>();
        for(Tag_Junction__c lo : deletedMemberList) {
            if(lo.Organization__c != null) {
                FeedItem newFeed = new FeedItem();
                if(lo.Account__c != null) {
                    newFeed.ParentId = lo.Account__c;
                } else if(lo.Contact__c != null) {
                    newFeed.ParentId = lo.Contact__c;
                }
                newFeed.Title = Assets.REMOVED_TITLE;
                newFeed.Body = lo.Name + ' removed from ' + newFeed.ParentId + ' | ' + lo.Tag__c;
                feedsList.add(newFeed);
            }
        }
        BBApps_Crud.doInsertWithHandling((List<SObject>)feedsList, false, new BBApps_ErrorCustomFields(ERR_INSERT_FEEDLIST));
    }
    
    private void updateNames() {
        if(!Trigger.isBefore || Trigger.isDelete) return;
        Set<Id> tagSet = new Set<Id>();
        for(Tag_Junction__c tag : newTagsList) {
            tagSet.add(tag.Tag__c);
        }
        Map<Id, Tag__c> tagsMap = new Map<Id, Tag__c>(
            [SELECT Id, Name FROM Tag__c WHERE Id IN :tagSet]
        );
        if(tagsMap.isEmpty()) return;
        for(Tag_Junction__c tagLink : newTagsList) {
            Tag__c tag = tagsMap.get(tagLink.Tag__c);
            if(tag != null) tagLink.Name = tag.Name;
        }
    }
    
    private void updateContactTagIdFields() {
        try {
            if(Trigger.isDelete) return;
            if(contactToTagsMap == null) contactToTagsMap = getContactToTagsMap();
            if(contactToTagsMap.isEmpty()) return;
            Set<Contact> conSet = new Set<Contact>();
            for(Tag_Junction__c tag : newTagsList) {
                if(tag.Contact__c == null) continue;
                Map<Id, Tag__c> conTags = contactToTagsMap.get(tag.Contact__c);
                if(conTags != null && !conTags.isEmpty()) {
                    Contact c = new Contact(Id = tag.Contact__c);
                    String tags = '';
                    for(Id tagId : conTags.keySet()) {
                        Tag__c t = conTags.get(tagId);
                        tags += t.Id + ',';
                    }
                    c.Tag_Ids__c = tags;
                    conSet.add(c);
                }
            }
            List<Contact> updateList = new List<Contact>(conSet);
            BBApps_Crud.doUpdateWithHandling(
                (List<SObject>)updateList,
                false,
                new BBApps_ErrorCustomFields(ERR_UPDATE_CONTACT_TAG_IDS)
            );
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_CONTACT_TAG_IDS));
            throw ex;
        }
    }
    
    private void onDeleteRemoveContactTagIdFields() {
        try {
            if(!Trigger.isDelete) return;
            Set<Id> conSetIds = new Set<Id>();
            Map<Id, Set<Id>> conTagMap = new Map<Id, Set<Id>>();
            for(Tag_Junction__c tag : oldTagsList) {
                if(tag.Contact__c != null) {
                    conSetIds.add(tag.Contact__c);
                        Set<Id> tagSet = conTagMap.get(tag.Contact__c);
                        if(tagSet == null) tagSet = new Set<Id>();
                        if(tag.Tag__c != null) tagSet.add(tag.Tag__c);

                    conTagMap.put(tag.Contact__c, tagSet);
                }
            }
            if(conSetIds.isEmpty()) return;
            List<Contact> updateList = [
                SELECT Id, Tag_Ids__c
                FROM Contact
                WHERE Tag_Ids__c != NULL AND Id IN :conSetIds
            ];
            for(Contact c : updateList) {
                Set<Id> conTags = conTagMap.get(c.Id);
                if(conTags != null && !conTags.isEmpty()) {
                    List<String> tagsList = c.Tag_Ids__c != null ? c.Tag_Ids__c.split(',') : new List<String>();
                    String tags = '';
                    for(String tagStr : tagsList) {
                        if(String.isNotBlank(tagStr)) {
                            Id tagId = Id.valueOf(tagStr);
                            if(!conTags.contains(tagId)) tags += tagStr + ',';
                        }
                    }
                    c.Tag_Ids__c = tags;
                }
            }
            BBApps_Crud.doUpdateWithHandling(
                (List<SObject>)updateList,
                false,
                new BBApps_ErrorCustomFields(ERR_REMOVE_CONTACT_TAG_IDS)
            );
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_REMOVE_CONTACT_TAG_IDS));
            throw ex;
        }
    }
    
    private void validateDupeTags() {
        try {
            if(!Trigger.isBefore || Trigger.isDelete) return;
            for(Tag_Junction__c tag : newTagsList) {
                Map<Id, Tag__c> conTags = contactToTagsMap.get(tag.Contact__c);
                if (conTags != null &&
                    tag.Tag__c != null &&
                    conTags.containsKey(tag.Tag__c) &&
                    isFieldChanged(tag, 'Tag__c')) {

                    tag.addError('This contact already contains this tag.');
                }
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_VALIDATE_DUPE));
            throw ex;
        }
    }
    
    private Map<Id, Map<Id, Tag__c>> getContactToTagsMap() {
        try {
            Set<Id> conIds = new Set<Id>();
            List<Tag_Junction__c> tagsList = newTagsList != null ? newTagsList : oldTagsList;


            for (Tag_Junction__c tag : tagsList) {
                if (tag.Contact__c != null) conIds.add(tag.Contact__c);





            }
            Map<Id, Map<Id, Tag__c>> result = new Map<Id, Map<Id, Tag__c>>();
            if (conIds.isEmpty()) return result;

            List<Tag_Junction__c> conTagList = [
                SELECT Id, Contact__c, Tag__c, Tag__r.Name, RecordType.Name
                FROM Tag_Junction__c
                WHERE Contact__c IN :conIds AND RecordType.Name = 'Contact'
            ];
            for (Tag_Junction__c tj : conTagList) {
                Map<Id, Tag__c> tagMap = result.get(tj.Contact__c);
                if (tagMap == null) tagMap = new Map<Id, Tag__c>();
                Tag__c newTag = new Tag__c(Id = tj.Tag__c, Name = tj.Tag__r.Name);
                tagMap.put(tj.Tag__c, newTag);
                result.put(tj.Contact__c, tagMap);

            }
            return result;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_CONTACT_TAGS));
            throw ex;
        }
    }
}