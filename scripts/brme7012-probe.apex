// BRME-7012 probe: verify SOQL LIKE with Set bind + inspect existing Patti/Patricia Harris contacts (read-only)
Set<String> fn = new Set<String>{'Patti'};
Set<String> ln = new Set<String>{'Harris'};
List<Contact> r = [SELECT Id, FirstName, LastName, Preferred_First_Name__c FROM Contact WHERE (FirstName LIKE :fn OR Preferred_First_Name__c LIKE :fn) AND LastName LIKE :ln LIMIT 20];
System.debug('LIKESET rows=' + r.size());
for (Contact c : r) System.debug('  LIKESET ' + c.Id + ' ' + c.FirstName + ' / pref=' + c.Preferred_First_Name__c + ' ' + c.LastName);
List<Contact> patti = [SELECT Id, FirstName, LastName, Preferred_First_Name__c, Email, Converted_FirstName__c, Converted_LastName__c, Converted_Full_Name__c FROM Contact WHERE LastName = 'Harris' AND (FirstName = 'Patti' OR FirstName = 'Patricia' OR Preferred_First_Name__c = 'Patti')];
System.debug('HARRIS rows=' + patti.size());
for (Contact c : patti) System.debug('  HARRIS ' + c.Id + ' ' + c.FirstName + ' pref=' + c.Preferred_First_Name__c + ' email=' + c.Email + ' conv=' + c.Converted_FirstName__c + '|' + c.Converted_LastName__c + '|' + c.Converted_Full_Name__c);
