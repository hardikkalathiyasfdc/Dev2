@isTest
public class TestReportEmailCntrlTest {
	
  @TestSetup
  public static void makeData() {
    Contact c = TestDataFactory.createMayorContact();
    TestDataFactory.createInteraction(c.Id, 'Test Report 1 (Email)', 'Arts',null);
    TestDataFactory.createInteraction(c.Id,'Test Report (Email)', 'Arts',null);

    Account a = TestDataFactory.createCityViewOrg();
    TestDataFactory.createOrgInteraction(a.Id,'Test Report 1 (Email)', 'Arts','Publish to CityView');
    TestDataFactory.createOrgInteraction(a.Id, 'Test Report (Email)', 'Arts','Publish to CityView');

  }
    
   @isTest
  public static void testSchedulerMayorAndCityViewReport() {
    Test.startTest();
      
      TestReportEmailCntrl.sendMayorReportEmail();
      Integer emailInvocation = Limits.getEmailInvocations();
    Test.stopTest();
    System.assertEquals(1, emailInvocation, 'An email should be sent.');
  }
    
    @isTest
  public static void testSendBoardMemberReportEmail() {
    Test.startTest();
      TestReportEmailCntrl.sendBoardMemberReportEmail();
      Integer emailInvocation = Limits.getEmailInvocations();
    Test.stopTest();
    System.assertEquals(1, emailInvocation, 'An email should be sent.');
  }
}