// BIM Requested Amount fix — E2E step A (Dev1): create push.
// Pre-req: scripts/bim-requested-amount-dev1-setup.apex executed.
// Sync-only script: IMGrantService.sync ends with DML, so the Bgive readback MUST run separately
// (scripts/bim-requested-amount-dev1-read.apex) or the callout fails with "uncommitted work pending".
// Next: -dev1-read.apex, -dev1-b-change.apex, -dev1-c-update.apex, -dev1-read.apex

Id grantId = 'a0oOz000004YgAbIAK';

try {
	IMGrantService.sync(grantId, Assets.SINGLE_CREATE);
} catch (Exception e) {
	System.debug('SYNC-CREATE EXCEPTION: ' + e.getMessage());
}
IM_Grant__c g1 = [
	SELECT Id, Bgive_Id__c, Sync_Error__c, Total_Amount_Local__c, Budget_Amount_Local__c
	FROM IM_Grant__c
	WHERE Id = :grantId
];
System.debug('AFTER CREATE (Dev1): Bgive_Id__c=' + g1.Bgive_Id__c + ' | Sync_Error__c=' + g1.Sync_Error__c
	+ ' | Total=' + g1.Total_Amount_Local__c + ' | Budget=' + g1.Budget_Amount_Local__c);
