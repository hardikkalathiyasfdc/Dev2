/**
* Author : Ravi
* Date   : 1/4/2024
* Jira   : BRME-4881
* Description : This is the scheduler class to send BP Memeber report.
* Test   : BoardMememberReportSender_Test
* Modified Date: 04/20/2024
* Last ModfiedBy: Paddy
**/
public with sharing class BoardMememberReportSender implements Schedulable {
    
    private static final String ERR_EXECUTE = 'BOARD_MEMBER_REPORT_SENDER_EXECUTE_FAILED';
    public static String settingName = Assets.BOAD_MEMBER_EMAIL_RECEIVER_REPORT_SETTING_NAME;
    BBApps_ErrorCustomFields errorCustomFields = new BBApps_ErrorCustomFields(ERR_EXECUTE); 
    
    public void execute(SchedulableContext SC) {
        try {
            ReportEmailHelper.sendReport(settingName, Page.BoardMemberInteractions, Page.BoardMemberInteractionsEmailBody);
        } catch(Exception ex) {BBApps_ErrorHandler.logErrors(ex, errorCustomFields);}
    }
}