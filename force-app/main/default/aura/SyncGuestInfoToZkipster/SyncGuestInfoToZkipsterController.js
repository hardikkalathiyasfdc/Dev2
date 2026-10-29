({
    init : function(component, event, helper) {
        let eventId = component.get('v.recordId');
        

        var action = component.get("c.syncEvent");   
        action.setParams({ 
            "listId" : eventId
        });
        action.setCallback(this, function(response) {
            var toastEvent = $A.get("e.force:showToast");
            if(response.getReturnValue()=='Cancelled'){
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Unable to sync Cancelled or Complete events to zkipster.",
                    "type": "error"
                });
            }
            else{
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Guests are syncing to zkipster and will appear in zkipster shortly.",
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