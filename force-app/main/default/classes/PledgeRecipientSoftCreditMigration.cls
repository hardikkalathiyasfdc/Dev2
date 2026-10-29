/**
 * Backfills Pledge Recipient Soft Credit values for existing Pledge records.
 * Uses the shared synchronization service and preserves partial-save results.
 */
global without sharing class PledgeRecipientSoftCreditMigration implements Database.Batchable<SObject>, Database.Stateful {
    private static final String ERR_START = 'PLEDGE_RECIPIENT_SOFT_CREDIT_MIGRATION_START_FAILED';
    private static final String ERR_EXECUTE = 'PLEDGE_RECIPIENT_SOFT_CREDIT_MIGRATION_EXECUTE_FAILED';
    private static final String ERR_FINISH = 'PLEDGE_RECIPIENT_SOFT_CREDIT_MIGRATION_FINISH_FAILED';

    global Integer correctedCount = 0;
    global Integer unmatchedCount = 0;
    global Integer failureCount = 0;

    global Database.QueryLocator start(Database.BatchableContext context) {
        try {
            return Database.getQueryLocator([
                SELECT Id, Fundraising_Effort__c, Organization__c, Recipient_Soft_Credit__c
                FROM Pledge__c
            ]);
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_START));
            throw ex;
        }
    }

    global void execute(Database.BatchableContext context, List<SObject> records) {
        try {
            List<Pledge__c> scope = new List<Pledge__c>();
            for (SObject record : records) scope.add((Pledge__c) record);
            Map<Id, Id> previousValues = new Map<Id, Id>();
            for (Pledge__c pledge : scope) {
                previousValues.put(pledge.Id, pledge.Recipient_Soft_Credit__c);
            }

            PledgeRecipientSoftCreditService.populatePledgeFields(scope);
            List<Pledge__c> changes = new List<Pledge__c>();
            for (Pledge__c pledge : scope) {
                if (previousValues.get(pledge.Id) != pledge.Recipient_Soft_Credit__c) {
                    changes.add(pledge);
                }
                if (pledge.Fundraising_Effort__c != null && pledge.Organization__c != null && pledge.Recipient_Soft_Credit__c == null) {
                    unmatchedCount++;
                }
            }

            if (!changes.isEmpty()) {
                Database.SaveResult[] results = Database.update(changes, false);
                for (Database.SaveResult result : results) {
                    if (result.isSuccess()) correctedCount++;
                    else failureCount++;
                }
            }
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_EXECUTE));
            throw ex;
        }
    }

    global void finish(Database.BatchableContext context) {
        try {
            System.debug(LoggingLevel.INFO, 'Recipient soft-credit migration corrected=' + correctedCount
                + ', unmatched=' + unmatchedCount + ', failures=' + failureCount);
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_FINISH));
            throw ex;
        }
    }
}