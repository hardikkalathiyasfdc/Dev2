@isTest
public without sharing class TagsReportControllerTest {
  @isTest(seeAllData=true)
  public static void validateRedirectToReport() {
    Test.startTest();
    List<Tag_Junction__c> tagsList = [SELECT Id FROM Tag_Junction__c WITH SYSTEM_MODE LIMIT 10];
    PageReference pref = page.TagsReportPage;
    Test.setCurrentPage(pref);

    ApexPages.StandardSetController sc = new ApexPages.StandardSetController(
      tagsList
    );
    sc.setSelected(tagsList);
    TagsReportController testCont = new TagsReportController(sc);
    System.assert(
      testCont.redirectToReport() != null,
      'failed to redirect to report.'
    );
    Test.stopTest();
  }

  @isTest
  public static void validateGetConfig() {
    Test.startTest();
    makeData();
    System.assert(
      TagsReportController.getConfig() != null,
      'failed to get config'
    );
    Test.stopTest();
  }

  @isTest
  public static void validateGetData() {
    Test.startTest();
    makeData();
    Tag__c tag = [SELECT Id FROM Tag__c WITH SYSTEM_MODE LIMIT 1];
    System.assert(
      TagsReportController.getData(new List<String>{'Id'}, new List<String>{tag.Id}, null) != null,
      'failed to get data'
    );
    Test.stopTest();
  }

  private static void makeData() {
    Account a = TestDataFactory.getOrg('test');
    insert as system a;
    Contact c = TestDataFactory.getContact('test');
    c.AccountId = a.Id;
    insert as system c;
    Tag__c t = TestDataFactory.getTag('test');
    insert as system t;
    Tag_Junction__c tJunc = TestDataFactory.getTagJunc(t, c);
    tJunc.Tag__c = t.Id;
    tJunc.Contact__c = c.Id;
    insert as system tJunc;

    Report testReport = new Report();
  }
}