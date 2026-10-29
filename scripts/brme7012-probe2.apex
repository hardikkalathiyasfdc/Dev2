// BRME-7012 probe 2: char composition of Contact.Converted_Full_Name__c (read-only)
Contact c = [SELECT Id, Name, FirstName_LastName__c, Converted_Full_Name__c, Converted_FirstName__c, Converted_LastName__c FROM Contact WHERE Id = '003bc000014Q78UAAS'];
String cf = c.Converted_Full_Name__c;
String codes = '';
for (Integer i = 0; i < cf.length(); i++) { codes += cf.substring(i, i+1) + '=' + cf.charAt(i) + ' '; }
System.debug('CFN value=[' + cf + '] len=' + cf.length());
System.debug('CFN chars: ' + codes);
System.debug('Name=[' + c.Name + '] FirstName_LastName__c=[' + c.FirstName_LastName__c + ']');
System.debug('ConvFirst=[' + c.Converted_FirstName__c + '] ConvLast=[' + c.Converted_LastName__c + ']');
