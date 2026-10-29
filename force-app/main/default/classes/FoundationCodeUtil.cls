/**
 * Author : Neha Gire
 * Date   : 04/12/2024
 * Jira   : BRME-5240
 * Description : This class contains util methods for Foundation Code logic.
 * Test : BatchFoundationCodeSyncTest
 */
public with sharing class FoundationCodeUtil {
    public static List<String> getModelAttributes(){
        List<String> modelAttributeIds;
        Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{'Foundation_Code_Model_Attribute_Ids__c'});
        if(envAttributeMap != null) {
            if(envAttributeMap.get('Foundation_Code_Model_Attribute_Ids__c') != null) {
                modelAttributeIds = (String.valueOf(envAttributeMap.get('Foundation_Code_Model_Attribute_Ids__c'))).split(',');
            }
        }
        if(modelAttributeIds != null && !modelAttributeIds.isEmpty()){
            return modelAttributeIds;
        } else {
            createLog('','Foundation Code Model Attribute Ids are not defined in setting.', true);
        }
        return null;
    }

    public static void sendMail(String address, String subject, String body) {
        if (Test.isRunningTest()) {
            return;
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {address};
        mail.setOrgWideEmailAddressId(EmailUtility.getBRMEmailAddress());
        mail.setReplyTo(EmailUtility.getReplyToEmail());
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static void createLog(String id , String message , Boolean notifyViaEmail){
        if(notifyViaEmail){
            String userAddress = UserInfo.getUserEmail();
            String emailBody = 'Hi '+ UserInfo.getName();
            emailBody += '<br/> Failed to sync your recent "Foundation Code" changes in BGive.';
            emailBody += '<br/><br/> Error     : '+ message;
            emailBody += '<br/> Record Id : '+ id;
            emailBody += '<br/> Org       : <a href="' + Environment.getBaseUrl() + '">' + Environment.getEnvironment() + '</a>';
            emailBody += '<br/><br/>  Thanks,<br/> BRM System. ';
            sendMail(userAddress, 'Foundation Code Sync Failure', emailBody);
        }
        MB_Error__c log = new MB_Error__c();
        log.Description__c = message;
        log.Object_Id__c = id;
        log.Type__c = Assets.FC_ERROR_TYPE;
        insert as system log;
    }

    public static MB_Error__c createLog(String id , String message ){
        MB_Error__c log = new MB_Error__c();
        log.Description__c = message;
        log.Object_Id__c = id;
        log.Type__c = Assets.FC_ERROR_TYPE;
        return log;
    }

    public static void notifyUser(Map<Id, BBApps_ErrorCustomFields> errors){
        String userAddress = UserInfo.getUserEmail();
        String emailBody = 'Hi '+UserInfo.getName();
        emailBody += '<br/> Failed to sync your recent "Foundation Code" changes in BGive.';

            if(!errors.isEmpty()){
                for(Id id : errors.keySet()){
                    emailBody += '<br/> Record Id : '+ id;
                    emailBody += '<br/><br/> Error: '+ errors.get(id);
            }
        }
        emailBody += '<br/> Org       : <a href="'+Environment.getBaseUrl()+'">'+ Environment.getEnvironment() + '</a>';
        emailBody += '<br/><br/>  Thanks,<br/> BRM System. ';
        sendMail(userAddress, 'Foundation Code Sync Failure', emailBody);
    }

    public static Integer isCodeRetired(Foundation_Code__c code){
        return ((Assets.RETIRED).equalsIgnoreCase(code.Status__c) || (Assets.DELETED).equalsIgnoreCase(code.Status__c)) || !code.Enabled_for_Grants__c ? 1 : 0;
    }

    public static String getBGiveIdForCode(Foundation_Code__c code , String modelAttributeId){
        if(code == null || code.BGive_ID__c == null) { return null;}
        if(code.BGive_ID__c != null){
            Map<String,Object> bGiveIds = (Map<String,Object>) JSON.deserializeUntyped(code.BGive_ID__c);
            return String.valueOf(bGiveIds.get(modelAttributeId));
        }
        return null;
    }

    public static String getExtIdForCode(Foundation_Code__c code , String modelAttributeId){
        if(code == null || code.BGive_ID__c == null) { return null;}
        if(code.BGive_ID__c != null){
            Map<String,Object> bGiveIds = (Map<String,Object>) JSON.deserializeUntyped(code.BGive_ID__c);
            return String.valueOf(((Map<String,Object>)bGiveIds.get(modelAttributeId))?.get('ExternalId'));
        }
        return null;
    }

    public static List<FoundationCodeService.ModelAttributeValue> getAllBGiveCodes(Map<String,String> filters){
        if(!filters.isEmpty()){
            BGiveApiMav mav = new BGiveApiMav();
            mav.setNonEsFilters(filters);
            mav.setPageSize(1000);
            BGiveApi.BGiveAPIListResponse response = (BGiveApi.BGiveAPIListResponse)mav.get();
            if(response.records != null && response.records.size() > 0){
                return (List<FoundationCodeService.ModelAttributeValue>)JSON.deserialize(JSON.serialize(response.records) , List<FoundationCodeService.ModelAttributeValue>.class);
            }
        }
        return null;
    }
}