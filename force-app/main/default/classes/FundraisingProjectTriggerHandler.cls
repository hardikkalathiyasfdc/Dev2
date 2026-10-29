public without sharing class FundraisingProjectTriggerHandler extends TriggerHandler {
    public Boolean isAfterTrigger = false;
    public Boolean isDeleteTrigger = false;
    public static set<Id> setoffundraisingIds = new Set<Id>();
    
    private static final String ERR_AND_FINALLY = 'FUNDRAISING_PROJECT_TRIGGER_AND_FINALLY_FAILED';
    private static final String ERR_AFTER_UPDATE = 'FUNDRAISING_PROJECT_TRIGGER_AFTER_UPDATE_FAILED';

    public FundraisingProjectTriggerHandler() {
        if(Trigger.isAfter) isAfterTrigger = true;
        if(Trigger.isDelete) isDeleteTrigger = true;
    }
    
    public override void andFinally() {
        try {
            if(Trigger.isAfter && Trigger.isDelete) {
                if(!setoffundraisingIds.isEmpty()) {
                   PledgeTriggerHandler.updateActivityPledgeAmount(setoffundraisingIds);
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_AND_FINALLY);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        try {
            Fundraising_Project__c newRec = (Fundraising_Project__c)so;
            if(isFieldChanged(newRec, 'Personal__c') || isFieldChanged(newRec, 'Political__c')) {
                Set<Id> donorIds = new Set<Id>();
                for(Donor__c donor : [SELECT Id FROM Donor__c WHERE Pledge__r.Fundraising_Effort__c = :newRec.Id]) {
                    donorIds.add(donor.Id);
                }
                if(!donorIds.isEmpty()) DonorTriggerHelper.updateCoFunderForDonors(donorIds, new Set<Id>());
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_AFTER_UPDATE);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }

    public override void afterDelete(SObject so) {
        Fundraising_Project__c f = (Fundraising_Project__c)so;
        if(String.isNotBlank(f.Id)) { 
            setoffundraisingIds.add(f.id);
        }  
    }
}