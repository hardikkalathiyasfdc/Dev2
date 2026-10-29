/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 05/02/2025
 * Jira        : IM-170
 * Description : This class is used create amendment record for the main initiative.
 * Test        : Yet to be created.
 * ChangeLog   :
 *  Sai on Sep 18th, 2025: IM-391: Added logic to populate the parent initiative field on the amendment.
 */
public with sharing class IMCreateAmendmentController {
	private static final String PARENT_INITIATIVE_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.PARENT_INITIATIVE)
		.getRecordTypeId();
	private static String ACTIVE_ERROR_MESSAGE = 'Only one amendment may remain active at a given time. Please complete or deactivate the existing amendment before initiating a new one.';

	public class IMCreateAmendmentException extends Exception {
	}

	private static final String ERR_CREATE_AMENDMENT = 'CREATE_AMENDMENT_FAILED';

	//Global Variables
	private static final String AMENDMENT_RECORD_TYPE_ID = Schema.SObjectType.IM_Initiative__c.getRecordTypeInfosByName()
		.get(Assets.AMENDMENT)
		.getRecordTypeId();
	public static IM_Initiative__c mainInitiative = new IM_Initiative__c();
	public static Object parentId = '';
	public static List<String> fieldList = new List<String>{
		'Name',
		'Team__c',
		'Amendment_of__c',
		'Original_Approved_Amount__c',
		'End_Date__c',
		'Program_Contact__c',
		'Proposed_Amount__c',
		'Start_Date__c',
		'Segment__c',
		'Focus_Area__c',
		'External_Milestone_Date__c',
		'External_Milestone_Explanation__c',
		'Grants_Team_Contact__c',
		'Original_End_Date__c',
		'Parent_Initiative__c',
		'Partner_Funds__c',
		'Partner_Funding_Type__c',
		'CityView_Initiative__c'
	};

	/**
	 * Description : Responsible for creating amendment record and updating main initiative
	 * Parameters  : Accepts initiative id
	 * Return Type : Void
	 */
	@AuraEnabled
	public static String createAmendment(String initiativeId) {
		String amendmentRecordId = '';
		try {
			//If the initiative Id is not null, query the initiative to retrieve field data to set
			if (initiativeId != null) {
				UserRecordAccess userAccess = IMUtil.getUserAccessLevel(initiativeId);
				if (userAccess.MaxAccessLevel != 'All' && userAccess.MaxAccessLevel != 'Edit') {
					throw new IMCreateAmendmentException(Assets.AMENDMENT_ACCESS_ERROR);
				}
				List<IM_Initiative__c> amendmentRecords = [
					SELECT Name
					FROM IM_Initiative__c
					WHERE Amendment_of__c = :initiativeId AND Status__c NOT IN ('Declined', 'Completed')
					WITH SYSTEM_MODE
				];
				if (!amendmentRecords.isEmpty()) {
					throw new IMCreateAmendmentException(ACTIVE_ERROR_MESSAGE);
				}
				mainInitiative = IMUtil.getMainInitiative(initiativeId);
				if (mainInitiative != null) {
					//IM-391
					Object parentName = mainInitiative.get('Parent_Initiative_Name__c');
					parentId = [
						SELECT Id
						FROM IM_Initiative__c
						WHERE Name = :String.valueOf(parentName) AND RecordTypeId = :PARENT_INITIATIVE_RECORD_TYPE_ID
						WITH SYSTEM_MODE LIMIT 1
					]?.Id;
					amendmentRecordId = createAmendmentRecord(Assets.IM_INITIATIVE);
				}
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors((Id) initiativeId, e, new BBApps_ErrorCustomFields(ERR_CREATE_AMENDMENT));
			throw new IMCreateAmendmentException(e.getMessage());
		}
		return amendmentRecordId;
	}

	/**
	 * Description : Responsible for creating amendment record and updating main initiative
	 * Parameters  : None
	 * Return Type : Void
	 */
	private static String createAmendmentRecord(String objectName) {
		//Instance of the record
		SObject amendmentRecord = Schema.getGlobalDescribe().get(objectName).newSObject();
		//Set the record Type and Initiative Type and Status
		amendmentRecord.put('RecordTypeId', AMENDMENT_RECORD_TYPE_ID);
		amendmentRecord.put('Initiative_Type__c', 'Amendment');
		amendmentRecord.put('Status__c', 'Draft');

		//Setting the Amendment Number
		amendmentRecord.put('Amendment_Number__c', ((Integer.valueOf(mainInitiative.get('Amendment_Number__c'))) + 1));
		//Setting the field values
		for (String field : fieldList) {
			amendmentRecord.put(field, mainInitiative.get(field));
			//Field logic for amendment record
			if (field.equalsIgnoreCase('Original_Approved_Amount__c') || field.equalsIgnoreCase('Proposed_Amount__c')) {
				amendmentRecord.put(field, mainInitiative.get('Approved_Amount__c'));
			}
			if (field.equalsIgnoreCase('Amendment_of__c')) {
				amendmentRecord.put(field, mainInitiative.get('Id'));
			}
			if (field.equalsIgnoreCase('Name')) {
				amendmentRecord.put(
					field,
					IMUtil.truncateFieldValue(68, String.valueOf(mainInitiative.get(field)), null, ' Amendment ') + amendmentRecord.get('Amendment_Number__c')
				);
			}
			if (field.equalsIgnoreCase('Original_End_Date__c')) {
				amendmentRecord.put(field, mainInitiative.get('End_Date__c'));
			}
			//IM-391
			if (field.equalsIgnoreCase('Parent_Initiative__c')) {
				amendmentRecord.put(field, parentId);
			}
		}
		//Save the amendment
		BBApps_Crud.doInsert(
			amendmentRecord
		);
		//Set the Open Amendment value
		mainInitiative.Open_Amendment__c = amendmentRecord.Id;
		//Update main initiative
		BBApps_Crud.doUpdate(
			mainInitiative
		);
		// Clone strategic locations from intiative to Amendment Initiative
		IMClone.cloneStrategicLocations(mainInitiative.Id, amendmentRecord.Id);
		//Call IM Budget clone
		IM_Budget__c clonedBudget = IMClone.cloneBudget(mainInitiative.Current_Budget__c, amendmentRecord.Id, Assets.AMENDMENT_CREATE, null);
		clonedBudget.Status__c = Assets.DRAFT;
		BBApps_Crud.doUpdate(
			clonedBudget
		);
		//return the id of amendment
		return amendmentRecord.Id;
	}
}