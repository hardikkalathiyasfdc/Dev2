/**
 * Author : Sai Thotakura
 * Date   : 08/05/2025
 * Jira   : IM-309
 * Description : This class is used to mass delete records
 * Test : MassDeleteRecordsControllerTest
 */

public without sharing class MassDeleteRecordsController {
	/**
	 * Description : Flow Invocable Method
	 * Parameters  : Flow input variables list
	 * Return Type : Flow List<OutputWrapper> variable
	 */
	@InvocableMethod(label='Delete Records by ID')
	public static List<OutputWrapper> deleteRecords(List<InputWrapper> inputs) {
		//Default Wrapper in case of no errors or exception
		OutputWrapper output = new OutputWrapper();
		output.hasError = false;
		output.errorMessage = '';
		try {
			List<Id> inputIds = inputs[0].ids;
			//Check if the inputIds present and the user can delete the ids based on the available limits
			if (!inputIds.isEmpty() && inputIds.size() < Limits.getLimitDMLRows()) {
				String sobjectType = inputIds[0].getSObjectType().getDescribe().getName();
				List<UserRecordAccess> currentUserRecordsAccess = IMUtil.getUserAccessLevel(new Set<Id>(inputIds));
				//Capture deletable and non deletable Ids
				Set<Id> deletableRecordIds = new Set<Id>();
				Set<Id> nonDeletableRecordIds = new Set<Id>();
				for (UserRecordAccess access : currentUserRecordsAccess) {
					if (access.HasDeleteAccess || access.HasTransferAccess || access.HasAllAccess) {
						deletableRecordIds.add(access.RecordId);
					} else {
						nonDeletableRecordIds.add(access.RecordId);
					}
				}
				//Delete deletableRecordIds
				if (!deletableRecordIds.isEmpty()) {
					deleteRecords(sobjectType, deletableRecordIds);
				}
				//Prepare errorMessage for nonDeletableRecordIds
				if (!nonDeletableRecordIds.isEmpty()) {
					output.hasError = true;
					output.errorMessage = prepareErrorForNonDeletable(sobjectType, nonDeletableRecordIds);
				}
			} else if (!inputIds.isEmpty() && inputIds.size() > Limits.getLimitDMLRows()) {
				output.hasError = true;
				output.errorMessage = String.format(Assets.MORE_RECORDS_FOR_DELETE, new List<String>{ String.valueOf(Limits.getLimitDMLRows()) });
			} else {
				output.hasError = true;
				output.errorMessage = Assets.NO_RECORDS_SELECTED;
			}
		} catch (DmlException dmlEx) {
			output.hasError = true;
			output.errorMessage = Assets.NO_DELETE_ACCESS;
		} catch (Exception ex) {
			output.hasError = true;
			output.errorMessage = Assets.NO_ACCESS;
		}
		return new List<OutputWrapper>{ output };
	}

	/**
	 * Description : get the Name field based on the Object
	 * Parameters  : String sObject Name
	 * Return Type : String fieldName
	 */
	private static String getNameField(String sobjectType) {
		//get all the fields of an Object
		Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sobjectType).getDescribe().fields.getMap();
		for (Schema.SObjectField field : fieldMap.values()) {
			Schema.DescribeFieldResult describe = field.getDescribe();
			if (describe.isNameField()) {
				return describe.getName();
			}
		}
		//If not found any NameField, return id
		return '';
	}

	/**
	 * Description : Query and delete the deletable records
	 * Parameters  : String sObject Name, Set<Id> deletableRecordIds
	 * Return Type : Void
	 */
	private static void deleteRecords(String sobjectType, Set<Id> deletableRecordIds) {
		//Query and delete the deletable records
		List<SObject> deletableRecords = Database.query('SELECT Id FROM ' + sobjectType + ' WHERE Id IN :deletableRecordIds WITH SYSTEM_MODE');
		BBApps_Crud.doDelete(
			deletableRecords
		);
	}

	/**
	 * Description : Query and delete the deletable records
	 * Parameters  : String sObject Name, Set<Id> deletableRecordIds
	 * Return Type : Void
	 */
	private static String prepareErrorForNonDeletable(String sobjectType, Set<Id> nonDeletableRecordIds) {
		String nameField = getNameField(sobjectType);
		String fieldsToQuery = nameField == '' ? 'Id' : 'Id,' + nameField;
		String query = 'SELECT ' + fieldsToQuery + ' FROM ' + sobjectType + ' WHERE Id IN :nonDeletableRecordIds WITH SYSTEM_MODE';
		List<SObject> noAccessRecords = Database.query(query);
		List<String> recordNames = new List<String>();
		for (SObject rec : noAccessRecords) {
			recordNames.add(String.valueOf(rec.get(nameField)));
		}
		return Assets.NO_DELETE_ACCESS + ': ' + recordNames.toString();
	}

	/**
	 * Description : Flow input variables
	 * Parameters  : None
	 * Return Type : None
	 */
	public class InputWrapper {
		@InvocableVariable(required=true)
		public List<Id> ids;
	}

	/**
	 * Description : OutPutWrapper for the flow
	 * Parameters  : None
	 * Return Type : None
	 */
	public class OutputWrapper {
		@InvocableVariable
		public Boolean hasError;
		@InvocableVariable
		public String errorMessage;
	}
}