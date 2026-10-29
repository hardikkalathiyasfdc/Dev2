// BRME-7012 pre-fix BASELINE evidence: run the exact DIT retrieval query for each scenario.
// Replicates DITCmpController.getDupeContactList name/email branches against the current (unfixed) org code.
System.debug('======== BRME-7012 PRE-FIX BASELINE (' + Datetime.now().format() + ') ========');

// Scenario A: single-row import (Patti / BRME7012Test, no email)
Set<String> fnA = new Set<String>{'Patti'};
Set<String> lnA = new Set<String>{'BRME7012Test'};
List<Contact> a = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email
    FROM Contact
    WHERE ((Converted_FirstName__c LIKE :fnA OR Preferred_First_Name__c LIKE :fnA) AND Converted_LastName__c LIKE :lnA)
       OR ((FirstName LIKE :fnA OR Preferred_First_Name__c LIKE :fnA) AND LastName LIKE :lnA)
    ORDER BY Name ASC LIMIT 10000];
System.debug('--- A. retrieval rows (Patti/BRME7012Test, no email): ' + a.size());
for (Contact c : a) System.debug('  A ' + c.Id + ' ' + c.FirstName + ' pref=' + c.Preferred_First_Name__c + ' ' + c.LastName);
// prepareResult equivalent: only keys the row reads (pattibrme7012test / patti brme7012test)
System.debug('  A keys the row reads: pattibrme7012test / patti brme7012test');

// Scenario B: regression file (Patti/PATTI/Patti-space + Bob on BRME7012Test; Patti BRME7012Nomatch; Randall BRME7012Email + alt email)
Set<String> fnB = new Set<String>{'Patti','PATTI','Bob','Randall'};
Set<String> lnB = new Set<String>{'BRME7012Test','BRME7012Nomatch','BRME7012Email'};
Set<String> emB = new Set<String>{'randy.alt.brme7012@brme7012.invalid'};
List<Contact> b = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Alternate_Email__c
    FROM Contact
    WHERE ((Converted_FirstName__c LIKE :fnB OR Preferred_First_Name__c LIKE :fnB) AND Converted_LastName__c LIKE :lnB)
       OR ((FirstName LIKE :fnB OR Preferred_First_Name__c LIKE :fnB) AND LastName LIKE :lnB)
       OR (Personal_Email_2__c IN :emB) OR (Business_Email_2__c IN :emB) OR (Alternate_Email__c IN :emB) OR (Email IN :emB)
    ORDER BY Name ASC LIMIT 10000];
System.debug('--- B. retrieval rows (regression): ' + b.size());
for (Contact c : b) System.debug('  B ' + c.Id + ' ' + c.FirstName + ' pref=' + c.Preferred_First_Name__c + ' ' + c.LastName + ' email=' + c.Email + ' alt=' + c.Alternate_Email__c);

// Scenario C: two-row (same as A plus email of row2 = patricia's email)
Set<String> fnC = new Set<String>{'Patti'};
Set<String> lnC = new Set<String>{'BRME7012Test'};
Set<String> emC = new Set<String>{'patricia.brme7012@brme7012.invalid'};
List<Contact> cc = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email
    FROM Contact
    WHERE ((Converted_FirstName__c LIKE :fnC OR Preferred_First_Name__c LIKE :fnC) AND Converted_LastName__c LIKE :lnC)
       OR ((FirstName LIKE :fnC OR Preferred_First_Name__c LIKE :fnC) AND LastName LIKE :lnC)
       OR (Email IN :emC)
    ORDER BY Name ASC LIMIT 10000];
System.debug('--- C. retrieval rows (two-row): ' + cc.size());
for (Contact c : cc) System.debug('  C ' + c.Id + ' ' + c.FirstName + ' pref=' + c.Preferred_First_Name__c + ' ' + c.LastName + ' email=' + c.Email);
System.debug('======== END BASELINE ========');

