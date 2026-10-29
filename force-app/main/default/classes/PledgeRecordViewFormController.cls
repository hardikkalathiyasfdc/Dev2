public without sharing class PledgeRecordViewFormController {
	
    private static final String ERR_GET_PLEDGE_CHILDS = 'PLEDGE_RECORD_VIEW_GET_PLEDGE_CHILDS_FAILED';
    private static final String ERR_HAS_RECORD_EDIT_ACCESS = 'PLEDGE_RECORD_VIEW_HAS_RECORD_EDIT_ACCESS_FAILED';
    
    private static final String MSG_GET_PLEDGE_CHILDS = 'Unable to fetch pledge child records.';
    private static final String MSG_HAS_RECORD_EDIT_ACCESS = 'Unable to check record edit access.';
	
    @AuraEnabled(cacheable=false)
    public static PledgeChildClass getPledgeChilds(Id recordId){
        try {
       System.debug('recordId>>>>'+recordId);
        List<Donor__c> donors = new List<Donor__c> ();
        List<Pledge_Benefit__c> pBenefits = new List<Pledge_Benefit__c>();
            for(Donor__c donor : [SELECT Id, Donor_Type__c, Contact__c, Contact__r.Name, Contact__r.Search_Display_Name__c, Contact__r.Restricted__c, Contact__r.Restricted_Name__c,
            Organization__c, Organization__r.Name, Organization__r.Search_Display_Name__c, Organization__r.Restricted__c, Organization__r.Restricted_Org_Name__c, Amount__c, Credit_Type__c, Donor__c FROM Donor__c WHERE Pledge__c =: recordId ORDER BY Credit_Type__c ASC NULLS LAST]){
            donors.add(donor);          
        }
        for(Pledge_Benefit__c pb : [SELECT Id, Benefits__c, Benefits__r.Name, Listing_Location__c,Listing_Text__c,Quantity__c, Start_Date__c, End_Date__c FROM Pledge_Benefit__c WHERE Pledge__c =: recordId]){
            pBenefits.add(pb);
        }
        System.debug('donors>>>>>'+donors.size());
        PledgeChildClass pcClass = new PledgeChildClass();
        pcClass.donors = donors.isEmpty() ? new List<Donor__c>() : donors;
        pcClass.pBenefits = pBenefits.isEmpty() ? new List<Pledge_Benefit__c>() : pBenefits;
        System.debug('donors>>>>>'+pcClass.donors.size());
        System.debug('donors>>>>>'+pcClass.donors);
        return pcClass;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_PLEDGE_CHILDS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_GET_PLEDGE_CHILDS);
        }
    }
    
    @AuraEnabled
    public static Boolean hasRecordEditAccess (Id recordId) {
        try {
        return [Select RecordId, HasEditAccess from UserRecordAccess where UserId =: UserInfo.getUserId() AND RecordId =: recordId].HasEditAccess;
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_HAS_RECORD_EDIT_ACCESS);
            BBApps_ErrorHandler.logErrors(ex, f);
            throw new AuraHandledException(MSG_HAS_RECORD_EDIT_ACCESS);
        }
    }
    
    public class PledgeChildClass{       
        @AuraEnabled public List<Donor__c> donors {get;set;} 
        @AuraEnabled public List<Pledge_Benefit__c> pBenefits {get;set;}    
        public PledgeChildClass(){
            this.donors = new List<Donor__c>();
            this.pBenefits = new List<Pledge_Benefit__c>();
        }     
    }
}