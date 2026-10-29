/**
* Author : Neha
* Date   : 1/4/2024
* Jira   : BRME-4881
* Description : This class is related to Test Report LWC cmp. This is designed to test scheduled reports for data team.
* Test   : TestReportEmailCntrlTest
* 
**/
public class TestReportEmailCntrl {

    @auraEnabled
    public static void sendMayorReportEmail(){
        SchedulerMayorAndCityViewReport scheduleObj = new SchedulerMayorAndCityViewReport();
        scheduleObj.execute(null);
    }
    
    
    @auraEnabled
    public static void sendBoardMemberReportEmail(){
        BoardMememberReportSender scheduleObj = new BoardMememberReportSender();
        scheduleObj.execute(null);
    }
}