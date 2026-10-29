@isTest
public class EventSummaryCmpControllerTest {
  @isTest
  public static void testGetUserEmail() {
    System.assert(
      EventSummaryCmpController.getUserEmail() != '',
      'failed to get user email'
    );
  }
  @isTest
  public static void testSendEmail() {
      Campaign c = [SELECT Id, Name FROM Campaign WITH SYSTEM_MODE LIMIT 1];
      String params = '{"isSalutationChecked":false,"isTitleChecked":true,"isOrgChecked":true,"isCityChecked":true,"isStateChecked":true,"isCountryChecked":true,"isWaitlistChecked":true,"isPreferredNameChecked":true, "isAddGuestOfChecked":true, "isAddSourceChecked":true, "sourceNames":["Test"]}';
      EventSummaryCmpController.sendEmail(c.Id, 'test@bloomberg.org', params);
  }
	
  @testSetup
  private static void dataSetup() {
    Id eventId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
      .get('Pre_Event')
      .getRecordTypeId();
    //Campaign camp = new Campaign(Name = 'test', RecordTypeId = eventId);
    Campaign camp = new Campaign(Name = 'test');
    insert as system camp;

    Account acct = TestDataFactory.getOrg('test');
    insert as system acct;
    List<CampaignMember> memList = new List<CampaignMember>();
    Contact con = TestDataFactory.getContact('test 1');
    con.AccountId = acct.Id;
    insert as system con;
    Id firstId = con.Id;
    CampaignMember mem = TestDataFactory.getListMember(camp.Id, con.Id);
    mem.Source__c = 'Test';
    mem.RSVPStatus__c = 'Yes';
    memList.add(mem);

    con = TestDataFactory.getContact('test 2');
    con.AccountId = acct.Id;
    con.Significant_Other__c = firstId;
    insert as system con;
    mem = TestDataFactory.getListMember(camp.Id, con.Id);
    mem.RSVPStatus__c = 'No';
    memList.add(mem);

    con = TestDataFactory.getContact('test 3');
    con.AccountId = acct.Id;
    insert as system con;
    mem = TestDataFactory.getListMember(camp.Id, con.Id);
    mem.RSVPStatus__c = 'Pend';
    memList.add(mem);

    insert as system memList;
  }
}