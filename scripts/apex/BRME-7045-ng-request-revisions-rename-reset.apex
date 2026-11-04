// Appends the BRME-7045 ticket tag to the NG demo records and resets the budgeted
// initiative so the Request Revisions action can be re-tested against the picklist field.
String tag = ' BRME-7045';
List<IM_Initiative__c> records = [
    SELECT Id, Name, Status__c, Revisions_Needed__c, Revisions_Reason__c
    FROM IM_Initiative__c
    WHERE Id IN ('a0r7x00002AmKSLAA3', 'a0r7x00002AmKSMAA3', 'a0r7x00002AmcXKAAZ')
];
for (IM_Initiative__c record : records) {
    if (!record.Name.endsWith(tag)) {
        record.Name = record.Name + tag;
    }
    if (record.Id == 'a0r7x00002AmKSMAA3') {
        record.Status__c = 'Ready for Approval';
        record.Revisions_Needed__c = 'No';
        record.Revisions_Reason__c = null;
    }
}
update records;
for (IM_Initiative__c record : records) {
    System.debug('RENAMED>>> ' + record.Id + ' | ' + record.Name + ' | ' + record.Status__c);
}
