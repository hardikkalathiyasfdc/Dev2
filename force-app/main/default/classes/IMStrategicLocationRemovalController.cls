/**
 * Author : Hardik Kalathiya
 * Date   : 10/08/2026
 * Jira   : IM-XXX
 * Description : Marks Strategic Locations as Pending Removal instead of hard deleting them.
 *               Mirrors IM_Remove_Strategic_Location_Request flow behavior:
 *               Approved Initiative -> Review Status = Pending Removal (Deleted stays false until committee action)
 *               Non-approved Initiative -> hard delete
 * Test : IMStrategicLocationRemovalControllerTest
 */

public without sharing class IMStrategicLocationRemovalController {
	private static final String DEFAULT_REMOVAL_NOTES = 'Marked for removal';
	private static final String ALREADY_PENDING_REMOVAL = 'You are trying to delete the location. It will be reviewed by the committee.';
	private static final String ERR_MARK_FOR_REMOVAL = 'MARK_STRATEGIC_LOCATIONS_FOR_REMOVAL_FAILED';

	/**
	 * Description : Flow Invocable Method to mark Strategic Locations for removal by Id
	 * Parameters  : Flow input variables list
	 * Return Type : Flow List<OutputWrapper> variable
	 */
	@InvocableMethod(label='Mark Strategic Locations for Removal' description='Marks the selected Strategic Locations as Pending Removal instead of deleting them')
	public static List<OutputWrapper> markForRemoval(List<InputWrapper> inputs) {
		OutputWrapper output = new OutputWrapper();
		output.hasError = false;
		output.errorMessage = '';
		List<Id> inputIds = inputs[0].ids;
		try {
			if (inputIds == null || inputIds.isEmpty()) {
				output.hasError = true;
				output.errorMessage = Assets.NO_RECORDS_SELECTED;
				return new List<OutputWrapper>{ output };
			}
			Integer alreadyPending = markRecordsForRemoval(new Set<Id>(inputIds));
			// A record selected for delete while already Pending Removal is not re-marked
			if (alreadyPending > 0) {
				output.hasError = true;
				output.errorMessage = ALREADY_PENDING_REMOVAL;
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(inputIds ?? new List<Id>(), ex, new BBApps_ErrorCustomFields(ERR_MARK_FOR_REMOVAL));
			output.hasError = true;
			output.errorMessage = ex.getMessage();
		}
		return new List<OutputWrapper>{ output };
	}

	/**
	 * Description : Marks the given Strategic Locations as Pending Removal (approved Initiative)
	 *               or hard deletes them (non-approved Initiative)
	 * Parameters  : locationIds Set<Id>
	 * Return Type : Integer - count of records that were already Pending Removal and skipped
	 */
	public static Integer markRecordsForRemoval(Set<Id> locationIds) {
		List<IM_Strategic_Locations__c> locations = [
			SELECT Id, Notes__c, Review_Status__c, Initiative__r.Approved__c
			FROM IM_Strategic_Locations__c
			WHERE Id IN :locationIds
			WITH SYSTEM_MODE
		];

		Integer alreadyPendingRemoval = 0;
		List<IM_Strategic_Locations__c> locationsToUpdate = new List<IM_Strategic_Locations__c>();
		List<IM_Strategic_Locations__c> locationsToDelete = new List<IM_Strategic_Locations__c>();
		for (IM_Strategic_Locations__c location : locations) {
			if (location.Initiative__r.Approved__c != true) {
				// Non-approved Initiative - hard delete regardless of review status
				locationsToDelete.add(location);
			} else if (location.Review_Status__c == Assets.PENDING_REMOVAL) {
				// Already marked for removal - do not re-mark
				alreadyPendingRemoval++;
			} else {
				location.Review_Status__c = Assets.PENDING_REMOVAL;
				location.Deleted__c = false;
				// Notes are required by the Pending_Review_Requires_Notes validation rule when a review is pending
				if (String.isBlank(location.Notes__c)) {
					location.Notes__c = DEFAULT_REMOVAL_NOTES;
				}
				locationsToUpdate.add(location);
			}
		}
		if (!locationsToUpdate.isEmpty()) {
			BBApps_Crud.doUpdateWithHandling(locationsToUpdate, true, new BBApps_ErrorCustomFields(ERR_MARK_FOR_REMOVAL));
		}
		if (!locationsToDelete.isEmpty()) {
			BBApps_Crud.doDeleteWithHandling(locationsToDelete, true, new BBApps_ErrorCustomFields(ERR_MARK_FOR_REMOVAL));
		}
		return alreadyPendingRemoval;
	}

	/**
	 * Description : Flow input variables
	 */
	public class InputWrapper {
		@InvocableVariable(required=true)
		public List<Id> ids;
	}

	/**
	 * Description : OutputWrapper for the flow
	 */
	public class OutputWrapper {
		@InvocableVariable
		public Boolean hasError;
		@InvocableVariable
		public String errorMessage;
	}
}