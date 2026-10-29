({
    init: function(component, event, helper) {

        var currentRecordId = component.get("v.recordId");
        helper.showToast(component);
        helper.handleRefresh(component);

        window.setTimeout(function() {
            var navService = component.find("navService");
            var pageReference = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: currentRecordId,
                    actionName: "view"
                }
            };
            navService.navigate(pageReference);
        }, 100);

   },

   invoke: function(component, event, helper) {

        var currentRecordId = component.get("v.recordId");
        helper.showToast(component);
        helper.handleRefresh(component);

        window.setTimeout(function() {
            var navService = component.find("navService");
            var pageReference = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: currentRecordId,
                    actionName: "view"
                }
            };
            navService.navigate(pageReference);
        }, 100);

        return new Promise(function(resolve) {
            window.setTimeout(function() {
                resolve();
            }, 500);
        });

   }
})