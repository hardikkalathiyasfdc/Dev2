/**
 * Author      : Gauri Sagane
 * Date        : 01/17/2024
 * Jira        : IM-87
 * Description : This class is used by Strategic Locations Trigger and contains helper methods.
 *                Contains logic to sync strategic locations on a particular initiaitve to bgive
 * Test        : IMStrategicLocationsTriggerHandlerTest
 * ChangeLog   : Hardik - 10/06/2026: Added before insert logic to default Review Status and Deleted based on the related Initiative's approval.
 */

public with sharing class IMStrategicLocationsTriggerHandler extends TriggerHandler {

	public List<IM_Strategic_Locations__c> newStrategicLocations;
	public List<IM_Strategic_Locations__c> oldStrategicLocations;
	public Map<Id, IM_Strategic_Locations__c> oldMap;
	public Map<Id, IM_Strategic_Locations__c> newMap;

	private static Set<Id> initiativeIds = new Set<Id>();
	private static Set<Id> initiativeIdsToUpdate = new Set<Id>();
	private static List<IM_Initiative__c> initiatives = new List<IM_Initiative__c>();
	private Map<Id, IM_Initiative__c> relatedInitiatives = new Map<Id, IM_Initiative__c>();
	private Map<Id, IM_Strategic_Locations__c> reviewedLocations = new Map<Id, IM_Strategic_Locations__c>();
	private Map<Id, IM_Initiative__c> insertInitiatives = new Map<Id, IM_Initiative__c>();
	private static final String AMENDMENT_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.AMENDMENT)
		.getRecordTypeId();

	public IMStrategicLocationsTriggerHandler() {
		this(Trigger.old, Trigger.new, (Map<Id, IM_Strategic_Locations__c>) Trigger.oldMap, (Map<Id, IM_Strategic_Locations__c>) Trigger.newMap);
	}

	public IMStrategicLocationsTriggerHandler(
		List<IM_Strategic_Locations__c> oldStrategicLocationsList,
		List<IM_Strategic_Locations__c> newStrategicLocationsList
	) {
		newStrategicLocations = newStrategicLocationsList;
		oldStrategicLocations = oldStrategicLocationsList;
	}

	public IMStrategicLocationsTriggerHandler(
		List<IM_Strategic_Locations__c> oldStrategicLocationsList,
		List<IM_Strategic_Locations__c> newStrategicLocationsList,
		Map<Id, IM_Strategic_Locations__c> oldMap,
		Map<Id, IM_Strategic_Locations__c> newMap
	) {
		newStrategicLocations = newStrategicLocationsList;
		oldStrategicLocations = oldStrategicLocationsList;
		this.oldMap = oldMap;
		this.newMap = newMap;
	}

	public override void bulkBefore() {
		if (Trigger.isInsert) {
			Set<Id> insertInitiativeIds = new Set<Id>();
			for (IM_Strategic_Locations__c stl : newStrategicLocations) {
				if (stl.Initiative__c != null) {
					insertInitiativeIds.add(stl.Initiative__c);
				}
			}
			if (!insertInitiativeIds.isEmpty()) {
				insertInitiatives = new Map<Id, IM_Initiative__c>(
					[
						SELECT Id, Approved__c
						FROM IM_Initiative__c
						WHERE Id IN :insertInitiativeIds
						WITH SYSTEM_MODE
					]
				);
			}
		}
	}

	public override void beforeInsert(SObject so) {
		IM_Strategic_Locations__c newStrategicLocation = (IM_Strategic_Locations__c) so;
		IM_Initiative__c relatedInitiative = insertInitiatives?.get(newStrategicLocation.Initiative__c);
		if (relatedInitiative == null) {
			return;
		}
		// Only stamp Pending Addition for approved Initiatives; leave Review Status untouched otherwise
		if (relatedInitiative.Approved__c) {
			newStrategicLocation.Review_Status__c = Assets.PENDING_ADDITION;
			newStrategicLocation.Deleted__c = false;
		}
	}

	public override void bulkAfter() {
		if (Trigger.isUpdate) {
			for (IM_Strategic_Locations__c stl : newStrategicLocations) {
				initiativeIds.add(stl.Initiative__c);
			}
			getRelatedInitiatives(initiativeIds);
		}
	}

	public override void afterUpdate(SObject oldSo, SObject so) {
		IM_Strategic_Locations__c newStrategicLocation = (IM_Strategic_Locations__c) so;
		IM_Strategic_Locations__c oldStrategicLocation = (IM_Strategic_Locations__c) oldSo;
		// When a strategic location addition is approved
		if (
			isFieldChanged(newStrategicLocation, Assets.REVIEW_STATUS) &&
			oldStrategicLocation?.Review_Status__c == Assets.PENDING_ADDITION && newStrategicLocation?.Review_Status__c == null
		) {
			if(relatedInitiatives?.get(newStrategicLocation.Initiative__c)?.Approved__c){
				initiativeIds.add(newStrategicLocation.Initiative__c);
				if(relatedInitiatives?.get(newStrategicLocation.Initiative__c)?.CityView_Initiative__c != null){
					reviewedLocations.put(newStrategicLocation.Id, newStrategicLocation);
				}
			}
		}
		// When a strategic location's removal is approved
		if(isFieldChanged(newStrategicLocation, Assets.REVIEW_STATUS) &&
			oldStrategicLocation?.Review_Status__c == Assets.PENDING_REMOVAL && newStrategicLocation?.Review_Status__c == null && newStrategicLocation.Deleted__c) {
			reviewedLocations.put(newStrategicLocation.Id, newStrategicLocation);
			initiativeIds.add(newStrategicLocation.Initiative__c);
		}
	}

	public override void andFinally() {
		if (Trigger.isAfter) {
			if(!initiativeIds.isEmpty()){
				getInitiatives(initiativeIds);
				if (!initiativeIdsToUpdate.isEmpty()) {
					syncStrategicLocation();
				}
			}
			if(!reviewedLocations.isEmpty()) {
				// Recompute/Create Org Associations
				ID jobID = System.enqueueJob(new OrgAssociationComputationQueueable(reviewedLocations, null));
			}
		}
	}

	/**
	 * Description : Method to sync Strategic Locations to BGive
	 * Parameters : initiatives List<IM_Initiative__c>
	 * Return Type : void
	 */
	private void syncStrategicLocation() {
		if (!Test.isRunningTest()) {
			Database.executeBatch(new BatchIMInitiativeSync(initiativeIdsToUpdate), 1);
		}
	}

	/**
	 * Description : Method to get related Initiative
	 * Parameters : initiativeIds Set<Id>
	 * Return Type : void
	 */
	private void getInitiatives(Set<Id> initiativeIds) {
		initiatives = [SELECT Id FROM IM_Initiative__c WHERE Id IN :initiativeIds AND Approved__c = TRUE AND RecordTypeId != :AMENDMENT_RECORD_TYPE_ID WITH SYSTEM_MODE];
		initiativeIdsToUpdate = (new Map<Id, IM_Initiative__c>(initiatives)).keySet();
	}

	/**
	 * Description : Method to get related Initiative
	 * Parameters : initiativeIds Set<Id>
	 * Return Type : void
	 */
	private void getRelatedInitiatives(Set<Id> initiativeIds) {
		relatedInitiatives = new Map<Id, IM_Initiative__c>([SELECT Id, Approved__c, CityView_Initiative__c FROM IM_Initiative__c WHERE Id IN :initiativeIds AND Approved__c = TRUE WITH SYSTEM_MODE]);
	}
}