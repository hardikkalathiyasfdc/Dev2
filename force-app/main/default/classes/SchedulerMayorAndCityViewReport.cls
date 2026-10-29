/**
 * Author : Neha Gire
 * Date   : 12/21/2023
 * Jira   : BRME-4773
 * Description : This is scheduler class which sends 
 *               report monthly to configured recipients.
 * Test   : MayorAndCityViewInteractionCntrlTest
 * Schedule Frequency - 1st Day of every month at 9.00 AM
 **/

public with sharing class SchedulerMayorAndCityViewReport implements Schedulable {
    
    public  static final String REPORT_SETTING_NAME = 'Interactions with Mayor & CityView';
    private static final String ERR_SEND_REPORT= 'SCHEDULER_MAYOR_AND_CITYVIEW_SEND_REPORT_FAILED';
    
	@TestVisible
    private static Boolean throwExceptionForTest = false;
    
    public void execute(SchedulableContext SC) {
        try {
             // only for test coverage
            if(Test.isRunningTest() && throwExceptionForTest){
                Integer x = 1 / 0;
            }
            ReportEmailHelper.sendReport(REPORT_SETTING_NAME ,Page.MayorAndCityViewInteractionReport, Page.MayorAndCityViewInteractionEmailBody);
        } catch(Exception e) {
            BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_SEND_REPORT));
            System.debug('Error while sending report : ' + REPORT_SETTING_NAME);
        }
    }
}