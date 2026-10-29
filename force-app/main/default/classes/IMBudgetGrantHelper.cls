/**
 * Author : Paddy
 * Date   : 04/01/2025
 * Jira   : IM-130
 * Description : This class provides methods needed for Initiaitve Management.
 * Test : IMBudgetGrantHelperTest
 * ChangeLog         :
 * Gauri - 01/28/2026: IM-493: Added logic to set Budget amount local to Zero in case of Zero Amount
 * Gauri - 03/03/2026: IM-518: fetching only non deleted budget grants in getExistingBudgetGrants method.
 * Gauri - 03/16/2026: IM-529: Removed logic to set local amount to zero if budget amount is changed.
 */
public with sharing class IMBudgetGrantHelper {
	/**
	 * Description : Method to setup Budget Grants based on Budget Rows and unique key combination.
	 * Parameters  : List<IM_Budget_Row__c> budgetRows, Map<String, IM_Budget_Grant__c> existingBudgetGrantMap, Map<String, IM_Grant__c> imGrants, Map<String, IM_Budget_Grant__c> grantsToUpdate
	 * Return Type : Map<String, IM_Budget_Grant__c>
	 */
	public static Map<String, IM_Budget_Grant__c> getBudgetGrants(
		List<IM_Budget_Row__c> budgetRows,
		Map<String, IM_Budget_Grant__c> existingBudgetGrantMap,
		Map<String, IM_Grant__c> imGrants,
		Map<String, IM_Budget_Grant__c> grantsToUpdate
	) {
		Map<String, IM_Budget_Grant__c> budgetGrantMap = new Map<String, IM_Budget_Grant__c>();

		for (IM_Budget_Row__c budgetRow : budgetRows) {
			String uniqueKey = formatUniqueKey(budgetRow.Budget__c, budgetRow.Partner__c, budgetRow.Unique_Identifier__c);

			IM_Budget_Grant__c budgetGrant = budgetGrantMap.containsKey(uniqueKey)
				? budgetGrantMap.get(uniqueKey)
				: new IM_Budget_Grant__c(
						Budget_Org__c = budgetRow.Partner__c,
						Budget__c = budgetRow.Budget__c,
						Unique_Identifier__c = budgetRow.Unique_Identifier__c,
						Budget_Amount_USD__c = 0
				  );

			budgetGrant.Budget_Amount_USD__c = budgetGrant.Budget_Amount_USD__c + budgetRow.Total_Amount__c;
			budgetGrantMap.put(uniqueKey, budgetGrant);

			if (existingBudgetGrantMap.containsKey(uniqueKey)) {
				//set Budget Amount for existing Budget Grants
				IM_Budget_Grant__c existingBG = existingBudgetGrantMap.get(uniqueKey);
				existingBG.Budget_Amount_USD__c = budgetGrant.Budget_Amount_USD__c;
				grantsToUpdate.put(uniqueKey, existingBG);
			} else if (!imGrants.containsKey(uniqueKey)) {
				//Create new IM Grant for new Budget Grants
				imGrants.put(uniqueKey, new IM_Grant__c(Partner_Org__c = budgetRow.Partner__r.Organization__c));
			}
		}

		//Check for grants that are missing in the new budget while recomputing, make them zero amounts.
		for (String uniqueKey : existingBudgetGrantMap.keySet()) {
			if (!grantsToUpdate.containsKey(uniqueKey)) {
				//set Budget Amount for existing Budget Grants
				existingBudgetGrantMap.get(uniqueKey).Budget_Amount_USD__c = 0;
				existingBudgetGrantMap.get(uniqueKey).Budget_Amount_Local__c = 0;
				grantsToUpdate.put(uniqueKey, existingBudgetGrantMap.get(uniqueKey));
			}
		}
		return budgetGrantMap;
	}

	/**
	 * Description : Method to get a BedgetGrants based on Budget Ids
	 * Parameters  : Set<Id> budgetIds
	 * Return Type : Map<String, IM_Budget_Grant__c>, key is combination of
	 *               budgetid, budgerOrg and uniqueIdentifier i.e.a0I4C000005zPMlUAMa0TD1000000vP9tMAEDYE6348HU
	 */
	public static Map<String, IM_Budget_Grant__c> getExistingBudgetGrants(Set<Id> budgetIds) {
		Map<String, IM_Budget_Grant__c> budgetGrantMap = new Map<String, IM_Budget_Grant__c>();

		List<IM_Budget_Grant__c> budgetGrants = [
			SELECT Name, IM_Grant__c, Budget__c, Budget_Org__c, Unique_Identifier__c, Budget_Amount_USD__c, Confirmed_Budget_Amount_USD__c
			FROM IM_Budget_Grant__c
			WHERE Budget__c IN :budgetIds AND Deleted__c = false
			WITH SYSTEM_MODE
		];

		for (IM_Budget_Grant__c budgetGrant : budgetGrants) {
			String key = formatUniqueKey(budgetGrant.Budget__c, budgetGrant.Budget_Org__c, budgetGrant.Unique_Identifier__c);
			budgetGrantMap.put(key, budgetGrant);
		}
		return budgetGrantMap;
	}

	public static String formatUniqueKey(String budgetId, String partnerId, String uniqueIdentifier) {
		String uniqueKey = budgetId + partnerId;
		if (String.isNotBlank(uniqueIdentifier)) {
			uniqueKey += uniqueIdentifier;
		}
		return uniqueKey;
	}
}