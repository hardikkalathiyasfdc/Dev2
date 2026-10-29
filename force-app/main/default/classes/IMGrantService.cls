/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 03/30/2025
 * Jira        : IM-134
 * Description : This class is used to sync IM Grant record in BGive system when the user clicks on the sync to Bgive button the custom grant UI.
 * Test        : Yet to be created.
 * ChangeLog   :
 * Gauri IM-519: Modified the unlink method to also clear the Bgive_IM_Connection__c & Funded_By_Multiple_Initiatives__c field in Bgive when unlinking.
 * Gauri IM-519: Added the delete zero amount grant & the unlinkBRM to unlink in BRM methods.
 * Gauri IM-452: Added logic for error logging framework
 * Paddy IM-523: Added logic to check whether record is locked in Bgive.
 * Gauri IM-570: Added logic to sync the partner changes from BIM to Bgive.
 * Paddy IM-572: Added logic to update Open Request Amendment as Bgive Managed.

 */
public with sharing class IMGrantService {

	private static IM_Grant__c imGrantRec;
	//Maps
	private static Map<String, Object> bgiveSyncResultMap;
	private static Map<String, Object> paymentResultMap;
	private static Map<String, Object> allocationResultMap;

	// Needed for meta-data
	private static Map<String, Map<String, String>> picklistValMap = new Map<String, Map<String, String>>();

	//List
	private static List<Object> parsedPaymentJson = new List<Object>();
	//Booleans and Strings
	private static String BGIVE_ID_FLD = 'Bgive_Id__c';
	//Exception
    public class IMGrantServiceException extends Exception{}

	private static final String ERR_SYNC_GRANT = 'SYNC_GRANT_FAILED';
	private static final String ERR_UPDATE_IM_GRANT = 'UPDATE_IM_GRANT_FAILED';
	private static final String ERR_GET_BGIVE_GRANT = 'GET_BGIVE_GRANT_FAILED';
	private static final String ERR_LINK_BGIVE_GRANT = 'LINK_BGIVE_GRANT_FAILED';
	private static final String ERR_UNLINK_GRANT = 'UNLINK_GRANT_FAILED';
	private static final String ERR_UNLINK_BRM = 'UNLINK_BRM_FAILED';
	private static final String ERR_DELETE_ZERO_AMT_IMGRANT = 'DELETE_ZERO_AMT_IMGRANT_FAILED';
	private static final String ERR_SYNC_PARTNER_CHANGE = 'SYNC_PARTNER_CHANGE_FAILED';
	private static final String ERR_SYNC_FROM_BGIVE = 'SYNC_FROM_BGIVE_FAILED';
	private static final String ERR_SYNC_IM_GRANT = 'SYNC_IM_GRANT_FAILED';

	/**
	 * Description : Sync method responsible for grant creation/update and payments/allocations creation/update
	 * Parameters  : Accepts grant id
	 * Return Type : Void
	 */
	public static void sync(String imGrantId, String type) {
		try {
			if (type == 'Bgive Managed') {
				link(imGrantId);
			} else {
				List<String> columns = new List<String>{
					'contig_id',
					'state',
					'amount_recommended_local',
					'project_title_internal',
					'grant_begins_at',
					'grant_closed_at',
					'program_organization_id',
					'program_org_name'
				};
				//get the grant record based on the grantId received
				imGrantRec = IMUtil.getImGrant(imGrantId);
				if (imGrantRec != null) {
					if (imGrantRec.get('Funded_By_Multiple_Initiatives__c') == 'No' && type == Assets.SINGLE_CREATE) {
						//Call the sync method to create/update the respective Bgive Grant in BGive/Fluxx
						bgiveSyncResultMap = BGiveApiSync.sync(imGrantRec, 'IM_Grant__c', columns);
						checkForErrors();
						parseDataJson((String) imGrantRec.get(Assets.DATAJSON), Assets.BGIVE_PAYMENT_NAME);
						//SCENARIO 1 and SCENARIO 2
						if (!bgiveSyncResultMap.isEmpty() && bgiveSyncResultMap.get('BgiveId') != null) {
							//Assumption is that all the payment data will be stored as per the Bgive data format.
							if (!parsedPaymentJson.isEmpty()) {
								paymentResultMap = IMPaymentService.createPayments(String.valueOf(bgiveSyncResultMap.get('BgiveId')), parsedPaymentJson);
								if (!paymentResultMap.isEmpty() && paymentResultMap.containsKey('allPaymentsCreated')) {
                                    updateGrantRecord();
								}
							}
							//Just Grant Update - No Payments present to process - Create/Update
							else {
								updateGrantRecord();
							}
						}
					} else if (imGrantRec.get('Funded_By_Multiple_Initiatives__c') == 'Yes' && type == Assets.PARTIAL_FIRST_ALLOCATION) {
						//Incase of Partial, create allocation records first and then update the grant in Bgive
						//SCENARIO 3
						allocationResultMap = IMAllocationService.createAllocations(imGrantRec.Bgive_Id__c);
						if (allocationResultMap != null && !allocationResultMap.isEmpty() && allocationResultMap.containsKey('allAllocationsCreated')) {
							//Call Bgive Sync, all allocation records got created
							bgiveSyncResultMap = BGiveApiSync.sync(imGrantRec, 'IM_Grant__c', columns);
							checkForErrors();
							if (!bgiveSyncResultMap.isEmpty() && bgiveSyncResultMap.get('BgiveId') != null) {
								updateGrantRecord();
							}
						} else if (allocationResultMap != null && !allocationResultMap.isEmpty() && allocationResultMap.containsKey('Errors')) {
							//Allocation records creation failed, store the errors in the sync error field.
                            updateGrantRecord();
						}
					} else if (imGrantRec.get('Funded_By_Multiple_Initiatives__c') == 'Yes' && type == Assets.PARTIAL_SUBSEQUENT_ALLOCATION) {
						bgiveSyncResultMap = BGiveApiSync.sync(imGrantRec, 'IM_Grant__c', columns);
						checkForErrors();
						if (!bgiveSyncResultMap.isEmpty() && bgiveSyncResultMap.get('BgiveId') != null) {
							updateGrantRecord();
						}
					}
					// added else to push amount
					else {
						bgiveSyncResultMap = BGiveApiSync.sync(imGrantRec, 'IM_Grant__c', columns);
						checkForErrors();
						if (!bgiveSyncResultMap.isEmpty() && bgiveSyncResultMap.get('BgiveId') != null) {
							updateGrantRecord();
						}
					}
				} else {
					throw new IMGrantServiceException('No Grant Record returned for the given grant id');
				}
			}
		} catch (Exception ex) {
			//Exception - update sync error field.
			imGrantRec.Sync_Error__c = String.valueOf(ex) + ' || ';
			BBApps_Crud.doUpdate(
				imGrantRec,
				false
			);
			BBApps_ErrorHandler.logErrors(imGrantRec, ex, new BBApps_ErrorCustomFields(ERR_SYNC_GRANT));
			throw new IMGrantServiceException(String.valueOf(ex));
		}
	}


	/**
	 * Description : parses the data json into respective parsedPaymentJson map to access field values
	 * Parameters  : Accepts the data json from the grant record, and the object name
	 * Return Type : Void
	 */
	private static void parseDataJson(String dataJson, String objectName) {
		Map<String, Object> dataJsonMap = (Map<String, Object>) JSON.deserializeUntyped(dataJson);
		if (dataJsonMap.containsKey(objectName)) {
			parsedPaymentJson = (List<Object>) dataJsonMap.get(objectName);
		}
	}

	/**
	 * Description : update syncRecord record in BRM
	 * Parameters  : None
	 * Return Type : None
	 */
	private static void updateGrantRecord() {

		// Getting picklist values from custom meta-data
		picklistValMap = IMUtil.getPicklistValuesFromMetadata(Assets.IM_GRANT);

		//Field Updates
		if (paymentResultMap != null && paymentResultMap.containsKey(Assets.DATAJSON)) {
			imGrantRec.Data_JSON__c = (String) paymentResultMap.get(Assets.DATAJSON);
		}
		imGrantRec.Bgive_Id__c = (String) bgiveSyncResultMap.get('BgiveId');
		imGrantRec.Bgive_Contig_Id__c = bgiveSyncResultMap.get('BgiveContigId') != null ? (String) bgiveSyncResultMap.get('BgiveContigId') : '';

		if (bgiveSyncResultMap.get('Record') != null) {
			Map<String, Object> record = (Map<String, Object>) bgiveSyncResultMap.get('Record');
			imGrantRec.Bgive_Status__c = record.get('state') != null ? picklistValMap.get('state')?.get(String.valueOf(record.get('state'))) : '';
			imGrantRec.Bgive_Amount_Local__c = record.get('amount_recommended_local') != null
				? (Decimal) record.get('amount_recommended_local')
				: imGrantRec.Bgive_Amount_Local__c;
			imGrantRec.Project_Title_Internal__c = record.get('project_title_internal') != null
				? (String) record.get('project_title_internal')
				: imGrantRec.Project_Title_Internal__c;
			imGrantRec.Bgive_Program_Organization_Id__c = record.get('program_organization_id') != null 
				? String.valueOf((Integer) record.get('program_organization_id')) 
				: '';
			imGrantRec.Bgive_Grantee_Name__c = record.get('program_org_name') != null 
				? (String) record.get('program_org_name') 
				: '';
			if (record.get('grant_begins_at') != null) {
				String startDate = String.valueOf(record.get('grant_begins_at'));
				imGrantRec.Start_Date__c = Date.valueOf(startDate.substring(0, startDate.indexOf('T')));
			}
			if (record.get('grant_closed_at') != null) {
				String endDate = String.valueOf(record.get('grant_closed_at'));
				imGrantRec.End_Date__c = Date.valueOf(endDate.substring(0, endDate.indexOf('T')));
			}
		}

		imGrantRec.Sync_Error__c = '';
		//Check for Errors in bgiveSyncResultMap
		if (bgiveSyncResultMap.get('Errors') != null) {
			imGrantRec.Sync_Error__c = imGrantRec.Sync_Error__c + '||' + bgiveSyncResultMap.get('Errors');
		}
		//Check for Errors in paymentResultMap
		if (paymentResultMap != null && paymentResultMap.containsKey('Errors') && paymentResultMap.get('Errors') != null) {
			imGrantRec.Sync_Error__c = imGrantRec.Sync_Error__c + '||' + paymentResultMap.get('Errors');
		}
		//Check for Errors in allocationResultMap
        if(allocationResultMap != null && !allocationResultMap.isEmpty() && allocationResultMap.containsKey('Errors') && allocationResultMap.get('Errors') != null){
			imGrantRec.Sync_Error__c = imGrantRec.Sync_Error__c + '||' + allocationResultMap.get('Errors');
		}

		BBApps_DMLResult dr = BBApps_Crud.doUpdateWithHandling(
			imGrantRec,
			false,
			new BBApps_ErrorCustomFields(ERR_UPDATE_IM_GRANT)
		);
        if(!dr.isSuccess()){
			BBApps_ErrorHandler.logErrors(imGrantRec, new IMGrantServiceException(dr.getErrors().toString()), new BBApps_ErrorCustomFields(ERR_UPDATE_IM_GRANT));
            throw new IMGrantServiceException(dr.getErrors().toString());
		}
	}

	/**
	 * Description : Calls BGive API to fetch BGive Grant request record using bgive contig id.
	 * Parameters  : String imGrantContigId
	 * Return Type : Map<String,Object>
	 */
	public static Map<String, Object> getBgiveGrantUsingContigId(String imGrantContigId) {

		// Getting picklist values from custom meta-data
		picklistValMap = IMUtil.getPicklistValuesFromMetadata(Assets.IM_GRANT);

		Map<String, Object> grantRequestMap = new Map<String, Object>();
		//Set the filter
		BGiveFilterCondition contigIdCondition = new BGiveFilterCondition('contig_id', BGiveFilterCondition.Operator.EQ, imGrantContigId);
		BGiveApiFilter filter = new BGiveApiFilter();
		filter.addCondition(contigIdCondition);
		List<String> cols = new List<String>{'id','state','program_organization_id','brm_id','contig_id','program_id','program_org_name','amount_recommended_local','funded_by_multiple_initiatives','bgive_im_connection','project_title_internal','grant_begins_at','grant_closed_at','fx_type_id','granted'};
		BGiveApiGrant bgiveApiGrant = new BGiveApiGrant();
		bgiveApiGrant.setFilters(filter.getFilterString());
		try {
			BGiveApi.BGiveAPIListResponse fetchResponse = (BGiveApi.BGiveAPIListResponse) bgiveApiGrant.get(cols);
			if (fetchResponse.records != null && fetchResponse.records.size() > 0) {
				grantRequestMap = (Map<String, Object>) fetchResponse.records.get(0);
				if (grantRequestMap.containsKey('state')) {
					grantRequestMap.put('state', picklistValMap.get('state')?.get(String.valueOf(grantRequestMap.get('state'))));
				}
				return grantRequestMap;
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_BGIVE_GRANT));
		}
		return null;
	}

	/**
	 * Description : Method to unlink brm and bgive grant
	 * Parameters  : IM_Grant__c imGrant, IM_Budget_Grant__c budgetGrant, String actionType (actionType can be 'Decline', 'Delete' or 'Unlink')
	 * Return Type : void
	 */
	public static void unlink(IM_Grant__c imGrant, IM_Budget_Grant__c budgetGrant, String actionType) {
		if (imGrant != null) {
			try {
				List<String> cols = new List<String>{ 'id', 'brm_id', 'bgive_im_connection', 'marked_for_decline', 'marked_for_delete' };
				Map<String, Object> data = new Map<String, Object>();
				data.put('brm_id', '');
				data.put('bgive_im_connection', new List<String>{});
				Datetime myDateTime = datetime.now();
				String markedForFields = myDateTime.format('yyyy/MM/dd') + ', ' + UserInfo.getUserEmail();
				if(actionType == 'Decline'){
					data.put('marked_for_decline', markedForFields);
				} else if(actionType == 'Delete'){
					data.put('marked_for_delete', markedForFields);
				}
				
				BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiGrant().modify(imGrant.Bgive_Id__c, data, cols);
				if (updateResponse.record != null) {
					unlinkBRM(imGrant, budgetGrant);
				}
			} catch (Exception e) {
				imGrant.Sync_Error__c = 'Error while unlinking the grant record. ' + e.getMessage();
				BBApps_Crud.doUpdate(
					imGrantRec,
					false
				);
				BBApps_ErrorHandler.logErrors(imGrantRec, e, new BBApps_ErrorCustomFields(ERR_UNLINK_GRANT));
				throw new IMGrantServiceException('Could not unlink the bgive grant record. ' + e.getMessage());
			}
		}
	}

	/**
	 * Description : Method to link brm and bgive grant
	 * Parameters  : imGrantId String
	 * Return Type : Void
	 */
	private static void link(String imGrantId) {
		imGrantRec = IMUtil.getImGrant(imGrantId);
		if (imGrantRec != null) {
			List<String> cols = new List<String>{
				'id',
				'brm_id',
				'contig_id',
				'state',
				'funded_by_multiple_initiatives',
				'bgive_im_connection',
				'project_title_internal',
				'grant_begins_at',
				'grant_closed_at',
				'program_organization_id',
				'program_org_name'
			};
			try {
				BGiveApi.BGiveAPIResponse fetchResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiGrant().fetch(imGrantRec.Bgive_Id__c, cols);
				if (fetchResponse.record != null) {
					Map<String, Object> responseMap = (Map<String, Object>) fetchResponse.record;
					Map<String, Object> data = new Map<String, Object>();
					data.put('brm_id', imGrantRec.Id);
					data.put('bgive_im_connection', imGrantRec.Bgive_IM_Connection__c);
					if (responseMap.get('funded_by_multiple_initiatives') == null || responseMap.get('funded_by_multiple_initiatives') == '') {
						data.put('funded_by_multiple_initiatives', imGrantRec.Funded_By_Multiple_Initiatives__c);
					} else {
						data.put('funded_by_multiple_initiatives', responseMap.get('funded_by_multiple_initiatives'));
					}
					BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiGrant().modify(imGrantRec.Bgive_Id__c, data, cols);
					if (updateResponse.record != null) {
						Map<String, Object> updateResponseMap = (Map<String, Object>) updateResponse.record;
						bgiveSyncResultMap = new Map<String, Object>();
						bgiveSyncResultMap.put('BgiveId', String.valueOf(updateResponseMap.get('id')));
						bgiveSyncResultMap.put('BgiveContigId', updateResponseMap.get('contig_id'));
						bgiveSyncResultMap.put('Record', updateResponse.record);

						updateAmendmentRequest(imGrantRec);
						updateGrantRecord();
					}
				}
			} catch (Exception e) {
				BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_LINK_BGIVE_GRANT));
				throw new IMGrantServiceException('Could not modify the bgive grant record. ' + e.getMessage());
			}
		}
	}

	/**
	 * Description : Method to unlink brm grant
	 * Parameters  : IM_Grant__c imGrantRec, IM_Budget_Grant__c budgetGrant
	 * Return Type : void
	 */
	private static void unlinkBRM(IM_Grant__c imGrantRec, IM_Budget_Grant__c budgetGrant) {
		try{
			imGrantRec.Bgive_Id__c = '';
			imGrantRec.Bgive_Contig_Id__c = '';
			imGrantRec.Bgive_IM_Connection__c = '';

			imGrantRec.Sync_Error__c = '';
			if(imGrantRec?.Budget_Amount_USD__c == 0){
				deleteZeroAmountIMGrant(imGrantRec, budgetGrant);
			} else{
				BBApps_Crud.doUpdate(
					imGrantRec,
					false
				);
			}
		}catch(Exception e){
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_UNLINK_BRM));
			throw new IMGrantServiceException('Could not unlink the bgive grant record. ' + e.getMessage());
		}
	}

	/**
	 * Description : Method to soft delete IM Grant (i.e mark Deleted__c as true on Grants) in case of Zero Amount scenario
	 * Parameters : imGrant IM_Grant__c , budgetGrant IM_Budget_Grant__c
	 * Return Type : void
	 */
	private static void deleteZeroAmountIMGrant(IM_Grant__c imGrant, IM_Budget_Grant__c budgetGrant) {
		try {
			if (imGrant != null) {
				budgetGrant.Deleted__c = true;
				budgetGrant.Budget_Amount_USD__c = 0;
				budgetGrant.Budget_Amount_Local__c = 0;
				budgetGrant.Confirmed_Budget_Amount_USD__c = 0;
				budgetGrant.Confirmed_Budget_Amount_Local__c = 0;
				budgetGrant.Is_Active__c = false;
		
				List<IM_Non_Budget_Grant__c> nonBudgetGrants = IMUtil.getNonBudgetedGrants(imGrant.Id);
				if(nonBudgetGrants.isEmpty()) {
					imGrant.Deleted__c = true;
				}
				BBApps_Crud.doUpdate(
					imGrant,
					false
				);
				}
			BBApps_Crud.doUpdate(
				budgetGrant,
				false
			);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_DELETE_ZERO_AMT_IMGRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

    /**
	 * Description : Method to refresh IM Grant with details from Bgive Grant
	 * Parameters  : IM_Grant__c imGrant
	 * Return Type : void
	 */
	public static void syncFromBgive(IM_Grant__c imGrant) {
		if (imGrant != null) {
			try {
				Map<String, Object> grantRequestMap = new Map<String, Object>();

				List<String> cols = new List<String>{'id','state','program_organization_id','brm_id','contig_id','program_id','program_org_name','amount_recommended_local','funded_by_multiple_initiatives','bgive_im_connection','project_title_internal','grant_begins_at','grant_closed_at','fx_type_id','granted'};
				
				BGiveApi.BGiveAPIResponse fetchResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiGrant().fetch(imGrant.Bgive_Id__c, cols);
				if (fetchResponse.record != null) {
					grantRequestMap = (Map<String, Object>) fetchResponse.record;
					List<Object> openAmendments = new BgiveAPIRequestAmendment().getOpenAmendmentsByRequestId(imGrant.Bgive_Id__c);
					syncIMGrant(imGrant, grantRequestMap, openAmendments);
				}
			} catch (Exception e) {
				imGrant.Sync_Error__c = 'Unable to update the grant data from Bgive. ' + e.getMessage();
				BBApps_Crud.doUpdate(
					imGrant,
					false
				);
				BBApps_ErrorHandler.logErrors(imGrant, e, new BBApps_ErrorCustomFields(ERR_SYNC_FROM_BGIVE));
				throw new IMGrantServiceException('Unable to update the grant data from Bgive. ' + e.getMessage());
			}
		}
	}

	/**
	 * Description : Method to update IM Grant with details from Bgive Grant record
	 * Parameters  : IM_Grant__c imGrant, Map<String, Object> grantRequestMap, List<Object> openAmendments
	 * Return Type : void
	 */
	public static void syncIMGrant(IM_Grant__c imGrant, Map<String, Object> grantRequestMap, List<Object> openAmendments) {
		if (imGrant != null) {
			try {
				picklistValMap = IMUtil.getPicklistValuesFromMetadata(Assets.IM_GRANT);

				String state = (String) grantRequestMap.get('state');
				imGrant.Bgive_Status__c = state != null ? picklistValMap?.get('state')?.get(String.valueOf(grantRequestMap.get('state'))) : imGrant.Bgive_Status__c;

				Decimal amountRecommendedLocal = (Decimal) grantRequestMap.get('amount_recommended_local');
				imGrant.Bgive_Amount_Local__c = amountRecommendedLocal ?? imGrant.Bgive_Amount_Local__c;

				String projectTitleInternal = (String) grantRequestMap.get('project_title_internal');
				imGrant.Project_Title_Internal__c = projectTitleInternal ?? imGrant.Project_Title_Internal__c;

				Integer programOrganizationId = (Integer) grantRequestMap.get('program_organization_id');
				imGrant.Bgive_Program_Organization_Id__c = String.valueOf(programOrganizationId) ?? imGrant.Bgive_Program_Organization_Id__c;

				String programOrgName = (String) grantRequestMap.get('program_org_name');
				imGrant.Bgive_Grantee_Name__c = programOrgName ?? imGrant.Bgive_Grantee_Name__c;

				if (grantRequestMap.get('grant_begins_at') != null) {
					String startDate = String.valueOf(grantRequestMap.get('grant_begins_at'));
					imGrant.Start_Date__c = Date.valueOf(startDate.substring(0, startDate.indexOf('T')));
				}
				if (grantRequestMap.get('grant_closed_at') != null) {
					String endDate = String.valueOf(grantRequestMap.get('grant_closed_at'));
					imGrant.End_Date__c = Date.valueOf(endDate.substring(0, endDate.indexOf('T')));
				}
				if(openAmendments != null && !openAmendments.isEmpty()){
					Boolean isValidAmendment = isValidAmendment(imGrant, openAmendments);
					if(!isValidAmendment) {
						// If there is no latest amendment id stored on the grant, then we can take the details of the first open amendment and update the grant record.
						Map<String, Object> latestAmendmentMap = (Map<String, Object>) openAmendments?.get(0);
						String amendmentId = String.valueOf(latestAmendmentMap.get('id'));
						imGrant.Amendment_Bgive_Id__c = amendmentId ?? imGrant.Amendment_Bgive_Id__c;

						if(latestAmendmentMap.get('end_date') != null){
							String endDate = String.valueOf(latestAmendmentMap.get('end_date'));
							imGrant.Amendment_Future_End_Date__c = Date.valueOf(endDate.substring(0, endDate.indexOf('T')));
						}
						
						Decimal futureAmountLocal = (Decimal) latestAmendmentMap.get('amount_recommended_local');
						imGrant.Amendment_Future_Amount_Local__c = futureAmountLocal ?? imGrant.Amendment_Future_Amount_Local__c;
					}
				}else{
					imGrant.Amendment_Bgive_Id__c = '';
					imGrant.Amendment_Future_End_Date__c = null;
					imGrant.Amendment_Future_Amount_Local__c = null;
				}
				BBApps_Crud.doUpdate(
					imGrant,
					false
				);
			} catch (Exception e) {
				imGrant.Sync_Error__c = 'Error while refreshing the grant record. ' + e.getMessage();
				BBApps_Crud.doUpdate(
					imGrant,
					false
				);
				BBApps_ErrorHandler.logErrors(imGrant, e, new BBApps_ErrorCustomFields(ERR_SYNC_IM_GRANT));
				throw new IMGrantServiceException('Unable to update the grant data from Bgive. ' + e.getMessage());
			}
		}
	}

	/**
	 * Description : Method to check if current amendment details are the valid details
	 * Parameters  : IM_Grant__c imGrant, Map<String, Object> grantRequestMap, List<Object> openAmendments
	 * Return Type : Boolean
	 */
	public static Boolean isValidAmendment(IM_Grant__c imGrant, List<Object> openAmendments) {
		Boolean isValidAmendment = false;
			if(imGrant?.Amendment_Bgive_Id__c != null){
				for(Object amendmentObj : openAmendments) {
					Map<String, Object> amendmentMap = (Map<String, Object>) amendmentObj;
					if(amendmentMap.containsKey('id') && amendmentMap.get('id') != null && String.valueOf(amendmentMap.get('id')) == imGrant.Amendment_Bgive_Id__c) {
						isValidAmendment = true;
						break;
					}
				}
			}
		return isValidAmendment;
	}
    
    /**
	 * Description : Checks for any errors returned from BGive Sync.
	 * Parameters  : None
	 * Return Type : void
	 */
	private static void checkForErrors() {
		if(bgiveSyncResultMap.get('Errors') != null) {
			String error = (String)bgiveSyncResultMap.get('Errors');
			error = error.remove('BGiveApiSyncException:[]:').trim();
			throw new IMGrantServiceException(error);
		}
	}

	/**
	 * Description : Method to sync the partner changes from BIM to Bgive
	 * Parameters  : imGrantId String
	 * Return Type : Void
	 */
	public static void syncPartnerWithBGive(String imGrantId) {
		imGrantRec = IMUtil.getImGrant(imGrantId);
		if (imGrantRec != null) {
			List<String> cols = new List<String>{
				'id',
				'brm_id',
				'contig_id',
				'program_organization_id',
				'program_org_name'
			};
			try {
				Map<String, Object> data = new Map<String, Object>();
				data.put('program_organization_id', imGrantRec?.Partner_Org__r?.Bgive_Id__c);

				BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BGiveApiGrant().modify(imGrantRec.Bgive_Id__c, data, cols);
				if (updateResponse.record != null) {
					Map<String, Object> updateResponseMap = (Map<String, Object>) updateResponse.record;
					bgiveSyncResultMap = new Map<String, Object>();
					bgiveSyncResultMap.put('BgiveId', String.valueOf(updateResponseMap.get('id')));
					bgiveSyncResultMap.put('BgiveContigId', updateResponseMap.get('contig_id'));
					bgiveSyncResultMap.put('Record', updateResponse.record);
					updateIMGrantRecord(imGrantRec, updateResponseMap);
				}
			} catch (Exception e) {
				BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_SYNC_PARTNER_CHANGE));
				throw new IMGrantServiceException('Could not modify the bgive grant record with the new partner. ' + e.getMessage());
			}
		}
	}

	/**
	 * Description : Method to update IM Grant with Partner details from Bgive Grant record
	 * Parameters  : IM_Grant__c imGrant, Map<String, Object> updateResponseMap
	 * Return Type : void
	 */
	public static void updateIMGrantRecord(IM_Grant__c imGrant, Map<String, Object> updateResponseMap) {
		if (imGrant != null) {
			try {
				Integer programOrganizationId = (Integer) updateResponseMap?.get('program_organization_id');
				imGrant.Bgive_Program_Organization_Id__c = String.valueOf(programOrganizationId) ?? imGrant.Bgive_Program_Organization_Id__c;

				String programOrgName = (String) updateResponseMap?.get('program_org_name');
				imGrant.Bgive_Grantee_Name__c = programOrgName ?? imGrant.Bgive_Grantee_Name__c;

				BBApps_Crud.doUpdate(
					imGrant,
					false
				);
			} catch (Exception e) {
				imGrant.Sync_Error__c = 'Error while changing that Partner in Bgive. ' + e.getMessage();
				BBApps_Crud.doUpdate(
					imGrant,
					false
				);
				BBApps_ErrorHandler.logErrors(imGrant, e, new BBApps_ErrorCustomFields(ERR_UPDATE_IM_GRANT));
				throw new IMGrantServiceException('Unable to change the partner in Bgive. ' + e.getMessage());
			}
		}
	}

	/**
	 * Description : Method to update Open Request Amendment as Bgive Managed.
	 * Parameters  : IM_Grant__c imGrant
	 * Return Type : void
	 */
	public static void updateAmendmentRequest(IM_Grant__c imGrant) {
		List<Object> openAmendments = new BgiveAPIRequestAmendment().getOpenAmendmentsByRequestId(imGrant.Bgive_Id__c);
		if(openAmendments != null && !openAmendments.isEmpty()) {
			if(isValidAmendment(imGrant, openAmendments)) {
				List<String> cols = new List<String>{
					'id',
					'bgive_im_connection'
				};
				Map<String, Object> data = new Map<String, Object>();
				data.put('bgive_im_connection', imGrantRec.Bgive_IM_Connection__c);

				BGiveApi.BGiveAPIResponse updateResponse = (BGiveApi.BGiveAPIResponse) new BgiveAPIRequestAmendment().modify(imGrant.Amendment_Bgive_Id__c, data, cols);
			}
		}
	}
}