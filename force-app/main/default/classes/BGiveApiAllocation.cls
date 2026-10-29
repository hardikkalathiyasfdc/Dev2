/**
* Author      : Sai Bhargav Thotakura
* Date        : 04/07/2025
* Jira        : IM-143
* Description : This class is used to sync Allocation records in BGive system when the user clicks on the sync to Bgive button the custom grant UI.
* Test        : Yet to be created.
* ChangeLog   :
*/
public with sharing class BGiveApiAllocation extends BGiveApi {

    private static final String ERR_BGIVE_GET_ALLOCATIONS = 'BGIVE_GET_ALLOCATIONS_FAILED';
    private static final String ERR_BGIVE_CREATE_ALLOCATION = 'BGIVE_CREATE_ALLOCATION_FAILED';

    public class BGiveApiAllocationException extends Exception {} 

    public BGiveApiAllocation(){
        super('machine_model');
    }
    
    /**
    * Description : Overrides abstract class getModel - Object/Table name in BGive
    * Parameters  : None
    * Return Type : Object/Table Name in Bgive
    */
    public override String getModel(){
        return Assets.BGIVE_ALLOCATION_NAME;
    }

    /**
    * Description : fetch all allocation records by using paymentId in an or condition
    * Parameters  : Accepts List<Object> paymentList
    * Return Type : List<Object>
    */
    public List<Object> getAllAllocationsByPayments(List<Object> paymentList){
        //Set Filter
        BGiveApiFilter filter = new BGiveApiFilter();
        filter.setGroupType('or');
        if(paymentList !=null && !paymentList.isEmpty()){
            for(Object paymentRec : paymentList){
                Map<String,Object> payment = (Map<String,Object>)paymentRec;
                String paymentId = String.valueOf(payment.get('id'));
                BGiveFilterCondition paymentIdCondition = new BGiveFilterCondition('payment_allocation_relationship', BGiveFilterCondition.Operator.EQ, paymentId);
                filter.addCondition(paymentIdCondition);
            }
        }
        //Set Cols
        List<String> cols = new List<String>{'id','contig_id','migrate_id'};
        //Set relation cols
        List<String> fields = new List<String>{'id'};
        Map<String,Object> relationFields = new Map<String,Object>();
        relationFields.put('payment_allocation_relationship', (Object)fields);
        setPageSize(Assets.BGIVE_MAX_PAYMENTS);
        setFilters(filter.getFilterString());
        setRelationColumns(relationFields);
        try{
            BGiveApi.BGiveAPIListResponse fetchResponse = (BGiveApi.BGiveAPIListResponse) get(cols);
            if(fetchResponse.records!=null && fetchResponse.records.size() > 0){
                return fetchResponse.records;
            }
        }catch(Exception ex){
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BGIVE_GET_ALLOCATIONS));
            throw new BGiveApiAllocationException('API call to fetch allocation records failed'+' : '+String.valueOf(ex.getMessage()));
        }
        return null;
    }
    
    /**
    * Description : create allocation record in BGive/Fluxx
    * Parameters  : Accepts single allocation record 
    * Return Type : None
    */
    public void createAllocation(Map<String,Object> allocationRec){
        try{
            BGiveApi.BGiveAPIResponse insertResp = (BGiveApi.BGiveAPIResponse) create(allocationRec,null);
        }catch(Exception ex){
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BGIVE_CREATE_ALLOCATION));
            throw new BGiveApiAllocationException('Error while creating allocation record ' + String.valueOf(allocationRec.get('migrate_id')) + ' : '+ex.getMessage());
        }
    }
}