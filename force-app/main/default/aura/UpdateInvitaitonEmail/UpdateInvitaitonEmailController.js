({
    closeButton : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();

         $A.get('e.force:refreshView').fire();
    }
})