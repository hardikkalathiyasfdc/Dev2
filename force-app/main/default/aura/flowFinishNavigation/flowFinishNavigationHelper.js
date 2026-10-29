({
    helperMethod : function() {

    },

    handleRefresh : function(component) {
        // Fire the standard refresh event
        var refreshEvent = $A.get('e.force:refreshView');
        
        if (refreshEvent) {
            refreshEvent.fire();
        }
    },

    showToast : function(component) {
        // Fire a success toast when a message is provided
        var message = component.get("v.toastMessage");
        if (!$A.util.isEmpty(message)) {
            var toastEvent = $A.get('e.force:showToast');
            if (toastEvent) {
                toastEvent.setParams({
                    type: 'success',
                    message: message
                });
                toastEvent.fire();
            }
        }
    },
})