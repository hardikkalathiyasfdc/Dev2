// Resets the demo budgeted initiative so the Request Revisions action can be re-tested.
IM_Initiative__c initiative = new IM_Initiative__c(
    Id = 'a0r7x00002AmKSMAA3',
    Status__c = 'Ready for Approval',
    Revisions_Needed__c = 'No',
    Revisions_Reason__c = null
);
update initiative;
System.debug('RESET>>> ' + [SELECT Status__c, Revisions_Needed__c, Revisions_Reason__c FROM IM_Initiative__c WHERE Id = 'a0r7x00002AmKSMAA3']);
