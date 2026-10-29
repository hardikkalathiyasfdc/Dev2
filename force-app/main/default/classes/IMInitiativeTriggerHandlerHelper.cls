/**
 * Author            : Gauri Sagane
 * Date              : 08/05/2025
 * Jira              : IM-312
 * Description       : This class is used by Initiaitve Trigger Handler and contains helper methods.
 * Test              : IMParentInitiativeHandlerTest, IMBudgetedInitiativeHandlerTest, IMAmendmentInitiativeHandlerTest
 * ChangeLog         :
 * Paddy - 09/02/2025: IM-359: Added populateIsSyncError method to populate isSyncError field.
 * Gauri - 10/13/2025: Updated populateFocusArea method Focus_Area__c population logic
 * Paddy - 11/10/2025: IM-433: Added populateBgiveURL method to populate Bgive URL.
 * Paddy - 03/16/2026: IM-535: Added "Private Docs" to the fileGroupCategories.
 * Paddy - 04/29/2026: IM-559: Added method createInitiativeRenewals.
 * Paddy - 05/12/2026: IM-532: Added method checkForDeletion.
 * Paddy - 10/09/2026: BRME-7047: Added new fields to createInitiativeRenewals.
 */

public with sharing class IMInitiativeTriggerHandlerHelper {
	private static List<Bgive_Sync_Field_Mapping__mdt> bgiveSyncFieldMap = IMUtil.getBGiveSyncFieldMapList(Assets.IM_INITIATIVE);
	private Set<String> fileGroupCategories = new Set<String>{ 'Strategy', 'Metrics', 'Budget', 'Final Docs', 'Private Docs'};

	public static final String DELETE_ERROR_MESSAGE = 'You do not have sufficient permissions to delete this record.';
	private static final String REVISIONS_NEEDED_NOTIFICATION = 'IM_Initiative_Revisions_Needed';
	private static final String ERR_REVISIONS_NEEDED_NOTIFICATION = 'IMInitiativeTriggerHandlerHelper_REVISIONS_NEEDED_NOTIFICATION_FAILED';
	private static Set<Id> notifiedRevisionsIds = new Set<Id>();
	private static final String INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName()
		.get(Assets.INITIATIVE)
		.getRecordTypeId();

	/**
	 * Sends the revisions notification once per initiative. Sends are per-record because each initiative can have a different Grants Contact.
	 */
	public static void sendRevisionsNeededNotifications(Map<Id, Id> revisionsContactByInitiative) {
		if (revisionsContactByInitiative == null || revisionsContactByInitiative.isEmpty()) {
			return;
		}
		for (Id initiativeId : revisionsContactByInitiative.keySet()) {
			if (notifiedRevisionsIds.contains(initiativeId)) {
				continue;
			}
			notifiedRevisionsIds.add(initiativeId);
			try {
				NotificationService.sendEmail(
					REVISIONS_NEEDED_NOTIFICATION,
					new Set<Id>{ initiativeId },
					revisionsContactByInitiative.get(initiativeId)
				);
			} catch (Exception e) {
				BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_REVISIONS_NEEDED_NOTIFICATION));
			}
		}
	}

	/**
	 * Description : clone strategic locations from the original initiative and tag them to the renewed initiative
	 * Parameters  : Accepts List of strategic locations to clone
	 * Return Type : None
	 */
	public static void cloneStrategicLocations(List<IM_Strategic_Locations__c> strategicLocationsToClone, Map<String, IM_Initiative__c> successfulRenewals) {
		List<IM_Strategic_Locations__c> clonedStrategicLocations = new List<IM_Strategic_Locations__c>();

		//For each initiative, loop through the strategic locations and clone them
		for (IM_Strategic_Locations__c strategicLocation : strategicLocationsToClone) {
			IM_Strategic_Locations__c newClonedStLoc = strategicLocation.clone();
			newClonedStLoc.Initiative__c = (successfulRenewals.get(newClonedStLoc.Initiative__c)).Id;
			clonedStrategicLocations.add(newClonedStLoc);
		}

		//If clonedStrategicLocations is not empty, perform a DML insert
		if (!clonedStrategicLocations.isEmpty()) {
			insert as system clonedStrategicLocations;
		}
	}

	/**
	 * Description : Create File Group record for each category for the Initiative record
	 * Parameters  : initiative IM_Initiative__c
	 * Return Type : void
	 */
	public void processFileGroups(IM_Initiative__c initiative, List<File_Group__c> fileGroupsToInsert) {
		for (String category : fileGroupCategories) {
			fileGroupsToInsert.add(new File_Group__c(Parent_Initiative__c = initiative.Id, Object_Type__c = Assets.INITIATIVE, Category__c = category));
		}
	}

	//Process new FoundationCode after insert of initiative for Parent Initiative recordType
	public void processFoundationCodes(Set<Id> fcCreateInitiativeIds, Set<Id> fcCreateFocusAreaIds) {
		Map<String, Foundation_Code__c> newFCByInitiativeIds = new Map<String, Foundation_Code__c>();
		Map<String, String> foundationCodeIdsByFocusArea = new Map<String, String>();
		Map<String, IM_Initiative__c> initiatives = new Map<String, IM_Initiative__c>(
			[
				SELECT Name, RecordType.Name, Parent_Initiative__c, Parent_Initiative__r.Foundation_Code__c, Focus_Area__c
				FROM IM_Initiative__c
				WHERE Id IN :fcCreateInitiativeIds
				WITH SYSTEM_MODE
			]
		);
		for (Foundation_Code__c fc : [
			SELECT Focus_Area__c
			FROM Foundation_Code__c
			WHERE Type__c = :Assets.FOCUS_AREA AND Focus_Area__c IN :fcCreateFocusAreaIds
			WITH SYSTEM_MODE
		]) {
			foundationCodeIdsByFocusArea.put(fc.Focus_Area__c, fc.Id);
		}

		List<Foundation_Code__c> foundationCodesToInsert = new List<Foundation_Code__c>();
		for (IM_Initiative__c initiative : initiatives.values()) {
			Foundation_Code__c foundationCode = new Foundation_Code__c(
				Name = initiative.Name,
				Enabled_for_Grants__c = true,
				Foundation_Code__c = initiative.Name,
				System_Triggered__c = true,
				Type__c = initiative.RecordType.Name,
				Initiative__c = initiative.Id
			);
			if (String.isBlank(initiative.Parent_Initiative__c)) {
				foundationCode.Parent__c = foundationCodeIdsByFocusArea.get(initiative.Focus_Area__c);
			} else {
				foundationCode.Parent__c = initiative.Parent_Initiative__r.Foundation_Code__c;
			}
			foundationCodesToInsert.add(foundationCode);
			newFCByInitiativeIds.put(initiative.Id, foundationCode);
		}
		insert as system foundationCodesToInsert;
		fcCreateInitiativeIds.clear();
		if (!newFCByInitiativeIds.isEmpty()) {
			updateInitiatives(newFCByInitiativeIds, initiatives);
		}
	}

	private void updateInitiatives(Map<String, Foundation_Code__c> fcByInitiativeIds, Map<String, IM_Initiative__c> initiatives) {
		for (String initiativeId : fcByInitiativeIds.keySet()) {
			IM_Initiative__c initiative = initiatives.get(initiativeId);
			if (Assets.BUDGET_INITIATIVE == initiative.RecordType.Name) {
				initiative.Parent_Initiative__c = null;
			}
			initiative.Foundation_Code__c = fcByInitiativeIds.get(initiativeId).Id;
		}
		update as system initiatives.values();
	}

	/**
	 * Description : Method to check if selected user is linked to BGive
	 * Parameters : initiative IM_Initiative__c
	 * Return Type : void
	 */
	public void getAssociatedUsers(List<IM_Initiative__c> newInitiatives, Map<Id, Contact> userContactMap) {
		Set<Id> userIds = new Set<Id>();
		if (newInitiatives != null && !newInitiatives.isEmpty()) {
			for (IM_Initiative__c initiative : newInitiatives) {
				if (initiative.Program_Contact__c != null)
					userIds.add(initiative.Program_Contact__c);
				if (initiative.Grants_Team_Contact__c != null)
					userIds.add(initiative.Grants_Team_Contact__c);
			}
		}
		if (!userIds.isEmpty()) {
			for (Contact con : [SELECT Id, BRM_User__c, Bgive_Id__c FROM Contact WHERE BRM_User__c IN :userIds WITH SYSTEM_MODE]) {
				userContactMap.put(con.BRM_User__c, con);
			}
		}
	}

	/**
	 * Description : Method to check if selected user is linked to BGive
	 * Parameters : initiative IM_Initiative__c
	 * Return Type : void
	 */
	public void validateUserLinkStatus(IM_Initiative__c initiative, Map<Id, Contact> userContactMap) {
		if (initiative.Program_Contact__c != null) {
			checkStatus(initiative, 'Program_Contact__c', userContactMap);
		}
		if (initiative.Grants_Team_Contact__c != null) {
			checkStatus(initiative, 'Grants_Team_Contact__c', userContactMap);
		}
	}

	/**
	 * Description : Method to check if selected user is linked to BGive
	 * Parameters : initiative IM_Initiative__c, fieldName String
	 * Return Type : void
	 */
	public void checkStatus(IM_Initiative__c initiative, String fieldName, Map<Id, Contact> userContactMap) {
		if (initiative.get(fieldName) != null) {
			if (
				userContactMap.get((Id) initiative.get(fieldName))?.Bgive_Id__c == null ||
				userContactMap.get((Id) initiative.get(fieldName))?.Bgive_Id__c == ''
			) {
				if (fieldName == 'Program_Contact__c') {
					initiative.addError('Selected Program Contact is not linked with Bgive user. Please select another user.');
				} else {
					initiative.addError('Selected Grants Team Contact is not linked with Bgive user. Please select another user.');
				}
			}
		}
	}

	/**
	 * Description : IM-103 Method to assign Focus Area lookup value based on Team's Focus Area before approval
	 * Parameters  : None
	 * Return Type : void
	 */
	public void populateFocusArea(List<IM_Initiative__c> newInitiatives) {
		Set<Id> teamIds = new Set<Id>();
		if (newInitiatives != null && !newInitiatives.isEmpty()) {
			//duplicate code for loop, need to optimize
			for (IM_Initiative__c initiative : newInitiatives) {
				teamIds.add(initiative.Team__c);
			}
		}
		if (!teamIds.isEmpty()) {
			Map<Id, Team__c> teams = new Map<Id, Team__c>([SELECT Focus_Area__c FROM Team__c WHERE Id IN :teamIds WITH SYSTEM_MODE]);
			for (IM_Initiative__c initiative : newInitiatives) {
				if (teams.containsKey(initiative.Team__c)) {
					initiative.Focus_Area__c = ((Team__c) teams.get(initiative.Team__c))?.Focus_Area__c ?? initiative.Focus_Area__c;
				}
			}
		}
	}

	/**
	 * Description : IM-310 Method to assign Segment lookup value to BFF, if not already populated.
	 * Parameters  : List of newInitiatives
	 * Return Type : void
	 */
	public void populateSegment(List<IM_Initiative__c> newInitiatives) {
		Segment__c segmentRec = [SELECT Id FROM Segment__c WHERE Name = :Assets.BFF WITH SYSTEM_MODE];
		//Populate the Segment Record id - Bloomberg Family Foundation - If Segment value is not populated already
		//For Amendment, the segment is copied from the budgeted initiative.. no need to populate here
		if (newInitiatives != null && !newInitiatives.isEmpty()) {
			for (IM_Initiative__c initiative : newInitiatives) {
				if (
					initiative.Segment__c == null &&
					initiative.RecordType.Name != Assets.FOCUS_AREA_MISC_TYPE &&
					initiative.RecordType.Name != Assets.AMENDMENT
				) {
					initiative.Segment__c = segmentRec.Id;
				}
			}
		}
	}

	/**
	 * Description : Method to check if the Initiative is of type Renewal
	 * Parameters  : iniativeType String
	 * Return Type : Boolean
	 */
	public Boolean isRenewal(String initiativeType) {
		return Assets.RENEWAL.equalsIgnoreCase(initiativeType);
	}

	/**
	 * Description : Method to check if the Initiative is declined
	 * Parameters  : initiativeStatus String
	 * Return Type : Boolean
	 */
	public Boolean isDeclined(String initiativeStatus) {
		return Assets.DECLINED.equalsIgnoreCase(initiativeStatus);
	}

	/**
	 * Description : Method to check if any of the sync fields are changed
	 * Parameters  : oldInitiative IM_Initiative__c, newInitiative IM_Initiative__c
	 * Return Type : Boolean
	 */
	public Boolean isSyncFieldChanged(IM_Initiative__c oldInitiative, IM_Initiative__c newInitiative) {
		//Check if any of the sync fields changed
		Boolean syncFieldChanged = false;
		for (Bgive_Sync_Field_Mapping__mdt syncFieldMapping : bgiveSyncFieldMap) {
			if (syncFieldMapping.BRM_Field__c != null) {
				if (!syncFieldMapping.BRM_Field__c.contains('__r') && !syncFieldMapping.BRM_Field__c.contains(';') && syncFieldMapping.BRM_Field__c != 'Id') {
					syncFieldChanged = isFieldChanged(oldInitiative, newInitiative, syncFieldMapping.BRM_Field__c);
					if (syncFieldChanged) {
						break;
					}
				} else if (syncFieldMapping.BRM_Field__c.contains('__r') && syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_VALUE) {
					String actualField = syncFieldMapping.BRM_Field__c.replace('__r', '__c');
					String fieldName = actualField.split('\\.').get(0);
					if (fieldName != Assets.FOUNDATION_CODE_API_NAME) {
						syncFieldChanged = isFieldChanged(oldInitiative, newInitiative, fieldName);
						if (syncFieldChanged) {
							break;
						}
					}
				}
			}
		}
		return syncFieldChanged;
	}

	/**
	 * Description : Method to check if old and new values of field don't match
	 * Parameters  : oldInitiative IM_Initiative__c, newInitiative IM_Initiative__c, fieldName String
	 * Return Type : Boolean
	 */
	private Boolean isFieldChanged(IM_Initiative__c oldInitiative, IM_Initiative__c newInitiative, String fieldName) {
		Object oldFieldValue = oldInitiative.get(fieldName);
		Object newFieldValue = newInitiative.get(fieldName);
		if (oldFieldValue == null && newFieldValue == null) {
			return false;
		} else if (oldFieldValue == null && newFieldValue != null) {
			return true;
		} else {
			return !oldFieldValue.equals(newFieldValue);
		}
	}

	/**
	 * Description : Method to update Current Budget's Status to Approved when Initiative is approved (for budgeted/amendment initiative).
	 * Parameters : isComputeGrants Boolean, approvedCurrentBudgetedIds Set<Id>
	 * Return Type : void
	 */
	public static void updateCurrentBudgetStatus(Boolean isComputeGrants, Set<Id> approvedCurrentBudgetedIds) {
        if (!approvedCurrentBudgetedIds.isEmpty()) {
			List<IM_Budget__c> currentBudgets = new List<IM_Budget__c>();
			//Budgeted Initiative/Amendment Initiative - Budget Status
			for (String budgetId : approvedCurrentBudgetedIds) {
				currentBudgets.add(new IM_Budget__c(Id = budgetId, Status__c = Assets.APPROVED));
			}
			//Computing Grants for Budgeted Initiative - Budget
			if (isComputeGrants) {
				isComputeGrants = false;
				IMService.computeGrants(approvedCurrentBudgetedIds);
			}
			update as system currentBudgets;
		}
	}

	//When the type is Renewal update the parent field to - Renewal of -> Foundation Code -> Parent -> Initiative
	public String updateRenewalParent(String renewalOf) {
		String parent = '';
		IM_Initiative__c parentInitiative = [
			SELECT Id, Foundation_Code__r.Parent__r.Initiative__c
			FROM IM_Initiative__c
			WHERE Id = :renewalOf
			WITH SYSTEM_MODE
		] ?? null;
		if (parentInitiative != null) {
			parent = parentInitiative.Foundation_Code__r.Parent__r.Initiative__c ?? null;
		}
		return parent;
	}

	/**
	 * Description : IM-104 Method to validate for multiple active renewal initiatives.
	 * Parameters  : List<IM_Initiative__c> initiatives, Set<Id> renewalOfIds
	 * Return Type : void
	 */
	public static void validateMultipleRenewals(List<IM_Initiative__c> initiatives, Set<Id> renewalOfIds, Map<String, IM_Initiative__c> successfulRenewals) {
		Set<Id> activeRenewalIds = new Set<Id>();
		for (IM_Initiative__c initiative : IMUtil.getInitiativesByRenewalIds(renewalOfIds)) {
			activeRenewalIds.add(initiative.Renewal_of__c);
		}

		for (IM_Initiative__c initiative : initiatives) {
			if (activeRenewalIds.contains(initiative.Renewal_of__c)) {
				initiative.addError(Assets.MULTIPLE_ACTIVE_RENEWAL);
			} else {
				successfulRenewals.put(initiative.Renewal_of__c, initiative);
			}
		}
	}

	/**
	 * Description : Method to clone Budget from the Amendment to the main Initiative
	 * Parameters  : None
	 * Return Type : void
	 */
	public static void cloneAmendmentCurrentBudget(Boolean cloneAmendmentBudRun, Map<Id, String> apprvdAmendmentBudgetMap) {
		if (!cloneAmendmentBudRun) {
			if (!apprvdAmendmentBudgetMap.isEmpty()) {
				for (Id currentBudgetId : apprvdAmendmentBudgetMap.keySet()) {
					IM_Budget__c clonedBudget = IMClone.cloneBudget(currentBudgetId, apprvdAmendmentBudgetMap.get(currentBudgetId), Assets.AMENDMENT_APPROVAL, null);
					//Clone Budget Grants from Main Initiative current Budget, and associate to the clonedBudget
					String baseInitiativeId = apprvdAmendmentBudgetMap.get(currentBudgetId);
					apprvdAmendmentBudgetMap.clear();
					cloneAmendmentBudRun = true;
					IMService.cloneBudgetGrants(clonedBudget, baseInitiativeId);
				}
			}
		}
	}

	/**
	 * Modified By : Gauri (IM-304: changed from clearOpenAmendments to updateMainInitiative)
	 * Description : Method to update main initiative to update partner funds and clear Open Amendment for AmendmentOf initiative.
	 * Parameters  : None
	 * Return Type : void
	 */
	public void updateMainInitiative(Set<Id> amendmentOfInitiativeIds, Map<Id, IM_Initiative__c> initiativeToAmendmentMap) {
		List<IM_Initiative__c> mainInitiatives = new List<IM_Initiative__c>();
		IMInitiativeTriggerHandlerHelper helper = new IMInitiativeTriggerHandlerHelper();
		for (Id initiativeId : amendmentOfInitiativeIds) {
			if (initiativeToAmendmentMap.get(initiativeId) != null) {
				mainInitiatives.add(
					new IM_Initiative__c(
						Id = initiativeId,
						Open_Amendment__c = null,
						Partner_Funds__c = initiativeToAmendmentMap.get(initiativeId)?.Partner_Funds__c,
						Partner_Funding_Type__c = initiativeToAmendmentMap.get(initiativeId)?.Partner_Funding_Type__c
					)
				);
			} else {
				mainInitiatives.add(new IM_Initiative__c(Id = initiativeId, Open_Amendment__c = null));
			}
		}
		update as system mainInitiatives;
	}

	/**
	 * Description : IM-315 Method to create the Approval records for the Initiative.
	 * Parameters  : None
	 * Return Type : void
	 */
	public void processApprovals(List<IM_Initiative__c> initiatives) {
		List<IM_Approval__c> approvals = new List<IM_Approval__c>();
		for (IM_Initiative__c initiative : initiatives) {
			approvals.add(
				new IM_Approval__c(
					Initiative__c = initiative.Id,
					Approval_Date__c = initiative.Approved_Date__c,
					Approved_Amount_Term__c = initiative.Amount_Term__c,
					Is_Final_Approval__c = true,
					Approver__c = initiative.Approver__c
				)
			);
		}
		insert as system approvals;
	}

	/**
	 * Description : BRME-6859: Method to create Org Associations using the strategic locations on Initiative.
	 * Parameters  : None
	 * Return Type : void
	 */
	public void processStrategicLocations(Map<Id, IM_Initiative__c> initiativeMap, Map<Id, Id> associationsByInitiative) {
		Map<Id, IM_Strategic_Locations__c> strategicLocations = IMUtil.getStrategicLocations(initiativeMap.keySet());
		ID jobID = System.enqueueJob(new OrgAssociationComputationQueueable(strategicLocations, associationsByInitiative));
	}

	//Populate isSyncError based on SyncError field value..
	public void populateIsSyncError(IM_Initiative__c newInitiative, IM_Initiative__c oldInitiative) {
		if (oldInitiative != null && String.isBlank(oldInitiative.Sync_Error__c) && String.isNotBlank(newInitiative.Sync_Error__c)) {
			newInitiative.Is_Sync_Error__c = true;
		} else if (oldInitiative != null && String.isNotBlank(oldInitiative.Sync_Error__c) && String.isBlank(newInitiative.Sync_Error__c)) {
			newInitiative.Is_Sync_Error__c = false;
		}
	}

	//Populate Bgive URL field value based on Fluxx base URL and Bgive Id..
	public void populateBgiveURL(IM_Initiative__c newInitiative) {
		newInitiative.Bgive_URL__c = String.isNotBlank(newInitiative.Bgive_Id__c) 
			? Environment.getBgiveBaseUrl() + '/show/concept_initiatives/' + newInitiative.Bgive_Id__c : null;
	}

	/**
	* Description     : Method to create Renewal Initiatives.
	* Parameters      : List<IM_Initiative__c> initiatives
	* Return Type     : void
	*/
	public void createInitiativeRenewals(List<IM_Initiative__c> initiatives) {
		List<IM_Initiative__c> renewals = new List<IM_Initiative__c>();
		for (IM_Initiative__c initiative : initiatives) {
			renewals.add(new IM_Initiative__c(RecordTypeId = initiative.RecordTypeId,
				Name = initiative.Name + ' ' + Assets.RENEWAL, Team__c = initiative.Team__c,
				Focus_Area__c = initiative.Focus_Area__c,
				Start_Date__c = initiative.End_Date__c.addDays(1),
				Program_Contact__c = initiative.Program_Contact__c,
				Status__c = Assets.IN_DEVELOPMENT, Initiative_Type__c = Assets.RENEWAL,
				CityView_Initiative__c = initiative.CityView_Initiative__c,
				Locations_Tracked_As__c = initiative.Locations_Tracked_As__c,
				Proposed_CityView_Name__c = initiative.Proposed_CityView_Name__c,
				Proposed_CityView_Description__c = initiative.Proposed_CityView_Description__c,
				Renewal_of__c = initiative.Id));
		}
		insert as system renewals;
	}

	/**
	* Description     : Method to prevent deletion.
	* Parameters      : IM_Initiative__c initiative
	* Return Type     : void
	*/
	public void checkForDeletion(IM_Initiative__c initiative) {
		if(initiative.Status__c != Assets.DRAFT) {
			initiative.addError(DELETE_ERROR_MESSAGE);
		}
	}
}