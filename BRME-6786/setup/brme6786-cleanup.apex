// BRME-6786 cleanup: deletes ONLY the 4 synthetic baseline Accounts created for this ticket.
// See record-manifest.md. Safe to run multiple times. Does NOT touch BRME-7012/4425 or real records.
List<Id> ids = new List<Id>{
    '001bc00000kjz4sAAA', // BRME6786 Holdings Group
    '001bc00000kjz4tAAA', // BRME6786 City Foundation (A)
    '001bc00000kjz4uAAA', // BRME6786 City Foundation (B)
    '001bc00000kjz4vAAA'  // BRME6786 Exact Org
};
List<Account> toDelete = new List<Account>();
for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :ids]) {
    if (a.Name.startsWith('BRME6786')) {
        toDelete.add(a);
    } else {
        System.debug('SKIP unexpected record ' + a.Id + ' ' + a.Name);
    }
}
delete toDelete;
System.debug('DELETED ' + toDelete.size() + ' BRME-6786 baseline accounts');
// Reminder: also delete any Data_Load__c records created during DIT test uploads (cascade to Data_Load_Record__c),
// plus any Contact created via the DIT import flow during testing.
