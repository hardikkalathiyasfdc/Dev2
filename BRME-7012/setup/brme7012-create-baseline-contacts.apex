// BRME-7012: create synthetic baseline Contacts in the dev2 sandbox.
// All records are marked Description='BRME-7012 synthetic test data' and use @brme7012.invalid emails.
// Cleanup: delete by the IDs recorded in BRME-7012/setup/record-manifest.md (see brme7012-cleanup.apex).
List<Contact> cons = new List<Contact>{
    new Contact(FirstName='Patricia', LastName='BRME7012Test', Preferred_First_Name__c='Patti',
                Email='patricia.brme7012@brme7012.invalid', Description='BRME-7012 synthetic test data'),
    new Contact(FirstName='Patti',    LastName='BRME7012Test',
                Email='patti.brme7012@brme7012.invalid',    Description='BRME-7012 synthetic test data'),
    new Contact(FirstName='Bob',      LastName='BRME7012Test',
                Email='bob.brme7012@brme7012.invalid',      Description='BRME-7012 synthetic test data'),
    new Contact(FirstName='Randy',    LastName='BRME7012Email',
                Email='randy.brme7012@brme7012.invalid', Alternate_Email__c='randy.alt.brme7012@brme7012.invalid',
                Description='BRME-7012 synthetic test data')
};
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;
Database.SaveResult[] results = Database.insert(cons, dml);
for (Integer i = 0; i < results.size(); i++) {
    System.debug('INSERT ' + (results[i].isSuccess() ? 'OK ' + results[i].getId() : 'FAIL ' + results[i].getErrors()[0].getMessage()));
}
for (Contact c : [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Alternate_Email__c,
                         Converted_FirstName__c, Converted_LastName__c, Converted_Full_Name__c
                  FROM Contact WHERE LastName IN ('BRME7012Test', 'BRME7012Email') ORDER BY FirstName]) {
    System.debug('CREATED ' + c.Id + ' | ' + c.FirstName + ' ' + c.LastName + ' | pref=' + c.Preferred_First_Name__c
        + ' | email=' + c.Email + ' | alt=' + c.Alternate_Email__c
        + ' | conv=' + c.Converted_FirstName__c + ',' + c.Converted_LastName__c + ',' + c.Converted_Full_Name__c);
}
