// BRME-5632 probe 2: find a validation rule that fires on a DIT-style Contact insert (phone auto-formatted).
// Tries a phone WITH a value but an invalid country-code combination to force Office_Phone_Country_Code.
Contact c = new Contact(FirstName='Test', LastName='BRME5632Probe2', Phone='2125550100', Office_Phone_Country_Code__c=null);
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;
dml.optAllOrNone = false;
Database.SaveResult sr = Database.insert(c, dml);
System.debug('phoneNoCode success=' + sr.isSuccess());
if (!sr.isSuccess()) for (Database.Error e : sr.getErrors()) System.debug('ERR ' + e.getStatusCode() + ': ' + e.getMessage());

// try a phone with an explicit country code that the formatter can't reconcile
Contact c2 = new Contact(FirstName='Test', LastName='BRME5632Probe2', Phone='+44 20 1234 5678', Office_Phone_Country_Code__c='United States(+1)');
Database.SaveResult sr2 = Database.insert(c2, dml);
System.debug('mismatch success=' + sr2.isSuccess());
if (!sr2.isSuccess()) for (Database.Error e : sr2.getErrors()) System.debug('ERR2 ' + e.getStatusCode() + ': ' + e.getMessage());
