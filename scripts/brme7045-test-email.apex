// BRME-7045: confirm the real NotificationService path now delivers (SaveAsActivity fix).
Id initId = 'a0qbc00000HmnW5AAJ';
Id grantsContact = [SELECT Grants_Team_Contact__c FROM IM_Initiative__c WHERE Id = :initId].Grants_Team_Contact__c;
System.debug('Grants Contact: ' + grantsContact);
try {
    NotificationService.sendEmail('IM_Initiative_Revisions_Needed', new Set<Id>{ initId }, grantsContact);
    System.debug('sendEmail invoked OK');
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
