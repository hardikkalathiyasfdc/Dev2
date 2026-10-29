/**
* Author      : Sai Bhargav Thotakura
* Date        : 04/07s/2025
* Jira        : IM-134
* Description : This is a service class that can be used to sync (create/update) allocation records in BRM with Bgive
* Test        : Yet to be created.
* ChangeLog   :
*/
public with sharing class IMAllocationService {

    private static final String ERR_CREATE_ALLOCATIONS = 'ALLOCATION_SERVICE_CREATE_ALLOCATIONS';
    private static final String ERR_GET_ALLOCATIONS = 'ALLOCATION_SERVICE_GET_ALLOCATIONS';
    
    //Maps
    private static Map<String,Object> returnMap;
    private static Set<String> existingAllocationsByPaymentId;
    //Lists
    private static List<Map<String,Object>> allocationRecordsToInsert;
    private static List<Object> existingPayments;
    //Booleans and Strings
    private static Boolean doesAllocationsExistInBgive = false;
    private static String errors;
    //Exception
    public class IMAllocationServiceException extends Exception{}
    
    /**
    * Description : primary method responsible for creating allocations, based on the grant_request id received.
    * Parameters  : Accepts grant request bgive id
    * Return Type : Map<String,Object> returnMap
    */
    public static Map<String,Object> createAllocations(String bgiveGrantId){
        try{
            existingAllocationsByPaymentId = new Set<String>();
            allocationRecordsToInsert = new List<Map<String,Object>>();
            //get the payment records for the given grant request bgive id
            existingPayments = new BGiveApiPayment().getAllPayments(bgiveGrantId);
            //get all the allocations, and check for each allocation in the allocationsMap
            if(existingPayments!=null && !existingPayments.isEmpty()){
                getAllAllocations();
            }
            //If there are payment records
            if(existingPayments!=null && !existingPayments.isEmpty()){
                //Loop through the payment records and update allocationRecMap
                Map<Object, List<String>> foundationInitiativeMap = new Map<Object, List<String>>(); 
                for(Object existingPaymentRec : existingPayments){
                    Map<String,Object> existingPaymentRecMap = (Map<String,Object>)existingPaymentRec;
                    Map<String,Object> requestFieldsMap = (Map<String,Object>)(((List<Object>)existingPaymentRecMap.get('request_id')).get(0));
                    if(!findAllocationRecInBgive(existingPaymentRecMap)){
                        Map<String,Object> allocationRecMap = new Map<String,Object>();
                        if(!existingPaymentRecMap.isEmpty() && existingPaymentRecMap.containsKey('id') && existingPaymentRecMap.get('id') != null){
                            Map<String,Object> idMap = new Map<String,Object>();
                            idMap.put('id',existingPaymentRecMap.get('id'));
                            allocationRecMap.put('payment_allocation_relationship', idMap);
                            allocationRecMap.put('amount_allocated', existingPaymentRecMap.get('amount_due_local'));
                            allocationRecMap.put('migrate_id', (Object)(bgiveGrantId+'_'+String.valueOf(existingPaymentRecMap.get('id'))));
                            // Get foundation initiatives as List of Strings
                            if(!foundationInitiativeMap.isEmpty() && foundationInitiativeMap.containsKey(requestFieldsMap.get('id'))){
                                allocationRecMap.put('foundation_initiatives', foundationInitiativeMap.get(requestFieldsMap.get('id')));
                            }else{
                                List<String> foundationInitiatives = getFoundationInitiatives((List<Object>)requestFieldsMap.get('foundation_initiatives'));
                                foundationInitiativeMap.put(requestFieldsMap.get('id'), foundationInitiatives);
                                allocationRecMap.put('foundation_initiatives', foundationInitiatives);
                            }
                            allocationRecordsToInsert.add(allocationRecMap);
                        }
                    }
                }
                //Check the size of allocationRecMap, if there are records, create them.
                if(allocationRecordsToInsert!=null && !allocationRecordsToInsert.isEmpty()){
                    for(Map<String,Object> allocationRec : allocationRecordsToInsert){
                        new BGiveApiAllocation().createAllocation(allocationRec);
                    }
                }
            }else{
                throw new IMAllocationServiceException('No payment records found in Bgive to create allocation');
            }
        }catch(Exception ex){
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CREATE_ALLOCATIONS));
            errors = String.valueOf(ex);
        }
        //Update ReturnMap
        returnMap = new Map<String,Object>();
        if(errors != null){
            returnMap.put('Errors', errors);
        }else{
            returnMap.put('allAllocationsCreated', true);
        }
        return returnMap;
    }
    
    /**
    * Description : find the allocationRec in the existingAllocations, if exists return true, else false.
    * Parameters  : Accepts Map<String,Object> allocationRec
    * Return Type : Boolean
    */
    private static Boolean findAllocationRecInBgive(Map<String,Object> existingPaymentRecMap){
        if(!existingAllocationsByPaymentId.isEmpty()){
            return existingAllocationsByPaymentId.contains(String.valueOf(existingPaymentRecMap.get('id')));
        }
        return false;
    }
    
    /**
    * Description : Calls BGive API to fetch allocation records using all payments
    * Parameters  : None
    * Return Type : None
    */
    private static void getAllAllocations(){
        try{
            List<Object> allocationRecords = new BGiveApiAllocation().getAllAllocationsByPayments(existingPayments);
            if(allocationRecords != null && !allocationRecords.isEmpty()){
                doesAllocationsExistInBgive = true;
                setExistingAllocationMap(allocationRecords);
            }
        }catch(Exception ex){
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_ALLOCATIONS));
            errors = String.valueOf(ex.getMessage());
        }
    }
    
    
    /**
    * Description : create a map of existing allocations with key as payment Id, and value as TRUE/FALSE
    * Parameters  : Accepts List<Object> allocationRecords
    * Return Type : None
    */
    private static void setExistingAllocationMap(List<Object> allocationRecords){
        existingAllocationsByPaymentId = new Set<String>();
        for(Object allocation : allocationRecords){
            Map<String,Object> allocationData = (Map<String,Object>)allocation;
            Map<String,Object> paymentFieldMap = (Map<String,Object>)allocationData.get('payment_allocation_relationship');
            if(paymentFieldMap.containsKey('id') && String.isNotBlank(String.valueOf(paymentFieldMap.get('id')))){
                existingAllocationsByPaymentId.add(String.valueOf(paymentFieldMap.get('id')));
            }
        }
    }

    /**
    * Description : Method to get the foundation initiatives as a list of string
    * Parameters  : List<Object> foundationInitiatives
    * Return Type : List<String>
    */
    private static List<String> getFoundationInitiatives(List<Object> foundationInitiatives){
        List<String> foundationInitiativeValues = new List<String>();
        for(Object foundationInitiative : foundationInitiatives){
            foundationInitiativeValues.add(String.valueOf(foundationInitiative).substringAfterLast('|'));
        }
        return foundationInitiativeValues;
    }
}