@isTest
public class SObjectMultiSelectionControllerTest {

    @testSetup
    static void dataSetup () {
        Account a = TestDataFactory.getOrg('test');
        insert as system a;
        Contact c = TestDataFactory.getContact('test');
        c.AccountId = a.Id;
        insert as system c;
        Tag__c t = TestDataFactory.getTag('test');
        insert as system t;
        Tag_Junction__c j = TestDataFactory.getTagJunc(t,c);
        insert as system j;
        Campaign testCamp = new Campaign(Name = 'test list');
        insert as system testCamp;
        CampaignMember testMem = TestDataFactory.getListMember(testCamp.Id, c.Id);
        testMem.Source__c = 'Test';
        insert as system testMem;
    }
    
    @isTest
    static void testFetchLookUpValues() {
        List<sObject> excludeIds = new List<sObject>();
        List<SObjectMultiSelectionController.SelectedItem> excludeRecords = new List<SObjectMultiSelectionController.SelectedItem>();
        List<SObjectMultiSelectionController.ResultWrapper> resultWrapper = SObjectMultiSelectionController.fetchLookUpValues('test', excludeIds, 'Contact', '0124v000001uH3CAAU','  ');
        List<SObjectMultiSelectionController.ResultWrapper> allresultWrapper = SObjectMultiSelectionController.fetchLookUpAllValues('Campaign', '0124v000001uH3CAAU','  ');
        List<SObjectMultiSelectionController.ResultWrapper> filterResultWrapper = SObjectMultiSelectionController.fetchFilterLookUpValues('test', JSON.serialize(excludeRecords), 'Contact', '0124v000001uH3CAAU');
        Campaign testCmp = [Select Id from Campaign where Name = 'test list' WITH SYSTEM_MODE];
        SObjectMultiSelectionController.SelectedItem selectedItem = new SObjectMultiSelectionController.SelectedItem();
        selectedItem.label = 'test list';
        selectedItem.value = testCmp.Id;
        excludeRecords.add(selectedItem);
        List<SObjectMultiSelectionController.ResultWrapper> filterResultWrapper1 = SObjectMultiSelectionController.fetchLookUpAllValuesWithExcludeValues('Campaign', '0124v000001uH3CAAU', JSON.serialize(excludeRecords));
        System.assert(!resultWrapper.isEmpty());
    }

    @isTest
    static void testFetchAllSourceValues() {
        Campaign testCmp = [SELECT Id FROM Campaign WHERE Name = 'test list' WITH SYSTEM_MODE];
        List<SObjectMultiSelectionController.ResultWrapper> resultWrapper = SObjectMultiSelectionController.fetchLookUpAllSouceValues(testCmp.Id);
        Assert.isTrue(!resultWrapper.isEmpty());
    }

    @isTest
    static void testFetchExcludeSourceValues() {
        List<SObjectMultiSelectionController.SelectedItem> excludeRecords = new List<SObjectMultiSelectionController.SelectedItem>();
        SObjectMultiSelectionController.SelectedItem selectedItem = new SObjectMultiSelectionController.SelectedItem();
        selectedItem.label = 'Test';
        selectedItem.value = 'Test';
        excludeRecords.add(selectedItem);
        Campaign testCmp = [SELECT Id FROM Campaign WHERE Name = 'test list' WITH SYSTEM_MODE];
        List<SObjectMultiSelectionController.ResultWrapper> resultWrapper = SObjectMultiSelectionController.fetchLookUpAllSouceValuesWithExcludeValues(testCmp.Id, JSON.serialize(excludeRecords));
        Assert.isTrue(resultWrapper.isEmpty());
    }
}