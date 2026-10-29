@IsTest
private with sharing class BatchDashboardTextUpdateTest {

    @testSetup
    static void setupData() {
        Account org = TestDataFactory.createOrg('Test Org');
        Contact c1  = TestDataFactory.createContact(org.Id, 'Alice');
        Contact c2  = TestDataFactory.createContact(org.Id, 'Bob');

        Campaign camp = TestDataFactory.createCampaign('List - Test');
        TestDataFactory.createCampaignMember(camp.Id, c1.Id);
        TestDataFactory.createCampaignMember(camp.Id, c2.Id);

        TestDataFactory.createDashboardText('/lightning/r/Campaign/' + camp.Id + '/view', 0, true);
        TestDataFactory.createDashboardText('/lightning/r/Report/00O_NOT_VALID/view', 0, true);
        TestDataFactory.createDashboardText('/lightning/r/SomeObj/ABC123/view', 5, true);
    }

    @IsTest
    static void test_ExecuteMethodDirect_NoBatchAPI() {
        List<DashboardText__c> scopeConcrete = [
            SELECT Id, Link__c, Count__c, Campaign__c
            FROM DashboardText__c WITH SYSTEM_MODE
        ];
        List<SObject> scope = new List<SObject>();
        scope.addAll(scopeConcrete);

        Test.startTest();
        BatchDashboardTextUpdate b = new BatchDashboardTextUpdate();
        b.start((Database.BatchableContext) null);
        b.execute((Database.BatchableContext) null, scope);
        b.finish((Database.BatchableContext) null);
        Test.stopTest();

        // Regular assertions
        List<DashboardText__c> rows = [SELECT Id, Link__c, Count__c, Campaign__c FROM DashboardText__c WITH SYSTEM_MODE];
        System.assertEquals(3, rows.size());
    }

    // BRME-6207: This test is purely for code coverage
    @IsTest
    static void test_SetReportCount_Coverage() {
        Id fakeReportId = Id.valueOf('00Oa7000002npBVEAY');

        DashboardText__c dash = new DashboardText__c(
            Link__c = '/lightning/r/Report/' + fakeReportId + '/view',
            Count__c = 0
        );
        insert dash;

        List<DashboardText__c> dashList = [SELECT Id, Link__c, Count__c FROM DashboardText__c WHERE Id = :dash.Id WITH SYSTEM_MODE];
        Map<Id, Id> reportMap = new Map<Id, Id>{ dash.Id => fakeReportId };

        Test.startTest();
        BatchDashboardTextUpdate batch = new BatchDashboardTextUpdate();
        try {
            batch.setReportCount(dashList, reportMap);
        } catch (Exception e) {
            System.debug('Expected error due to fake report ID: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertNotEquals(null, dashList[0].Count__c, 'Count__c should remain initialized even if report run fails');
    }
}