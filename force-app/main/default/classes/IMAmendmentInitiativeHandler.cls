/**
 * Author            : Gauri Sagane
 * Date              : 08/18/2025
 * Jira              : IM-312
 * Description       : This is the handler class for Amendment Initiative RecordType of Initiative object
 * Test              : IMAmendmentInitiativeHandlerTest
 * ChangeLog		 : Paddy - IM-504 : Added logic to validate unique amendment names per initiative.
 * Paddy - 05/12/2026: IM-532: Added logic to prevent deletion.
 */
public with sharing class IMAmendmentInitiativeHandler extends TriggerHandler {
	public List<SObject> newInitiatives;
	public List<SObject> oldInitiatives;
	public Map<Id, SObject> oldMap;
	public Map<Id, SObject> newMap;

	private static List<IM_Initiative__c> initiativesToCreateProjections = new List<IM_Initiative__c>();
	private List<File_Group__c> fileGroupsToInsert = new List<File_Group__c>();
	private static Map<Id, String> apprvdAmendmentBudgetMap = new Map<Id, String>();
	private static Map<Id, IM_Initiative__c> initiativeToAmendmentMap = new Map<Id, IM_Initiative__c>();
	private static Map<Id, IM_Initiative__c> approvedInitiativesForBPDates = new Map<Id, IM_Initiative__c>();
	private Map<Id, IM_Initiative__c> approvedInitiativesMap = new Map<Id, IM_Initiative__c>();
	private List<IM_Initiative__c> approvedInitiatives = new List<IM_Initiative__c>();
	private Map<Id, Contact> userContactMap = new Map<Id, Contact>();
	private static Set<Id> projDeleteInitiativeIds = new Set<Id>();
	private static Set<Id> amendmentOfInitiativeIds = new Set<Id>();
	private static Set<Id> amendmentOfIds = new Set<Id>();

	private static Boolean isComputeGrants = true;
	private static Boolean isClearOpenAmendments = true;
	public static Boolean cloneAmendmentBudRun = false;
	private static Boolean isApprovalCreated = false;
	private static Boolean isProjectionsCreated = false;
	private static final String READY_FOR_APPROVAL_NOTIFICATION = 'IM_Amend_Initiative_Ready_for_Approval';
	private static final String ERR_READY_FOR_APPROVAL_NOTIFICATION = 'IMAmendmentInitiativeHandler_READY_FOR_APPROVAL_NOTIFICATION_FAILED';
	private static Set<Id> notifiedReadyForApprovalIds = new Set<Id>();
	private Set<Id> readyForApprovalIds = new Set<Id>();
	// BRME-7045: Store the Grants Contact for the shared revisions notification helper.
	private Map<Id, Id> revisionsContactByInitiative = new Map<Id, Id>();

	private IMInitiativeTriggerHandlerHelper helper = new IMInitiativeTriggerHandlerHelper();

	public IMAmendmentInitiativeHandler() {
		super(
			new Map<Schema.SObjectField, List<Object>>{
				IM_Initiative__c.RecordTypeId.getDescribe().getSObjectField() => new List<Object>{
					Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get(Assets.AMENDMENT).getRecordTypeId()
				}
			}
		);

		newInitiatives = this.getNewRecords();
		oldInitiatives = this.getOldRecords();
		oldMap = this.getOldRecordMap();
		newMap = this.getNewRecordMap();
	}

	public override void bulkBefore() {
		if (Trigger.isInsert) {
			// Check if users are b-linked
			helper.getAssociatedUsers(newInitiatives, userContactMap);

			helper.populateFocusArea(newInitiatives);
			helper.populateSegment(newInitiatives);
		} else if (Trigger.isUpdate) {
			helper.getAssociatedUsers(newInitiatives, userContactMap);
			Map<Id, IM_Initiative__c> initiativesTeamUpdated = new Map<Id, IM_Initiative__c>();
			for (IM_Initiative__c initiative : (List<IM_Initiative__c>) newInitiatives) {
				if (isFieldChanged(initiative, Assets.TEAM)) {
					initiativesTeamUpdated.put(initiative.Id, initiative);
				}
				//IM-241: Update Declined Amendments Name with suffix Declined
				if ((isFieldChanged(initiative, Assets.STATUS) && helper.isDeclined(initiative.Status__c))) {
					initiative.Name = IMUtil.truncateFieldValue(70, initiative.Name, null, ' DECLINED');
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
	}

	public override void beforeInsert(SObject so) {
		IM_Initiative__c initiative = (IM_Initiative__c) so;

		// check if the users on initiative are linked to bgive
		helper.validateUserLinkStatus(initiative, userContactMap);

		if(initiative.Amendment_of__c != null && initiative.Name != null) {
			amendmentOfIds.add(initiative.Amendment_of__c);
		}
	}

	public override void beforeUpdate(SObject oldSo, SObject so) {
		IM_Initiative__c newInitiative = (IM_Initiative__c) so;
		IM_Initiative__c oldInitiative = (IM_Initiative__c) oldSo;

		// check if the users on initiaitve are linked to bgive
		if (isFieldChanged(newInitiative, 'Program_Contact__c') || isFieldChanged(newInitiative, 'Grants_Team_Contact__c')) {
			helper.validateUserLinkStatus(newInitiative, userContactMap);
		}


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

		if (isFieldChanged(newInitiative, Assets.APPROVED_FIELD) && newInitiative.Approved__c) {
			apprvdAmendmentBudgetMap.put(newInitiative.Current_Budget__c, String.valueOf(newInitiative.Amendment_of__c));
			initiativeToAmendmentMap.put(newInitiative.Amendment_of__c, newInitiative);
		}

		if(isFieldChanged(newInitiative, Assets.NAME_FIELD) || isFieldChanged(newInitiative, Assets.AMENDMENT_OF_FIELD)) {
			if(newInitiative.Amendment_of__c != null && newInitiative.Name != null) {
				amendmentOfIds.add(newInitiative.Amendment_of__c);
			}
		}
			
	}

	public override void afterInsert(SObject so) {
		IM_Initiative__c initiative = (IM_Initiative__c) so;
		if (initiative != null) {
			helper.processFileGroups(initiative, fileGroupsToInsert);

			if (initiative.Include_in_Projections__c) {
				initiativesToCreateProjections.add(initiative);
			}
		}
	}

	public override void afterUpdate(SObject oldSo, SObject so) {
		IM_Initiative__c newInitiative = (IM_Initiative__c) so;
		IM_Initiative__c oldInitiative = (IM_Initiative__c) oldSo;

		if (
			!isApprovalCreated &&
			isFieldChanged(newInitiative, Assets.APPROVED_FIELD) &&
			newInitiative.Approved__c == true &&
			oldInitiative.Approved__c == false
		) {
			isApprovalCreated = true;
			approvedInitiatives.add(newInitiative);
			if (newInitiative.Current_Budget__c != null) {
				approvedInitiativesForBPDates.put(newInitiative.Id, newInitiative);
			}
			if(newInitiative.CityView_Initiative__c != null){
				approvedInitiativesMap.put(newInitiative.Id, newInitiative);
			}
		}

		if (
			((isFieldChanged(newInitiative, Assets.STATUS) && helper.isDeclined(newInitiative.Status__c)) ||
			(isFieldChanged(newInitiative, Assets.APPROVED_FIELD) && newInitiative.Approved__c == true))
		) {
			amendmentOfInitiativeIds.add(newInitiative.Amendment_of__c);
		}

		if (isFieldChanged(newInitiative, Assets.STATUS) && Assets.READY_FOR_APPROVAL.equals(newInitiative.Status__c)
				&& !notifiedReadyForApprovalIds.contains(newInitiative.Id)) {
			readyForApprovalIds.add(newInitiative.Id);
		}

		// BRME-7045: Amendments also notify their Grants Contact when sent back for revisions.
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
			if (Trigger.isInsert) {
				insert as system fileGroupsToInsert;
			} else if (Trigger.isUpdate) {
                if (!approvedInitiatives.isEmpty()) {
					helper.processApprovals(approvedInitiatives);
				}

				if(!approvedInitiativesMap.isEmpty()){
					helper.processStrategicLocations(approvedInitiativesMap, null);
				}

				if (!approvedInitiativesForBPDates.isEmpty()) {
					IMBudgetPeriodHelper.setDates(approvedInitiativesForBPDates);
				}

				if (!apprvdAmendmentBudgetMap.isEmpty()) {
					IMInitiativeTriggerHandlerHelper.cloneAmendmentCurrentBudget(cloneAmendmentBudRun, apprvdAmendmentBudgetMap);
				}
				if (!projDeleteInitiativeIds.isEmpty()) {
					IMProjections.remove(projDeleteInitiativeIds);
				}

				if (isClearOpenAmendments && !amendmentOfInitiativeIds.isEmpty()) {
					isClearOpenAmendments = false;
					helper.updateMainInitiative(amendmentOfInitiativeIds, initiativeToAmendmentMap);
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
        } else if (Trigger.isBefore) {
            if(!amendmentOfIds.isEmpty()) {
                validateUniqueAmendmentNames();
            }
        }
	}

	/**
	 * Description     : Validates that amendment names are unique per initiative
	 * Parameters      : none
	 * Return Type     : void
	 */
	private void validateUniqueAmendmentNames() {
		Map<Id, Set<String>> amendmentOfInitiativeNamesMap = new Map<Id, Set<String>>();

		for (IM_Initiative__c childAmendment : [SELECT Name, Amendment_of__c FROM IM_Initiative__c 
												WHERE Amendment_of__c IN :amendmentOfIds
												WITH SYSTEM_MODE]) {
			if (!amendmentOfInitiativeNamesMap.containsKey(childAmendment.Amendment_of__c)) {
				amendmentOfInitiativeNamesMap.put(childAmendment.Amendment_of__c, new Set<String>());
			}
			amendmentOfInitiativeNamesMap.get(childAmendment.Amendment_of__c).add(childAmendment.Name);
		}

		for (SObject initiative : newInitiatives) {
			IM_Initiative__c amendment = (IM_Initiative__c)initiative;
			if (!amendmentOfInitiativeNamesMap.isEmpty() 
				&& amendmentOfInitiativeNamesMap.get(amendment.Amendment_of__c).contains(amendment.Name)) {
				amendment.addError('No two amendments under one initiative can have the same name.');
			}
		}
	}
}