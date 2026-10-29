/**
* Author : Nishant Bakhrey
* Description : Test Class for ListOrganizationTriggerHandler
**/
@isTest
public with sharing class ListOrganizationTriggerHandlerTest {

    @testSetup
    static void setupData() {
        Campaign camp = new Campaign(Name = 'Test Org List');
        insert as system camp;
        Account org = new Account(Name = 'Test Org');
        insert as system org;
    }

    @isTest
    static void testAfterInsert_createsFeedItem() {
        Campaign camp = [SELECT Id, Name FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        Account org = [SELECT Id FROM Account WITH SYSTEM_MODE LIMIT 1];
        ListOrganization__c lo = new ListOrganization__c(
            List__c = camp.Id,
            Organization__c = org.Id
        );
        Test.startTest();
            insert as system lo;
        Test.stopTest();
        List<FeedItem> feeds = [
            SELECT ParentId, Title, Body
            FROM FeedItem
            WHERE ParentId = :camp.Id WITH SYSTEM_MODE
        ];
        System.assertEquals(1, feeds.size());
        System.assertEquals(Assets.ADDED_TITLE, feeds[0].Title);
        System.assert(feeds[0].Body.contains(String.valueOf(org.Id)));
    }

    @isTest
    static void testBeforeDelete_createsRemovalFeedItem() {
        Campaign camp = [SELECT Id, Name FROM Campaign WITH SYSTEM_MODE LIMIT 1];
        Account org = [SELECT Id FROM Account WITH SYSTEM_MODE LIMIT 1];
        ListOrganization__c lo = new ListOrganization__c(
            List__c = camp.Id,
            Organization__c = org.Id
        );
        insert as system lo;
        Test.startTest();
            delete as system lo;
        Test.stopTest();
        List<FeedItem> feeds = [
            SELECT Title, Body
            FROM FeedItem
            WHERE ParentId = :camp.Id WITH SYSTEM_MODE
        ];
        System.assertEquals(2, feeds.size());
        System.assertEquals(Assets.REMOVED_TITLE, feeds[0].Title);
    }
}