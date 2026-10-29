/*
Author     : Sai Bhargav Thotakura
Date       : 30th Dec 2024
Jira       : IM-52 : Final Approval Changes
Description: Controller class for Final Approval button on Budgeted Initiative record page.
Test Class : IMFinalApprovalControllerTest
*/
public with sharing class IMFinalApprovalController {
    
    public class IMFinalApprovalException extends Exception {
	}

	private static final String ERR_UPDATE_BUDGET_STATUS = 'UPDATE_BUDGET_STATUS_FAILED';
    
    /**
    * Description : Used to return Budget Amount and Budget Term Months for IM Final Approval Lightning record edit form
    * Parameters  : Accepts String - budgetId
    * Return Type : List<IM_Budget__c>
    */
    @AuraEnabled
    public static List<IM_Budget__c> getBudgetData(String budgetId){
        return [SELECT Id,Budget_Amount__c,Budget_Term_months__c 
        FROM IM_Budget__c 
        WHERE Id=:budgetId
        WITH SYSTEM_MODE];
    }

    /**
    * Description : Used to return Team Record,Focus Area Id based on the Team value on Lightning record edit form
    * Parameters  : Accepts String - TeamId
    * Return Type : List<Team__c>
    */
    @AuraEnabled
    public static List<Team__c> getTeamFocusArea(String teamId){
        return [SELECT Id,Bgive_Id__c,Focus_Area__c 
        FROM Team__c 
        WHERE Id=:teamId
        WITH SYSTEM_MODE];
    }

    /**
    * Description : Returns Budget records with pending approval status based on initiative.
    * Parameters  : String initiativeId
    * Return Type : List<IM_Budget__c>
    */
    @AuraEnabled
    public static List<IM_Budget__c> getPendingApprovalBudgets(String initiativeId) {
        return [SELECT Id, Name, Status__c FROM IM_Budget__c WHERE Initiative__c = :initiativeId
            AND Status__c = 'Pending Approval'
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