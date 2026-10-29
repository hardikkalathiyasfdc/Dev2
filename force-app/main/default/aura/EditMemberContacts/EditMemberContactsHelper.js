({
	getContactsToEdit : function(component, event, helper) {
        var action = component.get("c.getContactsToEdit");        
        action.setParams({           
            'campId': component.get("v.recordId")
        });   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {                
                var records =response.getReturnValue();                
                records.forEach(function(record){
                    record.linkName = '/'+record.Id;
                });
                component.set("v.data", records);
                component.set("v.filteredData", records);
                helper.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
                helper.hideSpinner(component);
                component.set("v.validateConMsg",null);
            } else {
                helper.showToast({
                        "title": "Error!!",
                        "type": "error",
                        "message": "Error in getting Contact records."
                    });
            }
        });           
        $A.enqueueAction(action);
    },
    updateContacts: function (cmp, event, helper) { 
        var msg = cmp.get("v.validateConMsg");
        if(msg != null && msg != '' && msg.includes('Invalid')){
            helper.showToast({
                        "title": "Error!!",
                        "type": "error",
                        "message": "Please update invalid Salutation/State values in order to save contact records."
                    });
        }else{
        cmp.set("v.validateConMsg",null);
        var draftValues = cmp.find( "editTable" ).get( "v.draftValues" );
        var totalRecordEdited = draftValues.length;       
        var action = cmp.get("c.updateContacts");
        action.setParams({"lstCon" : draftValues,
    						"campId": cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //if update is successful
                	var records =response.getReturnValue();
	                records.forEach(function(record){
	                    record.linkName = '/'+record.Id;
	                });
	                cmp.set("v.data", records);
	                cmp.set("v.filteredData", records);
	                helper.sortData(cmp, cmp.get("v.sortedBy"), cmp.get("v.sortedDirection"));
                	helper.hideSpinner(cmp);
                    helper.showToast({
                        "title": "Record Update",
                        "type": "success",
                        "message": totalRecordEdited+" Contact Records Updated."
                    });                	
                } else{ //if update got failed                    
                    var errors = response.getError();
                    console.error('errors-- > '+errors[0].pageErrors[0].message);
                    helper.showToast({
                        "title": "Error!!",
                        "type": "error",
                        "message": "Error in Updating Contact Records."
                    });
                }
        });
        $A.enqueueAction(action);
        }
    },

    validateContacts : function(component, event, helper) {
        var changedValues = event.getParam('draftValues');
        var action = component.get("c.validateContacts");        
        action.setParams({           
            "updatedCon" : changedValues
        });   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                var messageVal =response.getReturnValue();
                if(messageVal != null){
                    helper.showToast({
                        "title": "Error!",
                        "type": "error",
                        "message": messageVal
                    });                  
                    component.set("v.validateConMsg",messageVal);
                } else {
                   component.set("v.validateConMsg",null); 
                }               
            } else {
                helper.showToast({
                        "title": "Error!!",
                        "type": "error",
                        "message": "Error in Validating Contact Record."
                    });
            }
        });           
        $A.enqueueAction(action);
    },
    /*
     * Show toast with provided params
     * */
    showToast : function(params){
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent){
            toastEvent.setParams(params);
            toastEvent.fire();
        } else{
            //alert(params.message);
            sforce.one.showToast(params);
        }
    },

    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
     
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.filteredData");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.filteredData", data);
        cmp.set("v.data", data);
    },
    
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a)?key(a):'', b = key(b)?key(b):'', reverse * ((a > b) - (b > a));
        }
    },
})