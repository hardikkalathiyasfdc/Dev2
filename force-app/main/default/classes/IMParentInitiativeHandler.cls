/**
 * Author            : Gauri Sagane
 * Date              : 08/18/2025
 * Jira              : IM-312
 * Description       : This is the handler class for Parent Initiative RecordType of Initiative object
 * Test              : IMParentInitiativeHandlerTest
 * ChangeLog		 :
 * Paddy - 01/23/2026: IM-490: Added logic to call populateBgiveURL method.
 * Paddy - 05/12/2026: IM-532: Added logic to prevent deletion.
 */
public with sharing class IMParentInitiativeHandler extends TriggerHandler {
	public List<SObject> newInitiatives;
	public List<SObject> oldInitiatives;
	public Map<Id, SObject> oldMap;
	public Map<Id, SObject> newMap;

	private static List<Foundation_Code__c> foundationCodesToUpdate = new List<Foundation_Code__c>();
	private static Set<Id> fcCreateInitiativeIds = new Set<Id>();
	private static Set<Id> fcCreateFocusAreaIds = new Set<Id>();
	private static Set<Id> fcUpdateInitiativeIds = new Set<Id>();
	private static Set<Id> parentInitiativeIds = new Set<Id>();
	private Set<Id> initiativeIdSet = new Set<Id>();

	private static Integer delayInMinutes = 1;
	private IMInitiativeTriggerHandlerHelper helper = new IMInitiativeTriggerHandlerHelper();

	public IMParentInitiativeHandler() {
		super(
			new Map<Schema.SObjectField, List<Object>>{
				IM_Initiative__c.RecordTypeId.getDescribe().getSObjectField() => new List<Object>{
					Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName().get(Assets.PARENT_INITIATIVE).getRecordTypeId()
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
				helper.populateFocusArea(newInitiatives);
				helper.populateSegment(newInitiatives);
			} else if (Trigger.isUpdate) {
				Map<Id, IM_Initiative__c> initiativesTeamUpdated = new Map<Id, IM_Initiative__c>();
				for (SObject initiative : newInitiatives) {
					if (isFieldChanged(initiative, Assets.TEAM)) {
						initiativesTeamUpdated.put(initiative.Id, (IM_Initiative__c) initiative);
					}
				}
				// Not updating team if Initiative is already approved (i.e. Foundation Code is created)
				if (!initiativesTeamUpdated.isEmpty()) {
					List<Foundation_Code__c> fCodes = [SELECT Initiative__c FROM Foundation_Code__c WHERE Initiative__c IN :initiativesTeamUpdated.keySet() WITH SYSTEM_MODE];
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
		if(initiative.Bgive_Id__c != null) {
			helper.populateBgiveURL(initiative);
		}
	}

	public override void beforeUpdate(SObject oldSo, SObject so) {
		IM_Initiative__c newInitiative = (IM_Initiative__c) so;
		IM_Initiative__c oldInitiative = (IM_Initiative__c) oldSo;

		if (isFieldChanged(newInitiative, 'Name')) {
			fcUpdateInitiativeIds.add(newInitiative.Id);
		}
		if (isFieldChanged(newInitiative, 'Team__c')) {
			fcUpdateInitiativeIds.add(newInitiative.Id);
		}
		if (isFieldChanged(newInitiative, 'Focus_Area__c')) {
			fcUpdateInitiativeIds.add(newInitiative.Id);
		}
		if(isFieldChanged(newInitiative, Assets.BGIVE_ID)) {
			helper.populateBgiveURL(newInitiative);
		}
	}

	public override void bulkAfter() {
		if (Trigger.isUpdate) {
			//process Foundation codes
			//IM-393: No need to run the query if fcUpdateInitiativeIds is Empty
			if (!fcUpdateInitiativeIds.isEmpty()) {
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
			fcCreateInitiativeIds.add(initiative.Id);
			parentInitiativeIds.add(initiative.Id);
			if (initiative.Focus_Area__c != null) {
				fcCreateFocusAreaIds.add(initiative.Focus_Area__c);
			}
		}
	}

	public override void afterUpdate(SObject oldSo, SObject so) {
		IM_Initiative__c newInitiative = (IM_Initiative__c) so;
		IM_Initiative__c oldInitiative = (IM_Initiative__c) oldSo;

		//Final Approved Initiative is updated - update the BGive Concept initiative to reflect the update in BRM
		if (helper.isSyncFieldChanged(oldInitiative, newInitiative)) {
			if (!initiativeIdSet.contains(newInitiative.Id)) {
				initiativeIdSet.add(newInitiative.Id);
			}
		}
	}

	public override void beforeDelete(SObject so) {
		IM_Initiative__c initiative = (IM_Initiative__c) so;
		initiative.addError(IMInitiativeTriggerHandlerHelper.DELETE_ERROR_MESSAGE);
	}

	public override void andFinally() {
			if (Trigger.isAfter) {
				helper.processFoundationCodes(fcCreateInitiativeIds, fcCreateFocusAreaIds);
				if (Trigger.isInsert) {
					// Added to sync parent initiatives with BGive
					if (parentInitiativeIds.size() > 0) {
						Database.executeBatch(new BatchIMInitiativeSync(parentInitiativeIds), 1);
						// Added to create Non Budgeted Initiative and corresponding Foundation code
						ID jobID = System.enqueueJob(new IMQueueableNonBudgetedInitiativeSync(parentInitiativeIds), delayInMinutes);
					}
				} else if (Trigger.isUpdate) {
					update as system foundationCodesToUpdate;

					// Added to sync parent initiatives with BGive
					if (!fcUpdateInitiativeIds.isEmpty()) {
						ID jobID = System.enqueueJob(new IMQueueableNonBudgetedInitiativeSync(fcUpdateInitiativeIds), delayInMinutes);
					}
					if (initiativeIdSet.size() > 0) {
						Database.executeBatch(new BatchIMInitiativeSync(initiativeIdSet), 1);
					}
				}
			}
	}
}