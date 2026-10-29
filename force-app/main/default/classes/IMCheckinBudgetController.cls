/*
    Author     : Sai Bhargav Thotakura
    Date       : 4th Feb 2025
    Jira       : IM-106
    Description: Use this class to checkin the budget data using the Checkin button on the record detail page of Budget record detail page.
    Test Class : IMCheckinBudgetControllerTest
	ChangeLog  :  Sai on 08/27/2025: IM-375: Update code block to turn description and unique identifier to string values.
	Gauri on 03/03/2026: IM-518: Added logic to soft delete or undelete the budget orgs based on the latest checkin instead of hard delete.
	Paddy on 03/10/2026: IM-527: Updated fetchOrgMapping fallback to Account and multi-match null; AKA__c on orgs and added getAccountAKA method.
	Paddy on 06/15/2025: IM-450: Added logic for error logging framework
*/
public with sharing class IMCheckinBudgetController {

	private static final String ERR_GET_BUDGET = 'CHECKIN_BUDGET_CONTROLLER_GET_BUDGET_FAILED';
	private static final String ERR_GET_TOTAL_AMOUNTS_PARTNER = 'CHECKIN_BUDGET_CONTROLLER_GET_TOTAL_AMOUNTS_PARTNER_FAILED';
	private static final String ERR_GET_BUDGET_TEMPLATE = 'CHECKIN_BUDGET_CONTROLLER_GET_BUDGET_TEMPLATE_FAILED';
	private static final String ERR_DELETE_BUDGET_FILE = 'CHECKIN_BUDGET_CONTROLLER_DELETE_BUDGET_FILE_FAILED';
	private static final String ERR_FETCH_ORG = 'CHECKIN_BUDGET_CONTROLLER_GET_FETCH_ORG_MAPPING_FAILED';
	private static final String ERR_SAVE_BUDGET = 'CHECKIN_BUDGET_CONTROLLER_SAVE_BUDGET_FAILED';

	//Global Variable Declaration
	public static IM_Budget__c budgetRecord;
	public static BudgetWrapper budgetWrapperObj = new BudgetWrapper();
	public static TotalAmountWrapper totalAmountWrapperObj = new TotalAmountWrapper();
	public static Map<String, Id> componentMap = new Map<String, Id>();
	public static Map<String, Id> subComponentMap = new Map<String, Id>();
	public static Map<String, Id> partnerMap = new Map<String, Id>();
    public static Map<String,Id> subPartnerMap = new Map<String,Id>();
    public static Map<String,Id> payeeMap = new Map<String,Id>();
	public static Map<String, Id> geographyMap = new Map<String, Id>();
	public static Map<String, Object> partnerOrgNameIdMap = new Map<String, Object>();

	/**
	 * Description  : Fetch the UploadedBudgetTemplate Encoded Data
	 * Parameters   : Accepts String - Contentdocument Id
	 * Return Type  : Returns a String versionData
	 */
	@AuraEnabled
	public static BudgetWrapper getBudget(String budgetId) {
		try {
			if (budgetRecord == null) {
				budgetRecord = IMUtil.getBudget(budgetId);
				budgetWrapperObj.budget = budgetRecord;
				if ((budgetRecord.Checked_Out_By__c) != null && (budgetRecord.Checked_Out_By__c != UserInfo.getUserId())) {
					budgetWrapperObj.isDiffUser = true;
				}
				if (budgetRecord.Status__c == Assets.APPROVED) {
					budgetWrapperObj.isBudgetApproved = true;
				}
			}
		} catch (Exception error) {
			BBApps_ErrorHandler.logErrors(error, new BBApps_ErrorCustomFields(ERR_GET_BUDGET));
			throw new AuraHandledException(Assets.SYS_EXCPETION + error.getMessage());
		}
		return budgetWrapperObj;
	}

	/**
	 * Description  : compute the total amounts for budgetrows grouped by partner name
	 * Parameters   : Accepts String - budget Id
	 * Return Type  : Returns a Wrapper totalAmountsWrapper
	 */
	@AuraEnabled
	public static TotalAmountWrapper getTotalAmountsByPartner(String budgetId) {
		try {
			if (budgetId != null) {
				List<AggregateResult> aggregatedBudgetRows = IMUtil.getTotalAmountsByPartner(budgetId);
				if (!aggregatedBudgetRows.isEmpty()) {
					for (AggregateResult aggregatedBudget : aggregatedBudgetRows) {
						Decimal totalAmount = (Decimal) aggregatedBudget.get('totalAmount');
						if ((String) aggregatedBudget.get('partnerName') == Assets.PARTNER_GATES) {
							totalAmountWrapperObj.totalGatesMoney = totalAmount;
						} else if ((String) aggregatedBudget.get('partnerName') == Assets.PARTNER_AGERUP) {
							totalAmountWrapperObj.totalAgerupMoney = totalAmount;
						} else if ((String) aggregatedBudget.get('partnerName') == Assets.PARTNER_DFAT) {
							totalAmountWrapperObj.totalDfatMoney = totalAmount;
						} else {
							totalAmountWrapperObj.totalBpMoney = totalAmount;
						}
					}
				}
			}
		} catch (Exception error) {
			BBApps_ErrorHandler.logErrors(error, new BBApps_ErrorCustomFields(ERR_GET_TOTAL_AMOUNTS_PARTNER));
			throw new AuraHandledException(Assets.SYS_EXCPETION + error.getMessage());
		}
		return totalAmountWrapperObj;
	}

	/**
	 * Description  : Fetch the UploadedBudgetTemplate Encoded Data
	 * Parameters   : Accepts String - Contentdocument Id
	 * Return Type  : Returns a String versionData
	 */
	@AuraEnabled
	public static TemplateWrapper getBudgetTemplate(String budgetId, String documentId) {
		TemplateWrapper templateWrapperRec;
		try {
			if (budgetRecord == null) {
				budgetRecord = IMUtil.getBudget(budgetId);
			}
			if (budgetRecord != null) {
				String metadataRecName = budgetRecord.Budget_Categories__c ?? 'None';
				metadataRecName = metadataRecName.replaceAll(' ', '_').remove(',');
				//Fetch the associated Metadata record with the Name derived.
				IM_Template_Mapping__mdt templateMapping = IM_Template_Mapping__mdt.getInstance(Assets.IM_IB + metadataRecName);
				if (templateMapping == null) {
					throw new AuraHandledException(Assets.NO_TEMPLATES_FOUND);
				}
				Template__c template = IMUtil.getTemplate(templateMapping.Template_Name__c);
				//If Template record present, capture the metadata and template information in the wrapper variable.
				templateWrapperRec = new TemplateWrapper();
				if (template != null) {
					templateWrapperRec.metadata = template.Metadata__c ?? null;
				} else {
					throw new AuraHandledException(Assets.NO_TEMPLATES_FOUND);
				}
				if (documentId != null) {
					ContentVersion cv = IMUtil.getContentVersion(documentId);
					templateWrapperRec.versionData = EncodingUtil.base64Encode(cv.VersionData);
				} else {
					throw new AuraHandledException(Assets.NO_FILE_PRESENT);
				}
			} else {
				throw new AuraHandledException(Assets.NO_BUDGETS_FOUND);
			}
		} catch (Exception error) {
			BBApps_ErrorHandler.logErrors(error, new BBApps_ErrorCustomFields(ERR_GET_BUDGET_TEMPLATE));
			throw new AuraHandledException(Assets.SYS_EXCPETION + error.getMessage());
		}
		return templateWrapperRec;
	}

	/**
	 * Description  : Delete the earlier uploaded budget file in case of checkin Wizard Reset
	 * Parameters   : Accepts String - ContentDocument Id
	 * Return Type  : Returns a Boolean isSuccess
	 */
	@AuraEnabled
	public static Boolean deleteBudgetFile(String documentId) {
		Boolean isSuccess = false;
		try {
			ContentDocument cd = new ContentDocument(Id = documentId);
			BBApps_DMLResult dmlResult = BBApps_Crud.doDelete(cd);
			isSuccess = dmlResult.isSuccess();





		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(documentId + ' - Checkin Reset - Earlier Budget Delete Failed ' + ERR_DELETE_BUDGET_FILE));
			throw new AuraHandledException(ex.getMessage());
		}
		return isSuccess;
	}

	/**
	 * Description  : ConfirmData event triggered
	 * Parameters   : Accepts List - OrgNamesList
	 * Return Type  : Returns a Map<String,Boolean> isOrgFound
	 */
	@AuraEnabled
	public static Map<String, Account> fetchOrgMapping(List<String> orgNames, String budgetId) {
		Map<String, Account> orgMap = new Map<String, Account>();
		try {
			List<IM_Budget_Org__c> budgetOrgsList = [
				SELECT Organization__c, Organization__r.Name, Type__c,  Organization__r.AKA__c
				FROM IM_Budget_Org__c
				WHERE Budget__c = :budgetId AND Organization__r.Name IN :orgNames AND Deleted__c = false 
				WITH SYSTEM_MODE
			];
			Set<String> missingOrgNames = new Set<String>(orgNames);
			if (!budgetOrgsList.isEmpty()) {
				for (IM_Budget_Org__c budOrg : budgetOrgsList) {
					orgMap.put(budOrg.Organization__r.Name, budOrg.Organization__r);
					missingOrgNames.remove(budOrg.Organization__r.Name);
				}
			}

			if(!missingOrgNames.isEmpty()) {
					List<Account> matchingOrgsByNameList = [
										SELECT Name, AKA__c
										FROM Account
										WHERE Name IN :missingOrgNames 
										WITH SYSTEM_MODE
				];

				for (Account org : matchingOrgsByNameList) {
					if(orgMap.containsKey(org.Name)) {
						orgMap.put(org.Name, null);
					} else {
						orgMap.put(org.Name, org);
					}
				}
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FETCH_ORG));
			throw new AuraHandledException(ex.getMessage());
		}
		return orgMap;
	}

	/**
	 * Description  : Returns AKA__c for the given Account Id.
	 * Parameters   : accountId Id
	 * Return Type  : String
	 */
	@AuraEnabled
	public static String getAccountAKA(Id accountId) {
		if(accountId == null) {
			return null;
		}
		List<Account> accounts = [SELECT AKA__c FROM Account WHERE Id = :accountId WITH SYSTEM_MODE LIMIT 1];
		return accounts.isEmpty() ? null : accounts[0].AKA__c;
	}

	/**
	 * Description  : perform save operation
	 * Parameters   : Accepts String budgetId, Map<String,Object> dataMap
	 * Return Type  : retunrs boolean true if success, false if failure
	 */
	@AuraEnabled
	public static Boolean saveBudget(String budgetId, Map<String, Object> dataMap) {
		try {
			if (String.isNotBlank(budgetId)) {
				List<String> recordsToDelete = new List<String>();
				List<String> budgetOrgsToSoftDelete = new List<String>();
				List<IM_Budget_Org__c> budgetOrgsToUpdate = new List<IM_Budget_Org__c>();
				Map<String, Object> existingParamersDataMap = getExistingBudgetParameters(budgetId);
				partnerOrgNameIdMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(dataMap.get('OrgMapping')));
				//Components
				List<IM_Component__c> components = createComponents((List<Object>) dataMap.get('Components'), budgetId);

				if (!components.isEmpty()) {
					List<BBApps_DMLResult> dmlResults =	BBApps_Crud.doUpsert(components, IM_Component__c.External_Id__c, true);
					for (IM_Component__c comp : components) {
						componentMap.put(comp.External_Id__c, comp.Id);
					}
					recordsToDelete.addAll(getRecordsToDelete((Map<String, String>) existingParamersDataMap.get('Component'), componentMap.keySet()));
				}

				List<IM_Component__c> subComponents = createSubComponents((Map<Object, Object>) dataMap.get('SubComponentMapping'), componentMap, budgetId);
				if (!subComponents.isEmpty()) {
					List<BBApps_DMLResult> dmlResults =	BBApps_Crud.doUpsert(subComponents, IM_Component__c.External_Id__c, true);
					for (IM_Component__c subComp : subComponents) {
						subComponentMap.put(subComp.External_Id__c, subComp.Id);
					}
					recordsToDelete.addAll(getRecordsToDelete((Map<String, String>) existingParamersDataMap.get('SubComponent'), subComponentMap.keySet()));
				}

				//Geographies
				List<IM_Geography__c> geographies = createGeograpghies((List<Object>) dataMap.get('Geographies'), budgetId);
				if (!geographies.isEmpty()) {
					List<BBApps_DMLResult> dmlResults =	BBApps_Crud.doUpsert(geographies, IM_Geography__c.External_Id__c, true);
					for (IM_Geography__c geo : geographies) {
						geographyMap.put(geo.External_Id__c, geo.Id);
					}
					recordsToDelete.addAll(getRecordsToDelete((Map<String, String>) existingParamersDataMap.get('Geography'), geographyMap.keySet()));
				}

				//Partner
				List<IM_Budget_Org__c> budgetOrgs = new List<IM_Budget_Org__c>();
				budgetOrgs.addAll(createBudgetOrgs((List<Object>) dataMap.get('Partners'), budgetId, 'Partner'));
				budgetOrgs.addAll(createBudgetOrgs((List<Object>) dataMap.get('SubPartners'), budgetId, 'SubPartner'));
				budgetOrgs.addAll(createBudgetOrgs((List<Object>) dataMap.get('Payee'), budgetId, 'Payee'));
				if (!budgetOrgs.isEmpty()) {
					List<BBApps_DMLResult> dmlResults =	BBApps_Crud.doUpsert(budgetOrgs, IM_Budget_Org__c.External_Id__c, true);
					for (IM_Budget_Org__c partnerOrg : budgetOrgs) {
						partnerMap.put(partnerOrg.External_Id__c, partnerOrg.Id);
					}
					budgetOrgsToSoftDelete.addAll(getRecordsToDelete((Map<String, String>) existingParamersDataMap.get('ActiveBudgetOrg'), partnerMap.keySet()));
					budgetOrgsToUpdate = updateDeleteFlagForOrgs(budgetOrgsToSoftDelete);
				}
				// Updating budget orgs instead of hard deleting to avoid deleting the related data like Budget Grants
				List<BBApps_DMLResult> dmlResults =	BBApps_Crud.doUpdate(budgetOrgsToUpdate, true);

				// Delete other records (except budget orgs)
				BBApps_Crud.doDelete(recordsToDelete, true);
				BBApps_Crud.doDelete([SELECT Id FROM IM_Budget_Row__c WHERE Budget__c = :budgetId], true);
				createBudgetRows(budgetId, (List<Object>) dataMap.get('BudgetRows'));
				updateCheckInDetails(budgetId);
			}
		} catch (DMLException e) {
			Set<String> errorMessages = new Set<String>();
			for (Integer i = 0; i < e.getNumDml(); i++) {
				errorMessages.add(e.getDmlMessage(i));
			}
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_SAVE_BUDGET));
			throw new AuraHandledException(String.join(new List<String>(errorMessages), ''));
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_SAVE_BUDGET));
			throw new AuraHandledException(e.getMessage());
		}
		return true;
	}

	/**
	 * Description    : create budget Org records and return them
	 * Parameters     : Accepts inputList String, String budget Id, String Type
	 * Return Type    : List<Budget_Org__c>
	 */
	private static List<IM_Geography__c> createGeograpghies(List<Object> geographies, String budgetId) {
		List<IM_Geography__c> records = new List<IM_Geography__c>();
		for (Object geo : geographies) {
			String geoStr = (String) geo;
			IM_Geography__c record = new IM_Geography__c(Budget__c = budgetId, Name = geoStr, External_Id__c = budgetId + geoStr);
			records.add(record);
		}
		return records;
	}

	/**
	 * Description    : Based on the budgetId, return the budgetParameters
	 * Parameters     : Accepts String budgetId
	 * Return Type    : Map<String,Object>
	 */
	private static Map<String, Object> getExistingBudgetParameters(String budgetId) {
		Map<String, Object> dataMap = new Map<String, Object>();
		if (String.isNotBlank(budgetId) && String.isNotEmpty(budgetId)) {
			dataMap.put('Component', convertListToMap(IMUtil.getComponents(budgetId)));
			dataMap.put('SubComponent', convertListToMap(IMUtil.getSubComponents(budgetId)));
			dataMap.put('Geopgraphy', convertListToMap(IMUtil.getGeography(budgetId)));
			dataMap.put('ActiveBudgetOrg', convertListToMap(IMUtil.getActiveBudgetOrgs(budgetId)));
		}
		return dataMap;
	}

	/**
	 * Description    : based on the new records and exisiting map get the records to delete
	 * Parameters     : Accepts Map<String,String> existingDataMap , Set<String> newDataMap
	 * Return Type    : List<String>
	 */
	private static List<String> getRecordsToDelete(Map<String, String> existingDataMap, Set<String> newDataMap) {
		List<String> recordsToDelete = new List<String>();
		if (existingDataMap != null) {
			for (String existingRecord : existingDataMap?.keySet()) {
				if (!newDataMap.contains(existingRecord)) {
					recordsToDelete.add(existingDataMap.get(existingRecord));
				}
			}
		}
		return recordsToDelete;
	}

	/**
	 * Description    : Method to soft delete the budget orgs as per the latest checkin
	 * Parameters     : List<String> budgetOrgsToSoftDelete
	 * Return Type    : List<IM_Budget_Org__c>
	 */
	private static List<IM_Budget_Org__c> updateDeleteFlagForOrgs(List<String> budgetOrgsToSoftDelete) {
		List<IM_Budget_Org__c> budgetOrgsToUpdate = new List<IM_Budget_Org__c>();
		if(!budgetOrgsToSoftDelete.isEmpty()) {
			for(String budOrgId : budgetOrgsToSoftDelete) {
				IM_Budget_Org__c record = new IM_Budget_Org__c(Id = budOrgId, Deleted__c = true);
				budgetOrgsToUpdate.add(record);
			}
		}
		return budgetOrgsToUpdate;
	}

	/**
	 * Description    : Simple list to map conversion method
	 * Parameters     : Accepts List<Sobject> records
	 * Return Type    : Map<String,String>
	 */
	private static Map<String, String> convertListToMap(List<Sobject> records) {
		Map<String, String> recordMap = new Map<String, String>();
		for (Sobject record : records) {
			recordMap.put((String) record.get('External_Id__c'), (String) record.get('Id'));
		}
		return recordMap;
	}

	/**
	 * Description    : updateCheckInDetails - When a user performs successful budget checkin via UI
	 * Parameters     : Accepts budgetId
	 * Return Type    : Void
	 */
	private static void updateCheckInDetails(String budgetId) {
		IM_Budget__c budget = new IM_Budget__c(
			Id = budgetId,
			Checked_Out_At__c = null,
			Checked_Out_By__c = null,
			Last_Checked_In_At__c = System.now(),
			Last_Checked_In_By__c = UserInfo.getUserId()
		);
		TriggerFactory.setBypass('IMBudgetTriggerHandler');
		BBApps_Crud.doUpdate(budget);
		TriggerFactory.removeBypass('IMBudgetTriggerHandler');
	}

	/**
	 * Description    : create budget row records
	 * Parameters     : Accepts List<String>
	 * Return Type    : Void
	 */
	private static void createBudgetRows(String budgetId, List<Object> budgetRows) {
		List<IM_Budget_Row__c> budgetRowsToInsert = new List<IM_Budget_Row__c>();
		Map<String, Id> partnerFundByNameMap = getPartnerFundsByName(budgetId);
		for (Object row : budgetRows) {
			Map<Object, Object> budgetRowFieldMap = (Map<Object, Object>) row;
			IM_Budget_Row__c budgetRow = new IM_Budget_Row__c(Budget__c = budgetId);
			String componentName;
			for (Object fieldName : budgetRowFieldMap.keySet()) {
				String field = (String) fieldName;
				Object fieldValue = budgetRowFieldMap.get(field);
				String extId;
				if (field == 'Component__c') {
					extId = budgetId + (String) fieldValue;
					if (componentMap.containsKey(extId)) {
						budgetRow.put(field, componentMap.get(extId));
						componentName = (String) componentMap.get(extId);
					}
				} else if (field == 'SubComponent__c') {
					extId = budgetId + componentName + (String) fieldValue;
					if (subComponentMap.containsKey(extId)) {
						budgetRow.put(field, subComponentMap.get(extId));
					}
				} else if (field == 'Partner__c') {
					extId = budgetId + 'Partner' + (String) partnerOrgNameIdMap.get((String) fieldValue);
					if (partnerMap.containsKey(extId)) {
						budgetRow.put(field, partnerMap.get(extId));
					}
				} else if (field == 'Sub_Partner__c') {
					extId = budgetId + 'SubPartner' + (String) partnerOrgNameIdMap.get((String) fieldValue);
					if (partnerMap.containsKey(extId)) {
						budgetRow.put(field, partnerMap.get(extId));
					}
				} else if (field == 'Payee_Fiscal_Sponsor__c') {
					extId = budgetId + 'Payee' + (String) partnerOrgNameIdMap.get((String) fieldValue);
					if (partnerMap.containsKey(extId)) {
						budgetRow.put(field, partnerMap.get(extId));
					}
				} else if (field == 'Geography__c') {
					extId = budgetId + (String) fieldValue;
					if (geographyMap.containsKey(extId)) {
						budgetRow.put(field, geographyMap.get(extId));
					}
				} else if (field == 'Partner_Fund__c') {
					if (partnerFundByNameMap.containsKey((String) fieldValue)) {
						budgetRow.put(field, partnerFundByNameMap.get((String) fieldValue));
					}
				} else if (field == 'Description__c' || field == 'Unique_Identifier__c') {
					budgetRow.put(field, String.valueOf(fieldValue));
				} else {
					budgetRow.put(field, fieldValue);
				}
			}
			budgetRowsToInsert.add(budgetRow);
		}
		BBApps_Crud.doInsert(budgetRowsToInsert);
	}

	/**
	 * Description    : Accepts budgetId, to get the partner funds related to budget and creates a map of name and id
	 * Parameters     : Accepts String budgetId
	 * Return Type    : Map<String,Id>
	 */
	private static Map<String, Id> getPartnerFundsByName(String budgetId) {
		List<IM_Funding_Source__c> partnerFunds = IMUtil.getPartnerFunds(budgetId);
		Map<String, Id> partnerFundMap = new Map<String, Id>();
		if (!partnerFunds.isEmpty()) {
			for (IM_Funding_Source__c fund : partnerFunds) {
				partnerFundMap.put(fund.Name, fund.Id);
			}
		}
		return partnerFundMap;
	}

	/**
	 * Description    : create budget Org records and return them
	 * Parameters     : Accepts inputList String, String budget Id, String Type
	 * Return Type    : List<Budget_Org__c>
	 */
	private static List<IM_Budget_Org__c> createBudgetOrgs(List<Object> orgIds, String budgetId, String type) {
		List<IM_Budget_Org__c> records = new List<IM_Budget_Org__c>();
		for (Object orgId : orgIds) {
			String orgIdStr = (String) orgId;
			IM_Budget_Org__c record = new IM_Budget_Org__c(
				Budget__c = budgetId,
				Organization__c = orgIdStr,
				Type__c = type,
				External_Id__c = budgetId + type + orgIdStr,
				Deleted__c = false
			);
			records.add(record);
		}
		return records;
	}

	/**
	 * Description    : create Component records and return them
	 * Parameters     : Accepts inputList String, String budget Id, String Type
	 * Return Type    : List<IM_Component__c>
	 */
	private static List<IM_Component__c> createComponents(List<Object> componentList, String budgetId) {
		List<IM_Component__c> records = new List<IM_Component__c>();
		for (Object c : componentList) {
			String cmpName = (String) c;
			IM_Component__c record = new IM_Component__c(Budget__c = budgetId, Name = cmpName, Type__c = 'Component', External_Id__c = budgetId + cmpName);
			records.add(record);
		}
		return records;
	}

	/**
	 * Description    : create subComponent records and return them
	 * Parameters     : Accepts inputList String, String budget Id, String Type
	 * Return Type    : List<IM_Component__c>
	 */
	private static List<IM_Component__c> createSubComponents(Map<Object, Object> compSubCompMap, Map<String, Id> componentIdMap, String budgetId) {
		List<IM_Component__c> subComponentRecords = new List<IM_Component__c>();
		for (Object subCompName : compSubCompMap.keySet()) {
			String subCompNameStr = ((String) subCompName).split('_Sub')[0];
			String cmpName = (String) compSubCompMap?.get(subCompName);
			String componentId = componentIdMap.get(budgetId + cmpName);
			IM_Component__c subComponent = new IM_Component__c();
			subComponent.Name = subCompNameStr;
			subComponent.Budget__c = budgetId;
			subComponent.Type__c = 'SubComponent';
			subComponent.Parent_Component__c = componentId;
			subComponent.External_Id__c = budgetId + componentId + subCompNameStr;
			subComponentRecords.add(subComponent);
		}
		return subComponentRecords;
	}

	/**













































	 * Description    : TemplateWrapper contains the budget Template details
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class TemplateWrapper {
		@AuraEnabled
		public String metadata;
		@AuraEnabled
		public String versionData;
	}

	/**
	 * Description    : BudgetWrapper contains the data to fill the Budget Excel
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class BudgetWrapper {
		@AuraEnabled
		public IM_Budget__c budget;
		@AuraEnabled
		public Boolean isDiffUser;
		@AuraEnabled
		public Boolean isBudgetApproved;
	}

	/**
	 * Description    : TotalAmountsWrapper contains the data to about each partner total approved amount, including BP.
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class TotalAmountWrapper {
		@AuraEnabled
		public Decimal totalGatesMoney { get; set; }
		@AuraEnabled
		public Decimal totalAgerupMoney { get; set; }
		@AuraEnabled
		public Decimal totalDfatMoney { get; set; }
		@AuraEnabled
		public Decimal totalBpMoney { get; set; }
	}
}