global class BatchUpdateContactCovertedNames implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, FirstName, LastName, MiddleName FROM Contact]);
    }

    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : scope) {
            c.Converted_FirstName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(c.FirstName);
            c.Converted_MiddleName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(c.MiddleName);
            c.Converted_LastName__c = SpecialCharactersHelper.convertSpecialCharToEnglish(c.LastName);
            contactsToUpdate.add(c);
        }
        if (!contactsToUpdate.isEmpty()) {
            TriggerFactory.setBypass('ContactTriggerHandler');
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.update(contactsToUpdate, dml);
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch processing completed.');
    }
}