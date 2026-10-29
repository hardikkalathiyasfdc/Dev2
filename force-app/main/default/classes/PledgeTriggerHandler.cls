/********************************************************************************
 * Class Name  : PledgeTriggerHandler
 * Description : This class is used by Pledge__c Trigger
 * Modified By  : Ravi Bheemreddy
 * Test         : pledgeTriggerHandlerTest
 * Date: 06/03/2024
 * ChangeLog         :
 * Paddy - 10/05/2025: BRME-7004: Removed updateExcludeFromDonorMemoFlag method.
 * Paddy - 10/15/2026: BRME-7014: Recalc Programmatic Co-funding summary when pledge end date
 *                                changes. End Date edits were previously skipped on afterupdate.
 ********************************************************************************/
public without sharing class PledgeTriggerHandler extends TriggerHandler {
    public List<Pledge__c> newPledges;
    public List<Pledge__c> oldPledges;
    public Boolean isUpdateTrigger;
    public Boolean isInsertTrigger;
    public Boolean isDeleteTrigger;
    Set<Id> setOfFundraisingProjectIds = new Set<Id>();
    Set<Id> pledgesWithChanges = new Set<Id>();
    private static final String ERR_BULK_AFTER = 'PLEDGE_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_AFTER_UPDATE = 'PLEDGE_TRIGGER_AFTER_UPDATE_FAILED';
    private static final String ERR_BEFORE_DELETE = 'PLEDGE_TRIGGER_BEFORE_DELETE_FAILED';
    private static final String ERR_AFTER_DELETE = 'PLEDGE_TRIGGER_AFTER_DELETE_FAILED';
    private static final String ERR_UPDATE_PLEDGE_AMOUNT = 'PLEDGE_TRIGGER_UPDATE_PLEDGE_AMOUNT_FAILED';
    private static final String ERR_UPDATE_ACTIVITY_PLEDGE_AMOUNT = 'PLEDGE_TRIGGER_UPDATE_ACTIVITY_PLEDGE_AMOUNT_FAILED';
    private static final String ERR_AND_FINALLY = 'PLEDGE_TRIGGER_AND_FINAL_FAILED';
    private static final String ERR_UPDATE_RECIPIENT_ORGANIZATION = 'PLEDGE_TRIGGER_UPDATE_RECIPIENT_ORGANITION_FAILED';
    private static final String ERR_UPDATE_DONORS = 'PLEDGE_TRIGGER_UPDATE_DONORS_FAILED';
    private static final String ERR_INSERT_FAILED = 'PLEDGE_TRIGGER__INSERT_FAILED';
    private static final String ERR_UPDATE_FAILED = 'PLEDGE_TRIGGER__UPDATE_FAILED';
    private static final String ERR_UPDATE_EXCLUDE_FROM_DONOR_MEMO = 'PLEDGE_TRIGGER_UPDATE_EXCLUDE_FROM_DONOR_MEMO_FAILED';

    public PledgeTriggerHandler() {
        this(Trigger.old, Trigger.new);
        isUpdateTrigger = Trigger.isUpdate;
        isInsertTrigger = Trigger.isInsert;
        isDeleteTrigger = Trigger.isDelete;
    }

    public PledgeTriggerHandler(List<Pledge__c> oldCList, List<Pledge__c> newCList) {
        oldPledges = oldCList;
        newPledges = newCList;
    }

    public override void bulkBefore() {
        try {
            if(isInsertTrigger || isUpdateTrigger) {
                List<Pledge__c> pledgesToPopulate = new List<Pledge__c>();
                for (Pledge__c pledge : newPledges) {
                    if (isInsertTrigger || isFieldChanged(pledge, 'Organization__c') ||
                        isFieldChanged(pledge, 'Fundraising_Effort__c')) {
                        pledgesToPopulate.add(pledge);
                    }
                }
                if (!pledgesToPopulate.isEmpty()) {
                    PledgeRecipientSoftCreditService.populatePledgeFields(pledgesToPopulate);
                }
                //updateExcludeFromDonorMemoFlag(newPledges);
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_INSERT_FAILED)); }
    }

    public override void bulkAfter() {
        try {
            if(isInsertTrigger || isUpdateTrigger || isDeleteTrigger) {
                updatePledgeAmount(newPledges, oldPledges);
            }
            if(isInsertTrigger || isUpdateTrigger) {
                for(Pledge__c objpledge : newPledges) {
                    if(isInsertTrigger || ( isUpdateTrigger && (isFieldChanged(objpledge, 'Fundraising_Effort__c') ||
                                                                isFieldChanged(objpledge, 'Report_Amount_USD__c') ||
                                                                isFieldChanged(objpledge, 'Organization__c') ||
                                                                isFieldChanged(objpledge, 'Status__c'))
                    )) {
                        setOfFundraisingProjectIds.add(objpledge.Fundraising_Effort__c);
                    }
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_BULK_AFTER)); }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        try {
            Pledge__c newRec = (Pledge__c)so;
            Pledge__c oldRec = (Pledge__c)oldSo;
            if(isFieldChanged(newRec, 'Organization__c')) pledgesWithChanges.add(newRec.Id);
            if(isFieldChanged(newRec, 'Exclude_from_Donor_memo__c') ||
               isFieldChanged(newRec, 'Fundraising_Effort__c') ||
               isFieldChanged(newRec, 'Anonymous__c') ||
               isFieldChanged(newRec, 'Pledge_Start_date__c') ||
               isFieldChanged(newRec, 'Pledge_End_date__c') ||
               (isFieldChanged(newRec, 'Status__c') && (newRec.Status__c == 'Pledged' || oldRec.Status__c == 'Pledged'))) {
                Set<Id> relatedDonorIds = new Set<Id>();
                for(Donor__c donor : [SELECT Id FROM Donor__c WHERE Pledge__c = :newRec.Id]) {
                    relatedDonorIds.add(donor.Id);
                }
                if(!relatedDonorIds.isEmpty()) DonorTriggerHelper.updateCoFunderForDonors(relatedDonorIds, new Set<Id>());
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AFTER_UPDATE)); }
    }

    public override void beforeDelete(SObject so) {
        try {
            Pledge__c oldPledge = (Pledge__c)so;
            Set<Id> relatedDonorIds = new Set<Id>();
            for(Donor__c donor : [SELECT Id FROM Donor__c WHERE Pledge__c = :oldPledge.Id]) {
                relatedDonorIds.add(donor.Id);
            }
            if(!relatedDonorIds.isEmpty()) DonorTriggerHelper.updateCoFunderForDonors(new Set<Id>(), relatedDonorIds);
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,  new BBApps_ErrorCustomFields(ERR_BEFORE_DELETE)); }
    }

    public override void afterDelete(SObject so) {
        try {
            Pledge__c oldorg = (Pledge__c)so;
            setOfFundraisingProjectIds.add(oldorg.Fundraising_Effort__c);
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AFTER_DELETE)); }
    }

    public override void afterUndelete(SObject so) {
        PledgeRecipientSoftCreditService.populatePledgeFields(newPledges);
        if (!newPledges.isEmpty()) update newPledges;
    }

    public static void updatePledgeAmount(List<Pledge__c> newCList, List<Pledge__c> oldCList) {
        try {
            Set<Id> setOfActivityIds = new Set<Id>();
            if(Trigger.isDelete) {
                for(Pledge__c p: oldCList) {
                    setOfActivityIds.add(p.Fundraising_Mode__c);
                }
            } else {
                for(Integer i = 0; i < newCList.size(); i++) {
                    if(oldCList != null) {
                        if(newCList[i].Fundraising_Mode__c <> oldCList[i].Fundraising_Mode__c ||
                           newCList[i].Organization__c <> oldCList[i].Organization__c ||
                           newCList[i].Report_Amount_USD__c <> oldCList[i].Report_Amount_USD__c ||
                           newCList[i].Status__c <> oldCList[i].Status__c) {

                            setOfActivityIds.add(newCList[i].Fundraising_Mode__c);
                        }
                    } else {
                        setOfActivityIds.add(newCList[i].Fundraising_Mode__c);
                    }
                }
            }
            if(!setOfActivityIds.isEmpty()) {
                updateActivityPledgeAmount(setOfActivityIds);
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_PLEDGE_AMOUNT)); }
    }

    public static void updateActivityPledgeAmount(Set<Id> setOfActivityIds) {
        try {
            List<Fundraising_Activity__c> appealsToUpdate = new List<Fundraising_Activity__c> ();
            List<Fundraising_Activity__c> allAppeals = [
                SELECT Id, (SELECT Id, Report_Amount_USD__c, Status__c
                            FROM Pledge__r
                            WHERE Report_Amount_USD__c != null
                              AND Status__c = 'Pledged')
                FROM Fundraising_Activity__c
                WHERE Id IN :setOfActivityIds
            ];
            for(Fundraising_Activity__c appeal : allAppeals) {
                if(!appeal.Pledge__r.isEmpty()) {
                    appeal.Activity_Total_Pledge_Amount__c = 0;
                    for(Pledge__c pledgeRecord : appeal.Pledge__r) {
                        appeal.Activity_Total_Pledge_Amount__c += pledgeRecord.Report_Amount_USD__c;
                    }
                } else {
                    appeal.Activity_Total_Pledge_Amount__c = null;
                }
                appealsToUpdate.add(appeal);
            }
            if(!appealsToUpdate.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(appealsToUpdate, false, ERR_UPDATE_FAILED);
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_ACTIVITY_PLEDGE_AMOUNT)); }
    }

    public override void andFinally() {
        try {
            if(!setOfFundraisingProjectIds.isEmpty()) {
                updateRecipientOrganization(setOfFundraisingProjectIds);
            }
            if(!pledgesWithChanges.isEmpty()) {
                updateDonors(pledgesWithChanges);
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_AND_FINALLY)); }
    }

    @future
    public static void updateRecipientOrganization(Set<Id> setOfFundraisingProjectIds) {
        try {
            Map<String, Decimal> mapofCompositeKeywithAmount = new Map<String, Decimal>();
            Map<String, Decimal> mapofCompositeKeywithPledge = new Map<String, Decimal>();
            Set<String> setofCompositeKey = new Set<String>();
            for(Pledge__c pledge : [SELECT Id, Pledge_Amount__c, Report_Amount_USD__c, CompositeKey__c,
                                           Fundraising_Effort__c, Organization__c, Status__c
                                    FROM Pledge__c
                                    WHERE Fundraising_Effort__c IN :setOfFundraisingProjectIds
                                      AND Status__c = 'Pledged']) {
                if(pledge.Report_Amount_USD__c != null) {
                    if(mapofCompositeKeywithAmount.containsKey(pledge.CompositeKey__c)) {
                        Decimal amount = mapofCompositeKeywithAmount.get(pledge.CompositeKey__c) + pledge.Report_Amount_USD__c;
                        mapofCompositeKeywithAmount.put(pledge.CompositeKey__c, amount);
                    } else {
                        mapofCompositeKeywithAmount.put(pledge.CompositeKey__c, pledge.Report_Amount_USD__c);
                    }
                }
                if(pledge.Fundraising_Effort__c != null && pledge.Organization__c != null) {
                    if(mapofCompositeKeywithPledge.containsKey(pledge.CompositeKey__c)) {
                        Decimal totalpledge = mapofCompositeKeywithPledge.get(pledge.CompositeKey__c) +1;
                        mapofCompositeKeywithPledge.put(pledge.CompositeKey__c, totalpledge);
                    } else {
                        mapofCompositeKeywithPledge.put(pledge.CompositeKey__c, 1);
                    }
                }
            }
            List<Recipient_Organization__c> lstrecpOrg = new List<Recipient_Organization__c>();
            lstrecpOrg = [SELECT Id, Total_pledge_amounts__c, Composite_Key__c, Number_of_pledges__c
                          FROM Recipient_Organization__c
                          WHERE (Composite_Key__c IN :mapofCompositeKeywithPledge.keyset() OR
                                 Fundraising_Project__c IN :setOfFundraisingProjectIds)];
            for(Recipient_Organization__c recorg : lstrecpOrg) {
                recorg.Total_pledge_amounts__c = 0;
                recorg.Number_of_pledges__c = 0;
                if(mapofCompositeKeywithAmount.containsKey(recorg.Composite_Key__c))
                    recorg.Total_pledge_amounts__c += mapofCompositeKeywithAmount.get(recorg.Composite_Key__c) != null
                                                      ? mapofCompositeKeywithAmount.get(recorg.Composite_Key__c)
                                                      : 0;
                if(mapofCompositeKeywithPledge.containsKey(recorg.Composite_Key__c))
                    recorg.Number_of_pledges__c += mapofCompositeKeywithPledge.get(recorg.Composite_Key__c);
            }
            if(!lstrecpOrg.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(lstrecpOrg, false, ERR_UPDATE_FAILED);
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_RECIPIENT_ORGANIZATION)); }
    }

    private static void updateDonors(Set<Id> pledgeIds) {
        try {
            List<Donor__c> donorsToUpdate = new List<Donor__c>();
            for(Pledge__c p : [SELECT Id, Organization__c, (SELECT Id FROM Donors__r)
                               FROM Pledge__c
                               WHERE Id IN :pledgeIds]) {

                for(Donor__c d : p.Donors__r) {
                    d.Recipient_Organization_Lookup__c = p.Organization__c;
                    donorsToUpdate.add(d);
                }
            }
            if(!donorsToUpdate.isEmpty()) {
                BBApps_Crud.doUpdateWithHandling(donorsToUpdate, false, ERR_UPDATE_FAILED);
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_DONORS)); }
    }

    /*private void updateExcludeFromDonorMemoFlag(List<Pledge__c> pledges) {
        try {
            for(Pledge__c pledge : pledges) {
                if(isFieldChanged(pledge, 'Status__c')) {
                    pledge.Exclude_from_Donor_memo__c = (pledge.Status__c != 'Pledged');
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_EXCLUDE_FROM_DONOR_MEMO)); }
    }*/
}