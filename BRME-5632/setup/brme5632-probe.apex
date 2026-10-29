// BRME-5632 probe: confirm Business Phone without Country Code fails validation (no record persists).
Contact c = new Contact(FirstName='Test', LastName='BRME5632Probe', Phone='212-555-0100');
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;
dml.optAllOrNone = false;
Database.SaveResult sr = Database.insert(c, dml);
System.debug('success=' + sr.isSuccess());
if (!sr.isSuccess()) { for (Database.Error e : sr.getErrors()) System.debug('ERR ' + e.getStatusCode() + ': ' + e.getMessage()); }
