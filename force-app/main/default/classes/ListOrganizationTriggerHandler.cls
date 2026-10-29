/**
 * @author            : Nishant Bakhrey
 * @last modified on  : 07-15-2025
 * @last modified by  : Nishant Bakhrey
 * Description        : Trigger Handler for the ListOrganization object
 * Test Class         : ListOrganizationTriggerHandlerTest
**/
public without sharing class ListOrganizationTriggerHandler extends TriggerHandler {
    public List<ListOrganization__c> addedMemberList = new List<ListOrganization__c>();
    public List<ListOrganization__c> deletedMemberList = new List<ListOrganization__c>();
    private static final String ERR_AND_FINALLY = 'LIST_ORG_AND_FINALLY_FAILED';
    private static final String ERR_INSERT_FEEDLIST = 'LIST_ORG_INSERT_FEEDLIST_FAILED';

    public override void afterInsert(SObject so) {
        ListOrganization__c lo = (ListOrganization__c)so;
        addedMemberList.add(lo);
    }

    public override void beforeDelete(SObject so) {
        ListOrganization__c lo = (ListOrganization__c)so;
        deletedMemberList.add(lo);
    }

    public override void andFinally() {
        try {
            createNewMemberFeeds();
            deleteNewMemberFeeds();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AND_FINALLY));
        }
    }

    private void createNewMemberFeeds() {
        if(addedMemberList.isEmpty()) return;
        List<FeedItem> feedsList = new List<FeedItem>();
        for(ListOrganization__c lo : addedMemberList) {
            if(lo.Organization__c != null) {
                FeedItem newFeed = new FeedItem();
                newFeed.ParentId = lo.List__c;
                newFeed.Title = Assets.ADDED_TITLE;
                newFeed.Body = lo.Organization__c + ' added to ' + lo.List__c + ' | ' + lo.Organization__c;
                feedsList.add(newFeed);
            }
        }
        BBApps_Crud.doInsertWithHandling((List<SObject>)feedsList, false, new BBApps_ErrorCustomFields(ERR_INSERT_FEEDLIST));
    }

    private void deleteNewMemberFeeds() {
        if(deletedMemberList.isEmpty()) return;
        List<FeedItem> feedsList = new List<FeedItem>();
        for(ListOrganization__c lo : deletedMemberList) {
            if(lo.Organization__c != null) {
                FeedItem newFeed = new FeedItem();  
                newFeed.ParentId = lo.List__c;
                newFeed.Title = Assets.REMOVED_TITLE;
                newFeed.Body = lo.Organization__c + ' removed from ' + lo.List__c + ' | ' + lo.Organization__c;
                feedsList.add(newFeed);
            }
        }
        BBApps_Crud.doInsertWithHandling((List<SObject>)feedsList, false, new BBApps_ErrorCustomFields(ERR_INSERT_FEEDLIST));
    }
}