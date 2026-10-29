({
    handleLookupChange : function(component, event, helper) {
        var detail = JSON.parse(JSON.stringify(event.getParams()));
        var selectedRecords = detail.selectedRecords || [];
        var accounts = selectedRecords.map(function(r) { return { Id: r.Id }; });
        component.set('v.selectedAccounts', accounts);
    },

    addSelectedAccounts : function(component, event, helper) {
    	helper.saveOrgs(component);
    },

    closeAction : function(component, event, helper) {
    	$A.get("e.force:closeQuickAction").fire();
    }
})