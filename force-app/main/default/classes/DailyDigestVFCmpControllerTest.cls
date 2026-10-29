@isTest
public without sharing class DailyDigestVFCmpControllerTest {
  @isTest
  public static void validateGetListDigest() {
    Test.startTest();
    DailyDigestVFCmpController digest = new DailyDigestVFCmpController();
    System.assert(digest.listDigest != null, 'failed to get list digest');
    Test.stopTest();
  }
  @isTest
  public static void validateGetContactDigestList() {
    Test.startTest();
    DailyDigestVFCmpController digest = new DailyDigestVFCmpController();
    System.assert(
      digest.contactDigest != null,
      'failed to get contact digest list'
    );
    Test.stopTest();
  }
  @isTest
  public static void validateIsValidField() {
    Test.startTest();
    FeedTrackedChange ftc = new FeedTrackedChange();
    System.assert(
      !DailyDigestVFCmpController.isValidField(ftc),
      'failed to validate field'
    );
    Test.stopTest();
  }
  @isTest
  public static void validateContactDigestProperties() {
    Test.startTest();
    DailyDigestVFCmpController digest = new DailyDigestVFCmpController();
    System.assert(digest.contactDigest.feedList != null, 'feedList should not be null');
    System.assert(digest.contactDigest.hasMore != null, 'hasMore should not be null');
    System.assert(digest.contactDigest.hasVal != null, 'hasVal should not be null');
    System.assert(digest.contactDigest.viewMoreUrl != null, 'viewMoreUrl should not be null');
    Test.stopTest();
  }
  @isTest
  public static void validateListDigestProperties() {
    Test.startTest();
    DailyDigestVFCmpController digest = new DailyDigestVFCmpController();
    System.assert(digest.listDigest.feedList != null, 'feedList should not be null');
    System.assert(digest.listDigest.hasMore != null, 'hasMore should not be null');
    System.assert(digest.listDigest.hasVal != null, 'hasVal should not be null');
    System.assert(digest.listDigest.viewMoreUrl != null, 'viewMoreUrl should not be null');
    Test.stopTest();
  }
    
  @isTest
  public static void validateUserName() {
    Test.startTest();
    DailyDigestVFCmpController digest = new DailyDigestVFCmpController();
    System.assert(digest.userName != null, 'userName should not be null');
    System.assert(digest.userName != 'there', 'userName should resolve to actual user name');
    Test.stopTest();
  }
  
  @TestSetup
  private static void makeData() {
    User curUser = [
      SELECT Id, Chatter_Digest__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    curUser.Chatter_Digest__c = true;
    curUser.Sharing_Team__c = 'System Administration';
    System.runAs ( new User(Id = UserInfo.getUserId()) ){
            update curUser;
        }
    Contact c = new Contact(LastName = 'test', Title = 'test');
    insert c;
    FeedItem f = new FeedItem(ParentId = c.Id, body = 'test contact');
    insert f;
    EntitySubscription testSub = new EntitySubscription(
      SubscriberId = curUser.Id,
      ParentId = c.Id
    );
    insert testSub;
    Campaign camp = new Campaign(Name = 'test');
    insert camp;
    f = new FeedItem(ParentId = camp.Id, body = 'test list');
    insert f;
    testSub = new EntitySubscription(
      SubscriberId = curUser.Id,
      ParentId = camp.Id
    );
    insert testSub;
    CampaignMember mem = new CampaignMember(
      ContactId = c.Id,
      CampaignId = camp.Id
    );
    insert mem;
  }
    
    @isTest
    public static void validateMyContactFeed() {
      ContactFeed cf = [SELECT Id, ParentId, Parent.Name, Parent.Title,
        Parent.CreatedBy.Name, Parent.CreatedById, Parent.AccountId,
        Parent.Account.Name, CreatedDate, CreatedBy.Name, CreatedById,
        Title, Body FROM ContactFeed LIMIT 1];
      Test.startTest();
      DailyDigestVFCmpController.MyContactFeed feed = new DailyDigestVFCmpController.MyContactFeed(cf);
      feed.add(cf);
      System.assert(feed.name != null, 'name should not be null');
      System.assert(feed.url != null, 'url should not be null');
      System.assert(feed.changeList != null, 'changeList should not be null');
      System.assert(feed.hasMore != null, 'hasMore should not be null');
      System.assert(feed.viewMoreUrl != null, 'viewMoreUrl should not be null');
      Test.stopTest();
    }
    
    @isTest
    public static void validateMyListFeedAndChange() {
      CampaignFeed cf = [SELECT Id, ParentId, Parent.Name, Parent.OwnerId,
        Parent.Owner.Name, CreatedDate, CreatedBy.Name, CreatedById,
        Title, Body FROM CampaignFeed LIMIT 1];
      Contact c = [SELECT Id, Name FROM Contact LIMIT 1];
      Test.startTest();
      DailyDigestVFCmpController.MyListFeed feed = new DailyDigestVFCmpController.MyListFeed(cf);
      DailyDigestVFCmpController.MyListChange change = new DailyDigestVFCmpController.MyListChange(cf);
      feed.add(cf);
      System.assert(!feed.changeList.isEmpty(), 'changeList should not be empty after add');
      Map<Id, Contact> conMap = new Map<Id, Contact>{ c.Id => c };
      feed.changeList[0].conId = c.Id;
      feed.setName(conMap);
      System.assert(feed.changeList[0].name != null, 'name should be set after setName');
      System.assert(feed.name != null, 'feed name should not be null');
      Test.stopTest();
    }

  @isTest
  public static void validateHasDigestContent() {
    Test.startTest();
    Boolean hasContent = DailyDigestVFCmpController.hasDigestContent(UserInfo.getUserId());
    System.assertNotEquals(null, hasContent, 'hasDigestContent should return a boolean');
    System.assertEquals(
      false,
      DailyDigestVFCmpController.hasDigestContent(null),
      'null user should have no digest content'
    );
    Test.stopTest();
  }
}