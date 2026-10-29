/*
Author     : Gauri Sagane
Date       : 10/26/2026
Jira       : BRME-7044
Description: Controller class for Approve button on Initiative record page.
Test Class : IMApproveInitiativeControllerTest
*/
public with sharing class IMApproveInitiativeController {

    public class IMFinalApprovalException extends Exception {
	}

    private static final String ERR_UPDATE_INITIATIVE_STATUS = 'UPDATE_INITIATIVE_STATUS_FAILED';
    private static final String ERR_UPDATE_BUDGET_STATUS = 'UPDATE_BUDGET_STATUS_FAILED';

    /**
    * Description : Method to get the Current Budget on Initiative
    * Parameters  : String budgetId
    * Return Type : IM_Budget__c
    */
    @AuraEnabled
    public static IM_Initiative__c getInitiative(String initiativeId){
        return [SELECT Id, Status__c, Approved__c, Approved_Date__c, Approver__c, Original_Approved_Date__c, Initiative_Type__c, Term_Alignment__c, Required_Approval_Docs__c 
            FROM IM_Initiative__c 
            WHERE Id=:initiativeId
            WITH SYSTEM_MODE];
    }

    /**
    * Description : Method to get the Current Budget on Initiative
    * Parameters  : String budgetId
    * Return Type : IM_Budget__c
    */
    @AuraEnabled
    public static void updateInitiative(IM_Initiative__c initiative){
        System.debug('ini: '+initiative);
        BBApps_DMLResult result = BBApps_Crud.doUpdate(
			initiative,
            true
		);
        if(!result.isSuccess()){
            BBApps_ErrorHandler.logErrors(initiative.Id, new IMFinalApprovalException('Error in updating Initiative Status to Approved'), new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET_STATUS));
            throw new AuraHandledException('Error in updating Initiative Status to Approved');
        }
    }

    /**
    * Description : Method to get the Current Budget on Initiative
    * Parameters  : String budgetId
    * Return Type : IM_Budget__c
    */
    @AuraEnabled
    public static List<IM_Budget__c> getBudgetData(String budgetId){
        return [SELECT Id 
            FROM IM_Budget__c 
            WHERE Id=:budgetId
            WITH SYSTEM_MODE];
    }

    /**
    * Description : Updates Budget records with status as Approved.
    * Parameters  : String budgetId
    * Return Type : void
    */
    @AuraEnabled
    public static void updateBudgetStatus(String budgetId) {
        IM_Budget__c budget = new IM_Budget__c( Id = budgetId, Status__c = 'Approved');
        BBApps_DMLResult result = BBApps_Crud.doUpdate(
			budget,
            true
		);
        if(!result.isSuccess()){
            BBApps_ErrorHandler.logErrors((Id) budgetId, new IMFinalApprovalException('Error in updating Budget Status to Approved'), new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET_STATUS));
            throw new AuraHandledException('Error in updating Budget Status to Approved');
        }
    }
}