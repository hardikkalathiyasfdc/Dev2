/*
* Author     : Sai Bhargav Thotakura
* Date       : 24th Mar 2025
* Jira       : IM-133 : BGive Grant UI Payment Section
* Description: Controller class for generating Payment Rows
* Test Class : Yet to be created
* ChangeLog   :
* Gauri IM-452: Added logic for error logging framework
*/
public with sharing class IMPaymentScheduler {
    
	//Global Variables
	public static PaymentScheduleNode paymentRecords = new PaymentScheduleNode();
	public static IM_Budget_Grant__c budGrant;
	public static Fund__c partnerFund = [SELECT Id, Name FROM Fund__c WHERE Name = :Assets.PARTNER_BFF WITH SYSTEM_MODE];
	public static Set<String> uniqueFundingPartners = new Set<String>();
	private static List<Bgive_Sync_Field_Mapping__mdt> bgiveSyncFieldMapping = IMUtil.getBGiveSyncFieldMapList(Assets.IM_PAYMENT);
	private static List<Bgive_Field_Value_Mapping__mdt> bgiveFieldValueMapping = new List<Bgive_Field_Value_Mapping__mdt>();
	private static Map<String, Map<String, String>> picklistValMap = new Map<String, Map<String, String>>();
	public static List<PaymentScheduleWrapper> allpaymentRecords = new List<PaymentScheduleWrapper>();

	private static final String ERR_GET_PAYMENT_ROWS = 'GET_PAYMENT_ROWS_FAILED';

	/**
	 * Description    : Method to get Partner Fund types - Partner-BFF and Partner-DAF
	 * Parameters     : none
	 * Return Type    : List<Fund__c>
	 */
	@AuraEnabled(cacheable=true)
	public static List<Fund__c> getPartnerFunds() {
		return [SELECT Id FROM Fund__c WHERE Name = :Assets.PARTNER_BFF OR Name = :Assets.PARTNER_DAF WITH SYSTEM_MODE] ?? null;
	}

	/**
	 * Description    : getAggregatedPaymentRows computes the payment rows that are display on the payment grid
	 * Parameters     : Accepts budgetGrantId, startDate, endDate, fundId, typeOfSupport, isThisPaymentRestricted
	 * Return Type    : returns PaymentScheduleNode Wrapper
	 */
	@AuraEnabled
    public static PaymentScheduleNode getPaymentRows(Id budgetGrantId, String startDate, String endDate, String fund, String typeOfSupport,
    String isThisPaymentRestricted, Boolean isUsdCurrency, String initiativeStartDate, Boolean hasPaymentReset) {
		try {
			// IM-587: Fetch the personal subfund values from metadata
			getPaymentData();

			Boolean scheduledPaymentsPresent = false;
			//Check if payments present in the data json
			String dataJson = [SELECT IM_Grant__r.Data_JSON__c FROM IM_Budget_Grant__c WHERE Id = :budgetGrantId WITH SYSTEM_MODE]?.IM_Grant__r.Data_JSON__c;
			if (dataJson != null && !hasPaymentReset) {
				Map<String, Object> dataJsonMap = (Map<String, Object>) JSON.deserializeUntyped(dataJson);
				if (dataJsonMap != null && !dataJsonMap.isEmpty() && dataJsonMap.containsKey(Assets.BGIVE_PAYMENT_NAME)) {
					List<Object> paymentsList = (List<Object>) dataJsonMap.get(Assets.BGIVE_PAYMENT_NAME);
					Map<String, Object> totalAmountsMap = (Map<String, Object>) dataJsonMap.get(Assets.TOTALAMOUNTSMAP);
					if (paymentsList != null && !paymentsList.isEmpty()) {
						scheduledPaymentsPresent = true;
						fillPaymentWrapperWithJson(paymentsList, totalAmountsMap);
					}
				}
			}
			//if payments not present - generate it
			if (!scheduledPaymentsPresent) {
				generatePaymentWrapper(budgetGrantId, startDate, endDate, fund, typeOfSupport, isThisPaymentRestricted, isUsdCurrency, initiativeStartDate);
			}
		} catch (Exception e) {
			BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields(ERR_GET_PAYMENT_ROWS));
			throw new AuraHandledException(e.getMessage());
		}
		return paymentRecords;
	}

	/**
	 * Description  : fill the payment Wrapper with the payment json stored in Data json field
	 * Parameters   : Accepts paymentsJson
	 * Return Type  : None
	 */
	private static void fillPaymentWrapperWithJson(List<Object> paymentsList, Map<String, Object> totalAmountsMap) {
		createPayments(paymentsList);
		//Update PaymentScheduleNode
		if (!allpaymentRecords.isEmpty()) {
			paymentRecords.totalGatesMoney = Decimal.valueOf(String.valueOf(totalAmountsMap.get(Assets.PARTNER_GATES)));
			paymentRecords.totalAgerupMoney = Decimal.valueOf(String.valueOf(totalAmountsMap.get(Assets.PARTNER_AGERUP)));
			paymentRecords.totalDfatMoney = Decimal.valueOf(String.valueOf(totalAmountsMap.get(Assets.PARTNER_DFAT)));
			paymentRecords.totalBpMoney = Decimal.valueOf(String.valueOf(totalAmountsMap.get('BP')));
			paymentRecords.totalGrantMoney = Decimal.valueOf(String.valueOf(totalAmountsMap.get('TotalGrantAmount')));
			paymentRecords.partnerFundId = partnerFund.Id;
			paymentRecords.allFundingPartners = uniqueFundingPartners;
			paymentRecords.allPersonalSubfunds = picklistValMap.get(Assets.PERSONAL_SUBFUND)?.values();
			paymentRecords.allPayments = allpaymentRecords;
		}
	}

	/**
	 * Description  : create paymentRecords by accepting the paymentList stored in DataJson
	 * Parameters   : Accepts List<Object> paymentsList
	 * Return Type  : None
	 */
	private static void createPayments(List<Object> paymentsList) {
		//Loop through the data and fill the wrapper
		for (Object paymentRec : paymentsList) {
			Map<String, Object> payment = (Map<String, Object>) paymentRec;
			//Initialize the paymentWrapper
			PaymentScheduleWrapper paymentRecord = new PaymentScheduleWrapper();
			paymentRecord.is_this_payment_restricted = String.valueOf(payment.get('is_this_payment_restricted'));
			paymentRecord.amount_due_local = Decimal.valueOf(String.valueOf(payment.get('amount_due_local')));
			paymentRecord.due_at = Date.parse(formatDate(String.valueOf(payment.get('due_at'))));
			paymentRecord.fund = String.valueOf(payment.get('fund'));
			paymentRecord.gl_account = String.valueOf(payment.get('gl_account'));
			paymentRecord.isFundingPartnerRequired = Boolean.valueOf(String.valueOf(payment.get('isFundingPartnerRequired')));
			if (String.valueOf(payment.get('partner_name')) != null) {
				paymentRecord.partner_name = String.valueOf(payment.get('partner_name'));
				if (!uniqueFundingPartners.contains(String.valueOf(payment.get('partner_name')))) {
					uniqueFundingPartners.add(String.valueOf(payment.get('partner_name')));
				}
			}
			paymentRecord.partnerFundDisabled = Boolean.valueOf(String.valueOf(payment.get('partnerFundDisabled')));
			paymentRecord.type_of_payment = String.valueOf(payment.get('type_of_payment'));
			paymentRecord.period = paymentsList.indexOf(paymentRec) + 1;
			paymentRecord.request_id = String.valueOf(payment.get('request_id'));
			paymentRecord.type_of_support = String.valueOf(payment.get('type_of_support'));
			paymentRecord.state = Assets.DEFAULT_PAYMENT_STATE;
			paymentRecord.personal_subfund = String.valueOf(payment.get('personal_subfund'));
			allpaymentRecords.add(paymentRecord);
		}
	}

	/**
	 * Description  : formats the date to the current user lcoale
	 * Parameters   : Accepts date string
	 * Return Type  : date value in the current user locale
	 */
	private static String formatDate(String dueAt) {
		List<String> dateArray = dueAt.split('-');
		if (!dateArray.isEmpty()) {
			Date dueDate = Date.newInstance(Integer.valueOf(dateArray.get(0)), Integer.valueOf(dateArray.get(1)), Integer.valueOf(dateArray.get(2)));
			return dueDate.format();
		}
		return null;
	}

	/**
	 * Description  : construct the payment wrapper, there are no scheduled payments in the data json
	 * Parameters   : Accepts multiple strings - startDate, endDate, fund, typeOfSupport, isThisPaymentRestricted, budgetGrantId
	 * Return Type  : None
	 */
    private static void generatePaymentWrapper(Id budgetGrantId, String startDate, String endDate, String fund, String typeOfSupport, 
    String isThisPaymentRestricted, Boolean isUsdCurrency, String initiativeStartDate) {
		Fund__c fundRec;
		if (fund == null || !fund.isAlphanumeric()) {
			budGrant = [SELECT IM_Grant__r.Fund__c, IM_Grant__r.Fund__r.Name FROM IM_Budget_Grant__c WHERE Id = :budgetGrantId WITH SYSTEM_MODE LIMIT 1];
		} else {
			//get the fundName to set the gl_account
			fundRec = [SELECT Id, Name FROM Fund__c WHERE Id = :fund WITH SYSTEM_MODE];
		}
		//Fetch the Budget Rows for the given Budget Grant
        List<AggregateResult> aggregatedBudgetRows = [SELECT SUM(Total_Amount__c) totalAmount, SUM(Period_1_Amount__c) p0, SUM(Period_2_Amount__c) p1,
        SUM(Period_3_Amount__c) p2,SUM (Period_4_Amount__c) p3,SUM(Period_5_Amount__c) p4,SUM(Period_6_Amount__c) p5,
        SUM(Period_7_Amount__c) p6,SUM(Period_8_Amount__c) p7,SUM(Period_9_Amount__c) p8,SUM(Period_10_Amount__c) p9,
				Partner_Fund__r.Name partnerName
			FROM IM_Budget_Row__c
			WHERE Budget_Grant__r.Id = :budgetGrantId
			WITH SYSTEM_MODE
        GROUP BY Partner_Fund__r.Name];
		//Loop through the aggregateResult to fill the wrapper
		if (!aggregatedBudgetRows.isEmpty()) {
			Decimal totalGrantMoney = 0;
			for (AggregateResult aggregatedBudget : aggregatedBudgetRows) {
				Decimal totalAmount = (Decimal) aggregatedBudget.get('totalAmount');
				for (Integer i = 0; i < 10; i++) {
					Decimal periodAmount = (Decimal) aggregatedBudget.get('p' + i);
					if (periodAmount != null && periodAmount != 0) {
						PaymentScheduleWrapper paymentRecord = new PaymentScheduleWrapper();
						paymentRecord.period = i;
						if (i == 0) {
							paymentRecord.due_at = Date.valueOf(startDate);
						} else {
							paymentRecord.due_at = Date.valueOf(initiativeStartDate).addYears(i);
							Date currentStartDate = Date.valueOf(startDate);
							paymentRecord.due_at = Date.newInstance(paymentRecord.due_at.year(), currentStartDate.month(), currentStartDate.day());
						}
                        paymentRecord.fund = (String)aggregatedBudget.get('partnerName') != null ? 
                        (String)partnerFund.Id : fund != null ? fund : budGrant.IM_Grant__r.Fund__c;
						if ((String) aggregatedBudget.get('partnerName') != null) {
							paymentRecord.partner_name = (String) aggregatedBudget.get('partnerName');
							if (!uniqueFundingPartners.contains((String) aggregatedBudget.get('partnerName'))) {
								uniqueFundingPartners.add((String) aggregatedBudget.get('partnerName'));
							}
						}
						paymentRecord.request_id = budgetGrantId;
						paymentRecord.partnerFundDisabled = false;
						paymentRecord.isFundingPartnerRequired = false;
						if (!isUsdCurrency) {
							paymentRecord.amount_due_local = 0;
						} else {
							paymentRecord.amount_due_local = periodAmount;
						}
						paymentRecord.type_of_payment = Assets.PAYMENT_TYPE;
						paymentRecord.type_of_support = typeOfSupport;
						paymentRecord.is_this_payment_restricted = isThisPaymentRestricted;
						paymentRecord.state = Assets.DEFAULT_PAYMENT_STATE;
						if (fundRec != null) {
							paymentRecord.gl_account = getGlAccount(fundRec.Name, null);
						} else {
							paymentRecord.gl_account = getGlAccount(budGrant.IM_Grant__r.Fund__r.Name, null);
						}
						allpaymentRecords.add(paymentRecord);
					}
				}
				//Calculate total amounts for BP and non BP (Non BP when partnerName is Empty)
				if ((String) aggregatedBudget.get('partnerName') == Assets.PARTNER_GATES) {
					//Total Grant money and respective partner money
					totalGrantMoney += totalAmount;
					paymentRecords.totalGatesMoney = totalAmount;
				} else if ((String) aggregatedBudget.get('partnerName') == Assets.PARTNER_AGERUP) {
					//Total Grant money and respective partner money
					totalGrantMoney += totalAmount;
					paymentRecords.totalAgerupMoney = totalAmount;
				} else if ((String) aggregatedBudget.get('partnerName') == Assets.PARTNER_DFAT) {
					//Total Grant money and respective partner money
					totalGrantMoney += totalAmount;
					paymentRecords.totalDfatMoney = totalAmount;
				} else {
					//Total Grant money and BP money
					totalGrantMoney += totalAmount;
					paymentRecords.totalBpMoney = totalAmount;
				}
			}
			paymentRecords.totalGrantMoney = totalGrantMoney;
			paymentRecords.partnerFundId = partnerFund.Id;
			paymentRecords.allFundingPartners = uniqueFundingPartners;
			paymentRecords.allPersonalSubfunds = picklistValMap.get(Assets.PERSONAL_SUBFUND)?.values();
			paymentRecords.allPayments = allpaymentRecords;
		}
	}

	/**
	 * Description  : check the fund Name and return the respective gl_account value
	 * Parameters   : Accepts String fundName
	 * Return Type  : String
	 */
	@AuraEnabled
	public static String getGlAccount(String fundName, String fundRecId) {
		String glAccount = '';
		String fundRecName = fundName;
		if (fundRecId != null) {
			fundRecName = [SELECT Id, Name FROM Fund__c WHERE Id = :fundRecId WITH SYSTEM_MODE]?.Name;
		}
		if (fundRecName != null && fundRecName.containsIgnoreCase('Corp')) {
			glAccount = '710000';
		} else {
			glAccount = 'BP-000000';
		}
		return glAccount;
	}

	/**
	 * Description  : Get payments data from custom meta data
	 * Parameters   : None
	 * Return Type  : None
	 */
	private static void getPaymentData() {
		// IM-587: Fetch the personal subfund values from metadata
		for (Bgive_Sync_Field_Mapping__mdt syncFieldMapping : bgiveSyncFieldMapping) {
			//For picklist, capture all the child records
			if (syncFieldMapping.Mapping_Type__c == Assets.BGIVE_MAPPING_TYPE_PICKLIST) {
				bgiveFieldValueMapping.addAll(syncFieldMapping.Bgive_Field_Value_Mappings__r);
			}
		}
		//Fill picklist values
		for (Bgive_Field_Value_Mapping__mdt valueMapping : bgiveFieldValueMapping) {
			String brmFieldName = valueMapping.Bgive_Sync_Field_Mapping__r.BRM_Field__c;
			if (picklistValMap.get(brmFieldName) == null) {
				picklistValMap.put(brmFieldName, new Map<String, String>());
			}
			picklistValMap.get(brmFieldName).put(valueMapping.BRM_Value__c, valueMapping.Bgive_Field_Value__c);
		}
	}

	/**
	 * Description    : PaymentScheduleNode contains the data to for payment rows
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class PaymentScheduleNode {
        @AuraEnabled public Decimal totalGatesMoney {get; set;}
        @AuraEnabled public Decimal totalAgerupMoney {get; set;}
        @AuraEnabled public Decimal totalDfatMoney {get; set;}
        @AuraEnabled public Decimal totalBpMoney {get; set;}
        @AuraEnabled public Decimal totalGrantMoney {get; set;}
        @AuraEnabled public String partnerFundId {get; set;}
        @AuraEnabled public Set<String> allFundingPartners {get; set;}
		@AuraEnabled public List<String> allPersonalSubfunds {get; set;}
        @AuraEnabled public List<PaymentScheduleWrapper> allPayments {get; set;}
	}

	/**
	 * Description    : PaymentScheduleWrapper contains the data of each payment row
	 * Parameters     : None
	 * Return Type    : None
	 */
	public class PaymentScheduleWrapper {
        @AuraEnabled public Integer period { get; set;}
        @AuraEnabled public Date due_at { get; set;}
        @AuraEnabled public String fund { get; set;}
        @AuraEnabled public String request_id {get; set;}
        @AuraEnabled public String partner_name { get; set;}
        @AuraEnabled public Decimal amount_due_local { get; set;}
        @AuraEnabled public String type_of_support {get; set;}
        @AuraEnabled public String is_this_payment_restricted {get; set;}
        @AuraEnabled public String type_of_payment {get; set;}
        @AuraEnabled public String gl_account {get; set;}
        @AuraEnabled public String state {get; set;}
        @AuraEnabled public Boolean partnerFundDisabled { get; set;} 
		@AuraEnabled public String personal_subfund {get; set;}
        @AuraEnabled public Boolean isFundingPartnerRequired {get; set;}
	}
}