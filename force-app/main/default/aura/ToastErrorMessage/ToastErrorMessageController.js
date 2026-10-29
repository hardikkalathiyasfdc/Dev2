({
	showMyToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        var errorMsg = component.get("v.errorMessage");
        toastEvent.setParams({
            mode: 'sticky',
            "title": "Error!",
            "type": "error",
            message: errorMsg
        });
        toastEvent.fire();
	}
})