@isTest
public with sharing class BatchIMSyncLoadSkipDeletionTest {

  @TestSetup
  static void setup() {
    IM_Sync_Load_Skip__c syncLoadSkip = TestDataFactory.createSyncLoadSkip();
  }

  @isTest
  public static void testDeleteGrants() {
    Test.startTest();

    new BatchIMSyncLoadSkipDeletion().execute(null);

    Test.stopTest();
    List<IM_Sync_Load_Skip__c> syncLoadSkipDeleted = [
      SELECT Id
      FROM IM_Sync_Load_Skip__c
      WITH SYSTEM_MODE
    ];
    Assert.areEqual(true, syncLoadSkipDeleted.isEmpty());
  }
}