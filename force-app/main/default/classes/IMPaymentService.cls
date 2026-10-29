/**
* Author      : Sai Bhargav Thotakura
* Date        : 04/01/2025
* Jira        : IM-134
* Description : This is a service class that can be used to sync (create/update) payment records in BRM with Bgive
* Test        : Yet to be created.
* ChangeLog   :
* Gauri IM-452: Added logic for error logging framework
*/
public with sharing class IMPaymentService {

    //Maps
    private static Map<String,Object> returnMap;
    //Lists
    private static Map<String,Object> existingPaymentsByMigrateId;
    //Booleans and Strings
    private static Boolean doesPaymentsExistInBgive = false;
    private static String errors;
    private static String bgiveGrantId;
    //Exception
    public class IMPaymentServiceException extends Exception{}

    private static final String ERR_CREATE_PAYMENTS = 'CREATE_PAYMENTS_FAILED';
    private static final String ERR_GET_BGIVE_PAYMENTS = 'GET_BGIVE_PAYMENTS_FAILED';

    /**
    * Description : primary method responsible for creating payments, based on the paymentJson received.
    * Parameters  : Accepts paymentJson, imGrant bgive Id
    * Return Type : Map<String,Object> returnMap
    */
    public static Map<String,Object> createPayments(String bgiveId, List<Object> paymentsMap){
        try{
            bgiveGrantId = bgiveId;
            if(paymentsMap!=null && paymentsMap.size() > Assets.BGIVE_MAX_PAYMENTS){
                throw new IMPaymentServiceException('The payment records count exceeds more than the current hard set limit');
            }else{
                checkExistingPayments();
                BGiveApiPayment bgivePaymentClass = new BGiveApiPayment();
                //No Payments were present for the given grant request
                if(!doesPaymentsExistInBgive){
                    //Call the method responsible for creating payment records for each payment json
                    for(Object payment : paymentsMap){
                        Map<String,Object> paymentRec = (Map<String,Object>)payment;
                        bgivePaymentClass.createPayment(paymentRec, bgiveId);
                    }
                }
                //Payment records present - Partial Scenario
                else{
                    //Call the method responsible for creating payment records for each payment json if it does not exist in existing payments
                    for(Object payment : paymentsMap){
                        Map<String,Object> paymentRec = (Map<String,Object>)payment;
                        if(!findPaymentRecInBgive(paymentRec)){
                            bgivePaymentClass.createPayment(paymentRec, bgiveId);
                        }
                    }
                }
            }
        }catch(Exception ex){
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CREATE_PAYMENTS));
            errors = String.valueOf(ex);
        }
        //Update Return Map
        returnMap = new Map<String,Object>();
        if(errors != null && String.isNotBlank(errors)){
            returnMap.put('Errors', errors);
        }else{
            returnMap.put('allPaymentsCreated', true);
            returnMap.put('Data_JSON__c', null);
        }
        return returnMap;
    }

    /**
    * Description : find the paymentRec in the existingPayments, if exists return true, else false.
    * Parameters  : Accepts Map<String,Object> paymentRec
    * Return Type : Boolean
    */
    private static Boolean findPaymentRecInBgive(Map<String,Object> paymentRec){
        if(!existingPaymentsByMigrateId.isEmpty()){
            return existingPaymentsByMigrateId.get(bgiveGrantId+'_'+String.valueOf(paymentRec.get('id'))) != null;
        }
        return false;
    }

    /**
    * Description : Calls BGive API to fetch request transaction records using request_id (grant bgive Id)
    * Parameters  : Accepts grant bgive Id
    * Return Type : None
    */
    private static void checkExistingPayments(){
        try{
            List<Object> paymentRecords = new BGiveApiPayment().getAllPayments(bgiveGrantId);
            if(paymentRecords != null && !paymentRecords.isEmpty()){
                doesPaymentsExistInBgive = true;
                setExistingPaymentMap(paymentRecords);
            }
        }catch(Exception ex){
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_GET_BGIVE_PAYMENTS));
            errors = String.valueOf(ex.getMessage());
        }
    }

    /**
    * Description : create a map of existing payments with key as migrate Id, and its respective payment record
    * Parameters  : Accepts List<Object> existingPayments
    * Return Type : None
    */
    private static void setExistingPaymentMap(List<Object> existingPayments){
        existingPaymentsByMigrateId = new Map<String,Object>();
        for(Object payment : existingPayments){
            Map<String,Object> paymentData = (Map<String,Object>)payment;
            if(paymentData.containsKey('migrate_id') && String.isNotBlank(String.valueOf(paymentData.get('migrate_id')))){
                existingPaymentsByMigrateId.put(String.valueOf(paymentData.get('migrate_id')),paymentData);
            }
        }
    }

    /**
    * Description : Get All Payments for a given request from BGive
    * Parameters  : Accepts String requestId
    * Return Type : None
    */
    public static List<Object> getPaymentsByRequestId(String requestId){
        List<Object> paymentRecords = new BGiveApiPayment().getAllPayments(requestId);
        return paymentRecords;
    }
}