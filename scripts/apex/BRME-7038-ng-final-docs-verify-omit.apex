// Verify BRME-7038 AC: a blank link is omitted from the View Required Docs formula output.
IM_Initiative__c initiative = new IM_Initiative__c(
    Id = 'a0r7x00002Am4fUAAR',
    Approval_Email_Link__c = null
);
update initiative;
IM_Initiative__c result = [SELECT View_Required_Docs__c FROM IM_Initiative__c WHERE Id = 'a0r7x00002Am4fUAAR'];
System.debug('AFTER-BLANK>>> ' + result.View_Required_Docs__c);

// Restore the link so the record is fully populated for QA.
initiative.Approval_Email_Link__c = 'https://bloomberg.example.com/approval-email/ng-final-docs-demo';
update initiative;
System.debug('RESTORED>>> ' + [SELECT View_Required_Docs__c FROM IM_Initiative__c WHERE Id = 'a0r7x00002Am4fUAAR'].View_Required_Docs__c);
