({
	checkRestrictedContacts: function (component, done) {
		var action = component.get("c.getRestrictedContactInfo");
		action.setParams({ 'campId': component.get("v.recordId") });
		action.setCallback(this, function (response) {
			if (response.getState() === "SUCCESS") {
				var info = response.getReturnValue();
				var count = info.restrictedCount || 0;
				var hasAccess = info.hasPrivateAccess === true;
				component.set("v.restrictedCount", count);
				component.set("v.hasPrivateAccess", hasAccess);
				// Confirmation is required only when restricted contacts exist AND the
				// user lacks Private_Name_Fields access (records won't be cloned/exported).
				component.set("v.requiresRestrictedConfirm", count > 0 && !hasAccess);
			} else {
				component.set("v.requiresRestrictedConfirm", false);
			}
			if (done) { done(); }
		});
		$A.enqueueAction(action);
	},

	showRestrictedConfirm: function (component, event, helper) {
		var count = component.get("v.restrictedCount");
		var hasAccess = component.get("v.hasPrivateAccess");
		var message;
		if (hasAccess) {
			// User WITH Private_Name_Fields access: informational only.
			message = "Your results contain " + count + " Private Contact(s).";
		} else {
			// User WITHOUT access: records won't export; direct to brmpartnerships.
			message = "You've encountered a problem with some of the records you selected " +
				"(" + count + " records are not exporting). " +
				"Please contact brmpartnerships@bloomberg.org for further assistance.";
		}
		message += "\n\nDo you want to continue cloning?";
		component.set("v.confirmMessage", message);
		component.set("v.showConfirm", true);
	},

	cloneCampaign: function (component, event, helper) {
        // Use the fields captured at submit time (works both for direct submit and
        // after the restricted-contacts confirmation).
        var fields = component.get("v.pendingFields") || (event && event.getParam ? event.getParam('fields') : null);
        var action = component.get("c.cloneCampaignWithMem");
        action.setParams({
            'campIns' : fields,
            'campId' : component.get("v.recordId")
        });   
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner",false);
            if (state === "SUCCESS") {
            	var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();                                   
            	var sObectEvent = $A.get("e.force:navigateToSObject");
			    sObectEvent .setParams({
				    "recordId": response.getReturnValue(),
				    "slideDevName": "detail"
				   });
			    sObectEvent.fire();  
            	var toastEvent = $A.get("e.force:showToast");
			    toastEvent.setParams({
			        "title": "Success!",
			        "message": "List is successfully created. Contacts will be added shortly.",
			        "type": "success"
			    });
			    toastEvent.fire();			    
            }else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    alert("Unknown error");
                }
            }
        });           
        $A.enqueueAction(action);
    },
})