({
	doInit: function(component, event, helper) {
		helper.checkRestrictedContacts(component);
	},

	handleSubmit: function(component, event, helper) {
        event.preventDefault(); // stop the form from submitting
        component.set("v.pendingFields", event.getParam('fields'));

        // Determine restricted-contact status at submit time (not on init) so a fast
        // submit can't bypass the confirmation before the async init check returns.
        component.set("v.showSpinner", true);
        helper.checkRestrictedContacts(component, function () {
            if (component.get("v.requiresRestrictedConfirm")) {
                component.set("v.showSpinner", false);
                helper.showRestrictedConfirm(component, event, helper);
            } else {
                helper.cloneCampaign(component, event, helper);
            }
        });
    },

    confirmClone: function(component, event, helper) {
        component.set("v.showConfirm", false);
        component.set("v.showSpinner", true);
        helper.cloneCampaign(component, event, helper);
    },

    cancelClone: function(component, event, helper) {
        // Hide the confirm and close the quick action to return to the record.
        component.set("v.showConfirm", false);
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },

    closeAction: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire(); 
    },
})