// BIM Requested Amount fix — E2E cleanup (Dev1): unlink grant from Bgive.
// Mirrors the UI "Unlink" action: clears brm_id + bgive_im_connection on Bgive grant_request 52071
// and unlinks the BRM side (Bgive_Id__c etc. cleared by unlinkBRM).
// Callout + DML inside IMGrantService.unlink - run standalone (no prior DML in this transaction).

Id grantId = 'a0oOz000004YgAbIAK';
//Query every field unlinkBRM/deleteZeroAmountIMGrant touch (SObjectException on unqueried fields - repo lesson #1)
IM_Grant__c imGrant = [
	SELECT Id, Name, Bgive_Id__c, Bgive_Contig_Id__c, Bgive_IM_Connection__c, Sync_Error__c,
		Budget_Amount_USD__c, Deleted__c
	FROM IM_Grant__c
	WHERE Id = :grantId
];
IM_Budget_Grant__c budgetGrant = [
	SELECT Id, Deleted__c, Budget_Amount_USD__c, Budget_Amount_Local__c,
		Confirmed_Budget_Amount_USD__c, Confirmed_Budget_Amount_Local__c, Is_Active__c
	FROM IM_Budget_Grant__c
	WHERE IM_Grant__c = :grantId AND Is_Active__c = true
	LIMIT 1
];
System.debug('BEFORE UNLINK: Bgive_Id__c=' + imGrant.Bgive_Id__c);

try {
	IMGrantService.unlink(imGrant, budgetGrant, 'Unlink');
	System.debug('UNLINK OK');
} catch (Exception e) {
	System.debug('UNLINK EXCEPTION: ' + e.getMessage());
}

IM_Grant__c after = [
	SELECT Id, Bgive_Id__c, Bgive_IM_Connection__c, Sync_Error__c
	FROM IM_Grant__c
	WHERE Id = :grantId
];
System.debug('AFTER UNLINK: Bgive_Id__c=' + after.Bgive_Id__c
	+ ' | Bgive_IM_Connection__c=' + after.Bgive_IM_Connection__c
	+ ' | Sync_Error__c=' + after.Sync_Error__c);
