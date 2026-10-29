@isTest
public with sharing class ReportEmailHelperTest {
    
    @isTest
    public static void testIfReportSettingNotPresent() {
        Test.startTest();
        try{
            ReportEmailHelper.sendReport('Test Report Setting', null, null);
        }catch(Exception e){
            System.assertEquals(e.getMessage(), 'Report Email Setting does not exist.', 'Error should be thrown.');
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testIfReportSettingPresent() {
        Test.startTest();
        ReportEmailHelper.sendReport('Interactions with Mayor & CityView', null, null);
        Integer emailInvocation = Limits.getEmailInvocations();
        Test.stopTest();
    System.assertEquals(1, emailInvocation, 'An email should be sent.');
    }
}