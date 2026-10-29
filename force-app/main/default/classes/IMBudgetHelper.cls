/**
 * Author      : Paddy
 * Date        : 04/21/2025
 * Jira        : IM-154
 * Description : This class provides helper methods needed for IM_Budget.
 * ChangeLog   :
 * Paddy 	   : 06/15/2026: IM-442: Added logic for error logging framework
 * Test        : IMBudgetHelperTest
 */
public with sharing class IMBudgetHelper {

	private static final String ERR_BUDGET_HELPER = 'BUDGET_HELPER_UPDATEACTIVESTATUS_FAILED';
    
	/**
	 * Description : Method to setup Budget and Budget Grants Active status.
	 * Parameters  : Set<Id> oldCurrentBudgetIds, Set<Id> currentBudgetIds
	 * Return Type : void
	 */
	public static void updateActiveStatus(Set<Id> oldCurrentBudgetIds, Set<Id> currentBudgetIds) {
		try {
			Set<Id> activeBudgetIdSet = new Set<Id>();
			List<IM_Budget__c> activeBudgets = new List<IM_Budget__c>();
			List<IM_Budget__c> inactiveBudgets = new List<IM_Budget__c>();
			List<IM_Budget_Grant__c> budgetsGrantsToUpdate = new List<IM_Budget_Grant__c>();
			Set<Id> budgetIds = new Set<Id>(oldCurrentBudgetIds);
			budgetIds.addAll(currentBudgetIds);

			List<IM_Budget_Grant__c> budgetGrants = [SELECT Budget__c, Is_Active__c FROM IM_Budget_Grant__c 
														WHERE Budget__c IN :budgetIds WITH SYSTEM_MODE];

			//Budgets
			for (Id budgetId : budgetIds) {
				if (oldCurrentBudgetIds.contains(budgetId)) {
					inactiveBudgets.add(new IM_Budget__c(Id = budgetId, Is_Active__c = false, Disable_Budget_Options__c = ''));
				} else {
					activeBudgetIdSet.add(budgetId);
				}
			}

			//Budget Grants
			for (IM_Budget_Grant__c budgetGrant : budgetGrants) {
				if (oldCurrentBudgetIds.contains(budgetGrant.Budget__c) && budgetGrant.Is_Active__c) {
					budgetGrant.Is_Active__c = false;
					budgetsGrantsToUpdate.add(budgetGrant);
				} else if (currentBudgetIds.contains(budgetGrant.Budget__c) && !budgetGrant.Is_Active__c) {
					budgetGrant.Is_Active__c = true;
					budgetsGrantsToUpdate.add(budgetGrant);
				}
			}

			//IM-364: For Active Budgets update the Disable_Budget_Options__c field
			//Ignore budget categories, it can be updated at any time and is never locked
			for (IM_Budget__c budgetRec : IMUtil.getActiveBudgets(activeBudgetIdSet)) {
				budgetRec.Disable_Budget_Options__c += budgetRec.Partner_Fund__c == true ? 'Partner_Fund__c,' : '';
				budgetRec.Disable_Budget_Options__c += budgetRec.SubPartner_SubPartner_Type__c == true ? 'SubPartner_SubPartner_Type__c,' : '';
				budgetRec.Disable_Budget_Options__c += budgetRec.Partner_Partner_Role__c == true ? 'Partner_Partner_Role__c,' : '';
				budgetRec.Disable_Budget_Options__c += budgetRec.Run_Rate__c == true ? 'Run_Rate__c,' : '';
				budgetRec.Disable_Budget_Options__c += budgetRec.Duration_months__c == true ? 'Duration_months__c,' : '';
				budgetRec.Disable_Budget_Options__c += budgetRec.Type_of_Work__c == true ? 'Type_of_Work__c,' : '';
				budgetRec.Disable_Budget_Options__c += budgetRec.Payee_Fiscal_Sponsor__c == true ? 'Payee_Fiscal_Sponsor__c,' : '';
				budgetRec.Disable_Budget_Options__c += budgetRec.Duration_Run_Rate__c == true ? 'Duration_Run_Rate__c,' : '';
				budgetRec.Disable_Budget_Options__c += budgetRec.Unique_Identifier__c == true ? 'Unique_Identifier__c' : '';
				budgetRec.Disable_Budget_Options__c = (String.valueOf(budgetRec.Disable_Budget_Options__c).removeStart('null')).removeEnd(',');
				budgetRec.Is_Active__c = true;
				activeBudgets.add(budgetRec);
			}
			activeBudgetIdSet.clear();
			BBApps_Crud.doUpdate(activeBudgets);
			BBApps_Crud.doUpdate(inactiveBudgets);
			BBApps_Crud.doUpdateWithHandling(budgetsGrantsToUpdate);
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BUDGET_HELPER));
            System.debug ('ex.getMessage() :::::::::: '+ex.getMessage());
			throw new AuraHandledException(ex.getMessage());
		}




	}
}