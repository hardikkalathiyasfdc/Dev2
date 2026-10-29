// BRME-6993 cleanup: deletes ONLY the synthetic baseline Contacts + Accounts created for this ticket.
// See record-manifest.md. Safe to run multiple times. Does NOT touch other tickets' or real records.
List<Id> contactIds = new List<Id>{
    '003bc000018L8YYAA0', // Fiona BRME6993Full (chk=false, full)
    '003bc000018L8YZAA0', // Theo BRME6993ChkTrue (chk=true, full)
    '003bc000018KoOdAAK', // Paula BRME6993Partial (email only)
    '003bc000018KoOeAAK', // Adam BRME6993AddrOnly (address only)
    '003bc000018KoOfAAK'  // Bianca BRME6993Bare (none)
};
List<Id> accountIds = new List<Id>{
    '001bc00000kkfowAAA', // BRME6993 Org A (BRM)
    '001bc00000kkfoxAAA'  // BRME6993 Org B (Excel)
};
List<Contact> cons = [SELECT Id, LastName FROM Contact WHERE Id IN :contactIds];
delete [SELECT Id FROM Contact WHERE Id IN :contactIds AND LastName LIKE 'BRME6993%'];
System.debug('DELETED contacts: ' + cons.size());
delete [SELECT Id FROM Account WHERE Id IN :accountIds AND Name LIKE 'BRME6993%'];
System.debug('DELETED accounts: ' + accountIds.size());
// Reminder: also delete any Data_Load__c records created during DIT test uploads (cascade to rows).
