/**
 * Author      : Sai Bhargav Thotakura
 * Date        : 04/03/2025
 * Jira        : IM-134
 * Description : This class is used to sync Payment records in BGive system when the user clicks on the sync to Bgive button the custom grant UI.
 * Test        : Yet to be created.
 * ChangeLog   :
 * Gauri on 09/17/2025: IM-324: Added logic to remove partner name if it is null
 */
public with sharing class BGiveApiPayment extends BGiveApi {

	private static final String ERR_BGIVE_GET_PAYMENTS = 'BGIVE_GET_PAYMENTS_FAILED';
    private static final String ERR_BGIVE_CREATE_PAYMENT = 'BGIVE_CREATE_PAYMENT_FAILED';
    
    public class BGiveApiPaymentException extends Exception {} 
	public static Map<Id, Fund__c> fundRecordsMap = new Map<Id, Fund__c>([SELECT Id, Bgive_Api_Name__c FROM Fund__c WITH SYSTEM_MODE]);

	/**
	 * Description : Overrides abstract class getModel - Object/Table name in BGive
	 * Parameters  : None
	 * Return Type : Object/Table Name in Bgive
	 */
	public override String getModel() {
		return Assets.BGIVE_PAYMENT_NAME;
	}

	/**
	 * Description : Calls BGive API to fetch request transaction records using request_id (grant bgive Id)
	 * Parameters  : Accepts grant bgive Id
	 * Return Type : List<Object> all payment records
	 */
	public List<Object> getAllPayments(String bgiveGrantId) {
		//Set the filter
		BGiveFilterCondition requestIdCondition = new BGiveFilterCondition('request_id', BGiveFilterCondition.Operator.EQ, bgiveGrantId);
		BGiveApiFilter filter = new BGiveApiFilter();
		filter.addCondition(requestIdCondition);
		//Cols to return
		List<String> cols = new List<String>{ 'id', 'contig_id', 'migrate_id', 'amount_due_local', 'amount_paid_local' };
		//Set relation cols
		List<String> fields = new List<String>{ 'foundation_initiatives' };
		Map<String, Object> relationFields = new Map<String, Object>();
		relationFields.put('request_id', (Object) fields);
		setPageSize(Assets.BGIVE_MAX_PAYMENTS);
		setFilters(filter.getFilterString());
		setRelationColumns(relationFields);
		try {
			BGiveApi.BGiveAPIListResponse fetchResponse = (BGiveApi.BGiveAPIListResponse) get(cols);
			if (fetchResponse.records != null && fetchResponse.records.size() > 0) {
				return fetchResponse.records;
			}
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BGIVE_GET_PAYMENTS));
			throw new BGiveApiPaymentException('API call to fetch payment records failed' + ' : ' + String.valueOf(ex.getMessage()));
		}
		return null;
	}

	/**
	 * Description : create request_transaction record in BGive/Fluxx
	 * Parameters  : Accepts single payment record
	 * Return Type : None
	 */
	public void createPayment(Map<String, Object> paymentRec, String bgiveGrantId) {
		try {
			//Set Migrate Id
			paymentRec.put('migrate_id', (Object) (bgiveGrantId + '_' + String.valueOf(paymentRec.get('id'))));
			paymentRec.put('request_id', bgiveGrantId);
			paymentRec.put('fund', fundRecordsMap.get(String.valueOf(paymentRec.get('fund')))?.Bgive_Api_Name__c);

			//Remove id,partnerFundDisabled,isFundingPartnerRequired
			Object idValue = paymentRec.containsKey('id') ? paymentRec.remove('id') : null;
			Object partnerFundValue = paymentRec.containsKey('partnerFundDisabled') ? paymentRec.remove('partnerFundDisabled') : null;
			Object fundingPartnerReqValue = paymentRec.containsKey('isFundingPartnerRequired') ? paymentRec.remove('isFundingPartnerRequired') : null;
			if (paymentRec.containsKey('partner_name') && paymentRec.get('partner_name') == null)
				paymentRec.remove('partner_name');

			BGiveApi.BGiveAPIResponse insertResp = (BGiveApi.BGiveAPIResponse) create(paymentRec, null);
		} catch (Exception ex) {
			BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BGIVE_CREATE_PAYMENT));
            throw new BGiveApiPaymentException('Error while creating payment ' + String.valueOf(paymentRec.get('id')) + ' : '+String.valueOf(ex.getMessage()));
		}
	}
}