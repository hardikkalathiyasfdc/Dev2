({
    saveOrgs : function(component) {
    	let action = component.get('c.createListOrganizations');

    	action.setParams({'orgs': JSON.stringify(component.get('v.selectedAccounts')), 'listId':component.get('v.recordId')});

    	action.setCallback(this, function(response){
    		if(response.getState() === 'SUCCESS') {
    			var toastEvent = $A.get("e.force:showToast");
			    toastEvent.setParams({
			        "title": "Success!",
			        "type": 'success',
			        "message": "The organizations have been added successfully."
			    });
			    toastEvent.fire();

			    $A.get("e.force:closeQuickAction").fire();

			    $A.get('e.force:refreshView').fire();
    		}
    	});

    	$A.enqueueAction(action);
    }
})