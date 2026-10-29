// BRME-7012 cleanup: deletes ONLY the 4 synthetic baseline Contacts created for this ticket.
// See record-manifest.md. Safe to run multiple times.
List<Id> ids = new List<Id>{
    '003bc000018JAY2AAO', // Patricia BRME7012Test (pref Patti)
    '003bc000018JAY3AAO', // Patti BRME7012Test
    '003bc000018JAY4AAO', // Bob BRME7012Test
    '003bc000018JAY5AAO'  // Randy BRME7012Email
};
List<Contact> cons = [SELECT Id, FirstName, LastName FROM Contact WHERE Id IN :ids];
for (Contact c : cons) {
    if (!(c.LastName IN ('BRME7012Test', 'BRME7012Email'))) {
        System.debug('SKIP unexpected record ' + c.Id + ' ' + c.FirstName + ' ' + c.LastName);
    }
}
List<Contact> toDelete = new List<Contact>();
for (Contact c : cons) {
    if (c.LastName == 'BRME7012Test' || c.LastName == 'BRME7012Email') toDelete.add(c);
}
delete toDelete;
System.debug('DELETED ' + toDelete.size() + ' baseline contacts');
// Reminder: also delete any Data_Load__c records created during DIT test uploads (they cascade to Data_Load_Record__c).
