public with sharing class ListCreateTagsController {

  @AuraEnabled
  public static Object getListInfo(Id recId) {
    if (!FeatureManagement.checkPermission('Tags_Create_List')) {
      throw new MyException(
        'You do not have access to bulk add tags to lists.'
      );
    }
    try {
      Map<String, Object> results = new Map<String, Object>();
      Campaign c = [
        SELECT Id, Name, NumberOfContacts, RecordType.DeveloperName
        FROM Campaign
        WHERE Id = :recId
        LIMIT 1
      ];
      Boolean isOrgList = 'Organization'
        .equalsIgnoreCase(c.RecordType?.DeveloperName);
      Integer listCount = getMemCount(c, isOrgList);
      if (!isOrgList && listCount == 0) {
        throw new MyException('This list has no members to add tags.');
      }
      results.put('Id', c.Id);
      results.put('Name', c.Name);
      results.put('count', listCount);
      String recTypeName = isOrgList ? 'Account' : 'Contact';
      results.put('recordName', recTypeName);
      results.put(
        'recTypeId',
        TagsCmpController.TAG_JUNC_REC_TYPE_MAP.get(recTypeName)
      );
      return results;
    } catch (Exception e) {
      throw new MyException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void saveTags(Id recId, Id tagId) {
    try {
      Campaign c = [
        SELECT Id, RecordType.DeveloperName
        FROM Campaign
        WHERE Id = :recId
        LIMIT 1
      ];
      Boolean isOrgList = 'Organization'
        .equalsIgnoreCase(c.RecordType?.DeveloperName);
      Set<Id> relIds = getListMemIds(c, isOrgList);
      List<Tag_Junction__c> newTagsList = new List<Tag_Junction__c>();
      String tagName = [SELECT Id, Name FROM Tag__c WHERE Id = :tagId].Name;
      for (Id relId : relIds) {
        newTagsList.add(TagsCmpController.getNewTagJunc(relId, tagId, tagName));
      }
      Database.insert(newTagsList, false);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Integer getMemCount(Campaign c, Boolean isOrgList) {
    if (!isOrgList) {
      return c.NumberOfContacts;
    }
    Id campId = c.Id;
    Integer count = Database.countQuery(
      'SELECT COUNT() FROM ListOrganization__c WHERE List__c=: campId'
    );
    return count;
  }

  private static Set<Id> getListMemIds(Campaign c, Boolean isOrgList) {
    Set<Id> memIds = new Set<Id>();
    if (isOrgList) {
      List<ListOrganization__c> orgList = [
        SELECT Id, Organization__c
        FROM ListOrganization__c
        WHERE List__c = :c.Id AND Organization__c != NULL
      ];
      for (ListOrganization__c org : orgList) {
        memIds.add(org.Organization__c);
      }
    } else {
      List<CampaignMember> memList = [
        SELECT Id, ContactId
        FROM CampaignMember
        WHERE CampaignId = :c.Id AND ContactId != NULL
      ];
      for (CampaignMember mem : memList) {
        memIds.add(mem.ContactId);
      }
    }
    return memIds;
  }

  private class MyException extends Exception {
  }
}