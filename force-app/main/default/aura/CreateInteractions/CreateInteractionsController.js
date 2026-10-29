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
        helper.getExistingRecordTypes(component); 
        var selectedRows = component.get("v.selectedRecs");
        if(selectedRows != null){
            component.set("v.memCount",selectedRows.length);
        }else {
            helper.countMem(component, event, helper);
        }

    },

    handleComponentEvent: function(component, event, helper) { 
        var selectedRows = event.getParam("selectedRecs");
        component.set("v.selectedRecs",selectedRows);
        component.set("v.memCount",selectedRows.length);
        
    },

    handleCreate : function(component, event, helper) {
        component.set('v.showCreationSection', true);
        let selectedType = component.get('v.recordTypes').find(x => x.value === component.get('v.value'));
        helper.getFieldsByRecordType(component, selectedType.devName);
    },
    cancel : function(component,event,helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})