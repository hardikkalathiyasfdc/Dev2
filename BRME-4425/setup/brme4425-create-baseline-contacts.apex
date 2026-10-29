// BRME-4425: create synthetic baseline Contacts for the "require no review" expandable-table ticket.
// Distinct last names (BRME4425*) so they never collide with BRME-7012 fixtures or real data.
// All marked Description='BRME-4425 synthetic test data', emails on the .invalid TLD.
// Cleanup: BRME-4425/setup/brme4425-cleanup.apex (deletes only the IDs in record-manifest.md).
List<Contact> cons = new List<Contact>{
    // Exact-match targets: uploaded rows will equal these on every mapped field (incl. Business Email),
    // so DIT auto-classifies them as "require no review".
    new Contact(FirstName='Alice',   LastName='BRME4425Exact', Email='alice.brme4425@brme4425.invalid',   Description='BRME-4425 synthetic test data'),
    new Contact(FirstName='Brendan', LastName='BRME4425Exact', Email='brendan.brme4425@brme4425.invalid', Description='BRME-4425 synthetic test data'),
    new Contact(FirstName='Carla',   LastName='BRME4425Exact', Email='carla.brme4425@brme4425.invalid',   Description='BRME-4425 synthetic test data')
};
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;
Database.SaveResult[] results = Database.insert(cons, dml);
for (Integer i = 0; i < results.size(); i++) {
    System.debug('INSERT ' + (results[i].isSuccess() ? 'OK ' + results[i].getId() : 'FAIL ' + results[i].getErrors()[0].getMessage()));
}
for (Contact c : [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email,
                         Converted_FirstName__c, Converted_LastName__c, Converted_Full_Name__c
                  FROM Contact WHERE LastName = 'BRME4425Exact' ORDER BY FirstName]) {
    System.debug('CREATED ' + c.Id + ' | ' + c.FirstName + ' ' + c.LastName + ' | pref=' + c.Preferred_First_Name__c
        + ' | email=' + c.Email + ' | conv=' + c.Converted_FirstName__c + ',' + c.Converted_LastName__c + ',' + c.Converted_Full_Name__c);
}
