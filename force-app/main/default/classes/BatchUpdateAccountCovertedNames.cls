global class BatchUpdateAccountCovertedNames implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Name, AKA__c, Legal_Name__c, Converted_Org_Name__c, Converted_AKA__c, Converted_Legal_Name__c FROM Account]);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : scope) {
            acc.Converted_Org_Name__c = SpecialCharactersHelper.convertSpecialCharToEnglish(acc.Name);
            acc.Converted_AKA__c = SpecialCharactersHelper.convertSpecialCharToEnglish(acc.AKA__c);
            acc.Converted_Legal_Name__c = SpecialCharactersHelper.convertSpecialCharToEnglish(acc.Legal_Name__c);
            accountsToUpdate.add(acc);
        }
        if (!accountsToUpdate.isEmpty()) {
             TriggerFactory.setBypass('AccountTriggerHandler');
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.update(accountsToUpdate, dml);
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch processing completed.');
    }
}