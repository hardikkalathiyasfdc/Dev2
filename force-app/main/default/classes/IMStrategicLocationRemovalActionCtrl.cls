/**
 * Author      : Hardik Kalathiya
 * Date        : 10/12/2026
 * Jira        : BRME-6823
 * Description : Controller for the imStrategicLocationRemovalAction LWC quick action. Marks the
 *               Strategic Location Pending Removal (approved Initiative) or hard deletes it
 *               (non-approved). Runs on the record page, so no navigation is needed.
 * Test        : IMStrategicLocationRemovalActionCtrlTest
 */
public with sharing class IMStrategicLocationRemovalActionCtrl {

	public class RemovalResult {
		@AuraEnabled public Boolean hasError;
		@AuraEnabled public String errorMessage;
		@AuraEnabled public Boolean deleted;
	}

	@AuraEnabled
	public static RemovalResult markForRemoval(Id locationId) {
		RemovalResult result = new RemovalResult();
		result.hasError = false;
		result.deleted = false;
		try {
			if (locationId == null) {
				result.hasError = true;
				result.errorMessage = 'No record selected.';
				return result;
			}
			List<IM_Strategic_Locations__c> locations = [
				SELECT Id, Initiative__r.Approved__c
				FROM IM_Strategic_Locations__c
				WHERE Id = :locationId
				WITH SYSTEM_MODE
				LIMIT 1
			];
			if (locations.isEmpty()) {
				result.hasError = true;
				result.errorMessage = 'Record not found.';
				return result;
			}
			Boolean approved = locations[0].Initiative__r.Approved__c == true;
			Integer alreadyPending = IMStrategicLocationRemovalController.markRecordsForRemoval(new Set<Id>{ locationId });
			result.deleted = !approved;
			if (alreadyPending > 0) {
				result.hasError = true;
				result.errorMessage = 'You are trying to delete the location. It will be reviewed by the committee.';
			}
		} catch (Exception ex) {
			result.hasError = true;
			result.errorMessage = ex.getMessage();
		}
		return result;
	}
}