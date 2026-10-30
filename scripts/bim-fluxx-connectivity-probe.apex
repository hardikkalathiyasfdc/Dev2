// Connectivity probe: does the Fluxx named credential work in this org?
// Callout-only, no DML. Prints status/body of a minimal grant_request query.
try {
	BGiveApiGrant api = new BGiveApiGrant();
	BGiveApiFilter filter = new BGiveApiFilter();
	filter.setGroupType('and');
	filter.addCondition(new BGiveFilterCondition('id', BGiveFilterCondition.Operator.STARTS_WITH, '1'));
	api.setFilters(filter.getFilterString());
	api.setPageSize(1);
	BGiveApi.BGiveAPIListResponse resp = (BGiveApi.BGiveAPIListResponse) api.get(new List<String>{ 'id' });
	System.debug('FLUXX CONNECTIVITY OK: records=' + JSON.serialize(resp.records));
} catch (Exception e) {
	System.debug('FLUXX CONNECTIVITY FAILED: ' + e.getMessage());
}
