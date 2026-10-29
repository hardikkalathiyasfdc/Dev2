/**
 * Author : Gauri Sagane
 * Date   : 12/10/2024
 * Jira   : IM-48
 * Description : This class provides methods needed for Initiaitve Management.
 * Test : IMServiceTest
 * ChangeLog   :  Paddy on 02/25/2025: IM-116: removed cloneBudgetElements method.
 *                Paddy on 03/28/2025: IM-130: added computeGrants method.
 *                Paddy on 04/21/2025: IM-148: update computeGrants method to compute BudgetGrantPeriod.
 * 				  Gauri on 07/18/2025: IM-300: Soft deleting Grants instead of Hard Delete to support user permissioning
 *                Sai on 08/27/2025: IM-371: Capture Approved date of amendment on the base initiative.
 * 				  Paddy on 03/03/2027: IM-522: Added logic (computeBudgetGrantPeriod) to create BudgetGrantPeriod for every existing Budget Period;
 * 									   uses 0 when there's no budget row amount for that period. 
 */

public with sharing class IMService {
	//Global Variables
	public static Set<Id> newClonedBudOrgIds = new Set<Id>();
	private static Decimal amendmentNumber;
	private static String amendmentId;
	private static Date startDate;
	private static Date endDate;
	private static Date approvedDate;

	/**
	 * Description : Method to create/update Budget Grants and IMGrants based on Budget Rows
	 * Parameters  : Set<Id> budgetIds
	 * Return Type : void
	 */
	private static void computeGrants(IM_Budget__c clonedBudgetRec) {
		//Step 1 - Compute Grants
		computeGrants(new Set<Id>{ clonedBudgetRec.Id });
		//Step 2 - Update Initiative current budget and end date with Amendment end date
		String baseInitiativeId = clonedBudgetRec.Initiative__c;
		IM_Initiative__c initiativeToUpdate = new IM_Initiative__c(
			Id = baseInitiativeId,
			Start_Date__c = startDate,
			End_Date__c = endDate,
			Approved_Date__c = approvedDate,
			Amendment_Number__c = amendmentNumber,
			Current_Budget__c = clonedBudgetRec.Id
		);

		//DML
		BBApps_Crud.doUpdate(
			initiativeToUpdate
		);

		//Step 3 - update budget period end dates
		Map<Id, IM_Initiative__c> initiativeMap = new Map<Id, IM_Initiative__c>();
		initiativeMap.put(initiativeToUpdate.Id, initiativeToUpdate);
		IMBudgetPeriodHelper.setDates(initiativeMap);

		//Upsert Strategic Locations and clone approvals to main Initiative from Amendment
		BBApps_Crud.doDelete(
			IMUtil.getStrategicLocations(baseInitiativeId)
		);
		IMClone.cloneStrategicLocations(amendmentId, baseInitiativeId);
		IMClone.cloneApprovals(amendmentId, baseInitiativeId);
		insertNewConDocLinks(amendmentId, baseInitiativeId);
	}

	/**
	 * Description : Method to create/update Budget Grants and IMGrants based on Budget Rows
	 * Parameters  : Set<Id> budgetIds
	 * Return Type : void
	 */
	public static void computeGrants(Set<Id> budgetIds) {
		Map<String, IM_Budget_Grant__c> grantsToInsert = new Map<String, IM_Budget_Grant__c>();
		//List<IM_Budget_Grant__c> grantsToDelete = new List<IM_Budget_Grant__c>();
		Map<String, IM_Budget_Grant__c> grantsToUpdate = new Map<String, IM_Budget_Grant__c>();
		//Capture Grants having zero amount budget grants - String captures the IMGrant id
		Map<String, List<IM_Budget_Grant__c>> grantsToDelete = new Map<String, List<IM_Budget_Grant__c>>();
		Map<String, IM_Grant__c> imGrants = new Map<String, IM_Grant__c>();

		List<IM_Budget_Row__c> budgetRows = [
			SELECT
				Budget__c,
				Budget_Grant__c,
				Partner__c,
				Unique_Identifier__c,
				Period_1_amount__c,
				Period_2_amount__c,
				Period_3_amount__c,
				Period_4_amount__c,
				Period_5_amount__c,
				Period_6_amount__c,
				Period_7_amount__c,
				Period_8_amount__c,
				Period_9_amount__c,
				Period_10_amount__c,
				Total_Amount__c,
				Partner__r.Organization__c
			FROM IM_Budget_Row__c
			WHERE Budget__c IN :budgetIds AND Partner__c != NULL
			WITH SYSTEM_MODE
			ORDER BY Budget__c, Partner__c
		];

		if (!budgetRows.isEmpty()) {
			Map<String, IM_Budget_Grant__c> existingBudgetGrantMap = IMBudgetGrantHelper.getExistingBudgetGrants(budgetIds);
			Map<String, IM_Budget_Grant__c> budgetGrantMap = IMBudgetGrantHelper.getBudgetGrants(budgetRows, existingBudgetGrantMap, imGrants, grantsToUpdate);
			Map<Id, Map<Decimal, IM_Budget_Period__c>> periodsByBudgets = new Map<Id, Map<Decimal, IM_Budget_Period__c>>();
			List<IM_Budget_Grant_Period__c> budgetGrantPeriods = new List<IM_Budget_Grant_Period__c>();
			List<IM_Budget_Row__c> updateBudgetRows = new List<IM_Budget_Row__c>();
			Map<Id, Map<Integer, Decimal>> periodAmountsByGrant = new Map<Id, Map<Integer, Decimal>>();

			List<IM_Budget_Period__c> budgetPeriods = [
				SELECT Budget__c, Period__c
				FROM IM_Budget_Period__c
				WHERE Budget__c IN :budgetIds
				WITH SYSTEM_MODE
				ORDER BY Budget__c, Period__c
			];
			BBApps_Crud.doInsert(
				imGrants.values()
			);

			//key is combination of BudgetId, Partner and UniqueIdentifier i.e.a0I4C000005zPMlUAMa0TD1000000vP9tMAEDYE6348HU
			for (String key : budgetGrantMap.keySet()) {
				IM_Budget_Grant__c bg = budgetGrantMap.get(key);
				if (!existingBudgetGrantMap.containsKey(key)) {
					if (imGrants.containsKey(key)) {
						//Set IM Grant for new Budget Grants.
						bg.IM_Grant__c = imGrants.get(key).Id;
					}
					grantsToInsert.put(key, bg);
				}
			}

			BBApps_Crud.doUpdate(
				grantsToUpdate.values()
			); //Grants are recalculated.
			BBApps_Crud.doInsert(
				grantsToInsert.values()
			);

			for (IM_Budget_Period__c period : budgetPeriods) {
				Map<Decimal, IM_Budget_Period__c> periods = periodsByBudgets.containsKey(period.Budget__c)
					? periodsByBudgets.get(period.Budget__c)
					: new Map<Decimal, IM_Budget_Period__c>();
				periods.put(period.Period__c, period);
				periodsByBudgets.put(period.Budget__c, periods);
			}

			List<IM_Budget_Grant_Period__c> existingBudgetGrantPeriods = [
				SELECT Name
				FROM IM_Budget_Grant_Period__c
				WHERE Budget_Grant__c IN :existingBudgetGrantMap.values()
				WITH SYSTEM_MODE
			];

			for (IM_Budget_Row__c budgetRow : budgetRows) {
				String uniqueKey = IMBudgetGrantHelper.formatUniqueKey(budgetRow.Budget__c, budgetRow.Partner__c, budgetRow.Unique_Identifier__c);

				if (grantsToUpdate.containsKey(uniqueKey)) {
					budgetRow.Budget_Grant__c = grantsToUpdate.get(uniqueKey).Id;
				}
				if (grantsToInsert.containsKey(uniqueKey)) {
					budgetRow.Budget_Grant__c = grantsToInsert.get(uniqueKey).Id;
				}
				updateBudgetRows.add(budgetRow);
				computePeriodAmounts(budgetRow, budgetRow.Budget_Grant__c, periodAmountsByGrant);
			}

			//Compute BudgetGrandPeriods for all Budget Grants
			List<IM_Budget_Grant__c> allGrants = new List<IM_Budget_Grant__c>(grantsToInsert.values());
			allGrants.addAll(grantsToUpdate.values());

			for (IM_Budget_Grant__c budgetGrant : allGrants) {
				Map<Integer, Decimal> periodAmounts = periodAmountsByGrant.get(budgetGrant.Id);
				Map<Decimal, IM_Budget_Period__c> periods = periodsByBudgets.get(budgetGrant.Budget__c);
				if (periodAmounts != null) {
					computeBudgetGrantPeriods(budgetGrant.Id, periodAmounts, periods, budgetGrantPeriods);
				}
			}

			BBApps_Crud.doUpdate(
				updateBudgetRows
			);
			BBApps_Crud.doDelete(
				existingBudgetGrantPeriods
			);
			BBApps_Crud.doInsert(
				budgetGrantPeriods
			);

			//Check if the updated grants have any zero amount grants in the list
			if (!grantsToUpdate.values().isEmpty()) {
                
				for (IM_Budget_Grant__c budGrant : grantsToUpdate.values()) {
					//If the amount is becoming zero, capture these grants
					if (budGrant.Budget_Amount_USD__c == 0) {
						if (!grantsToDelete.containsKey(budGrant.IM_Grant__c)) {
							grantsToDelete.put(budGrant.IM_Grant__c, new List<IM_Budget_Grant__c>());
						}
						grantsToDelete.get(budGrant.IM_Grant__c).add(budGrant);
					}
				}

				//Delete Zero Amount Budget Grants
				if (!grantsToDelete.isEmpty()) {
					processZeroAmountGrants(grantsToDelete);
				}
			}
            
            
		}
	}

	/**
	 * Description : Method to compute respective period amount for all periods for the BudgetGrant
	 * Parameters  : Integer period, IM_Budget_Row__c budgetRow, Id grantId,
	 *               Map<Id, Map<Integer, Decimal>> periodAmountsByGrant
	 * Return Type : void
	 */
	private static void computePeriodAmounts(IM_Budget_Row__c budgetRow, Id grantId, Map<Id, Map<Integer, Decimal>> periodAmountsByGrant) {
		computePeriodAmount(1, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(2, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(3, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(4, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(5, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(6, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(7, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(8, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(9, budgetRow, grantId, periodAmountsByGrant);
		computePeriodAmount(10, budgetRow, grantId, periodAmountsByGrant);
	}

	/**
	 * Description : Method to compute respective period amount for the BudgetGrant
	 * Parameters  : Integer period, IM_Budget_Row__c budgetRow, Id grantId,
	 *               Map<Id, Map<Integer, Decimal>> periodAmountsByGrant
	 * Return Type : void
	 */
	private static void computePeriodAmount(Integer period, IM_Budget_Row__c budgetRow, Id grantId, Map<Id, Map<Integer, Decimal>> periodAmountsByGrant) {
        
		String fieldApiName = 'Period_' + period + '_Amount__c';
		if (budgetRow.get(fieldApiName) != null) {
			Map<Integer, Decimal> periodAmounts = periodAmountsByGrant.containsKey(grantId) ? periodAmountsByGrant.get(grantId) : new Map<Integer, Decimal>();

			Decimal periodAmount = periodAmounts.containsKey(period) ? periodAmounts.get(period) : 0;
			periodAmount += (Decimal) budgetRow.get(fieldApiName);
			periodAmounts.put(period, periodAmount);
			periodAmountsByGrant.put(grantId, periodAmounts);
		}
	}

	/**
	 * Description : Method to compute BudgetGrantPeriods
	 * Parameters  : Id budgetGrantId, Map<Integer, Decimal> periodAmounts,
	 *               Map<Decimal, IM_Budget_Period__c> periods, List<IM_Budget_Grant_Period__c> budgetGrantPeriods
	 * Return Type : void
	 */
	private static void computeBudgetGrantPeriods(
		Id budgetGrantId,
		Map<Integer, Decimal> periodAmounts,
		Map<Decimal, IM_Budget_Period__c> periods,
		List<IM_Budget_Grant_Period__c> budgetGrantPeriods
	) {
		computeBudgetGrantPeriod(1, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(2, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(3, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(4, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(5, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(6, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(7, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(8, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(9, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
		computeBudgetGrantPeriod(10, budgetGrantId, periodAmounts, periods, budgetGrantPeriods);
	}

	/**
	 * Description : Method to create BudgetGrantPeriod record based on Budget Grant and Budget Period
	 * Parameters  : Integer period, Id budgetGrantId, Map<Integer, Decimal> periodAmounts,
	 *               Map<Decimal, IM_Budget_Period__c> periods, List<IM_Budget_Grant_Period__c> budgetGrantPeriods
	 * Return Type : void
	 */
	private static void computeBudgetGrantPeriod(
		Integer period,
		Id budgetGrantId,
		Map<Integer, Decimal> periodAmounts,
		Map<Decimal, IM_Budget_Period__c> periods,
		List<IM_Budget_Grant_Period__c> budgetGrantPeriods
	) {
		if (periods.containsKey(period)) {
			Decimal amount = periodAmounts != null && periodAmounts.containsKey(period) ? periodAmounts.get(period) : 0;
			budgetGrantPeriods.add(
				new IM_Budget_Grant_Period__c(	
					Budget_Grant__c = budgetGrantId,
					Budget_Amount_USD__c = amount,
					Period__c = periods.get(period).Id
				)
			);
		}
	}

	/**
	 * Description : Method to check and delete zero amount grants
	 * Parameters  :
	 * Return Type : void
	 */
	private static void processZeroAmountGrants(Map<String, List<IM_Budget_Grant__c>> grantsToDelete) {
		//Delete Grants
		List<IM_Grant__c> imGrantsToDelete = new List<IM_Grant__c>();
		List<IM_Budget_Grant__c> budgetGrantsToDelete = new List<IM_Budget_Grant__c>();
        
		//Get all the IMGrants where the child budget grants have zero amounts
		Map<String, IM_Grant__c> allImGrants = new Map<String, IM_Grant__c>(
			[
				SELECT Id, Bgive_Id__c, (SELECT Id FROM Budget_Grant__r WHERE Is_Active__c = TRUE AND Deleted__c = FALSE), (SELECT Id FROM Non_Budget_Grants__r)
				FROM IM_Grant__c
				WHERE Id IN :grantsToDelete.keySet()
				WITH SYSTEM_MODE
			]
		);
		
		//Loop through each IMGrant to determine records to be deleted
		for (IM_Grant__c imGrantRec : allImGrants.values()) {
			Integer totalGrantChildren = imGrantRec.Budget_Grant__r.size() + imGrantRec.Non_Budget_Grants__r.size();
			List<IM_Budget_Grant__c> zeroAmountGrants = grantsToDelete.get(imGrantRec.Id);
			//If the IM Grant is not linked, there will be no possibility of having more than one budget grant.
			//IM Grant will have multiple budget grants in case of amendment
			if (imGrantRec.Bgive_Id__c == '' || imGrantRec.Bgive_Id__c == null) {
				budgetGrantsToDelete.addAll(zeroAmountGrants);
				if (totalGrantChildren == 1) {
					imGrantsToDelete.add(imGrantRec);
				}
			} else {
				//Linked with Bgive
				if (totalGrantChildren > 1 && zeroAmountGrants.size() < totalGrantChildren) {
					budgetGrantsToDelete.addAll(zeroAmountGrants);
				}
			}
		}

		// Soft Delete Budget grants
		if (!budgetGrantsToDelete.isEmpty()) {
			for (IM_Budget_Grant__c budgetGrantRec : budgetGrantsToDelete) {
				budgetGrantRec.Deleted__c = true;
				budgetGrantRec.Budget_Amount_Local__c = 0;
				budgetGrantRec.Budget_Amount_USD__c = 0;
				budgetGrantRec.Confirmed_Budget_Amount_USD__c = 0;
				budgetGrantRec.Confirmed_Budget_Amount_Local__c = 0;
			}
			BBApps_Crud.doUpdate(
				budgetGrantsToDelete
			);
		}

		// Soft Delete IM grants
		if (!imGrantsToDelete.isEmpty()) {
			for (IM_Grant__c imGrantRec : imGrantsToDelete) {
				imGrantRec.Deleted__c = true;
			}
			BBApps_Crud.doUpdate(
				imGrantsToDelete
			);
		}

		newClonedBudOrgIds.clear();
	}

	/**
	 * Description : Method to clone budget grants from the current budget of main initiative and associate to the cloned budget
	 * Parameters  : Accepts IM_Budget__c clonedBudgetRec, String baseInitiativeId
	 * Return Type : void
	 */
	public static void cloneBudgetGrants(IM_Budget__c clonedBudgetRec, String baseInitiativeId) {
		//Variables
		Map<String, List<IM_Budget_Grant__c>> prevBudOrgGrantMap = new Map<String, List<IM_Budget_Grant__c>>();
		IM_Initiative__c baseInitiativeRecord = [
			SELECT Current_Budget__c, Approved_Date__c, Start_Date__c, Open_Amendment__c, Open_Amendment__r.Amendment_Number__c, Open_Amendment__r.End_Date__c,
			Open_Amendment__r.Approved_Date__c
			FROM IM_Initiative__c
			WHERE Id = :baseInitiativeId
			WITH SYSTEM_MODE
		];
		//Update Global Variables
		amendmentNumber = baseInitiativeRecord?.Open_Amendment__r.Amendment_Number__c;
		amendmentId = baseInitiativeRecord?.Open_Amendment__c;
		startDate = baseInitiativeRecord?.Start_Date__c;
		endDate = baseInitiativeRecord?.Open_Amendment__r.End_Date__c;
		approvedDate = baseInitiativeRecord?.Open_Amendment__r.Approved_Date__c;

		//Get the Budget Grants to Clone using the current Budget Id
		//Cloning Budget Grants
		for (IM_Budget_Grant__c budgetGrant : IMUtil.getBudgetGrantsOfCurrBudget(baseInitiativeRecord?.Current_Budget__c)) {
			//Clone Budget Grant
			IM_Budget_Grant__c newClonedBudgetGrant = budgetGrant.clone(false, false, false, false);
			budgetGrant.Budget__c = clonedBudgetRec.Id;
			String uniqueKey = budgetGrant.Budget_Org__c + '_' + budgetGrant.Budget_Org__r.Organization__c + '_' + budgetGrant.Budget_Org__r.Type__c;
			if (!prevBudOrgGrantMap.containsKey(uniqueKey)) {
				prevBudOrgGrantMap.put(uniqueKey, new List<IM_Budget_Grant__c>());
			}
			prevBudOrgGrantMap.get(uniqueKey).add(newClonedBudgetGrant);
		}

		if (!prevBudOrgGrantMap.isEmpty()) {
			compareBudgetOrgs(clonedBudgetRec, prevBudOrgGrantMap);
		} else {
			computeGrants(clonedBudgetRec);
		}
	}

	/**
	 * Description : continue comparision of grants and orgs using previousBudOrgGrantMap
	 * Parameters  : Accepts IM_Budget__c clonedBudgetRec, and Map<String, List<IM_Budget_Grant__c>> prevBudOrgGrantMap
	 * Return Type : void
	 */
	public static void compareBudgetOrgs(IM_Budget__c clonedBudgetRec, Map<String, List<IM_Budget_Grant__c>> prevBudOrgGrantMap) {
		//Variables
		List<IM_Budget_Org__c> newClonedBudOrgsList = new List<IM_Budget_Org__c>();
		List<IM_Budget_Grant__c> newClonedBudGrantsList = new List<IM_Budget_Grant__c>();
		Map<String, Id> amendmentOrgTypeMap = updateAmendmentOrgTypeMap(IMUtil.getBudgetOrgs(clonedBudgetRec.Id), new Map<String, Id>());

		//Compare the previous Budget Orgs and amendment Budget Orgs
		for (String prevBudgetOrg : prevBudOrgGrantMap.keySet()) {
			String orgName = prevBudgetOrg.split('_').get(1);
			String typeValue = prevBudgetOrg.split('_').get(2);
			String uniqueKey = orgName + typeValue;
			if (!amendmentOrgTypeMap.containsKey(uniqueKey)) {
				//This record should be cloned.
				IM_Budget_Org__c newClonedBudgetOrg = new IM_Budget_Org__c();
				newClonedBudgetOrg.Organization__c = orgName;
				newClonedBudgetOrg.Type__c = typeValue;
				newClonedBudgetOrg.Budget__c = clonedBudgetRec.Id;
				newClonedBudOrgsList.add(newClonedBudgetOrg);
			}
		}

		//DML Begin
		BBApps_Crud.doInsert(
			newClonedBudOrgsList
		);
		//Capturing the Id of the clonedBudOrgs
		newClonedBudOrgIds.clear();
		for (IM_Budget_Org__c clonedBudOrg : newClonedBudOrgsList) {
			newClonedBudOrgIds.add(clonedBudOrg.Id);
		}
		//Update the amendmentOrgTypeMap - this will have all the budget orgs for the amendment, including the newly cloned ones above
		amendmentOrgTypeMap.putAll(updateAmendmentOrgTypeMap(newClonedBudOrgsList, amendmentOrgTypeMap));

		//Compare the previous Budget Orgs and amendment Budget Orgs
		for (String prevBudgetOrg : prevBudOrgGrantMap.keySet()) {
			String budgetOrgId = prevBudgetOrg.split('_').get(0);
			String orgName = prevBudgetOrg.split('_').get(1);
			String typeValue = prevBudgetOrg.split('_').get(2);
			String uniqueKey = orgName + typeValue;
			if (amendmentOrgTypeMap.containsKey(uniqueKey)) {
				//Replace the Budget_Org__c reference in the related grant
				for (IM_Budget_Grant__c budGrant : prevBudOrgGrantMap.get(prevBudgetOrg)) {
					budGrant.Budget_Org__c = amendmentOrgTypeMap.get(uniqueKey);
					budGrant.Budget__c = clonedBudgetRec.Id;
					newClonedBudGrantsList.add(budGrant);
				}
			}
		}

		//DML Begin
		BBApps_Crud.doInsert(
			newClonedBudGrantsList
		);
		//Call Compute Grants
		computeGrants(clonedBudgetRec);
	}

	/**
	 * Description : update the amendmentOrgTypeMap based on the budget org list
	 * Parameters  : Accepts List<IM_Budget_Org__c>, Map<String, Id> amendmentOrgTypeMap
	 * Return Type : Map<String, Id> amendmentOrgTypeMap
	 */
	private static Map<String, Id> updateAmendmentOrgTypeMap(List<IM_Budget_Org__c> budgetOrgsList, Map<String, Id> amendmentOrgTypeMap) {
		//Construct a Map of Organization+Type and Budget Org Id
		for (IM_Budget_Org__c budgetOrg : budgetOrgsList) {
			if (!amendmentOrgTypeMap.containsKey(budgetOrg.Organization__c + budgetOrg.Type__c)) {
				amendmentOrgTypeMap.put(budgetOrg.Organization__c + budgetOrg.Type__c, budgetOrg.Id);
            }
        }
		return amendmentOrgTypeMap;
	}

	/**
	 * Description : get all the contentDocLinks with the linkedEntity as amendment, create new links for base Initiative.
	 * Parameters  : Accepts String amendmentId, String baseInitiativeId
	 * Return Type : void
	 */
	public static void insertNewConDocLinks(String amendmentId, String baseInitiativeId) {
		//Get the fileGroup Ids
		String amendmentFileGroupId = FileGroupController.getFileGroup(amendmentId, 'Final Docs', Assets.IM_INITIATIVE);
		String baseInitiativeFileGroupId = FileGroupController.getFileGroup(baseInitiativeId, 'Final Docs', Assets.IM_INITIATIVE);
		//New Con Doc Links List
		List<ContentDocumentLink> newContentDocLinks = new List<ContentDocumentLink>();

		for (ContentDocumentLink conDoc : [
			SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :amendmentFileGroupId
			WITH SYSTEM_MODE
		]) {
			ContentDocumentLink clonedConDoc = new ContentDocumentLink();
			//Updating new LinkedEntity Id to the base Initiative Id
			clonedConDoc.ContentDocumentId = conDoc.ContentDocumentId;
			clonedConDoc.ShareType = conDoc.ShareType;
			clonedConDoc.Visibility = conDoc.Visibility;
			clonedConDoc.LinkedEntityId = baseInitiativeFileGroupId;
			newContentDocLinks.add(clonedConDoc);
		}
		//DML
		BBApps_Crud.doInsert(
			newContentDocLinks
		);
	}
}