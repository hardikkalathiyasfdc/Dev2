/**
 * Author : Gauri Sagane
 * Date   : 03/19/2025
 * Jira   : IM-131
 * Description : This is controller class for Budget Grant View component
 * Test : IMGrantViewControllerTest
 * ChangeLog   :  Gauri on 07/21/2025: IM-300: Soft deleting Grants instead of Hard Delete to support user permissioning
 * Gauri - IM-363 : Added logic to set type of work everytime before pushing to bgive
 * Gauri - IM-500 : Added method to get All children of Grant (Budgeted and Non Budgeted)
 * Gauri - IM-519 : Moved the delete Zero Amount Grant logic to Grant Service class
 * Gauri - IM-519 : Added method to send email on grant delete
 * Gauri - IM-513 : Added method to fetch request amendments related to a request from bgive
 * Gauri - IM-570 : Added method to sync the partner changes from BIM to Bgive
 * Gauri - IM-452 : Added logic for error logging framework
 */

public with sharing class IMGrantViewController {

	private static final String ERR_UPDATE_BUDGET_GRANT = 'UPDATE_BUDGET_GRANT_FAILED';
	private static final String ERR_UPDATE_IM_GRANT = 'UPDATE_IM_GRANT_FAILED';
	private static final String ERR_GET_BUDGET_GRANT = 'GET_BUDGET_GRANT_FAILED';
	private static final String ERR_GET_IM_GRANT = 'GET_IM_GRANT_FAILED';
	private static final String ERR_GET_CURRENCY = 'GET_CURRENCY_FAILED';
	private static final String ERR_DELETE_IM_GRANT = 'DELETE_IM_GRANT_FAILED';
	private static final String ERR_GET_USD_CURRENCY = 'GET_USD_CURRENCY_FAILED';
	private static final String ERR_GET_FUND = 'GET_FUND_FAILED';
	private static final String ERR_GET_PERSONAL_FUND = 'GET_PERSONAL_FUND_FAILED';
	private static final String ERR_GET_FISCAL_SPONSOR = 'GET_FISCAL_SPONSOR_FAILED';
	private static final String ERR_GET_CONTACT = 'GET_CONTACT_FAILED';
	private static final String ERR_GET_BGIVE_GRANT = 'GET_BGIVE_GRANT_FAILED';
	private static final String ERR_PUSH_TO_BGIVE = 'PUSH_TO_BGIVE_FAILED';
	private static final String ERR_CREATE_REQUEST_AMENDMENT = 'CREATE_REQUEST_AMENDMENT_FAILED';
	private static final String ERR_UNLINK_GRANT = 'UNLINK_GRANT_FAILED';
	private static final String ERR_GET_TYPE_OF_WORK = 'GET_TYPE_OF_WORK_FAILED';
	private static final String ERR_GET_DEFAULT_FUND = 'GET_DEFAULT_FUND_FAILED';
    private static final String ERR_GET_NON_BUDGET_GRANT = 'GET_NON_BUDGET_GRANT_FAILED';
	private static final String ERR_GET_PAYMENTS = 'GET_PAYMENTS_FAILED';
	private static final String ERR_SEND_EMAIL = 'SEND_EMAIL_FAILED';
	private static final String ERR_REFRESH_GRANT = 'REFRESH_GRANT_FAILED';
	private static final String ERR_GET_AMENDMENTS = 'GET_AMENDMENTS_FAILED';
	private static final String ERR_CALCULATE_BUDGET_ORGS = 'CALCULATE_BUDGET_ORGS_FAILED';
	private static final String ERR_SYNC_PARTNER_WITH_BGIVE = 'SYNC_PARTNER_WITH_BGIVE_FAILED';
	private static final String ERR_CHANGE_PARTNER = 'CHANGE_PARTNER_FAILED';
	private static final String ERR_GET_FOUNDATION_INITIATIVE = 'GET_FOUNDATION_INITIATIVE_FAILED';
	
	/**
	 * Description : Method to get Budget Grant
	 * Parameters : budgetGrantId String
	 * Return Type : IM_Budget_Grant__c
	 */
	@AuraEnabled(cacheable=true)
	public static IM_Budget_Grant__c getBudgetGrant(String budgetGrantId) {
		try {
			IM_Budget_Grant__c budgetGrant = [
				SELECT
					Id,
					Name,
					Budget__c,
					Budget_Amount_Local__c,
					Budget_Amount_USD__c,
					Status__c,
					Unique_Identifier__c,
					Budget_Grant_Name__c,
					IM_Grant__c,
					Is_Active__c,
					Budget__r.Initiative__r.Bgive_Id__c,
					Budget__r.Initiative__r.Name,
					Budget__r.Initiative__r.Team__r.Name,
					Budget__r.Initiative__r.Team__r.Bgive_Id__c,
					Budget_Org__r.Organization__r.Name,
					Budget__r.Initiative__r.Segment__c,
					Budget__r.Initiative__r.Program_Contact__c,
					Budget__r.Initiative__r.Grants_Team_Contact__c,
					Budget__r.Initiative__r.Start_Date__c,
					Budget__r.Initiative__r.End_Date__c,
					Budget__r.Initiative__r.Status__c,
					Budget__r.Initiative__r.Foundation_Code__r.Foundation_Code__c,
					Budget__r.Checked_Out_By__c,
					Confirmed_Budget_Amount_USD__c,
					Confirmed_Budget_Amount_Local__c
				FROM IM_Budget_Grant__c
				WHERE Id = :budgetGrantId
				WITH SYSTEM_MODE
			];
			return budgetGrant;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors((Id) budgetGrantId, e, new BBApps_ErrorCustomFields(ERR_GET_BUDGET_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to update Budget Grant
	 * Parameters : budgetGrant IM_Budget_Grant__c
	 * Return Type : void
	 */
	@AuraEnabled
	public static void updateBudgetGrant(IM_Budget_Grant__c budgetGrant) {
		try {
			BBApps_Crud.doUpdate(
				budgetGrant,
				false
			);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(budgetGrant, e, new BBApps_ErrorCustomFields(ERR_UPDATE_BUDGET_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get IM Grant
	 * Parameters : imGrantId String, isCurrentGrant Boolean (For onload i.e if isCurrentGrant = true then set default data)
	 * Return Type : IM_Grant__c
	 */
	@AuraEnabled
	public static IM_Grant__c getIMGrant(String imGrantId, Boolean isCurrentGrant) {
		try {
			IM_Grant__c imGrant = IMUtil.getImGrant(imGrantId);
			if (imGrant.Bgive_Id__c == null) {
				imGrant.Type_of_Work__c = getTypeOfWork(imGrant.Id);
			}
			if (imGrant != null && isCurrentGrant && imGrant.Data_JSON__c == null) {
				setGrantDefaults(imGrant);
			}
			return imGrant != null ? imGrant : null;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors((Id) imGrantId, e, new BBApps_ErrorCustomFields(ERR_GET_IM_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get IM Grant using bgive id
	 * Parameters : grantBgiveId String
	 * Return Type : IM_Grant__c
	 */
	@AuraEnabled(cacheable=true)
	public static IM_Grant__c getIMGrantByBgiveId(String grantBgiveId) {
		try {
		List<IM_Grant__c> imGrants = [
			SELECT Id, Bgive_Contig_Id__c, Bgive_Id__c, Bgive_Status__c
			FROM IM_Grant__c
			WHERE Bgive_Id__c = :grantBgiveId
			WITH SYSTEM_MODE
		];

		return imGrants.isEmpty() ? null : imGrants[0];
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_IM_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to soft delete IM Grant (i.e mark Deleted__c as true on Grants) in case of Partial allocation or other scenarios
	 * Parameters : imGrant IM_Grant__c
	 * Return Type : void
	 */
	@AuraEnabled
	public static void deleteIMGrant(IM_Grant__c imGrant) {
		try {
			String errors = '';
			if (imGrant != null) {
				List<Id> imGrantChildren = getAllIMGrantChildren(imGrant.Id);
				if (imGrantChildren.isEmpty()) {
					imGrant.Deleted__c = true;
					BBApps_Crud.doUpdate(
						imGrant,
						false
					);
				}
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(imGrant, e, new BBApps_ErrorCustomFields(ERR_DELETE_IM_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to set IM Grant defaults on first load
	 * Parameters : imGrant IM_Grant__c
	 * Return Type : void
	 */
	private static void setGrantDefaults(IM_Grant__c imGrant) {
		// set Defaults if empty here
		if (imGrant.Currency__c == null) {
			imGrant.Currency__c = getUSDCurrency()?.Id;
		}

		if (imGrant.Type_of_Work__c == null) {
			imGrant.Type_of_Work__c = getTypeOfWork(imGrant.Id);
		}

		if (imGrant.Fund__c == null) {
			imGrant.Fund__c = getDefaultFund(imGrant.Type_of_Work__c);
		}
	}

	/**
	 * Description : Method to update IM Grant
	 * Parameters : imGrant IM_Grant__c
	 * Return Type : void
	 */
	@AuraEnabled
	public static void updateIMGrant(IM_Grant__c imGrant) {
		try {
			BBApps_Crud.doUpdate(
				imGrant,
				false
			);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(imGrant, e, new BBApps_ErrorCustomFields(ERR_UPDATE_IM_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get Currency
	 * Parameters : currencyId String
	 * Return Type : Currency__c
	 */
	@AuraEnabled(cacheable=true)
	public static Currency__c getCurrency(String currencyId) {
		try {
			Currency__c currencyRec = [
				SELECT Id, Name, Currency_Code__c, Currency_Description__c, Bgive_Id__c, IM_Default__c
				FROM Currency__c
				WHERE Id = :currencyId
				WITH SYSTEM_MODE
			];
			return currencyRec;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors((Id) currencyId, e, new BBApps_ErrorCustomFields(ERR_GET_CURRENCY));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get Currency using bgive id
	 * Parameters : bgiveCurrencyId String
	 * Return Type : Currency__c
	 */
	@AuraEnabled(cacheable=true)
	public static Currency__c getCurrencyByBgiveId(String bgiveCurrencyId) {
		try {
			Currency__c currencyRec = [
				SELECT Id, Name, Currency_Code__c, Currency_Description__c, Bgive_Id__c, IM_Default__c
				FROM Currency__c
				WHERE Bgive_Id__c = :bgiveCurrencyId
				WITH SYSTEM_MODE
			];
			return currencyRec;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_CURRENCY));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get USD Currency
	 * Parameters : no parameters
	 * Return Type : Currency__c
	 */
	@AuraEnabled(cacheable=true)
	public static Currency__c getUSDCurrency() {
		try {
			Currency__c currencyRec = [
				SELECT Id, Name, Currency_Code__c, Currency_Description__c, Bgive_Id__c, IM_Default__c
				FROM Currency__c
				WHERE Name = 'USD'
				WITH SYSTEM_MODE
			];
			return currencyRec;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_USD_CURRENCY));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get Fund
	 * Parameters : fundId String
	 * Return Type : Fund__c
	 */
	@AuraEnabled(cacheable=true)
	public static Fund__c getFund(String fundId) {
		try {
			Fund__c fund = [SELECT Id, Name FROM Fund__c WHERE Id = :fundId WITH SYSTEM_MODE];
			return fund;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_FUND));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get personal Fund
	 * Parameters : no parameters
	 * Return Type : Id
	 */
	@AuraEnabled(cacheable=true)
	public static Id getPersonalFund() {
		try {
		List<Fund__c> funds = [
			SELECT Id
			FROM Fund__c
			WHERE Name = 'Personal'
			WITH SYSTEM_MODE
		];
		return funds.isEmpty() ? null : funds[0].Id;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_PERSONAL_FUND));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get Fiscal Sponsor from bugdet row
	 * Parameters : budgetGrantId String
	 * Return Type : IM_Budget_Row__c
	 */
	@AuraEnabled(cacheable=true)
	public static IM_Budget_Row__c getFiscalSponsor(String budgetGrantId) {
		try {
		List<IM_Budget_Row__c> budgetRows = [
			SELECT Id, Payee_Fiscal_Sponsor__c, Payee_Fiscal_Sponsor__r.Organization__r.Name, Payee_Fiscal_Sponsor__r.Organization__r.Bgive_Id__c
			FROM IM_Budget_Row__c
			WHERE Budget_Grant__c = :budgetGrantId
			WITH SYSTEM_MODE
		];
		if (budgetRows.size() > 0) {
			return budgetRows[0];
		} else {
			return null;
		}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_FISCAL_SPONSOR));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get Contact
	 * Parameters : userId String
	 * Return Type : Contact
	 */
	@AuraEnabled(cacheable=true)
	public static Contact getContact(String userId) {
		try {
		List<Contact> contacts = [
			SELECT Id, Bgive_Id__c
			FROM Contact
			WHERE BRM_User__c = :userId
			WITH SYSTEM_MODE
		];
		if (contacts.size() > 0) {
			return contacts[0];
		} else {
			return null;
		}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_CONTACT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get GrantRequest from Bgive
	 * Parameters : grantRequestContigId String
	 * Return Type : Map<String,Object>
	 */
	@AuraEnabled
	public static Map<String, Object> getBgiveGrant(String grantRequestContigId) {
		try {
			Map<String, Object> grantRequest = new Map<String, Object>();
			grantRequest = IMGrantService.getBgiveGrantUsingContigId(grantRequestContigId);
			return grantRequest;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_BGIVE_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to create GrantRequest in Bgive
	 * Parameters : imGrantId String, type String
	 * Return Type : void
	 */
	@AuraEnabled
	public static void pushToBGive(String imGrantId, String type) {
		try {
			IMGrantService.sync(imGrantId, type);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors((Id) imGrantId, e, new BBApps_ErrorCustomFields(ERR_PUSH_TO_BGIVE));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to create GrantAmendment record in Bgive
	 * Parameters : imGrantBgiveId String, amendmentDetails Map<String,Object>
	 * Return Type : Map<String,Object>
	 */
	@AuraEnabled
	public static Map<String, Object> createRequestAmendment(String imGrantBgiveId, Map<String, Object> amendmentDetails) {
		try {
			BgiveAPIRequestAmendment bgiveRequestAmendment = new BgiveAPIRequestAmendment();
			Map<String, Object> requestAmendment = bgiveRequestAmendment.createAmendment(imGrantBgiveId, amendmentDetails);
			return requestAmendment;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_CREATE_REQUEST_AMENDMENT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to unlink Grant from Bgive
	 * Parameters : IM_Grant__c imGrant, IM_Budget_Grant__c budgetGrant, String actionType (actionType can be 'Decline', 'Delete' or 'Unlink')
	 * Return Type : void
	 */
	@AuraEnabled
	public static void unlinkGrant(IM_Grant__c imGrant, IM_Budget_Grant__c budgetGrant, String actionType) {
		try {
			// Call unlink method here
			IMGrantService.unlink(imGrant, budgetGrant, actionType);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(budgetGrant.Id, e, new BBApps_ErrorCustomFields(ERR_UNLINK_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get Type of Work
	 * Parameters : imGrantId Id
	 * Return Type : String
	 */
	private static String getTypeOfWork(Id imGrantId) {
		try {
		List<IM_Budget_Row__c> budgetRows = [
			SELECT Type_of_Work__c
			FROM IM_Budget_Row__c
			WHERE
				Budget_Grant__c IN (
					SELECT Id
					FROM IM_Budget_Grant__c
					WHERE IM_Grant__c = :imGrantId
				)
			WITH SYSTEM_MODE
			ORDER BY CreatedDate DESC
		];

		if (budgetRows.size() > 0) {
			return budgetRows[0].Type_of_Work__c;
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(imGrantId, e, new BBApps_ErrorCustomFields(ERR_GET_TYPE_OF_WORK));
			throw new AuraHandledException(e.getMessage());
		}
			return '';
		}

	/**
	 * Description : Method to get Default Fund
	 * Parameters : typeOfWork String
	 * Return Type : String
	 */
	private static String getDefaultFund(String typeOfWork) {
		try {
			IM_Funding_Mapping__mdt fundMapping = [
				SELECT Fund__c
				FROM IM_Funding_Mapping__mdt
				WHERE Type_Of_Work__c = :typeOfWork
				WITH SYSTEM_MODE
				LIMIT 1
			];
			if (fundMapping != null) {
				return [
					SELECT Id
					FROM Fund__c
					WHERE Name = :fundMapping.Fund__c
					WITH SYSTEM_MODE
				]
				.Id;
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_DEFAULT_FUND));
			return null;
		}
		return null;
	}

	/**
	 * Description : Method to get Picklist values from meta data
	 * Parameters : none
	 * Return Type : Map<String, List<String>>
	 */
	@AuraEnabled(cacheable=true)
	public static Map<String, List<String>> getPicklistValues() {
		return IMUtil.getBgiveFieldToValueMap(Assets.IM_GRANT);
	}

	/**
	 * Description : Method to get base url of deep link of bgive record
	 * Parameters : none
	 * Return Type : String
	 */
	@AuraEnabled(cacheable=true)
	public static String getBgiveGrantURL() {
		String fluxxURL = Environment.getBgiveBaseUrl();
        return fluxxURL + '/show/requests/';
    }

	/**
	 * Description : Method to get all children of IMGrant
	 * Parameters : imGrantId Id
	 * Return Type : List<Id>
	 */
	@AuraEnabled(cacheable=true)
	public static List<Id> getAllIMGrantChildren(Id imGrantId) {
		List<IM_Budget_Grant__c> budgetGrants = IMUtil.getIMGrantChildren(imGrantId);
		List<IM_Non_Budget_Grant__c> nonBudgetGrants = IMUtil.getNonBudgetedGrants(imGrantId);
		List<Id> childGrantIds = new List<Id>();
		for(IM_Budget_Grant__c bg : budgetGrants){
			if(!bg.Deleted__c && bg.Is_Active__c){
				childGrantIds.add(bg.Id);
			}
		}
		for(IM_Non_Budget_Grant__c nbg : nonBudgetGrants){
			childGrantIds.add(nbg.Id);
		}
		return childGrantIds;
    }

	/**
	 * Description : Method to get non-budget grant
	 * Parameters : nonBudgetGrantId String
	 * Return Type : IM_Non_Budget_Grant__c
	 */
	@AuraEnabled(cacheable=true)
	public static IM_Non_Budget_Grant__c getNonBudgetGrant(String nonBudgetGrantId) {
		try {
			IM_Non_Budget_Grant__c nonBudgetGrant = [
				SELECT
					Id,
					Non_Budget_Grant_Name__c,
					Budget_Amount_Local__c,
					Budget_Amount_USD__c,
					IM_Grant__c,
					IM_Grant__r.Partner_Org__r.Name,
					Initiative__r.Name
				FROM IM_Non_Budget_Grant__c
				WHERE Id = :nonBudgetGrantId
                WITH SYSTEM_MODE
			];
			return nonBudgetGrant;
		} catch (Exception e) {
        	BBApps_ErrorHandler.logErrors((Id) nonBudgetGrantId, e, new BBApps_ErrorCustomFields(ERR_GET_NON_BUDGET_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
    }

	/**
	 * Description : Method to get payments from Bgive using request id
	 * Parameters : String requestId
	 * Return Type : List<Object>
	 */
	@AuraEnabled
	public static List<Object> getPaymentsByRequestId(String requestId){
		try {
			return IMPaymentService.getPaymentsByRequestId(requestId);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_PAYMENTS));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to send an email to bgive helpdesk on grant delete
	 * Parameters : IM_Grant__c imGrant, String grantContigId, String bgiveGrantURL
	 * Return Type : none
	 */
	@AuraEnabled
    public static void sendEmail(IM_Grant__c imGrant, String grantContigId, String bgiveGrantURL) {
		try{
			String bgiveHelpDeskEmail = EmailUtility.getBgiveHelpDeskEmail();
			String recipient = String.isBlank(bgiveHelpDeskEmail) ? UserInfo.getUserEmail() : bgiveHelpDeskEmail;
			
			EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'IM_Bgive_Grant_Delete_Template' WITH SYSTEM_MODE LIMIT 1];
			
			// Set content
			Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, UserInfo.getUserId(), imGrant.Id);
			
			String emailBody = email.getHtmlBody();
			emailBody = emailBody.replace('<<bgiveGrantURL>>', bgiveGrantURL);
			emailBody = emailBody.replace('<<grantContigId>>', grantContigId);

			// Cannot use merge fields in subject line of email template as the record is already unlinked, 
			// so need to replace the placeholder with contig id here
			String subject = email.getSubject()?.replace('<<grantContigId>>', grantContigId);
			
			// Set recipients
			String[] toAddresses = new String[] {recipient};
			email.setToAddresses(toAddresses);
			email.setOrgWideEmailAddressId(EmailUtility.getIMEmailAddress());
			email.setSaveAsActivity(false);
			email.setTreatTargetObjectAsRecipient(false);
			email.setHtmlBody(emailBody);
			email.setSubject(subject);

			// Send email
			Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(imGrant.Id, e, new BBApps_ErrorCustomFields(ERR_SEND_EMAIL));
			throw new AuraHandledException(e.getMessage());
		}
    }

	/**
	 * Description : Method to get request amendments from Bgive using request id
	 * Parameters : String requestId
	 * Return Type : List<Object>
	 */
	@AuraEnabled
	public static List<Object> getAmendmentsByRequestId(String requestId){
		try {
			return new BgiveAPIRequestAmendment().getOpenAmendmentsByRequestId(requestId);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_AMENDMENTS));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to refresh request data from Bgive
	 * Parameters : String requestId
	 * Return Type : void
	 */
	@AuraEnabled
	public static void refresh(IM_Grant__c imGrant){
		try {
			IMGrantService.syncFromBgive(imGrant);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(imGrant.Id, e, new BBApps_ErrorCustomFields(ERR_REFRESH_GRANT));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get partner change details for a given IM Grant
	 * Parameters : IM_Grant__c imGrant
	 * Return Type : Map<String, Object>
	 */
	@AuraEnabled
	public static Map<String, Object> getPartnerChangeDetails(IM_Grant__c imGrant){
		try {
			if(imGrant.Funded_By_Multiple_Initiatives__c == 'Yes'){
				throw new AuraHandledException('This grant is funded by multiple initiatives. The partner cannot be changed.');
			}else{
				Map<String, Object> data = new Map<String, Object>();
				Map<Id, IM_Budget_Grant__c> budgetGrantsMap = IMUtil.getBudgetGrantsByIMGrant(imGrant.Id);
				List<Id> budgetIds = new List<Id>();
				List<Id> budgetOrgIds = new List<Id>();
				data.put('budgetGrants', budgetGrantsMap);
				data.put('isCheckedOut', false);
				for(IM_Budget_Grant__c bg : budgetGrantsMap.values()){
					budgetIds.add(bg.Budget__c);
					budgetOrgIds.add(bg.Budget_Org__c);
					if(bg.Budget__r?.Checked_Out_By__c != null){
						data.put('isCheckedOut', true);
					}
				}
				data.put('budgetIds', budgetIds);
				data.put('budgetOrgIds', budgetOrgIds);
				return data;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to validate partner change
	 * Parameters : Id partnerId, List<Id> budgetIds
	 * Return Type : Map<String, Boolean>
	 */
	@AuraEnabled
	public static Map<String, Object> validatePartner(IM_Budget_Grant__c budgetGrant, Id partnerId, List<Id> budgetIds){
		try {
			Map<String, Object> result = new Map<String, Object>();
			Account partner = IMUtil.getPartnerById(partnerId);
			result.put('isBlinked', false);
			result.put('partner', partner);
			Boolean isBlinked = partner?.Bgive_Id__c != null;
			if(!isBlinked){
				return result;
			} else {
				// Do further validations
				result.put('isBlinked', true);
				result.put('isBudgetOrgPresent', false);
				List<IM_Budget_Org__c> budgetOrgs = IMUtil.getPartnerBudgetOrgs(budgetIds, partnerId);
				List<Id> budgetOrgIds = new List<Id>();
				for(IM_Budget_Org__c bo : budgetOrgs){
					budgetOrgIds.add(bo.Id);
				}
				List<IM_Budget_Grant__c> budgetGrants = IMUtil.getBudgetGrantsByBudgets(budgetIds);
				List<String> uniqueIdentifiers = new List<String>();
				for(IM_Budget_Grant__c bg : budgetGrants){
					if(bg.Budget_Org__c != null && budgetOrgIds.contains(bg.Budget_Org__c)){
						result.put('isBudgetOrgPresent', true);
					}
					if(bg.Id != budgetGrant.Id && bg.Unique_Identifier__c != null){
						uniqueIdentifiers.add(bg.Unique_Identifier__c);
					}
				}
				result.put('uniqueIdentifiers', uniqueIdentifiers);
				result.put('budgetOrgs', budgetOrgs);
			}
			return result;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to change partner
	 * Parameters : IM_Grant__c imGrant, Map<Id, IM_Budget_Grant__c> budgetGrantMap, Id partnerId, String uniqueIdentifier, List<IM_Budget_Org__c> budgetOrgs, List<Id> budgetIds
	 * Return Type : Boolean
	 */
	@AuraEnabled
	public static Boolean changePartner(IM_Grant__c imGrant, Map<Id, IM_Budget_Grant__c> budgetGrantMap, Id partnerId, String uniqueIdentifier, List<IM_Budget_Org__c> budgetOrgs, List<Id> budgetIds){
		try {
			List<Id> budgetOrgIds = new List<Id>();

			List<IM_Budget_Grant__c> budgetGrants = budgetGrantMap.values();
			List<Id> budgetGrantIds = new List<Id>(budgetGrantMap.keySet());

			// List because multiple rows could be forming one grant
			List<IM_Budget_Row__c> budgetRows = IMUtil.getBudgetRowsByGrant(budgetIds, budgetGrantIds);

			// Create a Map of Budgets and their corresponding Budget Orgs
			Map<Id, IM_Budget_Org__c> budgetOrgMap = new Map<Id, IM_Budget_Org__c>();
			for(IM_Budget_Org__c bo : budgetOrgs){
				budgetOrgMap.put(bo.Budget__c, bo);
			}

			// Check if budget org already exists or new needs to be created for the new partner org
			for(Id budgetId : budgetIds){
				if(budgetOrgMap.containsKey(budgetId)){
					IM_Budget_Org__c bo = budgetOrgMap.get(budgetId);
					if(bo.Deleted__c){
						bo.Deleted__c = false;
					}
					budgetOrgMap.put(budgetId, bo);
				} else {
					IM_Budget_Org__c bo = new IM_Budget_Org__c();
					bo.Budget__c = budgetId;
					bo.Organization__c = partnerId;
					bo.Type__c = 'Partner';
					budgetOrgMap.put(budgetId, bo);
				}
			}

			// Create or update(undelete) the budget org records for the new partner org
			BBApps_Crud.doUpsert(
				budgetOrgMap.values(),
				true
			);

			// Add the budget org ids to a list for recalculating the totals later (both old and new partner org budget org ids)
			for(IM_Budget_Org__c bo : budgetOrgMap.values()){
				budgetOrgIds.add(bo.Id);
			}
			for(IM_Budget_Grant__c bg : budgetGrants){
				budgetOrgIds.add(bg.Budget_Org__c);
			}

			// Update the unique identifier on budget if the budget initially didn't have any unique identifier
			if(uniqueIdentifier != null){
				List<IM_Budget__c> budgets = [SELECT Id, Unique_Identifier__c FROM IM_Budget__c WHERE Id IN :budgetIds WITH SYSTEM_MODE];
				for(IM_Budget__c budget : budgets){
					if(budget != null && !budget.Unique_Identifier__c){
						budget.Unique_Identifier__c = true;
					}
				}
				BBApps_Crud.doUpdate(
					budgets,
					true
				);
			}

			// Update the budget grant with new unique identifier and partner org
			// Update the Budget Grant before the Budget Row as row's trigger will invoke the recomputation of grants & creates a duplicate BudgetGrant
			for(IM_Budget_Grant__c bg : budgetGrants){
				bg.Budget_Org__c = budgetOrgMap.get(bg.Budget__c).Id;
				bg.Unique_Identifier__c = uniqueIdentifier != null ? uniqueIdentifier : bg.Unique_Identifier__c;
			}
			TriggerFactory.setBypass('IMBudgetGrantTriggerHandler');
			BBApps_Crud.doUpdate(
				budgetGrants,
				true
			);
			TriggerFactory.removeBypass('IMBudgetGrantTriggerHandler');

			// Update the budget row with new partner and unique identifier
			for(IM_Budget_Row__c budgetRow : budgetRows){
				budgetRow.Partner__c = budgetOrgMap.get(budgetRow.Budget__c).Id;
				budgetRow.Unique_Identifier__c = uniqueIdentifier != null ? uniqueIdentifier : budgetRow.Unique_Identifier__c;
			}
			TriggerFactory.setBypass('IMBudgetRowTriggerHandler');
			BBApps_Crud.doUpdate(
				budgetRows,
				true
			);
			TriggerFactory.removeBypass('IMBudgetRowTriggerHandler');

			// Update the im grant with new partner org
			imGrant.Partner_Org__c = partnerId;
			BBApps_Crud.doUpdate(
				imGrant,
				true
			);

			// Recalculate the budget org totals for the affected budget orgs
			calculateBudgetOrgTotals(budgetIds, budgetOrgIds);

			return true;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_CHANGE_PARTNER));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to recalculate Budget Org Totals after partner change
	 * Parameters : budgetIds List<Id>, budgetOrgIds List<Id>
	 * Return Type : void
	 */
	private static void calculateBudgetOrgTotals(List<Id> budgetIds, List<Id> budgetOrgIds){
		try {
			Map<Id, IM_Budget_Org__c> budgetOrgsToUpdate = new Map<Id, IM_Budget_Org__c>();
			for(Id budgetOrgId : budgetOrgIds){
				budgetOrgsToUpdate.put(budgetOrgId, new IM_Budget_Org__c(
					Id = budgetOrgId,
					Total_Amount__c = 0.00
				));
			}
			AggregateResult[] partnerTotals = [
				SELECT Budget__c budget, Partner__c partner, SUM(Total_Amount__c) totalAmount
				FROM IM_Budget_Row__c
				WHERE Budget__c IN :budgetIds AND Partner__c IN :budgetOrgIds
				WITH SYSTEM_MODE
				GROUP BY Budget__c, Partner__c
			];
			for (AggregateResult ar : partnerTotals) {
				if ((Id) ar.get('partner') != null) {
					IM_Budget_Org__c bo = new IM_Budget_Org__c(
						Id = (Id) ar.get('partner'),
						Total_Amount__c = (Decimal) ar.get('totalAmount')
					);
					budgetOrgsToUpdate.put(bo.Id, bo);
				}
			}
			if (!budgetOrgsToUpdate.isEmpty()) {
				BBApps_Crud.doUpdate(
					budgetOrgsToUpdate.values(),
					true
				);
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_CALCULATE_BUDGET_ORGS));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to sync Partner with Bgive (used in case of partner change to update the partner details on bgive)
	 * Parameters : imGrantId String, type String
	 * Return Type : void
	 */
	@AuraEnabled
	public static void syncPartnerWithBGive(String imGrantId) {
		try {
			IMGrantService.syncPartnerWithBGive(imGrantId);
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_SYNC_PARTNER_WITH_BGIVE));
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Description : Method to get Foundation Initiative for a budget grant
	 * Parameters : budgetGrantId String
	 * Return Type : IM_Budget_Grant__c
	 */
	@AuraEnabled(cacheable=true)
	public static IM_Budget_Grant__c getFoundationInitiative(String budgetGrantId) {
		try {
			IM_Budget_Grant__c budgetGrant = [
				SELECT Id, Name, Budget__r.Initiative__r.Foundation_Code__r.Foundation_Code__c
				FROM IM_Budget_Grant__c
				WHERE Id = :budgetGrantId
				WITH SYSTEM_MODE
			];
			return budgetGrant;
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors((Id) budgetGrantId, e, new BBApps_ErrorCustomFields(ERR_GET_FOUNDATION_INITIATIVE));
			throw new AuraHandledException(e.getMessage());
		}
	}
}