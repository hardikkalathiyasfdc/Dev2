/**
* @description       : Utility class that retrieves environment-specific org-wide email address IDs and reply-to email
settings from custom metadata, and provides standardized email content for outbound communications.
**/
public without sharing class EmailUtility {

    private static final String ERR_GET_BRM_EMAIL_ADDRESS = 'EMAIL_UTILITY_GET_BRM_EMAIL_ADDRESS_FAILED';
    private static final String ERR_GET_BUSINESS_ADMIN_EMAIL_ADDRESS = 'EMAIL_UTILITY_GET_BUSINESS_ADMIN_EMAIL_ADDRESS';
    private static final String ERR_GET_INITIAL_EMAIL_CONTENT = 'EMAIL_UTILITY_GET_INITIAL_EMAIL_CONTENT';
    private static final String ERR_GET_REPLY_TO_EMAIL = 'EMAIL_UTILITY_GET_REPLY_TO_EMAI';

    @TestVisible
    private static Boolean forceException = false;

    public static String getBRMEmailAddress() {
        try {
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
            String orgWideEmailAddressId = '';
            List<OrgWideEmailAddress> orgWideEmails = [
                SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :envSetting.BRME_Email_Address__c];
            if(!orgWideEmails.isEmpty()) {
                OrgWideEmailAddress orgWideEmail = orgWideEmails.get(0);
                orgWideEmailAddressId = orgWideEmail.Id;
            }
            return orgWideEmailAddressId;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_BRM_EMAIL_ADDRESS) );
            return null;
        }
    }

    public static String getBusinessAdminEmailAddress() {
        try {
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
            String orgWideEmailAddressId = '';
            List<OrgWideEmailAddress> orgWideEmails = [
                SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :envSetting.Business_Email_Address__c];
            if(!orgWideEmails.isEmpty()) {
                OrgWideEmailAddress orgWideEmail = orgWideEmails.get(0);
                orgWideEmailAddressId = orgWideEmail.Id;
            }
            return orgWideEmailAddressId;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_BUSINESS_ADMIN_EMAIL_ADDRESS) );
            return null;
        }
    }

    public static String getInitialEmailContent() {
        try {
            return 'This email has been send on behalf of ' + UserInfo.getName() + '\n\n\n';
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_INITIAL_EMAIL_CONTENT) );
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getReplyToEmail() {
        try {
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
            return envSetting.BRME_Email_Address__c;
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_GET_REPLY_TO_EMAIL) );
            return null;
        }
    }

    public static String getIMEmailAddress() {
        Environment_Setting__mdt envSetting = Environment.getEnvironmentSetting();
        String orgWideEmailAddressId = '';
        List<OrgWideEmailAddress> orgWideEmails = [
            SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :envSetting.IM_Org_Wide_Email__c];
        if(!orgWideEmails.isEmpty()) {
            OrgWideEmailAddress orgWideEmail = orgWideEmails.get(0);
            orgWideEmailAddressId = orgWideEmail.Id;
        }
        return orgWideEmailAddressId;
    }

    public static String getBgiveHelpDeskEmail() {
        return Environment.isSandbox() ? UserInfo.getUserEmail() : Environment.getEnvironmentSetting().IM_Bgive_Helpdesk_Email__c;
    }
}