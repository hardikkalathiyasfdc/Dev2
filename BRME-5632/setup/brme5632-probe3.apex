// BRME-5632 probe 3: find a Contact failure that DIT Preview won't catch but the server DML will.
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.allowSave = true;
dml.optAllOrNone = false;

// B) Too-long FirstName (max 40) — Preview may not cap it if DLR field length differs.
String longName = 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ';
Contact b = new Contact(FirstName=longName, LastName='BRME5632P3B');
Database.SaveResult rb = Database.insert(b, dml);
System.debug('B longFirstName success=' + rb.isSuccess());
if (!rb.isSuccess()) for (Database.Error e : rb.getErrors()) System.debug('B ERR ' + e.getStatusCode() + ': ' + e.getMessage());

// C) Vetting date + status combination.
Contact cc = new Contact(FirstName='T', LastName='BRME5632P3C', Vetting_Date__c=System.today());
Database.SaveResult rc = Database.insert(cc, dml);
System.debug('C vettingDate success=' + rc.isSuccess());
if (!rc.isSuccess()) for (Database.Error e : rc.getErrors()) System.debug('C ERR ' + e.getStatusCode() + ': ' + e.getMessage());

// cleanup any that succeeded
delete [SELECT Id FROM Contact WHERE LastName LIKE 'BRME5632P3%'];
