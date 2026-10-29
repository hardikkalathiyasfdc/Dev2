/**
 * Author      : Paddy
 * Date        : 4/28/2025
 * Jira        : IM-160
 * Description : This class provides methods for clone funtionality.
 * Test        : IMCloneTest
 * ChangeLog   :
 * Sai on Jun 25th, 2025: IM-241: Added logic to truncate the budget Name while cloning in case of Amendment creation.
 * Paddy on 06/15/2025: IM-450: Added logic for error logging framework
 */
public with sharing class IMClone {

	private static final String ERR_CLONE_BUDGET = 'IMCLONE_CLONE_BUDGET_FAILED';

	public class IMCloneException extends Exception {
	}

	/**
	 * Description : Method to deep clone Budget
	 * Parameters : budgetId Id, initiativeId Id.
	 * Return Type : IM_Budget__c
	 */
	public static IM_Budget__c cloneBudget(Id budgetId, Id initiativeId, String newClonedBudgetName) {
		return cloneBudget(budgetId, initiativeId, Assets.REGULAR, newClonedBudgetName);
	}

	/**
	 * Description : Method to deep clone Budget
	 * Parameters : budgetId Id, initiativeId Id, cloneType String, newClonedBudgetName String
	 * Return Type : IM_Budget__c
	 */
	public static IM_Budget__c cloneBudget(Id budgetId, Id initiativeId, String cloneType, String newClonedBudgetName) {
		try {
			List<SObject> clonedRecords = new List<SObject>();
			IM_Budget__c budget = IMUtil.getBudget(budgetId);
		
			IM_Budget__c clonedBudget = budget.clone(false, false, false, false);
			clonedBudget.Name = String.isNotBlank(newClonedBudgetName) ? newClonedBudgetName : clonedBudget.Name;
			clonedBudget.Is_Active__c = false;
			clonedBudget.Initiative__c = initiativeId;
			clonedBudget.Cloned_From__c = budgetId;
			clonedBudget.External_Id__c = initiativeId + clonedBudget.Name;
			clonedBudget.Version__c = 0;
            
            IM_Budget__c budgetReference = new IM_Budget__c(External_Id__c = clonedBudget.External_Id__c);
            
			if (!Assets.AMENDMENT_APPROVAL.equalsIgnoreCase(cloneType)) {
				clonedBudget.Status__c = Assets.DRAFT;
			}
			if (Assets.AMENDMENT_CREATE.equalsIgnoreCase(cloneType)) {
				clonedBudget.Proposed_Amount__c = null;
				//IM-241: Added truncate logic
				clonedBudget.Name = IMUtil.truncateFieldValue(75, budget.Name, null, ' Copy');
			    clonedBudget.Last_Checked_In_At__c = null;
			    clonedBudget.Last_Checked_In_By__c = null;
			}
			clonedRecords.add(clonedBudget);

			//Clone Components
			Map<Id, IM_Component__c> clonedComponents = cloneComponents(budgetId, budgetReference);
			clonedRecords.addAll(clonedComponents.values());

			//Clone BudgetOrgs
			Map<Id, IM_Budget_Org__c> clonedBudgetOrgs = cloneBudgetOrgs(budgetId, budgetReference);
			clonedRecords.addAll(clonedBudgetOrgs.values());

			//Clone Geography
			Map<Id, IM_Geography__c> clonedGeographies = cloneGeography(budgetId, budgetReference);
			clonedRecords.addAll(clonedGeographies.values());

			//Clone Funding Partners
			Map<Id, IM_Funding_Source__c> clonedFundingPartners = cloneFundingPartner(budgetId, budgetReference);
			clonedRecords.addAll(clonedFundingPartners.values());

			//Clone Budget Periods
			Map<Id, IM_Budget_Period__c> clonedBudgetPeriods = cloneBudgetPeriods(budgetId, budgetReference);
			clonedRecords.addAll(clonedBudgetPeriods.values());
            
			if(!clonedRecords.isEmpty()) {
			List<BBApps_DMLResult> dmlResults = BBApps_Crud.doInsert(clonedRecords);
			}

			//Clone Components and SubComponents
			Map<Id, IM_Component__c> clonedSubComponents = cloneSubComponents(budgetId, clonedBudget, clonedComponents);

			//Clone Budget Rows
			Map<Id, IM_Budget_Row__c> clonedBudgetRows = cloneBudgetRows(
				budgetId,
				clonedBudget,
				clonedComponents,
				clonedSubComponents,
				clonedGeographies,
				clonedBudgetOrgs,
				clonedFundingPartners
			);

			return clonedBudget;
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CLONE_BUDGET));
			throw new IMCloneException('Error while cloning the Budget: ' + ex.getMessage());
		}
	}

	/**
	 * Description : Method to deep clone Components related to budget
	 * Parameters : budgetId Id, clonedBudget IM_Budget__c
	 * Return Type : Map<Id, IM_Component__c>
	 */
	public static Map<Id, IM_Component__c> cloneComponents(Id budgetId, IM_Budget__c clonedBudget) {
		List<IM_Component__c> components = IMUtil.getComponents(budgetId);
		Map<Id, IM_Component__c> clonedComponents = new Map<Id, IM_Component__c>();

		for (IM_Component__c component : components) {
			IM_Component__c clonedComponent = component.clone(false, false, false, false);
			clonedComponent.Budget__r = clonedBudget;
			clonedComponent.External_Id__c = '';
			clonedComponents.put(component.Id, clonedComponent);
		}
		return clonedComponents;
	}

	/**
	 * Description : Method to deep clone Sub Components related to budget
	 * Parameters : budgetId Id, clonedBudget IM_Budget__c, clonedComponents Map<Id, IM_Component__c>
	 * Return Type : Map<Id, IM_Component__c>
	 */
	public static Map<Id, IM_Component__c> cloneSubComponents(Id budgetId, IM_Budget__c clonedBudget, Map<Id, IM_Component__c> clonedComponents) {
		List<IM_Component__c> subComponents = IMUtil.getSubComponents(budgetId);
		Map<Id, IM_Component__c> clonedSubComponents = new Map<Id, IM_Component__c>();

		for (IM_Component__c subComponent : subComponents) {
			IM_Component__c clonedSubComponent = subComponent.clone(false, false, false, false);
			clonedSubComponent.Budget__c = clonedBudget.Id;
			clonedSubComponent.External_Id__c = '';
			clonedSubComponent.Parent_Component__c = subComponent.Parent_Component__c != null
				? clonedComponents.get(subComponent.Parent_Component__c).Id
				: subComponent.Parent_Component__c;
			clonedSubComponents.put(subComponent.Id, clonedSubComponent);
		}
		if(!clonedSubComponents.isEmpty()) {
			BBApps_Crud.doInsert(clonedSubComponents.values());
		}
		return clonedSubComponents;
	}

	/**
	 * Description : Method to deep clone Budget Orgs related to budget
	 * Parameters : budgetId Id, clonedBudget IM_Budget__c
	 * Return Type : Map<Id, IM_Budget_Org__c>
	 */
	public static Map<Id, IM_Budget_Org__c> cloneBudgetOrgs(Id budgetId, IM_Budget__c clonedBudget) {
		List<IM_Budget_Org__c> budgetOrgs = IMUtil.getActiveBudgetOrgs(budgetId);
		Map<Id, IM_Budget_Org__c> clonedBudgetOrgs = new Map<Id, IM_Budget_Org__c>();

		for (IM_Budget_Org__c org : budgetOrgs) {
			IM_Budget_Org__c clonedBudgetOrg = org.clone(false, false, false, false);
			clonedBudgetOrg.Budget__r = clonedBudget;
			clonedBudgetOrg.External_Id__c = '';
			clonedBudgetOrgs.put(org.Id, clonedBudgetOrg);
		}
		return clonedBudgetOrgs;
	}

	/**
	 * Description : Method to deep clone Geographies related to budget
	 * Parameters : budgetId Id, clonedBudget IM_Budget__c
	 * Return Type : Map<Id, IM_Geography__c>
	 */
	public static Map<Id, IM_Geography__c> cloneGeography(Id budgetId, IM_Budget__c clonedBudget) {
		List<IM_Geography__c> geographies = IMUtil.getGeography(budgetId);
		Map<Id, IM_Geography__c> clonedGeographies = new Map<Id, IM_Geography__c>();

		for (IM_Geography__c geography : geographies) {
			IM_Geography__c clonedGeography = geography.clone(false, false, false, false);
			clonedGeography.Budget__r = clonedBudget;
			clonedGeography.External_Id__c = '';
			clonedGeographies.put(geography.Id, clonedGeography);
		}
		return clonedGeographies;
	}

	/**
	 * Description : Method to deep clone Funding Partners related to budget
	 * Parameters : budgetId Id, clonedBudget IM_Budget__c
	 * Return Type : Map<Id, IM_Geography__c>
	 */
	public static Map<Id, IM_Funding_Source__c> cloneFundingPartner(Id budgetId, IM_Budget__c clonedBudget) {
		List<IM_Funding_Source__c> fundingPartners = IMUtil.getFundingPartners(budgetId);
		Map<Id, IM_Funding_Source__c> clonedFundingPartners = new Map<Id, IM_Funding_Source__c>();

		for (IM_Funding_Source__c fundingPartner : fundingPartners) {
			IM_Funding_Source__c clonedFundingPartner = fundingPartner.clone(false, false, false, false);
			clonedFundingPartner.Budget__r = clonedBudget;
			clonedFundingPartners.put(fundingPartner.Id, clonedFundingPartner);
		}
		return clonedFundingPartners;
	}

	/**
	 * Description : Method to deep clone Budget Periods related to budget
	 * Parameters : budgetId Id, clonedBudget IM_Budget__c
	 * Return Type : Map<Id, IM_Budget_Period__c>
	 */
	public static Map<Id, IM_Budget_Period__c> cloneBudgetPeriods(Id budgetId, IM_Budget__c clonedBudget) {
		List<IM_Budget_Period__c> budgetPeriods = IMUtil.getBudgetPeriods(budgetId);
		Map<Id, IM_Budget_Period__c> clonedBudgetPeriods = new Map<Id, IM_Budget_Period__c>();

		for (IM_Budget_Period__c period : budgetPeriods) {
			IM_Budget_Period__c clonedPeriod = period.clone(false, false, false, false);
			clonedPeriod.Budget__r = clonedBudget;
			clonedPeriod.Period_End_Date__c = null;
			clonedPeriod.Period_Start_Date__c = null;
			clonedBudgetPeriods.put(period.Id, clonedPeriod);
		}
		return clonedBudgetPeriods;
	}

	/**
	 * Description : Method to deep clone Budget Rows related to budget
	 * Parameters : budgetId Id, clonedBudget IM_Budget__c, clonedComponents Map<Id, IM_Component__c>, clonedSubComponents Map<Id, IM_Component__c>, clonedGeographies Map<Id, IM_Geography__c>, clonedBudgetOrgs Map<Id, IM_Budget_Org__c>
	 * Return Type : Map<Id, IM_Budget_Row__c>
	 */
	public static Map<Id, IM_Budget_Row__c> cloneBudgetRows(
		Id budgetId,
		IM_Budget__c clonedBudget,
		Map<Id, IM_Component__c> clonedComponents,
		Map<Id, IM_Component__c> clonedSubComponents,
		Map<Id, IM_Geography__c> clonedGeographies,
		Map<Id, IM_Budget_Org__c> clonedBudgetOrgs,
		Map<Id, IM_Funding_Source__c> fundingPartners
	) {
        List<IM_Budget_Row__c> budgetRows = IMUtil.getBudgetRowsByBudget(budgetId);
		Map<Id, IM_Budget_Row__c> clonedBudgetRows = new Map<Id, IM_Budget_Row__c>();

		for (IM_Budget_Row__c budgetRow : budgetRows) {
			IM_Budget_Row__c clonedBudgetRow = budgetRow.clone(false, false, false, false);
			clonedBudgetRow.Budget__c = clonedBudget.Id;
			clonedBudgetRow.Budget_Grant__c = null;
			clonedBudgetRow.Component__c = budgetRow.Component__c != null ? clonedComponents.get(budgetRow.Component__c).Id : budgetRow.Component__c;
			clonedBudgetRow.SubComponent__c = budgetRow.SubComponent__c != null
				? clonedSubComponents.get(budgetRow.SubComponent__c).Id
				: budgetRow.SubComponent__c;
			clonedBudgetRow.Geography__c = budgetRow.Geography__c != null ? clonedGeographies.get(budgetRow.Geography__c).Id : budgetRow.Geography__c;
			clonedBudgetRow.Partner__c = budgetRow.Partner__c != null ? clonedBudgetOrgs.get(budgetRow.Partner__c).Id : budgetRow.Partner__c;
			clonedBudgetRow.Payee_Fiscal_Sponsor__c = budgetRow.Payee_Fiscal_Sponsor__c != null
				? clonedBudgetOrgs.get(budgetRow.Payee_Fiscal_Sponsor__c).Id
				: budgetRow.Payee_Fiscal_Sponsor__c;
			clonedBudgetRow.Sub_Partner__c = budgetRow.Sub_Partner__c != null ? clonedBudgetOrgs.get(budgetRow.Sub_Partner__c).Id : budgetRow.Sub_Partner__c;
			clonedBudgetRow.Partner_Fund__c = budgetRow.Partner_Fund__c != null ? fundingPartners.get(budgetRow.Partner_Fund__c).Id : budgetRow.Partner_Fund__c;
			clonedBudgetRows.put(budgetRow.Id, clonedBudgetRow);
		}
		if(!clonedBudgetRows.isEmpty()) {
			BBApps_Crud.doInsert(clonedBudgetRows.values());
		}
		return clonedBudgetRows;
	}

	/**
	 * Description : Method to deep clone Strategic Locations related to Initiative
    * Parameters : initiativeId String, amendmentInitiativeId String
	 * Return Type : void
	 */
	public static void cloneStrategicLocations(String initiativeId, String amendmentInitiativeId) {
		// Get strategic locations related to the initiative
		List<IM_Strategic_Locations__c> strategicLocations = IMUtil.getStrategicLocations(initiativeId);
		List<IM_Strategic_Locations__c> clonedStrategicLocations = new List<IM_Strategic_Locations__c>();

		if (!strategicLocations.isEmpty()) {
			for (IM_Strategic_Locations__c strategicLocation : strategicLocations) {
				IM_Strategic_Locations__c clonedStrategicLocation = strategicLocation.clone(false, false, false, false);
				clonedStrategicLocation.Initiative__c = amendmentInitiativeId;
				clonedStrategicLocations.add(clonedStrategicLocation);
			}
		}

		if (!strategicLocations.isEmpty()) {
			BBApps_Crud.doInsert(clonedStrategicLocations);
		}
	}

	/**
	 * Description : Method to clone Approvals related to Amendment Initiative and attach them to main Initiative
	 * Parameters : initiativeId Id, newInitiative Id
	 * Return Type : void
	 */
	public static void cloneApprovals(String initiativeId, String newInitiativeId) {
		List<IM_Approval__c> clonedApprovals = new List<IM_Approval__c>();

		for (IM_Approval__c approval : IMUtil.getApprovals(initiativeId)) {
			IM_Approval__c clonedApproval = approval.clone(false, false, false, false);
			clonedApproval.Initiative__c = newInitiativeId;
			clonedApprovals.add(clonedApproval);
		}

		//DML
		if(!clonedApprovals.isEmpty()) {
			BBApps_Crud.doInsert(clonedApprovals);
		}
	}
}