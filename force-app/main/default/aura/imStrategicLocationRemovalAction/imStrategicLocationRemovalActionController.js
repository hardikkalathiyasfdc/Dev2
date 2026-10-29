({
    init: function(component, event, helper) {
        var action = component.get("c.markForRemoval");
        action.setParams({ locationId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result && result.hasError) {
                    helper.showToast("error", result.errorMessage);
                } else if (result && result.deleted) {
                    helper.showToast("success", "The location was deleted.");
                } else {
                    helper.showToast("success", "You are trying to delete the location. It will be reviewed by the committee.");
                }
            } else {
                var errors = response.getError();
                var message = (errors && errors[0] && errors[0].message) ? errors[0].message : "An error occurred.";
                helper.showToast("error", message);
            }
            $A.get("e.force:closeQuickAction").fire();
            $A.get("e.force:refreshView").fire();
        });
        $A.enqueueAction(action);
    }
})