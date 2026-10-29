({
    init : function(component, event, helper) {
        let eventId = component.get('v.recordId');
        

        var action = component.get("c.startSyncFromZkipster");   
        action.setParams({ 
            "eventId" : eventId
        });
        action.setCallback(this, function(response) {
            var toastEvent = $A.get("e.force:showToast");
            if(response.getReturnValue()=='Cancelled'){
                toastEvent.setParams({
                "title": "Error!",
                "message": "Unable to sync guest information to BRM for Cancelled events.",
                "type": "error"
            });
            }
            else{
            toastEvent.setParams({
                "title": "Success!",
                "message": "Guest information is syncing to BRM from zkipster and will appear in BRM shortly.",
                "type": "success"
            });
			}
            toastEvent.fire();

            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
        });

        $A.enqueueAction(action);
    }   
})