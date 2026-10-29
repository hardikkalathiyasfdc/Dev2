/**
* Author            : Paddy
* Date              : 04/14/2025
* Jira              : IM-148
* Description       : This class is used by IM_BudgetGrant Trigger.
* Test              : IMBudgetGrantTriggerHandlerTest
* ChangeLog         :
* Gauri Sagane on 05/07/2025 - IM-185 - Added logic to delete related budget rows and grant periods
* Paddy on 06/25/2025 - IM-244 - Added logic to set IsActive based on respective Budget IsActive on insert.
* Paddy on 06/15/2026 - IM-442 - Added logic for error logging framework
*/
public with sharing class IMBudgetGrantTriggerHandler extends TriggerHandler {

    public List<IM_Budget_Grant__c> newBudgetGrants;
    public List<IM_Budget_Grant__c> oldBudgetGrants;
    public Map<Id, IM_Budget_Grant__c> oldMap;
    public Map<Id, IM_Budget_Grant__c> newMap;

    private static List<IM_Budget_Row__c> budgetRows = new List<IM_Budget_Row__c>();
    private static List<IM_Budget_Grant_Period__c> budgetGrantPeriods = new List<IM_Budget_Grant_Period__c>();

	private static final String ERR_DELETE_BUDGET_ROWS = 'BUDGET_GRANT_TRIGGER_BUDGET_ROW_DELETE_FAILED';
    private static final String ERR_DELETE_BUDGET_GRANT_PERIODS = 'BUDGET_GRANT_TRIGGER_BUDGET_GRANT_PERIOD_DELETE_FAILED';
    public IMBudgetGrantTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, IM_Budget_Grant__c>) Trigger.oldMap, (Map<Id, IM_Budget_Grant__c>) Trigger.newMap);
    }

    public IMBudgetGrantTriggerHandler(List<IM_Budget_Grant__c> oldBudgetGrantList, List<IM_Budget_Grant__c> newBudgetGrantList) {
        newBudgetGrants = newBudgetGrantList;
        oldBudgetGrants = oldBudgetGrantList;
    }

    public IMBudgetGrantTriggerHandler(List<IM_Budget_Grant__c> oldBudgetGrantList, List<IM_Budget_Grant__c> newBudgetGrantList , Map<Id, IM_Budget_Grant__c> oldMap , Map<Id, IM_Budget_Grant__c> newMap) {
        newBudgetGrants = newBudgetGrantList;
        oldBudgetGrants = oldBudgetGrantList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void bulkBefore() {

        if (Trigger.isInsert) {
            setActives(newBudgetGrants);
        }
        if(Trigger.isDelete){
            getBudgetRowsToDelete(oldMap.keySet());
            getBudgetGrantPeriodsToDelete(oldMap.keySet());
        }
    }

    public override void andFinally() {
    	if(Trigger.isDelete) {
            if(!budgetRows.isEmpty()){
                BBApps_Crud.doDeleteWithHandling(budgetRows, false, 
                    new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_ROWS));
            }
            if(!budgetGrantPeriods.isEmpty()){
                BBApps_Crud.doDeleteWithHandling(budgetGrantPeriods, false, 
                    new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_GRANT_PERIODS));
            }
        }
    }

    /**
    * Description : Method to get related Budget Rows
    * Parameters : budgetGrantIds Set<Id>
    * Return Type : void
    */
    private void getBudgetRowsToDelete(Set<Id> budgetGrantIds){
        budgetRows = [SELECT Id FROM IM_Budget_Row__c WHERE Budget_Grant__c IN :budgetGrantIds WITH SYSTEM_MODE];
    }

    /**
    * Description : Method to get related Budget Grant Periods
    * Parameters : budgetGrantIds Set<Id>
    * Return Type : void
    */
    private void getBudgetGrantPeriodsToDelete(Set<Id> budgetGrantIds){
        budgetGrantPeriods = [SELECT Id FROM IM_Budget_Grant_Period__c WHERE Budget_Grant__c IN :budgetGrantIds WITH SYSTEM_MODE];
    }

    /**













































































	 * Description : IM-244 Set Is Active Flag on Budget Grant based on related Budget Active flag
	 * Parameters  : List<IM_Budget_Grant__c> budgetGrants
	 * Return Type : void
	 */
	private static void setActives(List<IM_Budget_Grant__c> budgetGrants) {
		Set<Id> budgetIds = new Set<Id>();
		if (budgetGrants != null && !budgetGrants.isEmpty()) {
			for (IM_Budget_Grant__c budgetGrant : budgetGrants) {
                if(budgetGrant.Budget__c != null)
				    budgetIds.add(budgetGrant.Budget__c);
			}
		}
		if (!budgetIds.isEmpty()) {
			Map<Id, IM_Budget__c> budgets = new Map<Id, IM_Budget__c>([SELECT Is_Active__c FROM IM_Budget__c WHERE Id IN :budgetIds WITH SYSTEM_MODE]);
			for (IM_Budget_Grant__c budgetGrant : budgetGrants) {
				if (budgets.containsKey(budgetGrant.Budget__c)) {
					budgetGrant.Is_Active__c = budgets.get(budgetGrant.Budget__c).Is_Active__c;
				}
			}
		}
    }
}