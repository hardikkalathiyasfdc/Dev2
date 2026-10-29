({
    showToast: function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({ type: type, message: message });
            toastEvent.fire();
        }
    }
})