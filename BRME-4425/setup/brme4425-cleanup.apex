// BRME-4425 cleanup: deletes ONLY the 3 synthetic baseline Contacts created for this ticket.
// See record-manifest.md. Safe to run multiple times. Does NOT touch BRME-7012 or real records.
List<Id> ids = new List<Id>{
    '003bc000018J9ykAAC', // Alice BRME4425Exact
    '003bc000018J9ylAAC', // Brendan BRME4425Exact
    '003bc000018J9ymAAC'  // Carla BRME4425Exact
};
List<Contact> toDelete = new List<Contact>();
for (Contact c : [SELECT Id, FirstName, LastName FROM Contact WHERE Id IN :ids]) {
    if (c.LastName == 'BRME4425Exact') {
        toDelete.add(c);
    } else {
        System.debug('SKIP unexpected record ' + c.Id + ' ' + c.FirstName + ' ' + c.LastName);
    }
}
delete toDelete;
System.debug('DELETED ' + toDelete.size() + ' BRME-4425 baseline contacts');
// Reminder: also delete any Data_Load__c records created during DIT test uploads (cascade to Data_Load_Record__c).
