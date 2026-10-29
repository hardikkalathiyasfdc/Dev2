@isTest
public without sharing class ListViewEditCmpControllerTest {
  @isTest
  public static void validateGetListMembers() {
    Test.startTest();
    Campaign testCamp = [SELECT Id FROM Campaign LIMIT 1];
    System.assert(
      ListViewEditCmpController.getListMembers(
        testCamp.Id,
        0,
        'CreatedDate',
        'desc'
      ) != null,
      ''
    );
    Test.stopTest();
  }

  @isTest
  public static void validateSaveListMembers() {
    Test.startTest();
    boolean isException = false;
    try {
      List<CampaignMember> mem = [SELECT Id, UB_Notes__c FROM CampaignMember];
      mem[0].UB_Notes__c = 'test';
      ListViewEditCmpController.saveListMembers(mem);
    } catch (Exception e) {
      isException = true;
    }
    System.assert(isException == false, 'failed to update member');
    Test.stopTest();
  }

  @isTest
  public static void validateGetListMembersNegative() {
    Test.startTest();
    Boolean isException = false;
    try {
      System.assert(
        ListViewEditCmpController.getListMembers(
          null,
          0,
          'CreatedDate',
          'desc'
        ) != null,
        ''
      );
    } catch (Exception e) {
      isException = true;
    }
    System.assert(isException, 'failed to throw no campaign id error');
    Test.stopTest();
  }

  @isTest
  public static void validateGetListMembersDataSize() {
    Test.startTest();
    delete [SELECT Id FROM CampaignMember];
    Campaign testCamp = [SELECT Id FROM Campaign LIMIT 1];

    Object check = ListViewEditCmpController.getListMembers(
      testCamp.Id,
      0,
      'CreatedDate',
      'desc'
    );
    Map<String, Object> checkMap = (Map<String, Object>) check;
    Integer dataSize = Integer.valueOf(checkMap.get('dataSize') + '');
    System.assert(dataSize == 0, 'failed to determine correct data size');
    Test.stopTest();
  }

  @TestSetup
  public static void makeData() {
    Contact c = new Contact(LastName = 'test');
    insert c;
    Campaign camp = new Campaign(Name = 'test');
    insert camp;
    CampaignMember mem = new CampaignMember(
      CampaignId = camp.Id,
      ContactId = c.Id
    );
    insert mem;
  }
}