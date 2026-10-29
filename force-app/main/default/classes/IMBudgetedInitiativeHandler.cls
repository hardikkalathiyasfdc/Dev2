/**
 * Author            : Gauri Sagane
 * Date              : 08/18/2025
 * Jira              : IM-312
 * Description       : This is the handler class for Budgeted Initiative RecordType of Initiative object
 * Test              : IMBudgetedInitiativeHandlerTest
 * ChangeLog         :
 * Paddy - 09/02/2025: IM-359: Added logic to call populateIsSyncError method.
 * Paddy - 11/10/2025: IM-433: Added logic to call populateBgiveURL method.
 * Paddy - 12/01/2025: IM-448: Added logic to change owner "IM Owner" to when status is changed to completed.
 * Paddy - 12/24/2025: IM-474: Added logic to execute only once per record per transaction to avoid recursion
 *                             when Start Date is changed for the approved Initiative.
 * Paddy - 01/23/2026: IM-492: Added logic to remove RenewalOf when Type is changed from Renewal.
 * Paddy - 02/17/2026: IM-506: Added logic to call sync only when Approved = true.
 * Paddy - 02/23/2026: IM-516: Added logic to populate Original Approved Date and End Date fields.
 * Paddy - 04/29/2026: IM-559: Added logice to create Renewals when Budgeted Initiative is approved.
 * Paddy - 05/12/2026: IM-532: Added logic to prevent deletion.
 * Gauri - 10/25/2026: BRME-7044: Added logic to send email on Initiative Approval.
 */
public with sharing class IMBudgetedInitiativeHandler extends TriggerHandler {
	public List<SObject> newInitiatives;
	public List<SObject> oldInitiatives;
	public Map<Id, SObject> oldMap;
	public Map<Id, SObject> newMap; 

	private static List<IM_Strategic_Locations__c> strategicLocationsToClone = new List<IM_Strategic_Locations__c>();
	private static List<Foundation_Code__c> foundationCodesToUpdate = new List<Foundation_Code__c>();
	private static List<IM_Initiative__c> initiativesToCreateProjections = new List<IM_Initiative__c>();
	private List<File_Group__c> fileGroupsToInsert = new List<File_Group__c>();
	private List<IM_Initiative__c> approvedInitiatives = new List<IM_Initiative__c>();
	private Map<Id, IM_Initiative__c> approvedCityViewInitiatives = new Map<Id, IM_Initiative__c>();
	private Map<Id, IM_Initiative__c> approvedInitiativesRenewal = new Map<Id, IM_Initiative__c>();
	private static Map<Id, IM_Initiative__c> approvedInitiativesForBPDates = new Map<Id, IM_Initiative__c>();
	private static Map<String, IM_Initiative__c> successfulRenewals = new Map<String, IM_Initiative__c>();
	private Map<Id, Contact> userContactMap = new Map<Id, Contact>();
	private Map<Id, Id> associationsByInitiative = new Map<Id, Id>();
	private static Set<Id> projDeleteInitiativeIds = new Set<Id>();
	private static Set<Id> fcCreateInitiativeIds = new Set<Id>();
	private static Set<Id> fcUpdateInitiativeIds = new Set<Id>();
	private Set<Id> initiativeIdSet = new Set<Id>();
	private Set<Id> currentBudgetIds = new Set<Id>();
	private Set<Id> oldCurrentBudgetIds = new Set<Id>();
	private static Set<Id> approvedCurrentBudgetedIds = new Set<Id>();
	private static Boolean isComputeGrants = true;
	private static Boolean isApprovalCreated = false;
	private static Boolean isProjectionsCreated = false;
    private static Boolean isEndDateUpdate = false;
	private static final String READY_FOR_APPROVAL_NOTIFICATION = 'IM_Budget_Initiative_Ready_for_Approval';
	private static final String ERR_READY_FOR_APPROVAL_NOTIFICATION = 'IMBudgetedInitiativeHandler_READY_FOR_APPROVAL_NOTIFICATION_FAILED';
	private static Set<Id> notifiedReadyForApprovalIds = new Set<Id>();
	private Set<Id> readyForApprovalIds = new Set<Id>();
	// BRME-7045: Store the Grants Contact for the shared revisions notification helper.
	private Map<Id, Id> revisionsContactByInitiative = new Map<Id, Id>();
	private static final String INITIATIVE_APPROVAL_NOTIFICATION = 'IM_Budgeted_Initiative_Approval';
	private Set<Id> approvedInitiativeIds = new Set<Id>();

	private IMInitiativeTriggerHandlerHelper helper = new IMInitiativeTriggerHandlerHelper();

	public IMBudgetedInitiativeHandler() {
		super(
			new Map<Schema.SObjectField, List<Object>>{
				IM_Initiative__c.RecordTypeId.getDescribe().getSObjectField() => new List<Object>{
					Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get(Assets.BUDGET_INITIATIVE).getRecordTypeId()
				}
			}
		);

		newInitiatives = this.getNewRecords();
		oldInitiatives = this.getOldRecords();
		oldMap = this.getOldRecordMap();
		newMap = this.getNewRecordMap();
	}

	public override void bulkBefore() {
		List<IM_Initiative__c> renewalInitiatives = new List<IM_Initiative__c>();
		Set<Id> renewalOfIds = new Set<Id>();
		if (Trigger.isInsert) {
			// Check if users are b-linked
			helper.getAssociatedUsers(newInitiatives, userContactMap);

			helper.populateFocusArea(newInitiatives);
			helper.populateSegment(newInitiatives);

			// For initiatives of type renewal
			for (IM_Initiative__c initiative : (List<IM_Initiative__c>) newInitiatives) {
				if (helper.isRenewal(initiative.Initiative_Type__c) && !helper.isDeclined(initiative.Status__c)) {
					renewalInitiatives.add(initiative);
					renewalOfIds.add(initiative.Renewal_of__c);
				}
			}
		} else if (Trigger.isUpdate) {
			helper.getAssociatedUsers(newInitiatives, userContactMap);
			Map<Id, IM_Initiative__c> initiativesTeamUpdated = new Map<Id, IM_Initiative__c>();
			for (IM_Initiative__c initiative : (List<IM_Initiative__c>) newInitiatives) {
				if (isFieldChanged(initiative, Assets.TEAM)) {
					initiativesTeamUpdated.put(initiative.Id, initiative);
				}
				if ((isFieldChanged(initiative, Assets.RENEWAL_OF)) && helper.isRenewal(initiative.Initiative_Type__c)) {
					renewalInitiatives.add(initiative);
					renewalOfIds.add(initiative.Renewal_of__c);
				}
			}
			// Not updating team if Initiative is laready approved (i.e. Foundation Code is created)
			if (!initiativesTeamUpdated.isEmpty()) {
				List<Foundation_Code__c> fCodes = [SELECT Initiative__c FROM Foundation_Code__c 
													WHERE Initiative__c IN :initiativesTeamUpdated.keySet() 
													WITH SYSTEM_MODE];
				for (Foundation_Code__c fCode : fCodes) {
					if (initiativesTeamUpdated.containsKey(fCode.Initiative__c)) {
						initiativesTeamUpdated.remove(fCode.Initiative__c);
					}
				}
				helper.populateFocusArea(initiativesTeamUpdated.values());
			}
		}

		// Check if only one active renewal on an initiative
		if (!renewalInitiatives.isEmpty()) {
			IMInitiativeTriggerHandlerHelper.validateMultipleRenewals(renewalInitiatives, renewalOfIds, successfulRenewals);
		}
	}

	public override void beforeInsert(SObject so) {
		IM_Initiative__c initiative = (IM_Initiative__c) so;

		// check if the users on initiative are linked to bgive
		helper.validateUserLinkStatus(initiative, userContactMap);

		//Type is Renewal
		if (initiative.Initiative_Type__c == 'Renewal') {
			initiative.Parent_Initiative__c = helper.updateRenewalParent(initiative.Renewal_of__c);
		}

		if(initiative.Bgive_Id__c != null) {
			helper.populateBgiveURL(initiative);
		}
	}

	public override void beforeUpdate(SObject oldSo, SObject so) {
		IM_Initiative__c newInitiative = (IM_Initiative__c) so;
		IM_Initiative__c oldInitiative = (IM_Initiative__c) oldSo;

		// check if the users on initiaitve are linked to bgive
		if (isFieldChanged(newInitiative, 'Program_Contact__c') || isFieldChanged(newInitiative, 'Grants_Team_Contact__c')) {
			helper.validateUserLinkStatus(newInitiative, userContactMap);
		}

		//Check fof SyncError
		helper.populateIsSyncError(newInitiative, oldInitiative);

		//Process projections based on include in Projections, start date, end date, term years and proposed amount
		if (
			!isProjectionsCreated && isFieldChanged(newInitiative, 'Include_in_Projections__c') ||
			(isFieldChanged(newInitiative, 'Proposed_Amount__c') ||
			isFieldChanged(newInitiative, 'Term_Years__c') ||
			isFieldChanged(newInitiative, 'Start_Date__c') ||
			isFieldChanged(newInitiative, 'End_Date__c'))
		) {
			projDeleteInitiativeIds.add(newInitiative.Id);
			if (newInitiative.Include_in_Projections__c && !initiativesToCreateProjections.contains(newInitiative)) {
				isProjectionsCreated = true;
				initiativesToCreateProjections.add(newInitiative);
			}
		}

		// Change name of corresponding foundation code as well
		if (isFieldChanged(newInitiative, 'Name')) {
			fcUpdateInitiativeIds.add(newInitiative.Id);
		}

		//Budgeted Initiative or Amendment is Approved.
		if (isFieldChanged(newInitiative, Assets.APPROVED_FIELD) && newInitiative.Approved__c) {
			newInitiative.Original_Approved_Amount__c = newInitiative.Approved_Amount__c;
			newInitiative.Original_Approved_Date__c = newInitiative.Approved_Date__c;
			newInitiative.Original_End_Date__c = newInitiative.End_Date__c;
			approvedCurrentBudgetedIds.add(newInitiative.Current_Budget__c);
			if (newInitiative.Parent_Initiative__c != null) {
				fcCreateInitiativeIds.add(newInitiative.Id);
			} else {
				newInitiative.addError('Please select Parent Initiative for the current Initiative.');
			}
		}
		if (isFieldChanged(newInitiative, Assets.START_DATE) && newInitiative.Approved__c && !isFieldChanged(newInitiative, Assets.APPROVED_FIELD)
           				&& !isEndDateUpdate) {
			if (oldInitiative.Start_Date__c != null && newInitiative.End_Date__c != null) {
                isEndDateUpdate = true;
				newInitiative.End_Date__c = newInitiative.End_Date__c.addDays(oldInitiative.Start_Date__c.daysBetween(newInitiative.Start_Date__c));
			}
		}

		if(isFieldChanged(newInitiative, Assets.BGIVE_ID)) {
			helper.populateBgiveURL(newInitiative);
		}
		if(isFieldChanged(newInitiative, Assets.INITIATIVE_TYPE)
				&& Assets.RENEWAL.equalsIgnoreCase(oldInitiative.Initiative_Type__c)) {
			newInitiative.Renewal_of__c = null;
		}
	}

	public override void bulkAfter() {
		if (Trigger.isUpdate) {
			if (!fcUpdateInitiativeIds.isEmpty()) {
				//process Foundation codes
				//IM-393: No need to run the query if fcUpdateInitiativeIds is Empty
				List<Foundation_Code__c> foundationCodes = [
					SELECT Name, Foundation_Code__c, Initiative__c
					FROM Foundation_Code__c
					WHERE Initiative__c IN :fcUpdateInitiativeIds
					WITH SYSTEM_MODE
				];
				for (Foundation_Code__c fc : foundationCodes) {
					String foundationCodeNewName = ((IM_Initiative__c) newMap.get(fc.Initiative__c))?.Name;
					if (fc.Name != foundationCodeNewName) {
						fc.Name = foundationCodeNewName;
						fc.Foundation_Code__c = foundationCodeNewName;
						foundationCodesToUpdate.add(fc);
					}
				}
			}
		}
	}

	public override void afterInsert(SObject so) {
		IM_Initiative__c initiative = (IM_Initiative__c) so;
		if (initiative != null) {
			helper.processFileGroups(initiative, fileGroupsToInsert);
			if (initiative.Current_Budget__c != null) {
				currentBudgetIds.add(initiative.Current_Budget__c);
			}

			if (initiative.Include_in_Projections__c) {
				initiativesToCreateProjections.add(initiative);
			}
		}
	}

	public override void afterUpdate(SObject oldSo, SObject so) {
		IM_Initiative__c newInitiative = (IM_Initiative__c) so;
		IM_Initiative__c oldInitiative = (IM_Initiative__c) oldSo;
		//Check if the initiative record is final approved and approved checkbox is TRUE - call Bgive to create conce
		if (
			!isApprovalCreated &&
			isFieldChanged(newInitiative, Assets.APPROVED_FIELD) &&
			newInitiative.Approved__c == true &&
			oldInitiative.Approved__c == false
		) {
			isApprovalCreated = true;
			approvedInitiatives.add(newInitiative);
			approvedInitiativeIds.add(newInitiative.Id);
			if(newInitiative.CityView_Initiative__c != null){
				approvedCityViewInitiatives.put(newInitiative.Id, newInitiative);
			}
			if (newInitiative.Current_Budget__c != null) {
				approvedInitiativesForBPDates.put(newInitiative.Id, newInitiative);
			}
			if (String.isBlank(newInitiative.Bgive_Id__c) && (!initiativeIdSet.contains(newInitiative.Id))) {
				initiativeIdSet.add(newInitiative.Id);
			}
		}
		if (isFieldChanged(newInitiative, Assets.START_DATE) && newInitiative.Approved__c == true && newInitiative.Current_Budget__c != null) {
			approvedInitiativesForBPDates.put(newInitiative.Id, newInitiative);
		}
		if (isFieldChanged(newInitiative, Assets.CURRENT_BUDGET_FIELD)) {
			if (newInitiative.Current_Budget__c != null) {
				currentBudgetIds.add(newInitiative.Current_Budget__c);
			}
			if (oldInitiative.Current_Budget__c != null) {
				oldCurrentBudgetIds.add(oldInitiative.Current_Budget__c);
			}
		}

		//Final Approved Initiative is updated - update the BGive Concept initiative to reflect the update in BRM
		if (newInitiative.Approved__c == true && helper.isSyncFieldChanged(oldInitiative, newInitiative)) {
				initiativeIdSet.add(newInitiative.Id);
		}

		if (isFieldChanged(newInitiative, Assets.APPROVED_FIELD) && newInitiative.Approved__c) {
			approvedInitiativesRenewal.put(newInitiative.Id, newInitiative);
		}

		if(isFieldChanged(newInitiative, Assets.CITYVIEW_INITIATIVE) && newInitiative.Approved__c && newInitiative.CityView_Initiative__c != null){
			approvedCityViewInitiatives.put(newInitiative.Id, newInitiative);
			if(oldInitiative.CityView_Initiative__c != null){
				associationsByInitiative.put(oldInitiative.Id, oldInitiative.CityView_Initiative__c);
			}
		}

		if (isFieldChanged(newInitiative, Assets.STATUS) && Assets.READY_FOR_APPROVAL.equals(newInitiative.Status__c)
				&& !notifiedReadyForApprovalIds.contains(newInitiative.Id)) {
			readyForApprovalIds.add(newInitiative.Id);
		}

		// BRME-7045: Budgeted Initiatives notify their Grants Contact when sent back for revisions.
		if (isFieldChanged(newInitiative, Assets.STATUS)
				&& Assets.READY_FOR_APPROVAL.equals(oldInitiative.Status__c)
				&& Assets.IN_DEVELOPMENT.equals(newInitiative.Status__c)
				&& String.isNotBlank(newInitiative.Grants_Team_Contact__c)) {
			revisionsContactByInitiative.put(newInitiative.Id, newInitiative.Grants_Team_Contact__c);
		}
	}

	public override void beforeDelete(SObject so) {
		IM_Initiative__c initiative = (IM_Initiative__c) so;
		helper.checkForDeletion(initiative);
	}

	public override void andFinally() {
		if (Trigger.isAfter) {
			helper.processFoundationCodes(fcCreateInitiativeIds, new Set<Id>());
			if (Trigger.isInsert) {
				insert as system fileGroupsToInsert;
			} else if (Trigger.isUpdate) {
				IMInitiativeTriggerHandlerHelper.updateCurrentBudgetStatus(isComputeGrants, approvedCurrentBudgetedIds);

				if (!projDeleteInitiativeIds.isEmpty()) {
					IMProjections.remove(projDeleteInitiativeIds);
				}

				update as system foundationCodesToUpdate;

				// Sync with bgive
				if (!initiativeIdSet.isEmpty()) {
					Database.executeBatch(new BatchIMInitiativeSync(initiativeIdSet), 1);
				}
				if (!approvedInitiativesForBPDates.isEmpty()) {
					IMBudgetPeriodHelper.setDates(approvedInitiativesForBPDates);
				}
				if (!approvedInitiatives.isEmpty()) {
					helper.processApprovals(approvedInitiatives);
				}
				if(!approvedCityViewInitiatives.isEmpty()){
					helper.processStrategicLocations(approvedCityViewInitiatives, associationsByInitiative);
				}
				if(!approvedInitiativesRenewal.isEmpty()) {
					helper.createInitiativeRenewals(approvedInitiativesRenewal.values());
				}
				if(!approvedInitiativeIds.isEmpty()) {
					NotificationService.sendEmail(INITIATIVE_APPROVAL_NOTIFICATION, approvedInitiativeIds);
				}
				if (!readyForApprovalIds.isEmpty()) {
					try {
						notifiedReadyForApprovalIds.addAll(readyForApprovalIds);
						NotificationService.sendEmail(READY_FOR_APPROVAL_NOTIFICATION, readyForApprovalIds);
					} catch (Exception e) {
						BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_READY_FOR_APPROVAL_NOTIFICATION));
					}
				}
				IMInitiativeTriggerHandlerHelper.sendRevisionsNeededNotifications(revisionsContactByInitiative);
			}
			if (!initiativesToCreateProjections.isEmpty()) {
				IMProjections.create(initiativesToCreateProjections);
			}
			if (!initiativesToCreateProjections.isEmpty() || !projDeleteInitiativeIds.isEmpty()) {
				IMProjections.save();
			}

			if (!oldCurrentBudgetIds.isEmpty() || !currentBudgetIds.isEmpty()) {
				IMBudgetHelper.updateActiveStatus(oldCurrentBudgetIds, currentBudgetIds);
			}

			//Check if successfulRenewals is not Empty, to clone strategic locations from the original initiative.
			if (!successfulRenewals.isEmpty()) {
				strategicLocationsToClone = IMUtil.getStrategicLocations(successfulRenewals.keySet());
				if (!strategicLocationsToClone.isEmpty()) {
					IMInitiativeTriggerHandlerHelper.cloneStrategicLocations(strategicLocationsToClone, successfulRenewals);
				}
				successfulRenewals.clear();
			}
		}
	}
}