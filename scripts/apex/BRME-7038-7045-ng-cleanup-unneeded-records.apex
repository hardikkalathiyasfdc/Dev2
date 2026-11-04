// Delete records not needed for QA to avoid confusion.
// KEEP (QA-ready budgeted records):
//   a0r7x00002Am4fUAAR  NG Final Docs Demo 1.0 BRME-7038
//   a0r7x00002AmJuTAAV  NG Final Docs Demo 2.0 BRME-7038
//   a0r7x00002AmKSMAA3  NG Request Revisions Demo 1.0 BRME-7045
//   a0r7x00002AmJuUAAV  NG Request Revisions Demo 2.0 BRME-7045
// DELETE: parent initiatives + auto-created Miscellaneous children.

Set<Id> keepIds = new Set<Id>{
    'a0r7x00002Am4fUAAR', 'a0r7x00002AmJuTAAV',
    'a0r7x00002AmKSMAA3', 'a0r7x00002AmJuUAAV'
};

List<IM_Initiative__c> toDelete = [
    SELECT Id, Name, RecordType.Name
    FROM IM_Initiative__c
    WHERE (Name LIKE '%BRME-7038%' OR Name LIKE '%BRME-7045%')
    AND Id NOT IN :keepIds
];

System.debug('DELETING ' + toDelete.size() + ' records:');
for (IM_Initiative__c r : toDelete) {
    System.debug('DELETE>>> ' + r.Id + ' | ' + r.Name + ' | ' + r.RecordType.Name);
}
delete toDelete;
System.debug('DONE. Remaining kept records:');
for (IM_Initiative__c r : [SELECT Id, Name, Status__c FROM IM_Initiative__c WHERE Id IN :keepIds]) {
    System.debug('KEEP>>> ' + r.Id + ' | ' + r.Name + ' | ' + r.Status__c);
}
