/*
Author     : Sai Bhargav Thotakura
Date       : 11th Dec 2024
Jira       : IM-50
Description: Use this class to download the budget data using the Checkout button on the record detail page of Budget record detail page.
Test Class : IMCheckoutBudgetControllerTest
ChangeLog  : Sai Bhargav Thotakura on Jan 29 2025 - IM-100 : Updated logic to use 1-1 mapping fields for easier cols hiding and better flexibility.
			 Paddy on 06/15/2025: IM-450: Added logic for error logging framework
*/
public with sharing class IMCheckoutBudgetController {

	private static final String ERR_GET_BUDGET_TEMPLATE = 'CHECKOUT_BUDGET_CONTROLLER_GET_BUDGET_TEMPLATE_FAILED';
	private static final String ERR_GET_BUDGET_DATA = 'CHECKOUT_BUDGET_CONTROLLER_GET_BUDGET_DATA_FAILED';
	private static final String ERR_FILL_BUDGET_DATA = 'CHECKOUT_BUDGET_CONTROLLER_FILL_BUDGET_DATA_FAILED';
	private static final String ERR_FILL_BUDGET_PARAMETER_WRAPPER = 'CHECKOUT_BUDGET_CONTROLLER_FILL_BUDGET_PARAMETER_WRAPPER_FAILED';
	private static final String ERR_UPDATE_BUDGET_CHECKOUT_BUDGET = 'CHECKOUT_BUDGET_CONTROLLER_UPDATE_BUDGET_CHECKOUT_DATA_BUDGET_FAILED';


	//Global Variable Declaration
	public static IM_Budget__c budgetRecord;
	public static BudgetWrapper budgetDataRecord = new BudgetWrapper();
	public static String globalBudgetId;

	/**
	 * Description  : Fetch the BudgetTemplate stored in the Template Object
	 * Parameters   : Accepts String - Budget Id, String type
	 * Return Type  : Returns a Template Wrapper - Contains the Template Metadata
	 */
     @AuraEnabled
	public static TemplateWrapper getBudgetTemplate(String budgetId, String type) {

		TemplateWrapper templateWrapperRec;
		try {
			//Check if Budget Id is Valid
			if (budgetId != null) {
				globalBudgetId = budgetId;
				if (budgetRecord == null) {
					budgetRecord = IMUtil.getBudget(budgetId);
				}
				//If Budget Record return rows, proceed with Template Query
				if (budgetRecord != null) {
					String subtype = budgetRecord.Budget_Categories__c ?? 'None';
					subtype = subtype?.replaceAll(' ', '');
					//Fetch the associated Metadata record.
					List<IM_Template_Mapping__mdt> templateMapping = IMUtil.fetchTemplatesByTypeAndSubtype(type,subtype);
					if (templateMapping == null || templateMapping.isEmpty()) {
						throw new AuraHandledException(Assets.NO_TEMPLATES_FOUND);
					}
					Template__c template = IMUtil.getTemplate(templateMapping.get(0).Template_Name__c);
					//If Template record present, capture the metadata and template information in the wrapper variable.
					if (template != null) {
						templateWrapperRec = new TemplateWrapper();
						templateWrapperRec.metadata = template.Metadata__c ?? null;
						if (template.File_Id__c != null) {
							ContentVersion cv = IMUtil.getContentVersion(template.File_Id__c);
							templateWrapperRec.template = EncodingUtil.base64Encode(cv.VersionData);
						} else {
							throw new AuraHandledException(Assets.NO_FILE_PRESENT);
						}
					} else {
						throw new AuraHandledException(Assets.NO_TEMPLATES_FOUND);
					}
				} else {
					throw new AuraHandledException(Assets.NO_BUDGETS_FOUND);
				}
			} else {
				throw new AuraHandledException(Assets.NULL_BUDGET);
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_BUDGET_TEMPLATE));
			throw new AuraHandledException(Assets.SYS_EXCPETION + ex.getMessage());
		}

		return templateWrapperRec;
	}

	/**
    * Description  : Fill the BudgetWrapper Description,Duration(months),Notes,Partner,Partner Role,Payee/Fiscal Sponsor,
    Total Amount,Run Rate,Sub Partner, Sub Partner Type, Type of Work, Unique Identifier, Year1, Year2 etc.,
    and Budget Parameters Data
    * Parameters   : Accepts String - Budget Id
    * Return Type  : Returns a Budget Wrapper - Contains the Budget Rows, Budget Elements, Components, Geographies, SubComponents, Partners, Payee etc.,
    */
	@AuraEnabled
	public static BudgetWrapper getBudgetData(String budgetId) {
		try {
			globalBudgetId = budgetId;
			if (budgetId != null && Schema.sObjectType.IM_Budget__c.isAccessible()) {
				//Getting Budget Rows - Budget Elements
				List<IM_Budget_Row__c> budgetRows = IMUtil.getBudgetRows(budgetId);
				//Getting Components and SubComponents
				List<IM_Component__c> components = IMUtil.getAllComponents(budgetId);
				//Getting Geographies
				List<IM_Geography__c> geographies = IMUtil.getGeography(budgetId);
				//Getting Budget Orgs - Partner/SubPartner/Payee
				List<IM_Budget_Org__c> budgetOrgs = IMUtil.getActiveBudgetOrgs(budgetId);
				List<IM_Funding_Source__c> partnerFunds = IMUtil.getPartnerFunds(budgetId);
				//Proceed to next steps, if Data fill rows and download, if no data - download empty file
				fillBudgetWrapper(budgetRows, components, geographies, budgetOrgs, partnerFunds);
			}
		} catch (Exception error) {
			BBApps_ErrorHandler.logErrors(error, new BBApps_ErrorCustomFields(ERR_GET_BUDGET_DATA));
			throw new AuraHandledException(Assets.SYS_EXCPETION + error.getMessage());
		}
		return budgetDataRecord;
	}

	/**
	 * Description    : Fill the BudgetWrapper with data received from the Budget Rows, Components, Geographies and Budget Org queries
	 * Parameters     : Accepts Lists - Budget Rows, Components, Geographies, Budget Orgs
	 * Return Type    : Void
	 */
	public static void fillBudgetWrapper(
		List<IM_Budget_Row__c> budgetRows,
		List<IM_Component__c> componentData,
		List<IM_Geography__c> geographyData,
		List<IM_Budget_Org__c> budgetOrgData,
		List<IM_Funding_Source__c> partnerFunds
	) {
		try {
			if (budgetRecord == null) {
				budgetRecord = IMUtil.getBudget(globalBudgetId);
				//Check if the budget is approved
				budgetDataRecord.isBudgetApproved = budgetRecord.Status__c == Assets.APPROVED ?? false;
				budgetDataRecord.isBudgetInitiative = 
					Assets.BUDGET_INITIATIVE.equalsIgnoreCase(budgetRecord.Initiative__r.RecordType.Name) ? true : false;
				budgetDataRecord.budgetRec = budgetRecord;
			}
			//Fill Budget Parameter Wrapper
			fillBudgetParameterWrapper(componentData, geographyData, budgetOrgData, partnerFunds);
			budgetDataRecord.budgetRowList = budgetRows.size() > 0 ? budgetRows : new List<IM_Budget_Row__c>();
			budgetDataRecord.periods = IMUtil.getBudgetPeriods(globalBudgetId);
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FILL_BUDGET_DATA));
			throw new AuraHandledException(Assets.SYS_EXCPETION + ex.getMessage());
		}

	}


	/**
	 * Description    : Fill the BudgetParameter Wrapper with data received from Component, Geographies, and BudgeOrg Queries
	 * Parameters     : Accepts Lists - IM_Component__c, IM_Geography__c, IM_Budget_Org__c
	 * Return Type    : Void
	 */
	private static void fillBudgetParameterWrapper(
		List<IM_Component__c> componentData,
		List<IM_Geography__c> geographyData,
		List<IM_Budget_Org__c> budgetOrgData,
		List<IM_Funding_Source__c> partnerFunds
	) {
		try {
			List<IM_Component__c> compList = new List<IM_Component__c>();
			List<IM_Component__c> subCompList = new List<IM_Component__c>();
			List<IM_Budget_Org__c> partnersList = new List<IM_Budget_Org__c>();
			List<IM_Budget_Org__c> subPartnersList = new List<IM_Budget_Org__c>();
			List<IM_Budget_Org__c> payeeList = new List<IM_Budget_Org__c>();

			if (componentData.size() > 0) {
				for (IM_Component__c imComp : componentData) {
					if (imComp.Type__c == Assets.COMPONENT) {
						compList.add(imComp);
					} else if (imComp.Type__c == Assets.SUB_COMPONENT) {
						subCompList.add(imComp);
					}
				}
			}
			if (budgetOrgData.size() > 0) {
				for (IM_Budget_Org__c budOrg : budgetOrgData) {
					if (budOrg.Type__c == Assets.PARTNER) {
						partnersList.add(budOrg);
					} else if (budOrg.Type__c == Assets.SUB_PARTNER) {
						subPartnersList.add(budOrg);
					} else if (budOrg.Type__c == Assets.PAYEE) {
						payeeList.add(budOrg);
					}
				}
			}

			BudgetParamWrapper budgetParameterRecord = new BudgetParamWrapper();
			budgetParameterRecord.data = new Map<String, List<sObject>>();
			budgetParameterRecord.data.put('Component__c', compList);
			budgetParameterRecord.data.put('SubComponent__c', subCompList);
			budgetParameterRecord.data.put('Geography__c', geographyData);
			budgetParameterRecord.data.put('Partner__c', partnersList);
			budgetParameterRecord.data.put('Sub_Partner__c', subPartnersList);
			budgetParameterRecord.data.put('Payee_Fiscal_Sponsor__c', payeeList);
			budgetParameterRecord.data.put('Partner_Fund__c', partnerFunds);
			budgetDataRecord.budgetParam = budgetParameterRecord;
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FILL_BUDGET_PARAMETER_WRAPPER));
			throw new AuraHandledException(Assets.SYS_EXCPETION + ex.getMessage());
		}
	}

	/**
	 * Description   : Update Checkout By, Checkout At fields post successful Budget Checkout
	 * Parameters    : Accepts BudgetId String
	 * Return Type   : Boolean isSuccess
	 */
	@AuraEnabled
	public static Boolean updateBudgetCheckoutFields(String budgetId) {
		Boolean result = false;
        IM_Budget__c budRec = new IM_Budget__c( Id = budgetId,
        Checked_Out_At__c = System.now(),
        Checked_Out_By__c = UserInfo.getUserId());

		BBApps_DMLResult dmlResult = BBApps_Crud.doUpdate(budRec);
		result = dmlResult.isSuccess();
		return result;
	}

	/**
	 * Description   : get Checkout Information from the given budget id
	 * Parameters    : Accepts BudgetId String
	 * Return Type   : String CheckedOutBy
	 */
	@AuraEnabled
	public static String checkoutInformation(String budgetId) {
		return IMUtil.getCheckoutInformation(budgetId);
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
		public String template;
	}

	/**
	 * Description    : BudgetWrapper contains the data to fill the Budget Excel
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class BudgetWrapper {
		@AuraEnabled
		public IM_Budget__c budgetRec;
		@AuraEnabled
		public List<IM_Budget_Row__c> budgetRowList;
		@AuraEnabled
		public BudgetParamWrapper budgetParam;
		@AuraEnabled
		public List<IM_Budget_Period__c> periods;
		@AuraEnabled
		public Boolean isBudgetApproved;
		@AuraEnabled
		public Boolean isBudgetInitiative;
	}

	/**
	 * Description    : BudgetParametersWrapper contains the data to fill the Budget Parameters Excel
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class BudgetParamWrapper {
		@AuraEnabled
		public Map<String, List<sObject>> data;
	}
}