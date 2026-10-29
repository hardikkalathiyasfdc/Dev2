/**
 * Author      : Paddy
 * Date        : 12/31/2024
 * Jira        : IM-84
 * Description : This class provides methods needed for Clone Budget LWC component.
 * Test        : IMCloneBudgetControllerTest
 * ChangeLog   :
 * Paddy - 01/26/2026: IM-491: Added budgetname to the cloneBudget method signature.
 */
public with sharing class IMCloneBudgetController {

	private static final String ERR_CLONE_BUDGET = 'CLONE_BUDGET_CONTROLLER_CLONE_BUDGET_FAILED';
    private static final String ERR_GET_TEAM_VALUE = 'CLONE_BUDGET_CONTROLLER_GET_TEAM_VALUE_FAILED';

	@AuraEnabled
	public static String cloneBudget(String budgetId, String initiativeId, String newBudgetName) {
		try {
			IM_Budget__c clonedBudget = IMClone.cloneBudget(budgetId, initiativeId, newBudgetName);
			return clonedBudget.Id;
		} catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CLONE_BUDGET));
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static string getTeamValue(String budgetId) {
		try {
			return [SELECT Id, Initiative__r.Team__c FROM IM_Budget__c WHERE Id = :budgetId WITH USER_MODE]?.Initiative__r.Team__c;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_TEAM_VALUE));
			throw new AuraHandledException(e.getMessage());
		}
	}
}