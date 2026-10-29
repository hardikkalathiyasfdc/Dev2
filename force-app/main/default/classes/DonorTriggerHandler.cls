public without sharing class  DonorTriggerHandler extends TriggerHandler{
    public List<Donor__c> newDonors;
    public List<Donor__c> oldDonors;
    public Map<Id, Donor__c> newDonorsMap;   
    public Map<Id, Donor__c> oldDonorsMap;
    private static Set<Id> pledgeIdsToUpdate = new Set<Id>();
    
    private static final String ERR_BULK_AFTER = 'DONOR_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_PREPARE_ORG_LOOKUP = 'DONOR_TRIGGER_PREPARE_ORG_LOOKUP_FAILED';
    
    public DonorTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Donor__c>)Trigger.oldMap, (Map<Id, Donor__c>)Trigger.newMap);
    }
    
    public DonorTriggerHandler(List<Donor__c> oldCList, List<Donor__c> newCList, Map<Id, Donor__c> oldMap, Map<Id, Donor__c> newMap) {
        oldDonors = oldCList;
        newDonors = newCList;
        oldDonorsMap = oldMap;
        newDonorsMap = newMap; 
    }
    
    public override void bulkAfter() {
        try {
            if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert || Trigger.isDelete)) {
                if(Trigger.isUpdate || Trigger.isInsert) {
                    Set<Id> coFunderDonorIds = new Set<Id>();
                    for(Donor__c d : newDonors) {
                        if(Trigger.isInsert) {
                            pledgeIdsToUpdate.add(d.Pledge__c);                
                        } else if (
                            d.Credit_Type__c != oldDonorsMap.get(d.Id).Credit_Type__c ||
                            d.Contact__c != oldDonorsMap.get(d.Id).Contact__c ||
                            d.Organization__c != oldDonorsMap.get(d.Id).Organization__c
                        ) {
                            pledgeIdsToUpdate.add(d.Pledge__c);
                        }
                        if(Trigger.isInsert) {
                            if(d.Credit_Type__c == 'Donor - Primary') {
                                coFunderDonorIds.add(d.Id);
                            }
                        } else if(
                            (d.Credit_Type__c == 'Donor - Primary' || oldDonorsMap.get(d.Id).Credit_Type__c == 'Donor - Primary') &&
                            (d.Credit_Type__c != oldDonorsMap.get(d.Id).Credit_Type__c || d.Amount__c != oldDonorsMap.get(d.Id).Amount__c)
                        ) {
                            coFunderDonorIds.add(d.Id);
                        }
                    }
                    if(!coFunderDonorIds.isEmpty()) {
                        DonorTriggerHelper.updateCoFunderForDonors(coFunderDonorIds, new Set<Id>());
                    }
                }
                if(Trigger.isDelete) {
                    DonorTriggerHelper.updateCoFunderForDonors(new Set<Id>(), oldDonorsMap.keyset());
                    for(Donor__c d : oldDonors) {
                        pledgeIdsToUpdate.add(d.Pledge__c);  
                    }
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_BULK_AFTER);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
    
    public override void beforeInsert(SObject so) {
        Donor__c DonrOrg = (Donor__c) so;
        prepareorgLookuoRelatedList(DonrOrg);
    }
    
    public override void beforeUpdate(SObject oldSo, SObject newSo) {
        Donor__c newRec = (Donor__c)newSo;
        if(isFieldChanged(newRec, 'Donor_Type__c')) {
            if(newRec.Donor_Type__c == 'Organization') {
                newRec.Contact__c = null;
            } else if (newRec.Donor_Type__c == 'Contact') {
                newRec.Organization__c = null;
            }
        }
    }

    public override void andFinally() {
        if(!pledgeIdsToUpdate.isEmpty()) {
            DonorTriggerHelper.updatePledges(pledgeIdsToUpdate);
        }
    }
    
    public static void prepareorgLookuoRelatedList(Donor__c donrlst) {
        try {
            Pledge__c pled = [SELECT id, Organization__c FROM Pledge__c WHERE id = :donrlst.Pledge__c];
            if(donrlst.Credit_Type__c == 'Donor - Primary') {
                donrlst.Recipient_Organization_Lookup__c = pled.Organization__c;
            }
        } catch (Exception ex) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_PREPARE_ORG_LOOKUP);
            BBApps_ErrorHandler.logErrors(ex, f);
        }
    }
}