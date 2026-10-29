({
    doInit : function(component, event, helper) {
        if(component.get("v.sObjectName")!='ListOrganization__c'){
            component.set("v.organizationIds",component.get("v.recordId"));
            component.set("v.showCmp",true);
        }
        
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            if(component.get("v.sObjectName")=='ListOrganization__c'){
                component.set("v.organizationIds",component.get("v.record").List__c);
                component.set("v.showCmp",true);
            }
        } else if(eventParams.changeType === "REMOVED") {
            console.log("Record is deleted");
        } else if(eventParams.changeType === "ERROR") {
            console.error("Error loading record:", eventParams.error);
        }
    },
    closeQA: function(component, event, helper) {
        
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        
        
        dismissActionPanel.fire();
    }
})