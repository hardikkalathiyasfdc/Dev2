@isTest
public without sharing class TagsCmpControllerTest {
  @isTest
  public static void validateTagsCmpController() {
    Test.startTest();
    Id recId = getTestRecordId();
    Tag__c testTag = getTestTag();
    Map<String, Object> tagMap = TagsCmpController.saveTag(
      recId,
      testTag.Id,
      'test'
    );

    System.assert(tagMap.get('id') != null, 'failed to save tag junc');

    System.assert(
      TagsCmpController.getTags(recId) != null,
      'failed to retrieve tags'
    );
    Id tagJuncId = (Id) tagMap.get('id');
    TagsCmpController.delTag(tagJuncId);
    List<Tag_Junction__c> juncList = [SELECT Id FROM Tag_Junction__c WITH SYSTEM_MODE];
    System.assert(juncList.isEmpty(), 'failed to delete tag junction');
    Test.stopTest();
  }

  @isTest
  public static void validateTagsTrigger() {
    Test.startTest();
    Id recId = getTestRecordId();
    Tag__c testTag = getTestTag();
    Map<String, Object> tagMap = TagsCmpController.saveTag(
      recId,
      testTag.Id,
      'test'
    );
    Id tagJuncId = (Id) tagMap.get('id');
    testTag.Name = 'test change';
    update testTag;
    List<Tag_Junction__c> tagJunc = [SELECT Id, Name FROM Tag_Junction__c WITH SYSTEM_MODE];
    System.assert(
      'test change'.equals(tagJunc.get(0).Name),
      'failed to update tag junc name'
    );
    Test.stopTest();
  }

  private static Id getTestRecordId() {
    return [SELECT Id FROM Contact WITH SYSTEM_MODE].Id;
  }

  private static Tag__c getTestTag() {
    return [SELECT Id, Name FROM Tag__c WITH SYSTEM_MODE];
  }
  @TestSetup
  private static void makeData() {
    Account a = TestDataFactory.getOrg('test');
    insert a;
    Contact c = TestDataFactory.getContact('test');
    c.AccountId = a.Id;
    insert c;
    Tag__c t = TestDataFactory.getTag('test');
    insert t;
  }
}