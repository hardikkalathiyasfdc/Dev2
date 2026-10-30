/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 04/01/2025
 * Jira        : IM-134
 * Description : This is a service class that can be used to sync (create/update) records in BRM with Bgive
 * Test        : BGiveApiSyncTest
 * ChangeLog   :
 * Gauri on 08/21/2025 IM-368 - Added a new type of None for BRM Fild Type
 * Paddy	   : IM-506, updated getFieldValue method to support nested relationship with multiple __r references
 * 				 i.e. Foundation_Code__r.Parent__r.Initiative__r.Bgive_Id__c
 * Paddy IM-523: Added logic to check whether record is locked in Bgive.
 * Paddy IM-517: Added logic to ensure that all fields marked as "BRM To Bgive Always" are alwasy sent during 
 * 				 the sync process, even if only a singel field is updated.
 */
public with sharing class BGiveApiSync {

	//Global variables
	private static SObject syncRecord;
	//Data Types
	private static Set<String> userIds = new Set<String>();
	private static Set<String> syncRecordFields = new Set<String>();
	private static List<Bgive_Sync_Field_Mapping__mdt> bgiveSyncFieldMapping = new List<Bgive_Sync_Field_Mapping__mdt>();
	private static Map<String, Map<String, String>> picklistValMap = new Map<String, Map<String, String>>();
	private static Map<String, Object> data = new Map<String, Object>();
	private static Map<String, Object> bgiveRecordMap = new Map<String, Object>();
	private static Map<String, Object> parsedDataJsonMap = new Map<String, Object>();
	private static Map<String, String> bgiveFieldToUserMap = new Map<String, String>();
	private static Map<String, String> alwaysSyncFieldsMap = new Map<String, String>();
	//Booleans
	private static Boolean isInsert = false;
	private static Boolean performUpdate = false;
	//Segment Related
	private static String segmentFieldName = 'segment__c';
	private static String teamFieldName = 'team__c';
	private static String brmSegmentFieldName = 'segment_id';
	private static String brmTeamFieldName = 'program_id';
	//Objects
	private static String grantObjName = 'IM_Grant__c';
	private static String initiativeObjName = 'IM_Initiative__c';
	//Bgive Sync Fields
	private static String BGIVE_ID_FLD = 'Bgive_Id__c';
	private static String BGIVE_CONTIG_ID_FLD = 'Bgive_Contig_Id__c';
	private static String BGIVE_SYNC_ERROR_FLD = 'Sync_Error__c';

	private static String bgiveId;
	private static String bgiveContigId;
	private static String errors;
	private static BGiveApi apiClassInstance;

	//Error Handling Constants
	private static final String ERR_UPDATE_RECORD = 'UPDATE_RECORD_FAILED';
  	private static final String ERR_SYNC_RECORD = 'SYNC_RECORD_FAILED';  

	//Exception
    public class BGiveApiSyncException extends Exception{}

	/**
	 * Description : primary method responsible for the entire sync logic, based on the id and object name we construct data map for api call.
	 * Parameters  : Accepts recordId, and object Name
	 * Return Type : Void
	 */
	public static Map<String, Object> sync(SObject record, String objectName, List<String> columns) {
		Map<String, Object> returnMap = new Map<String, Object>();
		Map<String, Object> bgiveRecord = new Map<String, Object>();
		try {
			List<String> cols = new List<String>();
			syncRecord = record;
			if (objectName == null) {
				throw new BGiveApiSyncException('Object api name of sync record is null.');
			}
			if (syncRecord == null) {
				throw new BGiveApiSyncException('Sync Record is null');
			}

			initializeClassInstance(objectName);
            setFieldMappings(objectName);
            
			//Parse the Data JSON into respective maps - this updates the parsedDataJsonMap
			if (syncRecordFields.contains((Assets.DATAJSON).toLowerCase())) {
				parseDataJson((String) syncRecord.get(Assets.DATAJSON), objectName);
			}

			//Get the record from Bgive
			getBgiveRecord(syncRecord.Id, objectName, cols);

			//Prepare the Data for Insert/Update to Bgive
			fillDataMap();
            if (!data.isEmpty()) {
				if (isInsert) {
					bgiveRecord = createRecordInBgive(objectName, columns);
				} else {
					if (performUpdate) {
						String lockedById = String.valueOf(bgiveRecordMap.get(Assets.LOCKED_BY_ID));
						if(String.isNotBlank(lockedById)) {
							String lockedByUserName = IMUtil.getContactNameByBgiveId(lockedById);
							throw new BGiveApiSyncException('This record is temporarily locked for editing in Bgive by another user ' + lockedByUserName);
						}
						bgiveRecord = updateRecordInBgive(objectName, columns);
					}
				}
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(syncRecord.Id, ex, new BBApps_ErrorCustomFields(ERR_SYNC_RECORD));
			errors = String.valueOf(ex);
		}

		returnMap.put('Errors', errors);
		returnMap.put('BgiveId', bgiveId);
		returnMap.put('BgiveContigId', bgiveContigId);
		returnMap.put('Record', bgiveRecord);
		return returnMap;
	}

	public static Map<String, Object> sync(SObject record, String objectName) {
		return sync(record, objectName, null);
	}
	private static void initializeClassInstance(String objectName) {
		if (objectName == grantObjName) {
			apiClassInstance = new BGiveApiGrant();
		} else if (objectName == initiativeObjName) {
			apiClassInstance = new BGiveApiInitiative();
		}
	}

	private static void setFieldMappings(String objectName) {
		List<Bgive_Field_Value_Mapping__mdt> bgiveFieldValueMapping = new List<Bgive_Field_Value_Mapping__mdt>();
		bgiveSyncFieldMapping = IMUtil.getBGiveSyncFieldMapList(objectName);
		syncRecordFields = syncRecord.getSObjectType().getDescribe().fields.getMap().keySet();
		if (bgiveSyncFieldMapping.isEmpty()) {
			throw new BGiveApiSyncException('BGive Sync Field Mapping Metadata is not configured for ' + objectName + '.');
		}

		for (Bgive_Sync_Field_Mapping__mdt syncFieldMapping : bgiveSyncFieldMapping) {
			//Capture all the fields that must be synced always
			if (syncFieldMapping.Sync_Mode__c == Assets.BGIVE_SYNC_MODE_ALWAYS) {
				alwaysSyncFieldsMap.put(syncFieldMapping.BRM_Field__c, syncFieldMapping.Bgive_Attribute_Name__c);
			}
			//For picklist, capture all the child records
			if (syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_PICKLIST) {
				bgiveFieldValueMapping.addAll(syncFieldMapping.Bgive_Field_Value_Mappings__r);
			}
		}

		//Fill picklist value map
		for (Bgive_Field_Value_Mapping__mdt valueMapping : bgiveFieldValueMapping) {
			String brmFieldName = valueMapping.Bgive_Sync_Field_Mapping__r.BRM_Field__c;
			if (picklistValMap.get(brmFieldName) == null) {
				picklistValMap.put(brmFieldName, new Map<String, String>());
			}
			picklistValMap.get(brmFieldName).put(valueMapping.BRM_Value__c, valueMapping.Bgive_Field_Value__c);
		}

	}
	/**
	 * Description : parses the data json into respective parsedDataJsonMap map to access field values
	 * Parameters  : Accepts the data json from the sync record, and the object name
	 * Return Type : Void
	 */
	private static void parseDataJson(String dataJson, String objectName) {
		if (dataJson != null) {
			Map<String, Object> dataJsonMap = (Map<String, Object>) JSON.deserializeUntyped(dataJson);
			parsedDataJsonMap = (Map<String, Object>) dataJsonMap.get(objectName);
		}
	}

	/**
	 * Description : fill the data map needed for record creation/update in BGive/Fluxx
	 * Parameters  : None
	 * Return Type : None
	 */
	private static void fillDataMap() {
		for (Bgive_Sync_Field_Mapping__mdt syncFieldMapping : bgiveSyncFieldMapping) {
			if(!alwaysSyncFieldsMap.containsKey(syncFieldMapping.BRM_Field__c)) {
				continue;
			}
			String brmField = syncFieldMapping.BRM_Field__c;
			if(brmField == null || brmField.contains(';')) {
				continue;
			}
			//check for mismatch if one mataches, break;
			Object comparisonValue = getComparisonValueForSyncAlways(syncFieldMapping);
			
			if(syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_RELATION_VALUE) {
				Object bgiveValue = bgiveRecordMap.get(alwaysSyncFieldsMap.get(brmField));
				if(String.valueOf(bgiveValue).contains('concept_initiative')) {
					Map<String, Object> parentInitiativeConcept = (Map<String, Object>)bgiveValue;
					Map<String, Object> parentInitiative = (Map<String, Object>)parentInitiativeConcept.get('concept_initiative');
                    if(parentInitiative.containsKey('id')) {
                        bgiveRecordMap.put(alwaysSyncFieldsMap.get(brmField), String.valueOf(parentInitiative.get('id')));
                    }
				}
			}
			if(checkForFieldMismatch(brmField, comparisonValue)) {
				break;
			}
		}

		for (Bgive_Sync_Field_Mapping__mdt syncFieldMapping : bgiveSyncFieldMapping) {
			Boolean fieldMismatch = false;
			String brmField = syncFieldMapping.BRM_Field__c;
			String bgiveField = syncFieldMapping.Bgive_Attribute_Name__c;
			Boolean isAlwaysSync = alwaysSyncFieldsMap.containsKey(brmField);

			Object dataValue = brmField != null && brmField.contains(';')
				? null
				: getValue(syncFieldMapping.BRM_Field_Type__c, brmField, syncFieldMapping.Default_Value__c);
			//MAPPING TYPE - PICKLIST
			if (syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_PICKLIST) {
				Object bgivePicklistValue = picklistValMap.get(brmField)?.get((String) dataValue);
				if (bgivePicklistValue != null && (isInsert || (isAlwaysSync && performUpdate))) {

					data.put(bgiveField, bgivePicklistValue);
				}

			}

			//MAPPING TYPE - USER LOOKUP
			else if (syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_USER_LOOKUP) {
				if (dataValue != null && !userIds.contains(String.valueOf(dataValue))) {
					userIds.add(String.valueOf(dataValue));
				}
				if (dataValue != null) {
					bgiveFieldToUserMap.put(bgiveField, String.valueOf(dataValue));
				}
			}

			//MAPPING TYPE - SEGMENT
			else if (syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_SEGMENT) {
				String segmentId = syncRecordFields.contains(segmentFieldName)
					? (String) syncRecord.get(segmentFieldName) != null ? (String) syncRecord.get(segmentFieldName) : ''
					: (String) dataValue;
				String teamId = syncRecordFields.contains(teamFieldName)
					? (String) syncRecord.get(teamFieldName) != null ? (String) syncRecord.get(teamFieldName) : ''
					: (String) parsedDataJsonMap.get('program_sfid');
				if (segmentId != null && teamId != null) {
					Object segmentTeamId = getSegmentTeam(segmentId, teamId);
					if (isInsert || (isAlwaysSync && performUpdate)) {

						data.put(bgiveField, segmentTeamId);
					}
				}
			}

			//MAPPING TYPE - RELATED LIST
			else if (syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_RELATED_LIST) {
				List<String> geoAreas = getGeoAreas(syncRecord.Id, syncFieldMapping.BRM_Field__c);
				if (isInsert || (isAlwaysSync && performUpdate)) {

					data.put(bgiveField, geoAreas);
				}
			}
			//MAPPING TYPE - VALUE
			else if (syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_VALUE) {
				if (isInsert || (isAlwaysSync && performUpdate)) {

					data.put(bgiveField, dataValue);
				}
			}
			//MAPPING TYPE - RELATION
			else if (syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_RELATION_VALUE) {
				if (isInsert || (isAlwaysSync && performUpdate)) {

					Map<String, Object> fieldIdMap = new Map<String, Object>();
					fieldIdMap.put('id', dataValue);
					data.put(bgiveField, fieldIdMap);
				}
			}



		}
		//call setDataForUserFields to fill user lookup mapping
		if (!userIds.isEmpty()) {
			setDataForUserFields();
		}
	}


	/**
	 * Description : returns the value attribute for the data construction in fillDataMap
	 * Parameters  : Accepts field String
	 * Return Type : Boolean
	 */
	private static Boolean checkForFieldMismatch(String field, Object currentfieldValue) {
		Boolean isMismatch = false;
		if (alwaysSyncFieldsMap.containsKey(field)) {
			Object bgiveStoredValue = bgiveRecordMap.get(alwaysSyncFieldsMap.get(field));
            Boolean isInteger = bgiveStoredValue instanceOf Integer;
            isMisMatch = isInteger 
                ? !String.valueOf(bgiveStoredValue).equalsIgnoreCase(String.valueOf(currentfieldValue))
                : currentfieldValue != bgiveStoredValue;
            performUpdate = isMisMatch;
		}
		return isInsert || isMismatch;
	}


	/**
	 * Description : Calls BGive API to fetch BGive Grant request record.
	 * Parameters  : Accetps String syncRecordId
	 * Return Type : Void
	 */
	private static void getBgiveRecord(String syncRecordId, String objectName, List<String> cols) {
		if (apiClassInstance == null) {
			throw new BGiveApiSyncException('API class instance is not initialized.');
		}
		cols.addAll(alwaysSyncFieldsMap.values());
		cols.add(Assets.LOCKED_BY_ID);
		//Check if the BRM IM Grant exists in BGive system this needs to change to use BgiveAPIFilterClass

		BGiveFilterCondition condition = new BGiveFilterCondition('brm_id', BGiveFilterCondition.Operator.STARTS_WITH, syncRecordId);

		BGiveApiFilter filter = new BGiveApiFilter();
		filter.setGroupType('and');
		filter.addCondition(condition);

		apiClassInstance.setFilters(filter.getFilterString());
        BGiveApi.BGiveAPIListResponse fetchResp = (BGiveApi.BGiveAPIListResponse) apiClassInstance.get(cols);
        getBgiveRecordHelper(fetchResp);
	}

	/**
	 * Description : helper method to get the bgiveId and run an update operation
	 * Parameters  : accepts the fetchResp
	 * Return Type : None
	 */
	private static void getBgiveRecordHelper(BGiveApi.BGiveAPIListResponse fetchResp) {
		//Bgive record is present - update record with bgive record id and run a update sync operation
		if (fetchResp.records.size() > 0) {
			//Assign the bgive id if it is empty on the syncRecord
			bgiveRecordMap = (Map<String, Object>) fetchResp.records.get(0);
			bgiveId = String.valueOf(bgiveRecordMap.get('id'));
			bgiveContigId = String.valueOf(bgiveRecordMap.get('contig_id'));
		} else {
			isInsert = true;
		}
	}

	/**
	 * Description : create grant_request record in BGive/Fluxx
	 * Parameters  : None
	 * Return Type : None
	 */
	private static Map<String, Object> createRecordInBgive(String objectName, List<String> cols) {
		if (apiClassInstance == null) {
			throw new BGiveApiSyncException('API class instance is not initialized.');
		}

		BGiveApi.BGiveAPIResponse insertResp = (BGiveApi.BGiveAPIResponse) apiClassInstance.create(data, cols);
		return handleResponse(insertResp);
	}

	/**
	 * Description : createRecordHelper deconstructs the resultmap from the parent method and updates the bgive id
	 * Parameters  : BGiveApi.BGiveAPIResponse insertResp from parent method createRecordInBgive();
	 * Return Type : None
	 */
	private static Map<String, Object> handleResponse(BGiveApi.BGiveAPIResponse insertResp) {
		Map<String, Object> record = (Map<String, Object>) insertResp.record;
		bgiveId = String.valueOf(record.get('id')) ?? null;
		bgiveContigId = String.valueOf(record.get('contig_id')) ?? null;
		return record;
	}

	/**
	 * Description : update grant_request record in BGive/Fluxx
	 * Parameters  : None
	 * Return Type : None
	 */
	private static Map<String, Object> updateRecordInBgive(String objectName, List<String> cols) {

		if (bgiveId == null) {
			throw new BGiveApiSyncException('BGiveId is null for update call.');
		}
		if (apiClassInstance == null) {
			throw new BGiveApiSyncException('API class instance is not initialized.');
		}

		BGiveApi.BGiveAPIResponse updateResp = (BGiveApi.BGiveAPIResponse) apiClassInstance.modify(bgiveId, data, cols);
		return handleResponse(updateResp);
	}

	/**
	 * Description : update syncRecord record in BRM
	 * Parameters  : None
	 * Return Type : None
	 */
	private static void updateSyncRecord(String objectName) {
		//Clearing heap
		data.clear();
		userIds.clear();

		SObject record = Schema.getGlobalDescribe().get(objectName).newSObject();
		record.put('id', syncRecord.get('Id'));
		if (syncRecord.get(BGIVE_ID_FLD) == null) {
			record.put(BGIVE_ID_FLD, bgiveId);
		}

		if (syncRecord.get(BGIVE_CONTIG_ID_FLD) == null) {
			record.put(BGIVE_CONTIG_ID_FLD, bgiveContigId);
		}

		if (errors != null) {
			record.put(BGIVE_SYNC_ERROR_FLD, errors);
		}
		BBApps_DMLResult dmlResult = BBApps_Crud.doUpdateWithHandling(
			record,
			false,
			new BBApps_ErrorCustomFields(ERR_UPDATE_RECORD)
		);
		if (!dmlResult.isSuccess()) {
			throw new BGiveApiSyncException(dmlResult.getErrors().toString());
		}
	}

	private static Boolean isFieldType(String fieldType) {
		return fieldType == Assets.BGIVE_BRM_FIELD_TYPE_FL;
	}

	private static Boolean isJSONType(String fieldType) {
		return fieldType == Assets.BGIVE_BRM_FIELD_TYPE_JSON;
	}

	private static Boolean isObjectType(String fieldType) {
		return fieldType == Assets.BGIVE_BRM_FIELD_TYPE_OBJ;
	}

	private static Boolean isNoneType(String fieldType) {
		return fieldType == Assets.BGIVE_BRM_FIELD_TYPE_NONE;
	}

	/**
	 * Description   : getFieldValue for relationship field used in fillDataMap
	 * Parameters    : String BRM Field
	 * Return Type   : String field value
	 */

	private static Object getFieldValue(String brmField) {
		Boolean isRelationshipField = brmField.contains('__r');
		if (isRelationshipField) {
			List<String> objNameList = brmField.split('\\.');
			String fieldName = objNameList.remove(objNameList.size() - 1);
			Sobject currentObj = syncRecord;
			for(Integer i = 0; i < objNameList.size(); i++) {
				String relationshipName = objNameList.get(i);
				if(currentObj != null) {
                    currentObj = currentObj.getSObject(relationshipName);
                } else {
                    return '';
                }
			}
			return currentObj != null ? (currentObj.get(fieldName)) : '';
        } else {
			return (syncRecord.get(brmField));
		}
	}

	private static Object getValue(String fieldType, String brmField, Object defaultValue) {
		if (isFieldType(fieldType)) {
			Object fieldValue = getFieldValue(brmField) ?? defaultValue;
			return normalizeBRMFieldValueForApi(fieldValue);
		} else if (isJSONType(fieldType)) {
			return parsedDataJsonMap.get(brmField) ?? defaultValue;
		} else if (isNoneType(fieldType)) {
			return defaultValue;
		}
		return null;
	}

    /**
	 * Description   : Converts BRN field values to match BGive/API payloads. Date values use
	 * 				   IMUtil.formatDateForApi so they serialize as date only (yyyy-MM-dd) instead of
	 * 				   Apex default strings that include time portion. All other types pass through unchanged.
	 * Parameters    : fieldValue Object from the BRM record.
	 * Return Type   : Object - formatted Date string for Date inputs; otherwise the original fieldValue;
	 */
	private static Object normalizeBRMFieldValueForApi(Object fieldValue) {
		if(fieldValue instanceOf Date) {
			return IMUtil.formatDateForApi((Date) fieldValue);
		}
		return fieldValue;
	}

	/**
	 * Description : update userContactMap for User Lookup Mapping Type
	 * Parameters  : None
	 * Return Type : None
	 */
	private static void setDataForUserFields() {
		//get the Bgive id from Contact record
		Map<String, String> userContactMap = new Map<String, String>();
		List<Contact> contactsList = IMUtil.getContactList(userIds);
		if (contactsList.size() > 0) {
			//Fill the userContactMap with user id and related Bgive id
			for (Contact con : contactsList) {
				userContactMap.put(con.BRM_User__c, String.valueOf(con.get(Assets.BGIVE_ID)));
			}
		}

		if (bgiveFieldToUserMap.size() > 0) {
			for (String bgiveField : bgiveFieldToUserMap.keySet()) {
				Map<String, Object> userMap = new Map<String, Object>();
                if(userContactMap.get(bgiveFieldToUserMap.get(bgiveField)) != null){
				userMap.put('id', userContactMap.get(bgiveFieldToUserMap.get(bgiveField)));
				data.put(bgiveField, userMap);
			}
		}
	}
    }

	/**
	 * Description   : getSegmentTeam
	 * Parameters    : Accepts String Segment Team Name
	 * Return Tyep   : String - BGive ID
	 */
	private static String getSegmentTeam(String segmentId, String teamId) {
		Segment_Team__c rec = IMUtil.getSegmentTeam(segmentId, teamId);
		return rec != null ? String.valueOf(rec.get(Assets.BGIVE_ID)) : '';
	}

	/**
	 * Description : Get the list of associated geo areas
	 * Parameters  : initiativeId Id, fieldName String
	 * Return Type : List<String>
	 */
	private static List<String> getGeoAreas(Id initiativeId, String fieldName) {
		List<IM_Strategic_Locations__c> strategicLocations = IMUtil.getStrategicLocations(initiativeId);
		List<String> geoAreas = new List<String>();
		for (IM_Strategic_Locations__c stl : strategicLocations) {
			String parentObject = fieldName?.split('\\.').get(0);
			String actualFieldName = fieldName?.split('\\.').get(1);
			geoAreas.add(String.valueOf(stl.getSobject(parentObject).get(actualFieldName)));
		}
		return geoAreas;
	}

	/** 
	* Description	: Returns the value used for SYNC_ALWAYS mismatch check.
	* Parameters	: syncFieldMapping Bgive_Sync_Field_Mapping__mdt
	* Return Type   : Object
	*/
	private static Object getComparisonValueForSyncAlways(Bgive_Sync_Field_Mapping__mdt syncFieldMapping) {
		String brmField = syncFieldMapping.BRM_Field__c;
		Object dataValue = getValue(syncFieldMapping.BRM_Field_Type__c, brmField, syncFieldMapping.Default_Value__c);
		if(syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_USER_LOOKUP) {
			return dataValue;
		}
		if(syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_SEGMENT) {
			String segmentId = syncRecordFields.contains(segmentFieldName)
				? (String) syncRecord.get(segmentFieldName) != null ? (String) syncRecord.get(segmentFieldName) : ''
				: (String) dataValue;
			String teamId = syncRecordFields.contains(teamFieldName)
				? (String) syncRecord.get(teamFieldName) != null ? (String) syncRecord.get(teamFieldName) : ''
				: (String) parsedDataJsonMap.get('program_sfid');
			return (segmentId != null && teamId != null) ? getSegmentTeam(segmentId, teamId) : null;
		}
		if(syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_RELATED_LIST) {
			return (Object) getGeoAreas(syncRecord.Id, brmField);
		}
		if(syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_VALUE ||
			syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_RELATION_VALUE ||
			syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_PICKLIST) {
			return dataValue;
		}
		return null;
	}
}