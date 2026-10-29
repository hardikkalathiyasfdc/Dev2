/**
 * Author             : Gauri Sagane
 * Date               : 02/20/2025
 * Jira               : IM-113
 * Description        : This class is used by Budget Row Trigger and contains helper methods.
 * Test               : IMBudgetRowTriggerHandlerTest
 * ChangeLog          :
 * Paddy on 03/20/2025: IM-129: Added logic to populate BudgetPeriod TotalAmount and TotalAmount on
 *                      Component, SubComponent, Geography.
 * Paddy on 03/28/2025: IM-130: added logic to call IMService.computeGrants method.
 * Paddy on 07/01/2025: IM-249: added logic to include budget ids (childRecordBudgetIds) on BudgetRowHelper.populateTotalAmount method.
 * Sai   on 09/01/2025: IM-365: added logic to calculate budget org totals at budget org level
 * Paddy on 02/26/2025: IM-520: added logic to set IM_Budget_Org__c.Total_Amount__c = 0 when respective BudgetRow is deleted.
 **/

public with sharing class IMBudgetRowTriggerHandler extends TriggerHandler {

	public List<IM_Budget_Row__c> newBudgetRows;
	public List<IM_Budget_Row__c> oldBudgetRows;
	public Map<Id, IM_Budget_Row__c> oldMap;
	public Map<Id, IM_Budget_Row__c> newMap;

	private Set<Id> budgetIds = new Set<Id>();
	private Set<Id> updateBGBudgetIds = new Set<Id>();
	private Set<Id> partnerFundIds = new Set<Id>();
	private List<IM_Funding_Source__c> partnerFunds = new List<IM_Funding_Source__c>();
	private List<IM_Funding_Source__c> partnerFundsToUpdate = new List<IM_Funding_Source__c>();
	private static Set<Id> geographyIds = new Set<Id>();
	private static Set<Id> componentIds = new Set<Id>();
	private static Set<Id> subComponentIds = new Set<Id>();
	private static Set<Id> periodAmountBudgetIds = new Set<Id>();
	private static Set<Id> childRecordBudgetIds = new Set<Id>();
	private Map<Id, IM_Budget_Org__c> budgetOrgsToUpdate = new Map<Id, IM_Budget_Org__c>();

	public IMBudgetRowTriggerHandler() {
		this(Trigger.old, Trigger.new, (Map<Id, IM_Budget_Row__c>) Trigger.oldMap, (Map<Id, IM_Budget_Row__c>) Trigger.newMap);
	}

	public IMBudgetRowTriggerHandler(List<IM_Budget_Row__c> oldBudgetRowsList, List<IM_Budget_Row__c> newBudgetRowsList) {
		oldBudgetRows = oldBudgetRowsList;
		newBudgetRows = newBudgetRowsList;
	}

	public IMBudgetRowTriggerHandler(
		List<IM_Budget_Row__c> oldBudgetRowsList,
		List<IM_Budget_Row__c> newBudgetRowsList,
		Map<Id, IM_Budget_Row__c> oldMap,
		Map<Id, IM_Budget_Row__c> newMap
	) {
		newBudgetRows = newBudgetRowsList;
		oldBudgetRows = oldBudgetRowsList;
		this.oldMap = oldMap;
		this.newMap = newMap;
	}

	public override void beforeInsert(SObject so) {
		IM_Budget_Row__c budgetRow = (IM_Budget_Row__c) so;
		setBPFund(budgetRow);
	}

	public override void afterInsert(SObject so) {
		IM_Budget_Row__c budgetRow = (IM_Budget_Row__c) so;
		if (budgetRow.Geography__c != null) {
			geographyIds.add(budgetRow.Geography__c);
			childRecordBudgetIds.add(budgetRow.Budget__c);
		}
		if (budgetRow.Component__c != null) {
			componentIds.add(budgetRow.Component__c);
			childRecordBudgetIds.add(budgetRow.Budget__c);
		}
		if (budgetRow.SubComponent__c != null) {
			subComponentIds.add(budgetRow.SubComponent__c);
			childRecordBudgetIds.add(budgetRow.Budget__c);
		}
		periodAmountBudgetIds.add(budgetRow.Budget__c);
		updateBGBudgetIds.add(budgetRow.Budget__c);
	}

	public override void beforeUpdate(SObject oldSo, SObject so) {
		IM_Budget_Row__c newBudgetRow = (IM_Budget_Row__c) so;
		IM_Budget_Row__c oldBudgetRow = (IM_Budget_Row__c) oldSo;

		if (isFieldChanged(newBudgetRow, Assets.PARTNER_FUND_FIELD)) {
			setBPFund(newBudgetRow);
		}
	}

	public override void afterUpdate(SObject oldSo, SObject so) {

		IM_Budget_Row__c newBudgetRow = (IM_Budget_Row__c) so;
		IM_Budget_Row__c oldBudgetRow = (IM_Budget_Row__c) oldSo;
		if (
			isFieldChanged(newBudgetRow, Assets.TOTAL_AMOUNT) ||
			isFieldChanged(newBudgetRow, Assets.GEOGRAPHY_FIELD) ||
			isFieldChanged(newBudgetRow, Assets.COMPONENT_FIELD) ||
			isFieldChanged(newBudgetRow, Assets.SUB_COMPONENT_FIELD)
		) {
			childRecordBudgetIds.add(newBudgetRow.Budget__c);
			childRecordBudgetIds.add(oldBudgetRow.Budget__c);
		}

		if (isFieldChanged(newBudgetRow, Assets.TOTAL_AMOUNT) || isFieldChanged(newBudgetRow, Assets.GEOGRAPHY_FIELD)) {
			if (newBudgetRow.Geography__c != null) {
				geographyIds.add(newBudgetRow.Geography__c);
			}
			if (oldBudgetRow.Geography__c != null) {
				geographyIds.add(oldBudgetRow.Geography__c);
			}
		}
		if (isFieldChanged(newBudgetRow, Assets.TOTAL_AMOUNT) || isFieldChanged(newBudgetRow, Assets.COMPONENT_FIELD)) {
			if (newBudgetRow.Component__c != null) {
				componentIds.add(newBudgetRow.Component__c);
			}
			if (oldBudgetRow.Component__c != null) {
				componentIds.add(oldBudgetRow.Component__c);
			}
		}
		if (isFieldChanged(newBudgetRow, Assets.TOTAL_AMOUNT) || isFieldChanged(newBudgetRow, Assets.SUB_COMPONENT_FIELD)) {
			if (newBudgetRow.SubComponent__c != null) {
				subComponentIds.add(newBudgetRow.SubComponent__c);
			}
			if (oldBudgetRow.SubComponent__c != null) {
				subComponentIds.add(oldBudgetRow.SubComponent__c);
			}
		}
		if (isFieldChanged(newBudgetRow, Assets.TOTAL_AMOUNT) || isFieldChanged(newBudgetRow, Assets.BUDGET_FIELD)) {
			periodAmountBudgetIds.add(newBudgetRow.Budget__c);
			periodAmountBudgetIds.add(oldBudgetRow.Budget__c);
		}

		//IM-130
		if (
			isFieldChanged(newBudgetRow, Assets.TOTAL_AMOUNT) ||
			isFieldChanged(newBudgetRow, Assets.PARTNER_FIELD) ||
			isFieldChanged(newBudgetRow, Assets.UNIQUE_IDENTIFIER_FIELD)
		) {
			updateBGBudgetIds.add(newBudgetRow.Budget__c);
		}
	}

	public override void bulkAfter() {
		if (Trigger.isInsert) {
			if (newBudgetRows != null && !newBudgetRows.isEmpty()) {
				for (IM_Budget_Row__c budgetRow : newBudgetRows) {
					if (budgetRow.Partner_Fund__c != null) {
						budgetIds.add(budgetRow.Budget__c);
						partnerFundIds.add(budgetRow.Partner_Fund__c);
					}
					if (budgetRow.Partner__c != null) {
						updateOrgTotalAmount(budgetRow.Partner__c, budgetRow.Total_Amount__c);
					}
					if (budgetRow.Sub_Partner__c != null) {
						updateOrgTotalAmount(budgetRow.Sub_Partner__c, budgetRow.Total_Amount__c);
					}
					if (budgetRow.Payee_Fiscal_Sponsor__c != null) {
						updateOrgTotalAmount(budgetRow.Payee_Fiscal_Sponsor__c, budgetRow.Total_Amount__c);
					}
				}
				getPartnerFunds(partnerFundIds);
			}
			updatePartnerFunds();
			updateBudgetOrgs();
		}
		if (Trigger.isUpdate) {
			if (newBudgetRows != null && !newBudgetRows.isEmpty()) {
				for (IM_Budget_Row__c budgetRow : newBudgetRows) {
					if (isFieldChanged(budgetRow, 'Partner_Fund__c') && budgetRow.Partner_Fund__c != null) {
						budgetIds.add(budgetRow.Budget__c);
						partnerFundIds.add(budgetRow.Partner_Fund__c);
						partnerFundIds.add(oldMap.get(budgetRow.Id)?.Partner_Fund__c);
					}
				}
				getPartnerFunds(partnerFundIds);
			}
			updatePartnerFunds();
		}
		if (Trigger.isDelete) {
			Set<IM_Budget_Org__c> budgetOrgs = new Set<IM_Budget_Org__c>();
			if (oldBudgetRows != null && !oldBudgetRows.isEmpty()) {
				for (IM_Budget_Row__c budgetRow : oldBudgetRows) {
					if (budgetRow.Partner_Fund__c != null) {
						budgetIds.add(budgetRow.Budget__c);
						partnerFundIds.add(budgetRow.Partner_Fund__c);
					}
					if(budgetRow.Partner__c != null) {
						budgetOrgs.add(new IM_Budget_Org__c(Id = budgetRow.Partner__c, Total_Amount__c = 0));
					}
					if (budgetRow.Sub_Partner__c != null) {
						budgetOrgs.add(new IM_Budget_Org__c(Id = budgetRow.Sub_Partner__c, Total_Amount__c = 0));
					}
					if (budgetRow.Payee_Fiscal_Sponsor__c != null) {
							budgetOrgs.add(new IM_Budget_Org__c(Id = budgetRow.Payee_Fiscal_Sponsor__c, Total_Amount__c = 0));
					}
				}
				getPartnerFunds(partnerFundIds);
			}
			updatePartnerFunds();
			BBApps_Crud.doUpdate(
				new List<IM_Budget_Org__c>(budgetOrgs),
				false
			);
		}
	}

	public override void andFinally() {
		if (Trigger.isAfter) {
			BBApps_Crud.doUpdate(
				partnerFundsToUpdate,
				false
			);

			if (!geographyIds.isEmpty()) {
				IMBudgetRowHelper.populateTotalAmount(childRecordBudgetIds, Assets.IM_GEOGRAPHY, new List<String>{ Assets.GEOGRAPHY_FIELD });
			}
			if (!componentIds.isEmpty() || !subComponentIds.isEmpty()) {
				IMBudgetRowHelper.populateTotalAmount(childRecordBudgetIds, Assets.IM_COMPONENT, new List<String>{ Assets.COMPONENT_FIELD, Assets.SUB_COMPONENT_FIELD });
			}
			if (!periodAmountBudgetIds.isEmpty()) {
				IMBudgetRowHelper.populatePeriodTotalAmount(periodAmountBudgetIds);
			}

			if (!updateBGBudgetIds.isEmpty()) {
				List<IM_Initiative__c> initiatives = [
					SELECT Current_Budget__c
					FROM IM_Initiative__c
					WHERE Current_Budget__c IN :updateBGBudgetIds AND Approved__c = TRUE
					WITH SYSTEM_MODE
				];

				Set<Id> budgetIds = new Set<Id>();
				for (IM_Initiative__c initiative : initiatives) {
					budgetIds.add(initiative.Current_Budget__c);
				}
				if (!budgetIds.isEmpty()) {
					IMService.computeGrants(budgetIds);
				}
			}
		}
	}

	/**
	 * Description : Method to get related Partner Funds
	 * Parameters : partnerFundIds Set<Id>
	 * Return Type : void
	 */
	private void getPartnerFunds(Set<Id> partnerFundIds) {
		partnerFunds = [SELECT Id, Partner__c, Allocated_Amount__c FROM IM_Funding_Source__c 
						WHERE Id IN :partnerFundIds WITH SYSTEM_MODE];
	}

	/**
	 * Description : Method to get budget rows which has a particular partner fund
	 * Parameters : no parameters
	 * Return Type : void
	 */
	private void updatePartnerFunds() {
		AggregateResult[] partnerFundsBudgetRows = [
			SELECT Budget__c, Partner_Fund__c partnerFundId, SUM(Total_Amount__c) totalAmount
			FROM IM_Budget_Row__c
			WHERE Budget__c IN :budgetIds
			WITH SYSTEM_MODE
			GROUP BY Budget__c, Partner_Fund__c
		];
		Set<Id> newPartnerFundIds = new Set<Id>();
		for (AggregateResult ar : partnerFundsBudgetRows) {
			if ((String) ar.get('partnerFundId') != null) {
				IM_Funding_Source__c partnerFund = new IM_Funding_Source__c(Id = (String) ar.get('partnerFundId'));
				partnerFund.Allocated_Amount__c = (Decimal) ar.get('totalAmount');
				partnerFundsToUpdate.add(partnerFund);
				newPartnerFundIds.add(partnerFund.Id);
			}
		}

		for (IM_Funding_Source__c partnerFund : partnerFunds) {
			if (!newPartnerFundIds.contains(partnerFund.Id)) {
				partnerFund.Allocated_Amount__c = 0;
				partnerFundsToUpdate.add(partnerFund);
			}
		}
	}

	/**
	 * Description : Method to set isBPFund=true if Partner fund is null
	 * Parameters  : IM_Budget_Row__c budgetRow
	 * Return Type : void
	 */
	private void setBPFund(IM_Budget_Row__c budgetRow) {
		budgetRow.Is_BP_Fund__c = budgetRow.Partner_Fund__c == null ? true : false;
	}

	/**
	 * Description : Update the map with budget orgs to Update
	 * Parameters  : Id OrgId, Decimal totalAmount
	 * Return Type : Void
	 */
	private void updateOrgTotalAmount(Id orgId, Decimal totalAmount) {
		IM_Budget_Org__c budgetOrg = budgetOrgsToUpdate.get(orgId);
		if (budgetOrg != null) {
			budgetOrg.Total_Amount__c += totalAmount;
		} else {
			budgetOrgsToUpdate.put(orgId, new IM_Budget_Org__c(Id = orgId, Total_Amount__c = totalAmount));
		}
	}

	/**
	 * Description : Updates the budget orgs with total amounts
	 * Parameters  : None
	 * Return Type : Void
	 */
	private void updateBudgetOrgs() {
		BBApps_Crud.doUpdate(
            budgetOrgsToUpdate.values(),
            false
        );
	}
}