/**
 * Synchronizes the system-managed Pledge Recipient Soft Credit lookup from the
 * Fundraising Project and Recipient Organization relationship.
 */
public without sharing class PledgeRecipientSoftCreditService {
    private static final String ERR_RECONCILE = 'PLEDGE_RECIPIENT_SOFT_CREDIT_RECONCILE_FAILED';

    public static void populatePledgeFields(List<Pledge__c> pledges) {
        if (pledges == null || pledges.isEmpty()) return;
        Set<String> compositeKeys = new Set<String>();
        for (Pledge__c pledge : pledges) {
            if (pledge.Fundraising_Effort__c != null && pledge.Organization__c != null) {
                compositeKeys.add(key(pledge.Fundraising_Effort__c, pledge.Organization__c));
            }
        }
        Map<String, Id> softCreditByKey = getSoftCredits(compositeKeys);
        for (Pledge__c pledge : pledges) {
            // This lookup is derived from the current project/organization mapping.
            // A missing mapping must clear stale data rather than preserve it.
            pledge.Recipient_Soft_Credit__c = pledge.Fundraising_Effort__c == null || pledge.Organization__c == null
                ? null
                : softCreditByKey.get(key(pledge.Fundraising_Effort__c, pledge.Organization__c));
        }
    }

    public static void reconcileRecipientOrganizationKeys(Set<String> affectedKeys) {
        if (affectedKeys == null || affectedKeys.isEmpty()) return;
        Map<String, Id> softCreditByKey = getSoftCredits(affectedKeys);
        List<Pledge__c> pledgesToUpdate = new List<Pledge__c>();
        for (Pledge__c pledge : [
            SELECT Id, Fundraising_Effort__c, Organization__c, CompositeKey__c, Recipient_Soft_Credit__c
            FROM Pledge__c
            WHERE CompositeKey__c IN :affectedKeys
            WITH SYSTEM_MODE
        ]) {
            Id expectedSoftCredit = softCreditByKey.get(pledge.CompositeKey__c);
            if (pledge.Recipient_Soft_Credit__c != expectedSoftCredit) {
                pledge.Recipient_Soft_Credit__c = expectedSoftCredit;
                pledgesToUpdate.add(pledge);
            }
        }
        if (!pledgesToUpdate.isEmpty()) {
            try {
                BBApps_Crud.doUpdateWithHandling(pledgesToUpdate, false, ERR_RECONCILE);
            } catch (Exception ex) {
                BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_RECONCILE));
                throw ex;
            }
        }
    }

    private static Map<String, Id> getSoftCredits(Set<String> compositeKeys) {
        Map<String, Id> result = new Map<String, Id>();
        if (compositeKeys.isEmpty()) return result;
        for (Recipient_Organization__c recipient : [
            SELECT Composite_Key__c, Recipient_Soft_Credit__c
            FROM Recipient_Organization__c
            WHERE Composite_Key__c IN :compositeKeys
            WITH SYSTEM_MODE
        ]) {
            result.put(recipient.Composite_Key__c, recipient.Recipient_Soft_Credit__c);
        }
        return result;
    }

    public static String key(Id projectId, Id organizationId) {
        return String.valueOf(projectId) + String.valueOf(organizationId);
    }
}