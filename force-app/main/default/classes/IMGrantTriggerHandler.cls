/**
 * Author      : Sai Bhargav T
 * Date        : 04/25/2025
 * Jira        : IM-168
 * Description : This class is Trigger handler class for IM_Grant__c.
 * Test        : Yet to be created
 * ChangeLog   :
 * Gauri Sagane on 05/07/2025 - IM-185 - Added logic to delete related budget grants's budget rows and grant periods
 * Paddy on 05/03/2026: IM-554 - Added logice to populate Include Foriend Currency and Total Not Appllication Amount.
 */
public with sharing class IMGrantTriggerHandler extends TriggerHandler {
	public List<IM_Grant__c> newGrants;
	public List<IM_Grant__c> oldGrants;
	public Map<Id, IM_Grant__c> oldMap;
	public Map<Id, IM_Grant__c> newMap;

	private static List<IM_Budget_Row__c> budgetRows = new List<IM_Budget_Row__c>();
	private static List<IM_Budget_Grant_Period__c> budgetGrantPeriods = new List<IM_Budget_Grant_Period__c>();

	private Set<Id> currencyChangeGrantIds = new Set<Id>();
	private Set<Id> bgiveConnectionChangeGrantIds = new Set<Id>();

	private static final String USD = 'USD';

	private static final String ERR_DELETE_BUDGET_ROWS = 'DELETE_BUDGET_ROWS_FAILED';
	private static final String ERR_DELETE_BUDGET_GRANT_PERIODS = 'DELETE_BUDGET_GRANT_PERIODS_FAILED';

	public IMGrantTriggerHandler() {
		this(
			Trigger.old,
			Trigger.new,
			(Map<Id, IM_Grant__c>) Trigger.oldMap,
			(Map<Id, IM_Grant__c>) Trigger.newMap
		);
	}

	public IMGrantTriggerHandler(
		List<IM_Grant__c> oldGrantList,
		List<IM_Grant__c> newGrantList
	) {
		newGrants = newGrantList;
		oldGrants = oldGrantList;
	}

	public IMGrantTriggerHandler(
		List<IM_Grant__c> oldGrantList,
		List<IM_Grant__c> newGrantList,
		Map<Id, IM_Grant__c> oldMap,
		Map<Id, IM_Grant__c> newMap
	) {
		newGrants = newGrantList;
		oldGrants = oldGrantList;
		this.oldMap = oldMap;
		this.newMap = newMap;
	}

	public override void bulkBefore() {
		if (Trigger.isDelete) {
            getBudgetRowsToDelete(oldMap.keySet());
            getBudgetGrantPeriodsToDelete(oldMap.keySet());
		}
	}

	public override void bulkAfter() {
		if (Trigger.isAfter) {
			if (!newGrants.isEmpty() && newGrants != null) {
				FieldHistoryService.track(Trigger.oldMap, Trigger.newMap);
			}
		}
	}

	public override void afterUpdate(SObject oldSo, SObject so) {
		IM_Grant__c oldGrant = (IM_Grant__c)oldSo;
		IM_Grant__c newGrant = (IM_Grant__c)so;
		if(isFieldChanged(newGrant, 'Currency__c')) {
			currencyChangeGrantIds.add(newGrant.Id);
		}
		if(isFieldChanged(newGrant, 'Bgive_IM_Connection__c') && (oldGrant.Bgive_IM_Connection__c == 'Not Applicable' || newGrant.Bgive_IM_Connection__c == 'Not Applicable')) {
			bgiveConnectionChangeGrantIds.add(newGrant.Id);
		}
	}

	public override void andFinally() {
		if (Trigger.isDelete) {
			if (!budgetRows.isEmpty()) {
				BBApps_Crud.doDeleteWithHandling(
					budgetRows,
					false,
					new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_ROWS)
				);

			}
			if (!budgetGrantPeriods.isEmpty()) {
				BBApps_Crud.doDeleteWithHandling(
					budgetGrantPeriods,
					false,
					new BBApps_ErrorCustomFields(ERR_DELETE_BUDGET_GRANT_PERIODS)
				);

			}
		}
		if(Trigger.isAfter && Trigger.isUpdate) {
			if(!currencyChangeGrantIds.isEmpty() || !bgiveConnectionChangeGrantIds.isEmpty()) {
				processInitiatives();
			}
		}
	}

	/**
	 * Description : Method to get related Budget Rows
	 * Parameters : imGrantIds Set<Id>
	 * Return Type : void
	 */
	private void getBudgetRowsToDelete(Set<Id> imGrantIds) {
		budgetRows = [
			SELECT Id
			FROM IM_Budget_Row__c
			WHERE Budget_Grant__r.IM_Grant__c IN :imGrantIds
			WITH SYSTEM_MODE
		];
	}

	/**
	 * Description : Method to get related Budget Grant Periods
	 * Parameters : imGrantIds Set<Id>
	 * Return Type : void
	 */
    private void getBudgetGrantPeriodsToDelete(Set<Id> imGrantIds) {
		budgetGrantPeriods = [
			SELECT Id
			FROM IM_Budget_Grant_Period__c
			WHERE Budget_Grant__r.IM_Grant__c IN :imGrantIds
			WITH SYSTEM_MODE
		];
	}


	private void processInitiatives() {
		Set<Id> budgetIds = new Set<Id>();
		Set<Id> imGrantIds = new Set<Id>(currencyChangeGrantIds);
		imGrantIds.addAll(bgiveConnectionChangeGrantIds);
		
		for (IM_Budget_Grant__c bg : [
				SELECT Budget__c  
				FROM IM_Budget_Grant__c
				WHERE IM_Grant__c IN :imGrantIds AND Budget__r.Initiative__c != NULL
				WITH SYSTEM_MODE
		]) {
			budgetIds.add(bg.Budget__c);
		}
		Map<Id, IM_Budget__c> budgetsToUpdate = new Map<Id, IM_Budget__c>();
		if(!budgetIds.isEmpty()) {
			for (AggregateResult ar : [
				SELECT COUNT(IM_Grant__r.Currency__c) nonUSDCount, Budget__c from IM_Budget_Grant__c 
				WHERE budget__c IN :budgetIds AND IM_Grant__r.Currency__r.name != :USD 
				WITH SYSTEM_MODE
				GROUP BY budget__c
			]) {
				Integer nonUSDCount = (Integer)ar.get('nonUSDCount');
				String budgetId = (String)ar.get('Budget__c');
				Boolean includeForeignCurrency = nonUSDCount > 0;
				budgetsToUpdate.put(budgetId, new IM_Budget__c(Id = budgetId, Include_Foreign_Currency__c = includeForeignCurrency));
			}
			Set<Id> grantAmountBudgetIds = new Set<Id>();
			for (AggregateResult ar : [
				SELECT SUM(Budget_Amount_USD__c) grantAmount, Budget__c from IM_Budget_Grant__c 
				WHERE budget__c IN :budgetIds AND IM_Grant__r.Bgive_IM_Connection__c = 'Not Applicable' 
				WITH SYSTEM_MODE
				GROUP BY budget__c
			]) {
				Decimal grantAmount = (Decimal)ar.get('grantAmount');
				String budgetId = (String)ar.get('Budget__c');
				grantAmountBudgetIds.add(budgetId);
				IM_Budget__c budget = budgetsToUpdate.containsKey(budgetId) 
					? budgetsToUpdate.get(budgetId)
					: new IM_Budget__c(Id = budgetId);
					budget.Total_Not_Applicable_Amount__c = grantAmount;
					budgetsToUpdate.put(budgetId, budget);
			}
			budgetIds.removeAll(grantAmountBudgetIds);
			if(!budgetIds.isEmpty()) {
				for(Id budgetId : budgetIds) {
					IM_Budget__c budget = budgetsToUpdate.containsKey(budgetId) 
					? budgetsToUpdate.get(budgetId)
					: new IM_Budget__c(Id = budgetId);
					budget.Total_Not_Applicable_Amount__c = null;
					budgetsToUpdate.put(budgetId, budget);
				}
			}
		}
		BBApps_Crud.doUpdate(
			budgetsToUpdate.values()
		);
	}
}