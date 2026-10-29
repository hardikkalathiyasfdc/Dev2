/**
* Author      : Neha
* Date        : 05/02/2024
* Jira        : BRME-5259
* Description : This class is used on manageFoundationCode LWC.
* Modified By : Paddy - BRME-5260 : Change code to add parent level fields on SOQL.
* Test        : ManageFoundationCodesCntrlTest
*/
public with sharing class ManageFoundationCodesCntrl {
    /*
    Used to retrieve all FoundationCode records.
    */
    @AuraEnabled(cacheable = true)
    public static List<Foundation_Code__c> getFoundationCodes(){
        try {
            return [SELECT Id , Name , Parent__c ,Foundation_Code__c, Status__c,BGive_Description__c,
                    Parent__r.Parent__c, Parent__r.Parent__r.Parent__c,
                    Parent__r.Parent__r.Parent__r.Parent__c,
                    Parent__r.Parent__r.Parent__r.Parent__r.Parent__c,
                    Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c,
                    Sync_Warning__c,Sync_Error__c
                    FROM Foundation_Code__c 
                    WITH USER_MODE
                    ORDER BY Parent__c, Sort_Order__c, Foundation_Code__c];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /*
     Used to sync a particular code from UI
    */
    @AuraEnabled
    public static void syncCode(Id recordId){
        try {
           List<Id> codeIds = new List<Id>{recordId};
           if(!codeIds.isEmpty()){
                System.debug(' codeIds'+codeIds);
                Database.executeBatch(new BatchFoundationCodeSync(codeIds), 1);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
     Used to sync all codes from UI
    */
    @AuraEnabled
    public static void syncAll(){
        try {
            Id batchJobId = Database.executeBatch(new BatchFoundationCodeSync(null), 20);

            Foundation_Code__c initiativeCode = [SELECT Id , Last_Sync_All_Job_Id__c 
                                                    FROM Foundation_Code__c
                                                    WHERE Foundation_Code__c = :Assets.INITIATIVES 
                                                    WITH SYSTEM_MODE 
                                                    LIMIT 1];
            initiativeCode.Last_Sync_All_Job_Id__c = batchJobId;

            TriggerFactory.setBypass('FoundationCodeHandler');
            update as system initiativeCode;
            TriggerFactory.removeBypass('FoundationCodeHandler');

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Object syncLastSyncJobStatus(){
        try {
            Foundation_Code__c initiativeCode = [SELECT Id , Last_Sync_All_Job_Id__c 
                                                    FROM Foundation_Code__c
                                                    WHERE Foundation_Code__c = :Assets.INITIATIVES 
                                                    WITH SYSTEM_MODE 
                                                    LIMIT 1];
            String batchJobId = initiativeCode.Last_Sync_All_Job_Id__c;

            if(!String.isEmpty(batchJobId)){
                List<AsyncApexJob> asyncJobs = [SELECT Id, CompletedDate ,Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                                                    FROM AsyncApexJob 
                                                    WHERE Id =:batchJobId 
                                                    WITH SYSTEM_MODE];
                return asyncJobs != null && asyncJobs.size() > 0 ? asyncJobs[0] : null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return null;
    }
}