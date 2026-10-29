/**
* Author      : Paddy
* Date        : 12/03/2024
* Jira        : IM-65
* Description : This class is Trigger handler class for IM_Budget__c.
* Modified By : Gauri - To prevent creating budget periods for cloned records - 12/16/2024
                Gauri - To prevent deleting budget if checked out - 03/14/2025
                Paddy - IM-199: Validation for Over/Under Allocations
				Sai - IM -403: Added checkForTermReducedBudgets in bulkAfter to recompute period amounts if the term is reduced.
				Gauri - IM-530: Added logic to check if there are multiple budgets in pending approval status for the same initiative.
				Paddy - IM-532: Added logic to prevent deletion.
				Gauri - IM-590: Added logic to send email notification when Budget is set to Pending Approval
* Test        : IMBudgetTriggerHandlerTest
*/
public with sharing class IMBudgetTriggerHandler extends TriggerHandler {

	public List<IM_Budget__c> newBudgets;
	public List<IM_Budget__c> oldBudgets;
	public Map<Id, IM_Budget__c> oldMap;
	public Map<Id, IM_Budget__c> newMap;
	public List<IM_Budget_Period__c> budgetPeriods = new List<IM_Budget_Period__c>();
	public List<IM_Budget_Period__c> deleteBudgetPeriods = new List<IM_Budget_Period__c>();
	public List<IM_Budget_Row__c> budgetRowsToUpdate = new List<IM_Budget_Row__c>();
	public List<IM_Budget_Row__c> lockBudgetRows = new List<IM_Budget_Row__c>();
	public Map<Id, List<IM_Budget_Period__c>> budgetToPeriodsMap = new Map<Id, List<IM_Budget_Period__c>>();
	Map<Id, IM_Initiative__c> initiativeMap = new Map<Id, IM_Initiative__c>();
	Map<Id, Id> budgetToInitiativeMap = new Map<Id, Id>();
	public Set<Id> pendingApprovalIds = new Set<Id>();
	public Map<Id, Decimal> termReducedBudgetsIdMap = new Map<Id, Decimal>();
	public Map<Id, Id> approvedBudgetInitiativeMap = new Map<Id, Id>();
	Set<Id> initiativeIds = new Set<Id>();
	//BRME-7040: Budget Id -> Initiative Id for budgets entering Pending Approval (to be set as the Initiative's Current Budget)
	public Map<Id, Id> budgetToSetAsCurrentMap = new Map<Id, Id>();
	//BRME-7040: Budget Id -> Initiative Id for budgets leaving Pending Approval to Draft/blank/Declined (to clear the Initiative's Current Budget)
	public Map<Id, Id> budgetToClearAsCurrentMap = new Map<Id, Id>();

	private static final String ALLOCATION_ERROR_MESSAGE = 'Amount cannot be over or under allocated for any partner funds in the budget.';
	private static final String PENDING_APPROVAL_ERROR_MESSAGE = 'Only one budget can be in pending approval status for an initiative. Please modify the status of the other budget under this initiative.';
	private static final String DELETE_ERROR_MESSAGE = 'You do not have sufficient permissions to delete this record.';
	private static final String ERR_UPDATE_BUDGET_CHECKBOXES = 'BUDGET_CHECKBOXES_UPDATE_FAILED';
	private static final String ERR_BUDGET_TERM_CHECK = 'BUDGET_TERM_CHECK_FAILED';
	private static final String ERR_GET_AMENDMENT_NUMBER = 'GET_AMENDMENT_NUMBER_FAILED';
	private static final String ERR_UPDATE_BUDGET_ROWS = 'UPDATE_BUDGET_ROWS_FAILED';

	public IMBudgetTriggerHandler() {
		this(Trigger.old, Trigger.new, (Map<Id, IM_Budget__c>) Trigger.oldMap, (Map<Id, IM_Budget__c>) Trigger.newMap);
	}

	public IMBudgetTriggerHandler(List<IM_Budget__c> oldBudgetList, List<IM_Budget__c> newBudgetList) {
		newBudgets = newBudgetList;
		oldBudgets = oldBudgetList;
	}

	public IMBudgetTriggerHandler(
		List<IM_Budget__c> oldBudgetList,
		List<IM_Budget__c> newBudgetList,
		Map<Id, IM_Budget__c> oldMap,
		Map<Id, IM_Budget__c> newMap
	) {
		newBudgets = newBudgetList;
		oldBudgets = oldBudgetList;
		this.oldMap = oldMap;
		this.newMap = newMap;
	}

	public override void beforeInsert(SObject so) {
		IM_Budget__c newBudget = (IM_Budget__c) so;
		updateCheckboxes(newBudget);
	}

	public override void afterInsert(SObject so) {
		IM_Budget__c budget = (IM_Budget__c) so;
		if (budget.isClone() == false && budget.Budget_Term_Years__c > 0) {
			createBudgetPeriods(budget.Budget_Term_Years__c, 0, budget.Id);
		}
		//BRME-7040: Set this budget as the Initiative's Current Budget when inserted directly as Pending Approval
		if (Assets.PENDING_APPROVAL.equalsIgnoreCase(budget.Status__c)) {
			budgetToSetAsCurrentMap.put(budget.Id, budget.Initiative__c);
		}
	}

	public override void afterUpdate(SObject oldSo, SObject so) {
		IM_Budget__c newBudget = (IM_Budget__c) so;
		IM_Budget__c oldBudget = (IM_Budget__c) oldSo;
		processBudgetPeriods(newBudget, oldBudget);
		if(isFieldChanged(newBudget, Assets.STATUS) && Assets.APPROVED.equalsIgnoreCase(newBudget.Status__c)) {
			lockBudgetRows();
		}
		if(isFieldChanged(newBudget, Assets.STATUS) && Assets.PENDING_APPROVAL.equalsIgnoreCase(newBudget.Status__c)) {
			//BRME-7040: Set this budget as the Initiative's Current Budget
			budgetToSetAsCurrentMap.put(newBudget.Id, newBudget.Initiative__c);
		}
		//BRME-7040: Clear Current Budget when Status changes from Pending Approval.
		if (isFieldChanged(newBudget, Assets.STATUS) && Assets.PENDING_APPROVAL.equalsIgnoreCase(oldBudget.Status__c)) {
			budgetToClearAsCurrentMap.put(newBudget.Id, newBudget.Initiative__c);
		}
	}

	public override void beforeUpdate(SObject oldSo, SObject so) {
		IM_Budget__c newBudget = (IM_Budget__c) so;
		IM_Budget__c oldBudget = (IM_Budget__c) oldSo;
		if (
			isFieldChanged(newBudget, 'Partner_Partner_Role__c') ||
			isFieldChanged(newBudget, 'Duration_Run_Rate__c') ||
			isFieldChanged(newBudget, 'Budget_Categories__c') ||
			isFieldChanged(newBudget, 'SubPartner_SubPartner_Type__c')
		) {
			updateCheckboxes(newBudget);
		}

		if (isFieldChanged(newBudget, Assets.STATUS)) {
			if(Assets.PENDING_APPROVAL.equalsIgnoreCase(newBudget.Status__c)) {
				pendingApprovalIds.add(newBudget.Id);
				initiativeIds.add(newBudget.Initiative__c);
			} else if (Assets.APPROVED.equalsIgnoreCase(newBudget.Status__c)) {
				newBudget.Total_Budget_Amount__c = newBudget.Budget_Amount__c;
			}
		}
		if(Assets.APPROVED.equalsIgnoreCase(newBudget.Status__c)) {
			approvedBudgetInitiativeMap.put(newBudget.Id, newBudget.Initiative__c);
	}
	}

	public override void beforeDelete(SObject so) {
		IM_Budget__c budget = (IM_Budget__c) so;
		if (budget.Checked_Out_By__c != null) {
			budget.addError('Checked out budget cannot be deleted.');
		}
	}

	public override void bulkBefore() {
		if (Trigger.isInsert) {
			hardMatchBudgetName();
		}
		if (Trigger.isUpdate) {
			setBudgetVersion();
		}
		if(Trigger.isDelete) {
			checkForDeletion();
		}
	}

	public override void bulkAfter() {
		if (Trigger.isUpdate) {
			setBudgetPeriodMap();
			//IM-403: Clear Yearly Amounts on Budget Term Reduction
			checkForTermReducedBudgets();
		}
	}

	public override void andFinally() {
		if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
			BBApps_Crud.doInsert(
				budgetPeriods,
				false
			);
			//BRME-7040: Auto-set/clear the Initiative's Current Budget on Pending Approval transitions (and inserts directly into Pending Approval)
			syncCurrentBudgetOnInitiatives();
			BBApps_Crud.doDelete(
				deleteBudgetPeriods,
				false
			);
			BBApps_Crud.doUpdate(
				budgetRowsToUpdate,
				false
			);
		}
		if (Trigger.isBefore && Trigger.isUpdate) {
			if (!pendingApprovalIds.isEmpty()) {
				validateOverUnderAllocation();
				validatePendingApprovalBudgets();
			}
			if(!approvedBudgetInitiativeMap.isEmpty()) {
				Map<Id, IM_Initiative__c> initiatives = new Map<Id, IM_Initiative__c>(
					[SELECT Partner_Funding_Type__c FROM IM_Initiative__c 
					WHERE Id in:approvedBudgetInitiativeMap.values() 
					AND Partner_Funding_Type__c = 'Supplemental' WITH SYSTEM_MODE]);
				for(Id budgetId : approvedBudgetInitiativeMap.keySet()) {
					if(initiatives.keySet().contains(approvedBudgetInitiativeMap.get(budgetId))) {
						IM_Budget__c newBudget = newMap.get(budgetId);
						newBudget.Total_Budget_Amount__c = newBudget.Budget_Amount__c;
					}
				}
			}
		}
	}

	private void createBudgetPeriods(Decimal count, Integer maxPeriod, String budgetId) {
		for (Integer i = 0; i < count; i++) {
			budgetPeriods.add(new IM_Budget_Period__c(Budget__c = budgetId, Period__c = i + 1 + maxPeriod));
		}
	}

	private void deleteBudgetPeriods(Decimal count, String budgetId) {
		if (budgetToPeriodsMap.containsKey(budgetId)) {
			for (Integer i = 0; i < count; i++) {
				deleteBudgetPeriods.add(budgetToPeriodsMap.get(budgetId).get(i));
			}
		}
	}

	private void setBudgetPeriodMap() {
		List<IM_Budget_Period__c> allBudgetPeriods = [
			SELECT Id, Name, Budget__c, Period__c
			FROM IM_Budget_Period__c
			WHERE Budget__c IN :newMap.keySet()
			WITH SYSTEM_MODE
			ORDER BY Period__c DESC
		];

		for (IM_Budget_Period__c bp : allBudgetPeriods) {
			List<IM_Budget_Period__c> bpList = budgetToPeriodsMap.containsKey(bp.Budget__c)
				? budgetToPeriodsMap.get(bp.Budget__c)
				: new List<IM_Budget_Period__c>();
			bpList.add(bp);
			budgetToPeriodsMap.put(bp.Budget__c, bpList);
		}
	}

	private void processBudgetPeriods(IM_Budget__c newBudget, IM_Budget__c oldBudget) {
		if (newBudget.Budget_Term_Years__c > oldBudget.Budget_Term_Years__c) {
			Integer lastPeriodNumber = budgetToPeriodsMap.containsKey(newBudget.Id) ? budgetToPeriodsMap.get(newBudget.Id).get(0).Period__c.intValue() : 0;
			createBudgetPeriods(newBudget.Budget_Term_Years__c - oldBudget.Budget_Term_Years__c, lastPeriodNumber, newBudget.Id);
		} else if (newBudget.Budget_Term_Years__c < oldBudget.Budget_Term_Years__c) {
			Integer lastPeriodNumber = budgetToPeriodsMap.containsKey(newBudget.Id) ? budgetToPeriodsMap.get(newBudget.Id).get(0).Period__c.intValue() : 0;
			if (lastPeriodNumber > 0) {
				deleteBudgetPeriods(oldBudget.Budget_Term_Years__c - newBudget.Budget_Term_Years__c, newBudget.Id);
			}
		}
	}

	/**
	 * Description     : update 1-1 mapping checkbox fields Partner,Partner Role, Duration, Run Rate, Component, SubComponent, Geography
	 * Parameters      : Accepts IM_Budget__c record
	 * Return Type     : None
	 */
	private void updateCheckboxes(IM_Budget__c newBudget) {
		try {
			newBudget = IMUtil.updateCheckboxes(newBudget);
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(newBudget, ex, new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET_CHECKBOXES));
		}
	}

	/**
	 * Description     : Method to hard match budget names under same initiative
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void hardMatchBudgetName() {
		//Variables
		Set<Id> initiativeIdSet = new Set<Id>();
		Map<Id, Set<String>> initiativeIdBudgetNamesMap = new Map<Id, Set<String>>();
		//Update Initiative Id as Key, Budget Name as Value.
		for (IM_Budget__c budget : newBudgets) {
			if (!initiativeIdSet.contains(budget.Initiative__c)) {
				initiativeIdSet.add(budget.Initiative__c);
			}
		}
		//Get all the budget Names under each Initiative Id and check if the above values exisit for each mapping.
		for (IM_Budget__c childBudget : [SELECT Id, Initiative__c, Name FROM IM_Budget__c WHERE Initiative__c IN :initiativeIdSet WITH SYSTEM_MODE]) {
			if (!initiativeIdBudgetNamesMap.containsKey(childBudget.Initiative__c)) {
				initiativeIdBudgetNamesMap.put(childBudget.Initiative__c, new Set<String>());
			}
			initiativeIdBudgetNamesMap.get(childBudget.Initiative__c).add(childBudget.Name);
		}
		//Check for Name
		for (IM_Budget__c budget : newBudgets) {
			if (!initiativeIdBudgetNamesMap.isEmpty() && initiativeIdBudgetNamesMap.get(budget.Initiative__c).contains(budget.Name)) {
				budget.addError('No two budgets under one initiative can have the same name.');
			}
		}
	}

	/**
	 * Description     : Method to set Budget Version
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void setBudgetVersion() {
		for (IM_Budget__c budget : newBudgets) {
			if (isFieldChanged(budget, 'Is_Active__c') && !oldMap.get(budget.Id).Is_Active__c && budget.Is_Active__c) {
				budgetToInitiativeMap.put(budget.Id, budget.Initiative__c);
			}
		}
		getAmendmentNumber();
		for (Id budgetId : budgetToInitiativeMap.keySet()) {
			newMap.get(budgetId).Version__c = initiativeMap.get(budgetToInitiativeMap.get(budgetId)).Amendment_Number__c + 1;
		}
	}

	/**
	 * Description     : Method to identify if the budget term is reduced
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void checkForTermReducedBudgets() {
		try {
			for (IM_Budget__c budget : newBudgets) {
				if (
					isFieldChanged(budget, 'Budget_Term_months__c') &&
					(oldMap.get(budget.Id).Budget_Term_months__c > budget.Budget_Term_months__c) &&
					oldMap.get(budget.Id).Last_Checked_In_At__c != null
				) {
					termReducedBudgetsIdMap.put(budget.Id, budget.Budget_Term_Years__c);
				}
			}
			if (!termReducedBudgetsIdMap.isEmpty()) {
				updatePeriodAmountsOnBudgetRows();
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BUDGET_TERM_CHECK));
		}
	}

	/**
	 * Description     : Method to clear the period amounts if the budget term is reduced
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void updatePeriodAmountsOnBudgetRows() {
		try {
			budgetRowsToUpdate = [
				SELECT
					Id,
					Budget__c,
					Period_1_Amount__c,
					Period_2_Amount__c,
					Period_3_Amount__c,
					Period_4_Amount__c,
					Period_5_Amount__c,
					Period_6_Amount__c,
					Period_7_Amount__c,
					Period_8_Amount__c,
					Period_9_Amount__c,
					Period_10_Amount__c
				FROM IM_Budget_Row__c
				WHERE Budget__c IN :termReducedBudgetsIdMap.keySet()
				WITH SYSTEM_MODE
				FOR UPDATE
			];
			//On these budget rows, the period amounts needs to be updated
			for (IM_Budget_Row__c budgetRow : budgetRowsToUpdate) {
				Decimal latestTerm = termReducedBudgetsIdMap.get(budgetRow.Budget__c);
				for (Decimal i = latestTerm + 1; i < 11; i++) {
					String fieldName = 'Period_'+String.valueOf(i)+'_Amount__c';
					budgetRow.put(fieldName, 0);
				}
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET_ROWS));
		}
	}

	/**
	 * Description     : Method to get current Amendment number from related Initiative
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void getAmendmentNumber() {
		try {
			initiativeMap = new Map<Id, IM_Initiative__c>([SELECT Id, Amendment_Number__c FROM IM_Initiative__c 
															WHERE Id IN :budgetToInitiativeMap.values() WITH SYSTEM_MODE]);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_AMENDMENT_NUMBER));
		}
	}

	/**
	 * Description     : Method to Validate for Over/Under Allocations
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void validateOverUnderAllocation() {
		AggregateResult[] aggregateResults = [
			SELECT Count(Id), Budget__c
			FROM IM_Funding_Source__c
			WHERE Budget__c IN :pendingApprovalIds
			AND Over_Under__c != 0
			AND Budget__r.Initiative__r.Partner_Funding_Type__c='Offset'
			WITH SYSTEM_MODE
			GROUP BY Budget__c
		];
		for (AggregateResult ar : aggregateResults) {
			IM_Budget__c budget = newMap.get((Id) ar.get('Budget__c'));
			budget.addError(ALLOCATION_ERROR_MESSAGE);
		}
	}

	/**
	 * Description     : Method to Validate if there are multiple budgets in Pending Approval Status for the same initiative
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void validatePendingApprovalBudgets() {
		if(!initiativeIds.isEmpty()) {
			Map<Id, Id> initiativeBudgetMap = new Map<Id, Id>();
			for (IM_Budget__c budget : [SELECT Id, Initiative__c FROM IM_Budget__c 
										WHERE Initiative__c IN :initiativeIds AND Status__c = :Assets.PENDING_APPROVAL
										WITH SYSTEM_MODE]) {
				initiativeBudgetMap.put(budget.Initiative__c, budget.Id);
			}
			for(IM_Budget__c budget : newBudgets) {
				if(pendingApprovalIds.contains(budget.Id) && initiativeBudgetMap.containsKey(budget.Initiative__c)) {
					budget.addError(PENDING_APPROVAL_ERROR_MESSAGE);
				}
			}
		}
	}

	/**
	 * Description     : Method to set the checkbox field 'Is_Locked__c' to true for all budget rows under the budget which is getting approved.
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void lockBudgetRows() {
		List<IM_Budget_Row__c> lockBudgetRows = [SELECT Id, Budget__c, Is_Locked__c 
													FROM IM_Budget_Row__c 
													WHERE Budget__c IN :newMap.keySet()
													WITH SYSTEM_MODE];
		for(IM_Budget_Row__c budgetRow : lockBudgetRows) {
			budgetRow.Is_Locked__c = true;
		}
		BBApps_Crud.doUpdate(
			lockBudgetRows,
			false
		);
	}

	/**
	* Description     : Method to prevent deletion.
	* Parameters      : none
	* Return Type     : void
	*/
	private void checkForDeletion() {
		String userId = UserInfo.getUserId();
		for(IM_Budget__c budget : oldBudgets) {
			if(budget.Status__c != Assets.DRAFT) {
				budget.addError(DELETE_ERROR_MESSAGE);
			}
			if(budget.CreatedById != userId) {
				budget.addError(DELETE_ERROR_MESSAGE);
			}
		}
	}

	/**
	 * Description     : BRME-7040: Method to sync the Initiative's Current Budget when a budget enters or leaves Pending Approval status.
	 *                   The update runs in AFTER context so the budget's saved Status satisfies the Current_Budget__c lookup filter
	 *                   (Status must be Pending Approval/Approved).
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void syncCurrentBudgetOnInitiatives() {
		if (budgetToSetAsCurrentMap.isEmpty() && budgetToClearAsCurrentMap.isEmpty()) {
			return;
		}
		List<IM_Initiative__c> initiativesToUpdate = new List<IM_Initiative__c>();
		//Only clear Current Budget when the Initiative still points at the budget leaving Pending Approval
		if (!budgetToClearAsCurrentMap.isEmpty()) {
			for (IM_Initiative__c initiative : [
				SELECT Id, Current_Budget__c
				FROM IM_Initiative__c
				WHERE Current_Budget__c IN :budgetToClearAsCurrentMap.keySet()
				WITH SYSTEM_MODE
			]) {
				initiativesToUpdate.add(new IM_Initiative__c(Id = initiative.Id, Current_Budget__c = null));
			}
		}
		for (Id budgetId : budgetToSetAsCurrentMap.keySet()) {
			initiativesToUpdate.add(new IM_Initiative__c(Id = budgetToSetAsCurrentMap.get(budgetId), Current_Budget__c = budgetId));
		}
		if (!initiativesToUpdate.isEmpty()) {
			BBApps_Crud.doUpdate(initiativesToUpdate);
		}
	}
}