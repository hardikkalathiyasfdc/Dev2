/**
* Author      : Paddy
* Date        : 04/22/2025
* Jira        : IM-164
* Description : This class is used for Request Amendment API service.
* Test        : BgiveAPIRequestAmendmentTest.
* ChangeLog   : 
* Gauri - IM-513 : Added logic to get open amendments for a request from bgive
*/
public with sharing class BgiveAPIRequestAmendment extends BGiveApi {

    private static final String ERR_BGIVE_CREATE_AMENDMENT = 'BGIVE_CREATE_AMENDMENT_FAILED';
    private static final String ERR_BGIVE_FETCH_AMENDMENT = 'BGIVE_FETCH_AMENDMENT_FAILED';

    public class BgiveAPIRequestAmendmentException extends Exception {}

    public static String APPROVED_STATUS = 'approved';
    public static String DECLINED_STATUS = 'declined';
    public static String REJECTED_STATUS = 'rejected';

    /**
    * Description : Overrides abstract class getModel - Object/Table name in BGive
    * Parameters  : None
    * Return Type : Object/Table Name in Bgive
    */
    public override String getModel() {
        return Assets.BGIVE_REQUEST_AMENDMENT;
    }

    /**
    * Description : create request_amendment record in BGive/Fluxx
    * Parameters  : String bgiveId, Map<String,Object> data
    * Return Type : Map<String,Object>
    */
    public Map<String,Object> createAmendment(String requestId, Map<String,Object> data) {
        if(String.isEmpty(requestId)) {
            throw new BgiveAPIRequestAmendmentException('BGive Grant Id cannot be null.');
        }

        List<String> cols = new List<String>{'id','amount_recommended_local','end_date'};
        try {
            data.put('request_id', requestId);

            BGiveApi.BGiveAPIResponse bgiveAPIResponse = (BGiveApi.BGiveAPIResponse) create(data, cols);
            if(bgiveAPIResponse.record != null) {
                Map<String,Object> responseMap = (Map<String,Object>)bgiveAPIResponse.record;
                Map<String,Object> responseData  = new Map<String,Object>();
                responseData.put('AmendmentBgiveID', String.valueOf(responseMap.get('id')));
                responseData.put('AmendmentFutureEndDate', String.valueOf(responseMap.get('end_date')));
                responseData.put('AmendmentFutureAmountLocal', String.valueOf(responseMap.get('amount_recommended_local')));
                return responseData;
            }
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BGIVE_CREATE_AMENDMENT));
            throw new BgiveAPIRequestAmendmentException('Error while creating Request Amendment : ' + String.valueOf(ex.getMessage()));
        }
        return null;
    }

    /**
    * Description : Method to get request_amendment using request id from Bgive
    * Parameters  : String requestId
    * Return Type : List<Object>
    */
    public List<Object> getAmendmentsByRequestId(String requestId) {
        if(String.isEmpty(requestId)) {
            throw new BgiveAPIRequestAmendmentException('Request Id can not be null.');
        }

        // Set the filter
		BGiveFilterCondition requestIdCondition = new BGiveFilterCondition('request_id', BGiveFilterCondition.Operator.EQ, requestId);
		BGiveApiFilter filter = new BGiveApiFilter();
		filter.addCondition(requestIdCondition);

        // Set the sort condition
        BGiveSortCondition sortCondition = new BGiveSortCondition('created_at','asc');
        BGiveApiSort sortBy = new BGiveApiSort();
        sortBy.addCondition(sortCondition);
        
		//Cols to return
		List<String> cols = new List<String>{ 'id', 'request_id', 'state', 'original' };

        return getAmendments(cols, filter, sortBy);
    }

    /**
    * Description : Method to get open request_amendment using request id from Bgive
    * Parameters  : String requestId
    * Return Type : List<Object>
    */
    public List<Object> getOpenAmendmentsByRequestId(String requestId) {
        if(String.isEmpty(requestId)) {
            throw new BgiveAPIRequestAmendmentException('Request Id can not be null.');
        }

        // Set the filter
		BGiveFilterCondition requestIdCondition = new BGiveFilterCondition('request_id', BGiveFilterCondition.Operator.EQ, requestId);
        BGiveFilterCondition approvedCondition = new BGiveFilterCondition('state', BGiveFilterCondition.Operator.NOT_EQ, APPROVED_STATUS);
        BGiveFilterCondition declinedCondition = new BGiveFilterCondition('state', BGiveFilterCondition.Operator.NOT_EQ, DECLINED_STATUS);
        BGiveFilterCondition rejectedCondition = new BGiveFilterCondition('state', BGiveFilterCondition.Operator.NOT_EQ, REJECTED_STATUS);
		BGiveApiFilter filter = new BGiveApiFilter();
		filter.addCondition(requestIdCondition);
        filter.addCondition(approvedCondition);
        filter.addCondition(declinedCondition);
        filter.addCondition(rejectedCondition);

        // Set the sort condition
        BGiveSortCondition sortCondition = new BGiveSortCondition('created_at','asc');
        BGiveApiSort sortBy = new BGiveApiSort();
        sortBy.addCondition(sortCondition);
        
		//Cols to return
		List<String> cols = new List<String>{ 'id', 'request_id', 'state', 'original' };

        return getAmendments(cols, filter, sortBy);
    }

    /**
    * Description : Method to get request_amendments from Bgive
    * Parameters  : List<String> cols, BGiveApiFilter filter
    * Return Type : List<Object>
    */
    public List<Object> getAmendments(List<String> cols, BGiveApiFilter filter, BGiveApiSort sortBy) {

        /**
        * Set the filter (exclude request amendment record which was inserted by bgive)
        * When an amendment is created for the first time for a grant in Bgive, 
        * Fluxx automatically creates an additional amendment for internal purposes and sets Original field to value 1. 
        * We should exclude this amendment for any logic.
        */
        if(filter == null) {
            filter = new BGiveApiFilter();
        }
        filter.addCondition(new BGiveFilterCondition('original', BGiveFilterCondition.Operator.EQ, '0'));
        setFilters(filter.getFilterString());
        if(sortBy != null) {
            setSortConditions(sortBy.getSortString());
        }
        
        try {
			BGiveApi.BGiveAPIListResponse fetchResponse = (BGiveApi.BGiveAPIListResponse) get(cols);
			if (fetchResponse.records != null && fetchResponse.records.size() > 0) {
				return fetchResponse.records;
			}
		} catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BGIVE_FETCH_AMENDMENT));
			throw new BgiveAPIRequestAmendmentException('Error while fetching Request Amendments' + ' : ' + String.valueOf(ex.getMessage()));
		}
        return null;
    }
}