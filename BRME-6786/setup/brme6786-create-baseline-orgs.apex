// BRME-6786: create synthetic baseline Accounts in the dev2 sandbox for Review Errors message scenarios.
// Distinctive names prefixed BRME6786; Description marks them for cleanup. No real Accounts touched.
// Scenarios:
//  1) Upload "BRME6786 Holdings"     -> not exact for "BRME6786 Holdings Group" (not found msg) but duplicate modal has a candidate.
//  2) Upload "BRME6786 Nonexistent Foundation" -> no candidates at all -> Create Organization.
//  3) Upload "BRME6786 City Foundation"      -> two Accounts share the exact normalized name -> "Multiple ..." + duplicate modal.
//  5) Upload "BRME6786 Exact Org"            -> exact match control (auto-links, no error row).
List<Account> accs = new List<Account>{
    new Account(Name='BRME6786 Holdings Group',  Description='BRME-6786 synthetic test data'),
    new Account(Name='BRME6786 City Foundation', Description='BRME-6786 synthetic test data'),
    new Account(Name='BRME6786 City Foundation', Description='BRME-6786 synthetic test data'),
    new Account(Name='BRME6786 Exact Org',       Description='BRME-6786 synthetic test data')
};
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;
Database.SaveResult[] results = Database.insert(accs, dml);
for (Integer i = 0; i < results.size(); i++) {
    System.debug('INSERT ' + (results[i].isSuccess() ? 'OK ' + results[i].getId() : 'FAIL ' + results[i].getErrors()[0].getMessage()));
}
for (Account a : [SELECT Id, Name, Converted_Org_Name__c, AKA__c, Legal_Name__c
                  FROM Account WHERE Name LIKE 'BRME6786%' ORDER BY Name, CreatedDate]) {
    System.debug('CREATED ' + a.Id + ' | ' + a.Name + ' | conv=' + a.Converted_Org_Name__c);
}
