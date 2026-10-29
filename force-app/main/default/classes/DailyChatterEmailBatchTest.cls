@isTest
public without sharing class DailyChatterEmailBatchTest {
  @TestSetup
    private static void makeData() {
      User curUser = [
        SELECT Id, Chatter_Digest__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
      ];
      curUser.Chatter_Digest__c = true;
      update curUser;
      Contact c = new Contact(LastName = 'test', Title = 'test');
      insert c;
      FeedItem f = new FeedItem(ParentId = c.Id, body = 'test contact');
      insert f;
      EntitySubscription testSub = new EntitySubscription(
        SubscriberId = curUser.Id,
        ParentId = c.Id
      );
      insert testSub;
      c.Title = c.Title + 'test';
      update c;
      Campaign camp = new Campaign(Name = 'test');
      insert camp;
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
    public static void validateBatch() {
        Test.startTest();
        Datetime dt = System.now().addMinutes(5);
        String cronExp =
            dt.second() + ' ' +
            dt.minute() + ' ' +
            dt.hour() + ' ' +
            dt.day() + ' ' +
            dt.month() + ' ? ' +
            dt.year();
        System.schedule(
            'Test Daily Chatter Email Job',
            cronExp,
            new ScheduleDailyChatterEmail()
        );
        Database.executeBatch(new DailyChatterEmailBatch());
        Test.stopTest();
        System.assert(true, 'batch completed without exception');
    } 
    
    @isTest
    static void testExecuteException() {
        ScheduleDailyChatterEmail.throwExceptionForTest = true;

        Test.startTest();

        ScheduleDailyChatterEmail job = new ScheduleDailyChatterEmail();
        job.execute(null);

        Test.stopTest();
    }
}