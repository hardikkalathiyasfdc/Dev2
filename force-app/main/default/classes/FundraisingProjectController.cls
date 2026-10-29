public without sharing class FundraisingProjectController {

    private static final String ERR_GET_SINGLE_ACTIVITY = 'FUNDRAISING_PROJECT_GET_SINGLE_ACTIVITY_FAILED';
    private static final String ERR_GET_CHILD_RECORDS = 'FUNDRAISING_PROJECT_GET_CHILD_RECORDS_FAILED';
    private static final String ERR_CREATE_CHILD_RECORDS = 'FUNDRAISING_PROJECT_CREATE_CHILD_RECORDS_FAILED';
    private static final String ERR_VALIDATE_DELETE_ORG = 'FUNDRAISING_PROJECT_VALIDATE_DELETE_ORG_FAILED';
    private static final String ERR_CREATE_APPEAL_RECORD = 'FUNDRAISING_PROJECT_CREATE_APPEAL_RECORD_FAILED';
    private static final String ERR_DUPLICATE_FUND = 'FUNDRAISING_PROJECT_DUPLICATE_FUND_FAILED';
    private static final String ERR_CHECK_FUNDRAISING_ACCESS = 'FUNDRAISING_PROJECT_CHECK_ACCESS_FAILED';
    
    private static final String MSG_GET_SINGLE_ACTIVITY = 'Unable to fetch activity.';
    private static final String MSG_GET_CHILD_RECORDS = 'Unable to fetch child records.';
    private static final String MSG_CREATE_CHILD_RECORDS = 'Unable to create child records.';
    private static final String MSG_VALIDATE_DELETE_ORG = 'Unable to validate and delete organization.';
    private static final String MSG_CREATE_APPEAL_RECORD = 'Unable to create appeal record.';
    private static final String MSG_DUPLICATE_FUND = 'Unable to check for duplicate fund.';
    private static final String MSG_CHECK_FUNDRAISING_ACCESS = 'Unable to check fundraising coding access.';

    @AuraEnabled(cacheable=true)
    public static Fundraising_Activity__c getSingleActivity(){
        try {
            return [SELECT Id, Name, Type__c, BP_Event_Id__c, Date__c, Fundraising_Effort_Id__c FROM Fundraising_Activity__c LIMIT 1];
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_SINGLE_ACTIVITY);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_SINGLE_ACTIVITY);
        }
    }
    @AuraEnabled(cacheable=false)
    public static FundraisingChildClass getchildrecords(Id recordId){
        try {
            List<Recipient_Organization__c> orgrecipients  = new List<Recipient_Organization__c>();
        for(Recipient_Organization__c rec : [Select Id,Fundraising_Project__c, Organization__c,Recipient_Soft_Credit__c,Recipient_Soft_Credit__r.Name,Recipient_Soft_Credit__r.Restricted__c,Organization__r.Search_Display_Name__c,
                                             Recipient_Soft_Credit__r.Restricted_Name__c,Number_of_pledges__c,Total_pledge_amounts__c,Name,Organization__r.Name,Organization__r.Restricted__c,Organization__r.Restricted_Org_Name__c  
                                                 from Recipient_Organization__c  
                                                 WHERE Fundraising_Project__c =: recordId ORDER BY createddate DESC]){
                                                     rec.Number_of_pledges__c = rec.Number_of_pledges__c > 0 ? rec.Number_of_pledges__c : 0; 
                                                     rec.Total_pledge_amounts__c = rec.Total_pledge_amounts__c > 0 ? rec.Total_pledge_amounts__c : 0;  
                                                     orgrecipients.add(rec);           
                                                 }
            
            FundraisingChildClass pcClass = new FundraisingChildClass();
            pcClass.recipients = orgrecipients.isEmpty() ? new List<Recipient_Organization__c>() : orgrecipients;
            return pcClass;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_CHILD_RECORDS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_CHILD_RECORDS);
        }
    }
    public class FundraisingChildClass{
        @AuraEnabled public List<Recipient_Organization__c> recipients {get;set;} 
    }
    @AuraEnabled(Cacheable=false)
    public static String createchildrecords(List<sObject> rec){
        String msg;
        try {
            BBApps_Crud.doUpsertWithHandling(rec, false, MSG_CREATE_CHILD_RECORDS);
            return msg;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CREATE_CHILD_RECORDS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_CREATE_CHILD_RECORDS);
        }
    }
    @AuraEnabled(Cacheable=false)
    public static boolean validateanddeleteOrg(String recordid){
            boolean isremovedorg = false;
            system.debug('recordid>>>'+recordid);
            if(recordid == null || recordid=='undefined'){
                isremovedorg = true;
            }
            List<Recipient_Organization__c> lstorg = [Select id,Organization__c,Composite_Key__c FROM Recipient_Organization__c WHERE Id=:recordid];
            system.debug('lstorg>>>'+lstorg);
            if(!lstorg.isEmpty()){
                List<Pledge__c> lstpledge = new List<Pledge__c>();
                lstpledge = [Select id FROM Pledge__c WHERE CompositeKey__c =: lstorg[0].Composite_Key__c];
                system.debug('lstpledge>>>'+lstpledge);
                if(lstpledge.isEmpty()){
                    BBApps_Crud.doDeleteWithHandling(lstorg, false, ERR_VALIDATE_DELETE_ORG);
                    isremovedorg = true;
                }
            }
            return isremovedorg;
    }
    
    @AuraEnabled(Cacheable=false)
    public static String createAppealrecod(sObject rec){
        try {
            BBApps_Crud.doInsertWithHandling(rec, false, ERR_CREATE_APPEAL_RECORD);
            return rec.id;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CREATE_APPEAL_RECORD);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_CREATE_APPEAL_RECORD);
        }
    }
     @AuraEnabled(Cacheable=false)
    public static Boolean duplicateFundd(String recChar){
        try {
            Boolean isduplicate = false;
            List<Fundraising_Project__c> lstorg = [Select Name FROM Fundraising_Project__c WHERE Name=:recChar];
            if(lstorg.size() > 0){
                isduplicate = true;
            }
            return isduplicate;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_DUPLICATE_FUND);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_DUPLICATE_FUND);
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkFundraisingCodingAccess() {
        return UtilityClass.checkIfUserHasAssignedPermissionSet(UserInfo.getUserId(), 'Fundraising_Coding_Access');
    }
}