// BRME-7045: reset the Send Back for Revisions test record to a clean Ready-for-Approval state.
Id initId = 'a0qbc00000HmnW5AAJ'; // Test - 08/14/2026 1.0
update new IM_Initiative__c(
    Id = initId,
    Status__c = 'Ready for Approval',
    Revisions_Needed__c = null,
    Revisions_Reason__c = null
);
System.debug('Reset ' + initId + ' to Ready for Approval; cleared Revisions fields.');
