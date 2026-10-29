/**
 * Maintains Recipient Organization composite keys and synchronizes affected
 * Pledge Recipient Soft Credit values when the mapping changes.
 */
public without sharing class RecipientOrganizationTriggerHandler extends TriggerHandler{
    public static Map<String,Id> mapOfkeywithRecOrgId = new Map<String,Id>(); 
    private Set<String> affectedKeys = new Set<String>();
    
    private static final String ERR_BEFORE_INSERT = 'RECEPIENT_ORGANIZATION_TRIGGER_BEFORE_INSERT_FAILED';
    private static final String ERR_BEFORE_UPDATE = 'RECEPIENT_ORGANIZATION_TRIGGER_BEFORE_UPDATE_FAILED';
    private static final String ERR_AND_FINALLY = 'RECEPIENT_ORGANIZATION_TRIGGER_AND_FINALLY_FAILED';
    private static final String ERR_UPDATE_ALL_RELATED_PLEADGE = 'RECEPIENT_ORGANIZATION_TRIGGER_UPDATE_ALL_RELATED_PLEADGE_FAILED';
    private static final String ERR_UPDATE_FAILED = 'RECEPIENT_ORGANIZATION_TRIGGER__UPDATE_FAILED';
    
    public override void beforeInsert(SObject so) {
        try{
            Recipient_Organization__c recpOrg = (Recipient_Organization__c) so;
            prepareCompositeKey(recpOrg);
        }catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BEFORE_INSERT)); }
    }
    public override void beforeUpdate(SObject olddat, SObject newdata) {
        try{ 
            Recipient_Organization__c recpOrg = (Recipient_Organization__c) newdata;
            Recipient_Organization__c oldorg = (Recipient_Organization__c) olddat;
            if(oldorg.Organization__c != recpOrg.Organization__c){
                mapOfkeywithRecOrgId.put(oldorg.Fundraising_Project__c+''+oldorg.Organization__c, recpOrg.Organization__c);
            }
            prepareCompositeKey(recpOrg);
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BEFORE_UPDATE)); }
    }
    public static void prepareCompositeKey(Recipient_Organization__c recpOrg){
        recpOrg.Composite_Key__c = recpOrg.Fundraising_Project__c+''+recpOrg.Organization__c;
    }
    
    public override void andFinally() {
        try{ 
            if (Trigger.isAfter) {
                if(!mapOfkeywithRecOrgId.isEmpty()){
                    updateAllrelatedPleadge(mapOfkeywithRecOrgId);
                    mapOfkeywithRecOrgId.clear();
                }
                if (!affectedKeys.isEmpty()) {
                    PledgeRecipientSoftCreditService.reconcileRecipientOrganizationKeys(affectedKeys);
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AND_FINALLY));
            throw ex;
        }
    }

    public override void afterInsert(SObject so) {
        Recipient_Organization__c recipient = (Recipient_Organization__c) so;
        if (recipient.Fundraising_Project__c != null && recipient.Organization__c != null) {
            affectedKeys.add(PledgeRecipientSoftCreditService.key(recipient.Fundraising_Project__c, recipient.Organization__c));
        }
    }

    public override void afterUpdate(SObject olddata, SObject newdata) {
        Recipient_Organization__c newRecipient = (Recipient_Organization__c) newdata;
        if (isFieldChanged(newRecipient, 'Recipient_Soft_Credit__c') &&
            newRecipient.Fundraising_Project__c != null && newRecipient.Organization__c != null) {
            affectedKeys.add(PledgeRecipientSoftCreditService.key(newRecipient.Fundraising_Project__c, newRecipient.Organization__c));
        }
    }

    public override void afterDelete(SObject so) {
        Recipient_Organization__c recipient = (Recipient_Organization__c) so;
        if (recipient.Fundraising_Project__c != null && recipient.Organization__c != null) {
            affectedKeys.add(PledgeRecipientSoftCreditService.key(recipient.Fundraising_Project__c, recipient.Organization__c));
        }
    }

    public override void afterUndelete(SObject so) {
        afterInsert(so);
    }
    
    Public Static void updateAllrelatedPleadge(Map<String,Id> mapOfkeywithRecOrgId){
        try{ 
            List<Pledge__c> lstPledge = [Select Id,Organization__c,CompositeKey__c FROM Pledge__c 
                                         WHERE CompositeKey__c IN:mapOfkeywithRecOrgId.keySet()];
            for(Pledge__c pledge: lstPledge){
                pledge.Organization__c = mapOfkeywithRecOrgId.get(pledge.CompositeKey__c);
            }
            if(!lstPledge.isEmpty()){
                BBApps_Crud.doUpdateWithHandling(lstPledge, false, ERR_UPDATE_FAILED);
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_ALL_RELATED_PLEADGE)); }
    }
    
}