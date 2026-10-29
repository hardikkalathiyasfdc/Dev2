/*
 *   test class TagsCmpControllerTest
 */
public with sharing class TagsCmpController {
  public static final Map<String, Id> TAG_JUNC_REC_TYPE_MAP = getTagJuncRecTypeMap();

  private static final String ERR_GET_TAGS  = 'TCC_GET_TAGS_FAILED';
  private static final String ERR_SAVE_TAG  = 'TCC_SAVE_TAG_FAILED';
  private static final String ERR_DEL_TAG   = 'TCC_DEL_TAG_FAILED';
  private static final String ERR_INSERT_TAG = 'TCC_INSERT_TAG_FAILED';
  private static final String ERR_DELETE_TAG = 'TCC_DELETE_TAG_FAILED';

  @AuraEnabled
  public static Object getTags(Id recordId) {
    try {
      Map<String, Object> result = new Map<String, Object>();
      result.put('tags', getTagsList(recordId));
      result.put('whereClause', getWhereClause(recordId));

      result.put('recordName', recordId.getSObjectType().getDescribe().getName());
      return result;
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_TAGS));
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String, Object> saveTag(
    Id recordId,
    Id tagId,
    String tagName
  ) {
    try {
      TagsCmpSystemController systemSave = new TagsCmpSystemController();
      return systemSave.saveTag(recordId, tagId, tagName);
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_SAVE_TAG));
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void delTag(Id tagId) {
    try {
      TagsCmpSystemController systemSave = new TagsCmpSystemController();
      systemSave.delTag(tagId);
    } catch (Exception e) {
      BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_DEL_TAG));
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static String getWhereClause(Id recordId){
    String objName = recordId.getSObjectType().getDescribe().getName();
    String clause = 'RecordType.DeveloperName = \'' + objName+'\'';
    if('contact'.equalsIgnoreCase(objName)){
      return '(RecordTypeId = NULL OR '+clause+')';
    }
    return clause;
  }

  public static Tag_Junction__c getNewTagJunc(
    Id recordId,
    Id tagId,
    String tagName
  ) {
    Tag_Junction__c tagJunc = new Tag_Junction__c();
    tagJunc.Tag__c = tagId;
    tagJunc.Name = tagName;
    String objName = recordId.getSObjectType().getDescribe().getName();
    tagJunc.RecordTypeId = TAG_JUNC_REC_TYPE_MAP.get(objName);
    tagJunc.put(getRelField(recordId), recordId);
    return tagJunc;
  }

  private static Tag_Junction__c getTagJunc(Id recordId, Id tagId) {
    String q =
      'SELECT Id, Tag__c, Tag__r.Name FROM Tag_Junction__c WHERE ' +
      getRelField(recordId) +
      '=: recordId AND Tag__c =: tagId WITH SYSTEM_MODE';
    List<Tag_Junction__c> tagsList = Database.query(q);
    return !tagsList.isEmpty() ? tagsList.get(0) : null;
  }

  private static List<Map<String, Object>> getTagsList(Id recordId) {
    String objField = getRelField(recordId);
    String q =
      'SELECT Id, Tag__c, Tag__r.Name FROM Tag_Junction__c WHERE ' +
      objField +
      ' =: recordId WITH SYSTEM_MODE';
    List<Tag_Junction__c> queryList = (List<Tag_Junction__c>) Database.query(q);
    List<Map<String, Object>> tagsList = new List<Map<String, Object>>();
    for (Tag_Junction__c tag : queryList) {
      tagsList.add(getTag(tag));
    }
    return tagsList;
  }

  private static Map<String, Object> getTag(Tag_Junction__c tag) {
    Map<String, Object> tagMap = new Map<String, Object>();
    tagMap.put('id', tag.Id);
    tagMap.put('label', tag.Tag__r.Name);
    tagMap.put('href', '/lightning/r/Tag__c/' + tag.Tag__c + '/view');
    return tagMap;
  }

  private static String getRelField(Id recordId) {
    return recordId.getSObjectType().getDescribe().getName() + '__c';
  }

  private without sharing class TagsCmpSystemController {
    public Map<String, Object> saveTag(Id recordId, Id tagId, String tagName) {
      Tag_Junction__c newJunc = getTagJunc(recordId, tagId);
      if (newJunc != null) {
        return null;
      }
      newJunc = getNewTagJunc(recordId, tagId, tagName);
      BBApps_Crud.doInsertWithHandling(new List<SObject>{newJunc}, false, ERR_INSERT_TAG);
      return getTag(newJunc);
    }

    public void delTag(Id tagId) {
      Tag_Junction__c oldJunc = new Tag_Junction__c(Id = tagId);
      BBApps_Crud.doDeleteWithHandling(new List<SObject>{oldJunc}, false, ERR_DELETE_TAG);
    }
  }
  
  private static Map<String, Id> getTagJuncRecTypeMap() {
    Map<String, Id> recTypeMap = new Map<String, Id>();
    Map<String, Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Tag_Junction__c.getRecordTypeInfosByName();
    for (String key : rtMapByName.keySet()) {
      Schema.RecordTypeInfo rtInfo = rtMapByName.get(key);
      recTypeMap.put(rtInfo.getDeveloperName(), rtInfo.getRecordTypeId());
    }
    return recTypeMap;
  }
}