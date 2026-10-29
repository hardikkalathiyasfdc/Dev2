/*
* Modified Date: 04/20/2024
* Last ModfiedBy: Paddy
*/
public with sharing class DonorMemoSender implements Schedulable {
    
    private static final String ERR_SEND_REPORT_FAILED = 'DONOR_MEMO_SENDER_FAILED';
    BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SEND_REPORT_FAILED); 

    public void execute(SchedulableContext SC) {
        try {
            ReportEmailHelper.sendReport(Assets.FUNDRAISING_DONOR_MEMO_REPORT_SETTING_NAME, Page.DonorMemoReport, Page.DonorMemoReportEmailBody);
        } catch(Exception e) { BBApps_ErrorHandler.logErrors(e, f); }
    }
}