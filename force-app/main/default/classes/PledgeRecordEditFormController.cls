public with sharing class PledgeRecordEditFormController {
    private static final String ERR_CREATE_CHILD_RECORDS = 'PLEDGE_RECORD_EDIT_CREATE_CHILD_RECORDS_FAILED';
    private static final String ERR_GET_PARENT_IDS = 'PLEDGE_RECORD_EDIT_GET_PARENT_IDS_FAILED';
    private static final String ERR_GET_PLEDGE_CHILDS = 'PLEDGE_RECORD_EDIT_GET_PLEDGE_CHILDS_FAILED';
    private static final String ERR_DELETE_RECORD = 'PLEDGE_RECORD_EDIT_DELETE_RECORD_FAILED';
    private static final String ERR_HAS_OUTSTANDING_PRIMARY_PLEDGE = 'PLEDGE_RECORD_EDIT_HAS_OUTSTANDING_PRIMARY_PLEDGE_FAILED';
    
    private static final String MSG_CREATE_CHILD_RECORDS = 'Unable to create child records.';
    private static final String MSG_GET_PARENT_IDS = 'Unable to fetch parent IDs.';
    private static final String MSG_GET_PLEDGE_CHILDS = 'Unable to fetch pledge child records.';
    private static final String MSG_DELETE_RECORD = 'Unable to delete record.';
    private static final String MSG_HAS_OUTSTANDING_PRIMARY_PLEDGE = 'Unable to check for outstanding primary pledge.';

    @AuraEnabled
    public static String createChildRecords(String recordId,  List<Sobject> donorsList,  List<Sobject> benefitsList,List<string> delId){
        try {
            //String recordId, String childIds, String donorType
            List<Id> delIds = new List<Id>();
            if(!delId.isEmpty() ){
                 System.debug('delId>>>>' + delId); 
                 for(String stri : delId){
                     if(String.IsNotBlank(stri) && stri!=null)
                    delIds.add(stri);
                 }
                 if(!delIds.isEmpty() )
                BBApps_Crud.doDeleteWithHandling(delIds, false, ERR_CREATE_CHILD_RECORDS);
              }
            List<Sobject> objList = new List<Sobject>();
            if(!donorsList.isEmpty()){
                for(Sobject sobj : donorsList){
                    Donor__c donor = (Donor__c)sobj;
                    donor.Pledge__c = recordId;
                    objList.add(donor);
                }
            }
           System.debug(objList); 
           System.debug('objList>>>>' + objList.size()); 
            if(!benefitsList.isEmpty()){
                for(Sobject sobj : benefitsList){
                    Pledge_Benefit__c pb = (Pledge_Benefit__c)sobj;
                    pb.Pledge__c = recordId;
                    objList.add(pb);
                } 
            }
            
                
              
            if(!objList.isEmpty()){
                BBApps_Crud.doUpsertWithHandling(objList, false, ERR_CREATE_CHILD_RECORDS);
            }
            
            return recordId;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_CREATE_CHILD_RECORDS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_CREATE_CHILD_RECORDS);
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static FEDetails getParentIds(Id recordId){
        try {
            if(String.isNotBlank(recordId)){
                String objName = recordId.getsobjecttype().getDescribe().getName();
                FEDetails fem = new FEDetails();
                SYstem.debug('recordId>>>'+recordId);
                if('Fundraising_Project__c'.equalsIgnoreCase(objName)){
                    fem.recOrgId=getRecpOrgRecord(recordId);
                    String modeId = getModeRecord(recordId);
                    //String recOrgID= getRecpOrgRecord(recordId);
                    fem.PaymentNotTracked = getPaymentNotTracked(recordId);
                    fem.FEId = recordId;
                    fem.FECurr= getRecpOrgRecordcurr(recordId);
                    //fem.RECIId=String.isNotBlank(recOrgID) ? recOrgID : '';
                    fem.FEModeId = String.isNotBlank(modeId) ? modeId : '';
                    fem.PTId = '';
                    return fem;
                }
               if('Fundraising_Activity__c'.equalsIgnoreCase(objName)){
                    Id feId = [SELECT Fundraising_Effort_Id__c FROM Fundraising_Activity__c WHERE Id=:recordId LIMIT 1 ]?.Fundraising_Effort_Id__c;
                    String fecyrr = [SELECT Fundraising_Effort_Id__r.Currency__c FROM Fundraising_Activity__c WHERE Id=:recordId LIMIT 1 ]?.Fundraising_Effort_Id__r.Currency__c;
                    fem.recOrgId=getRecpOrgRecord(feId);
                    fem.FEId = feId;
                    fem.FEModeId = recordId;
                    fem.PTId = '';
                   fem.FECurr= fecyrr ;
                    return fem;
                }
                if('Possible_Tiers__c'.equalsIgnoreCase(objName)){
                    Id feId = [SELECT Fundraising_Effort__c FROM Possible_Tiers__c WHERE Id=:recordId LIMIT 1 ]?.Fundraising_Effort__c;
                      String fecyrr = [SELECT Fundraising_Effort__r.Currency__c FROM Possible_Tiers__c WHERE Id=:recordId LIMIT 1  ]?.Fundraising_Effort__r.Currency__c;
                    fem.FEId = feId;
                    fem.FEModeId = '';
                    fem.PTId = recordId;
                      fem.FECurr= fecyrr ;
                    return fem;
                }
               
            }
            return null;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_PARENT_IDS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_PARENT_IDS);
        }
    }
    
    Public Static String getModeRecord(Id recordId){
       List<Fundraising_Activity__c> modeList = [SELECT Id FROM Fundraising_Activity__c WHERE Fundraising_Effort_Id__c=:recordId];
        Fundraising_Activity__c mode = (!modeList.isEmpty() && modeList.size() == 1) ? modeList[0] : new Fundraising_Activity__c();
        return mode.Id;
    }
    Public Static String getRecpOrgRecord(Id recordId){
       List<Recipient_Organization__c> recOrgList = [SELECT Organization__c,Fundraising_Project__r.Currency__c FROM Recipient_Organization__c WHERE Fundraising_Project__c=:recordId];
        List<Account> lstacc = new List<Account>();
        if(recOrgList.size() == 1){
            lstacc = [Select id, Name FROM Account WHERE id=: recOrgList[0].Organization__c];
        }
        Account recOrg = (!lstacc.isEmpty() && lstacc.size() == 1) ? lstacc[0] : new Account();
        return recOrg.Id;
    }
    Public Static String getRecpOrgRecordcurr(Id recordId){
       List<Recipient_Organization__c> recOrgList = [SELECT Organization__c,Fundraising_Project__r.Currency__c FROM Recipient_Organization__c WHERE Fundraising_Project__c=:recordId];
       
        return recOrgList[0].Fundraising_Project__r.Currency__c;
    }
    Public Static boolean getPaymentNotTracked(Id recordId){
       List<Fundraising_Project__c> modeList = [SELECT Id,Payments_NOT_Tracked__c FROM Fundraising_Project__c WHERE Id=:recordId];
        Fundraising_Project__c mode = (!modeList.isEmpty() && modeList.size() == 1) ? modeList[0] : new Fundraising_Project__c();
        return mode.Payments_NOT_Tracked__c;
    }     
    
    public class FEDetails{
        @AuraEnabled public String FEId {get;set;} 
        @AuraEnabled public String FECurr {get;set;} 
        @AuraEnabled public String FEModeId {get;set;} 
        @AuraEnabled public String PTId {get;set;}
        @AuraEnabled public String RECIId {get;set;}
        @AuraEnabled public String recOrgId {get;set;}
        @AuraEnabled public Boolean PaymentNotTracked {get;set;}
    }
    
    @AuraEnabled(cacheable=false)
    public static PledgeChildClass getPledgeChilds(Id recordId){
        try {
            List<Donor__c> donors  = new List<Donor__c>();
            List<Pledge_Benefit__c> pBenefits = new List<Pledge_Benefit__c>();
            for(Donor__c donor : [SELECT Id, Donor_Type__c, Contact__c, Organization__c,Pledge__r.Pledge_Amount__c,Credit_Type__c,Amount__c FROM Donor__c WHERE Pledge__c =: recordId ORDER BY Credit_Type__c ASC NULLS LAST]){
                donors.add(donor);           
            }
            for(Pledge_Benefit__c pb : [SELECT Id,Benefits__c FROM Pledge_Benefit__c WHERE Pledge__c =: recordId]){
                pBenefits.add(pb);
            }
            PledgeChildClass pcClass = new PledgeChildClass();
            pcClass.donors = donors.isEmpty() ? new List<Donor__c>() : donors;
            pcClass.pBenefits = pBenefits.isEmpty() ? new List<Pledge_Benefit__c>() : pBenefits;
            return pcClass;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_PLEDGE_CHILDS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_PLEDGE_CHILDS);
        }
    }
    public class PledgeChildClass{
        @AuraEnabled public List<Donor__c> donors {get;set;} 
        @AuraEnabled public List<Pledge_Benefit__c> pBenefits {get;set;} 
    }
     @AuraEnabled(cacheable=false)
   Public Static void deleteRecrd(List<sObject>  recordId){
        BBApps_Crud.doDeleteWithHandling(recordId, false, ERR_DELETE_RECORD);
    } 
    
    @AuraEnabled
    public static Boolean hasOutstandingPrimaryPledge(Id fundraisingEffortId, Id donorContactId, Id donorOrgId, Id excludePledgeId) {
        try {
            if (fundraisingEffortId == null || (donorContactId == null && donorOrgId == null)) {
                return false;
            }
        
            List<AggregateResult> results = [
                SELECT COUNT_DISTINCT(Pledge__c) cnt
                FROM Donor__c
                WHERE Credit_Type__c = 'Donor - Primary'
                AND Pledge__r.Fundraising_Effort__c = :fundraisingEffortId
                AND Pledge__r.Id != :excludePledgeId
                AND Pledge__r.Balance__c > 0
                AND (
                    (Contact__c != null AND Contact__c = :donorContactId)
                    OR (Organization__c != null AND Organization__c = :donorOrgId)
                )
            ];
        
            return (results.isEmpty() ? false : (Integer)results[0].get('cnt') > 0);
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_HAS_OUTSTANDING_PRIMARY_PLEDGE);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_HAS_OUTSTANDING_PRIMARY_PLEDGE);
        }
    }     
}