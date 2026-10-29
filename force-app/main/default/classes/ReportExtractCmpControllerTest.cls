@isTest
public without sharing class ReportExtractCmpControllerTest {
	
     @isTest
     public static void validateGetData() {
          System.assert(
               ReportExtractcmpController.getData(null, null) != null,
          	'failed to get data'
          );
     }
     
     @isTest
     public static void validateGetOptions() {
          System.assert(
               ReportExtractcmpController.getOptions() != null,
          	'failed to get options'
          );
     }
     
     @isTest(SeeAllData='true')
     public static void validateGetEvtMap() {
          Report testRpt = [SELECT Id FROM Report WITH SYSTEM_MODE LIMIT 1];
          Map<Id, User> userMap = new Map<Id, User> ([Select Id, BP_Team__c from User where Id =: userinfo.getUserId() WITH SYSTEM_MODE]);
          ReportEvent testEvt = new ReportEvent(
               ReportId = testRpt.Id,
			UserId = UserInfo.getUserId(),
			Records = '{"totalSize":1,"rows":[{"datacells":["005B0000001vURv","001B000000fewai"]}]}'
          );
          System.assert(
               ReportExtractcmpController.getEvtMap(testEvt, userMap) != null,
          	'failed to get evtMap'
          );
          ReportEventRecords recordData = (ReportEventRecords)JSON.deserialize(testEvt.Records,ReportEventRecords.Class);
          recordData.rows = new List<ReportEventRecords.rows> ();
     }
     
     @isTest
     static void validateGetEvtMap_exception() {
          Test.startTest();
          Map<String, Object> result =
               ReportExtractCmpController.getEvtMap(null, new Map<Id, User>());
          Test.stopTest();
          System.assertNotEquals(null, result);
          System.assertEquals(0, result.size(), 'Expected empty map after exception');
     }
}