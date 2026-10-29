({   

    closeAction: function (component, event, helper) {
       helper.closeAction(component, event, helper);
    },

    handleSuccess : function(component, event, helper) {
        
        helper.showToast({
                        "title": "Success!",
			        "message": "Interaction records are created successfully.",
			        "type": "success"
                    });
    },

    handleSubmit: function(component, event, helper) {
        event.preventDefault(); // stop the form from submitting 
        component.set('v.showSpinner', true);
        helper.createInteractions(component, event, helper); 
        
    },

    handleError: function(component, event) {
        component.set("v.hideCreateButton",true);
      
        helper.showToast({
                        "title": "Error!",
                        "type": "error",
                        "message": "An Error Occured/You do not have permission to create Interactions."
                    });
    },

    countMem: function(component, event, helper) {
        //helper.checkCreationPermission(component);
        
        helper.countMem(component, event, helper);
    },
    cancel : function(component,event,helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})