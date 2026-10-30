// BIM Requested Amount fix — E2E step A (dev2Current): create push.
// Pre-req: scripts/bim-requested-amount-setup.apex executed and the Option B CMDT change deployed.
// Sync-only script: IMGrantService.sync ends with DML, so the Bgive readback MUST run separately
// (scripts/bim-requested-amount-e2e-read.apex) or the callout fails with "uncommitted work pending".
// Next steps: bim-requested-amount-e2e-read.apex, bim-requested-amount-e2e-b-change.apex,
//             bim-requested-amount-e2e-c-update.apex, bim-requested-amount-e2e-read.apex

Id grantId = 'a0obc000003FE49AAG';

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
System.debug('AFTER CREATE: Bgive_Id__c=' + g1.Bgive_Id__c + ' | Sync_Error__c=' + g1.Sync_Error__c
	+ ' | Total=' + g1.Total_Amount_Local__c + ' | Budget=' + g1.Budget_Amount_Local__c);
