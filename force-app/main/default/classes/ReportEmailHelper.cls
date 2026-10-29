/**
* Author : Neha Gire
* Date   : 12/21/2023
* Jira   : BRME-4773
* Description : This is helper class to send pdf report based on custom setting defined.
* Test   : ReportEmailHelperTest
**/
public with sharing class ReportEmailHelper {
    private static final String ERR_SEND_REPORT= 'REPORT_EMAIL_HELPER_SEND_REPORT_FAILED';
    
    public class EmailReportException extends Exception {}
    
    public static void sendReport(String reportName, PageReference pageRefAttachment, PageReference pageRefEmailBody)  {
        try{
            Report_Email_Setting__mdt setting = getReportEmailSetting(reportName);
            Set<String> emailRecipients = getEmailRecipients(setting);
            Blob content;
            Blob contentBody;
            String contentBodyString;
            if(Test.isRunningTest()) {
                content = Blob.valueOf('Test String');
            } else {
                content = pageRefAttachment.getContentAsPDF();
                contentBody = pageRefEmailBody.getContent();
                contentBodyString = contentBody.toString();
            }
            String lastMonthText;
            if(setting.Add_Current_Month_To_Report__c) {
                String lastMonth = getLastMonthName();
                String lastYear = getLastMonthYear();
                lastMonthText = ' - ' + getLastMonthName() + ' ' + getLastMonthYear();
            }
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName(setting.File_Name__c + lastMonthText + '.pdf');
            attach.setBody(content);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(EmailUtility.getBRMEmailAddress());
            mail.setToAddresses(new List<String>(emailRecipients));
            mail.setSaveAsActivity(false);
            mail.setReplyTo(EmailUtility.getReplyToEmail());
            mail.setSubject(setting.Subject__c + lastMonthText);
            mail.setHTMLBody(
                String.format(setting.Email_Plain_Text_Body__c, new String[]{lastMonthText}) +
                '\n \n' +
                '<hr style="padding: 0; border: 0; border-top: 3px solid #ccc; margin: 1em 0;">'+
                '\n \n' +
                contentBodyString + '' +
                '\n \n' +
                '<hr style="padding: 0; border: 0; border-top: 3px solid #ccc; margin: 1em 0;">'+
                '\n \n' +
            	'<p style="font-weight: bold;">PDF Preview</p>'
            );
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
            Messaging.SendEmailResult[] mailResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_SEND_REPORT));
        }   
    }

    public static Report_Email_Setting__mdt getReportEmailSetting(String reportName) {
        String environment = UtilityClass.getEnvironment();
        List<Report_Email_Setting__mdt> setting = [
            SELECT File_Name__c, Sender_Display_Name__c, Sender_Email_Address__c, Subject__c ,
                   Email_Plain_Text_Body__c, Add_Current_Month_To_Report__c, Title__c,
                   (SELECT Email__c, Active__c, Environment__c
                    FROM Report_Email_Recipients__r
                    WHERE Active__c = true AND
                          Environment__c = :environment)
            FROM Report_Email_Setting__mdt
            WHERE MasterLabel = :reportName LIMIT 1];
        if(setting.isEmpty()) {
            throw new EmailReportException('Report Email Setting does not exist.');
        }
        return setting[0];
    }

    public static Set<String> getEmailRecipients(Report_Email_Setting__mdt setting) {
        Set<String> recipients = new Set<String>();
        if(setting != null) {
            for(Report_Email_Recipient__mdt recipient : setting.Report_Email_Recipients__r) {
                recipients.add(recipient.Email__c);
            }
        }
        return recipients;
    }

    private static String getLastMonthName() {
        Datetime dt = Datetime.now().addMonths(-1);
        return dt.format('MMMM');
    }

    private static String getLastMonthYear() {
        Datetime dt = Datetime.now().addMonths(-1);
        return String.valueOf(dt.year());
    }
}