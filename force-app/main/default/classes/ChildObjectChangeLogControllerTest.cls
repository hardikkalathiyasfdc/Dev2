/**
* Author : Nishant Bakhrey
* Description : Test Class for ChildObjectChangeLogController
**/
@isTest
public class ChildObjectChangeLogControllerTest {

    @isTest
    static void testHasRestrictedPermission() {
        Test.startTest();
            Boolean result = ChildObjectChangeLogController.hasRequiredPermission('Restricted_Access');
        Test.stopTest();
        System.assertEquals(FeatureManagement.checkPermission('Restricted_Access'), result);
    }

    @isTest 
    static void testGetFeedForList() {
        Contact c = new Contact(LastName = 'Test Contact');
        insert as system c;
        Account a = new Account(Name = 'Test Account');
        insert as system a;
        Campaign testList = new Campaign(Name = 'Test List');
        insert as system testList;
        FeedItem contactFeed = new FeedItem(
            ParentId = testList.Id,
            Body = 'Test Contact added to Test List | ' + c.Id,
            Title = Assets.ADDED_TITLE
        );
        FeedItem accountFeed = new FeedItem(
            ParentId = testList.Id,
            Body = 'Test Account removed from Test List | ' + a.Id,
            Title = Assets.REMOVED_TITLE
        );
        insert as system new List<FeedItem>{ contactFeed, accountFeed };
        Test.startTest();
            List<ChildObjectChangeLogController.LogItem> logs = 
                ChildObjectChangeLogController.getFeedForParent(testList.Id, 'CampaignMember', 'Name', 'Name', false);
        Test.stopTest();
        for(ChildObjectChangeLogController.LogItem log : logs) {
            if(log.relatedRecordId == c.Id) {
                System.assertEquals('Added', log.action);
            } else if(log.relatedRecordId == a.Id) {
                System.assertEquals('Removed', log.action);
            }
        }
    }
}