// BIM Requested Amount fix — E2E readback (Dev1). Callout-only script.
// Reads the Bgive grant_request for the Dev1 test grant and prints requested/recommended amounts.
// Run after a sync step (never in the same script as a sync - that ends with DML).

Id grantId = 'a0oOz000004YgAbIAK';
BGiveApiGrant api = new BGiveApiGrant();
BGiveApiFilter filter = new BGiveApiFilter();
filter.setGroupType('and');
filter.addCondition(new BGiveFilterCondition('brm_id', BGiveFilterCondition.Operator.STARTS_WITH, String.valueOf(grantId)));
api.setFilters(filter.getFilterString());
BGiveApi.BGiveAPIListResponse resp = (BGiveApi.BGiveAPIListResponse) api.get(
	new List<String>{ 'id', 'amount_requested_local', 'amount_recommended_local', 'state' }
);
System.debug('BGIVE READBACK (Dev1): ' + JSON.serialize(resp.records));
