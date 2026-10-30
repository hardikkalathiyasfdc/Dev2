// BIM Requested Amount fix — E2E step C (dev2Current): re-push (update path).
// Expect in Bgive after this: amount_requested_local still 0 (not overwritten), amount_recommended_local = 120000.
// Sync-only script: IMGrantService.sync ends with DML, so the Bgive readback MUST run separately
// (scripts/bim-requested-amount-e2e-read.apex) or the callout fails with "uncommitted work pending".

Id grantId = 'a0obc000003FE49AAG';

try {
	IMGrantService.sync(grantId, Assets.SINGLE_CREATE);
} catch (Exception e) {
	System.debug('SYNC-UPDATE EXCEPTION: ' + e.getMessage());
}
IM_Grant__c g = [
	SELECT Id, Bgive_Id__c, Sync_Error__c, Total_Amount_Local__c, Budget_Amount_Local__c
	FROM IM_Grant__c
	WHERE Id = :grantId
];
System.debug('AFTER UPDATE: Bgive_Id__c=' + g.Bgive_Id__c + ' | Sync_Error__c=' + g.Sync_Error__c
	+ ' | Total=' + g.Total_Amount_Local__c + ' | Budget=' + g.Budget_Amount_Local__c);
