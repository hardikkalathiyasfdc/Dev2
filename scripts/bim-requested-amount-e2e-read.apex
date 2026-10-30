// BIM Requested Amount fix — E2E readback (dev2Current). Callout-only script.
// Reads the Bgive grant_request for the test grant and prints requested/recommended amounts.
// Run after a sync step (never in the same script as a sync - that ends with DML).

Id grantId = 'a0obc000003FE49AAG';
BGiveApiGrant api = new BGiveApiGrant();
BGiveApiFilter filter = new BGiveApiFilter();
filter.setGroupType('and');
filter.addCondition(new BGiveFilterCondition('brm_id', BGiveFilterCondition.Operator.STARTS_WITH, String.valueOf(grantId)));
api.setFilters(filter.getFilterString());
BGiveApi.BGiveAPIListResponse resp = (BGiveApi.BGiveAPIListResponse) api.get(
	new List<String>{ 'id', 'amount_requested_local', 'amount_recommended_local', 'state' }
);
System.debug('BGIVE READBACK: ' + JSON.serialize(resp.records));
