({
    loadData: function(component, event, helper) {
 
      //call apex class method
      var action = component.get('c.initMethod'); 
      action.setCallback(this, function(response) {
        //store state of response
        var state = response.getState();
        if (state === "SUCCESS") {
          //set response value in wrapperList attribute on component.
          component.set('v.wrapperList', response.getReturnValue());
        }
      });
      $A.enqueueAction(action);

      var action2 = component.get("c.calcMapFldLabelFldPath");   
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {                
                var custs = [];
                var conts = response.getReturnValue();
                for(var key in conts){
                    custs.push({value:conts[key], key:key});
                }
                component.set("v.mapValue", custs);
            } 
        });           
        $A.enqueueAction(action2);

        var action3 = component.get("c.getMultiPiklistValues");
        action3.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var result = response.getReturnValue();
                var plValues = [];
                for (var i = 0; i < result.length; i++) {
                    plValues.push({
                        label: result[i],
                        value: result[i]
                    });
                }
                component.set("v.categoryList", plValues);
            }
        });
        $A.enqueueAction(action3);

        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set("v.MaxDate", today);
    },

    getContacts : function(component, event, helper) {
        
        var pageSize = component.get("v.pageSize").toString();
        var pageNumber = component.get("v.pageNumber").toString();
        var action = component.get("c.getContacts");
        action.setStorable();
        action.setParams({
            'lstWrap' : component.get('v.wrapperList'),
            'pageSize' : pageSize,
            'pageNumber' : pageNumber,
            'campId': component.get("v.recordId")
        });   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {                
                if(response.getReturnValue().length < component.get("v.pageSize")){
                    component.set("v.isLastPage", true);
                } else{
                    component.set("v.isLastPage", false);
                }
                response.getReturnValue().forEach(function(row) {
                   row.Id = row.Id+'-'+pageNumber;
                   if(row.AccountId != null)
                    row.OrgName = row.Account.Name;
                });
                component.set("v.resultSize", response.getReturnValue().length);
                component.set("v.data", response.getReturnValue());
                component.find("contactDataTable").set("v.selectedRows",component.get("v.selection"));
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    alert("Unknown error");
                }
            }
        });           
        $A.enqueueAction(action);
    },

    AddMemberContact: function(component, event) {
        // show spinner message
        component.find("Id_spinner").set("v.class" , 'slds-show');
        var action = component.get("c.addMemContact");
        action.setParams({
            'selectedRecords': component.get("v.selection"),
            'campId': component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
           // hide spinner when response coming from server 
            component.find("Id_spinner").set("v.class" , 'slds-hide');
            var state = response.getState();
            if (state === "SUCCESS") {
                
                var result = response.getReturnValue();               
                let displayMsg = '';
                let hasError = false;
                
                Object.keys(result).forEach(function(key) {
                    
                    if (result[key] && result[key].length > 0) {
                        
                        hasError = true;
                        
                        displayMsg +=
                            '<span><b>' +
                            key +
                            '</b></span>: <span>' +
                            result[key].join(', ') +
                            '</span><br/>';
                    }
                });
                
                if (hasError) {   
                    component.set("v.errorMessage", displayMsg);
                    $A.get("e.force:refreshView").fire();
                } else
                if(component.get("v.fromRelatedList")){
                    var recId = component.get("v.recordId");
                    sforce.one.navigateToSObject(recId);
                }else{
                    $A.get("e.force:refreshView").fire();
                    //This closes the Action Window
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }
            }else if (state === "INCOMPLETE") {
                alert('Response is Incompleted');
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var errMsg = errors[0].message;
                        var splitErrMsgArray=errMsg.split(',');
                        var splitErrMsg = splitErrMsgArray[splitErrMsgArray.length -1];
                        this.showToast({
                            "mode": 'sticky',
                            "title": "Error!",
                            "type": "error",
                            "message": splitErrMsg.replace(': []', '')
                    	});
                    }
                } else {
                    alert("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },

    AddMemberContactBasic: function(component, event) {
        // show spinner message
        component.find("Id_spinner").set("v.class" , 'slds-show');
        var action = component.get("c.addMemContactBasic");
        action.setParams({
            'selectedRecords': component.get("v.selectedLookUpRecords"),
            'campId': component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
           // hide spinner when response coming from server 
            component.find("Id_spinner").set("v.class" , 'slds-hide');
            var state = response.getState();
            if (state === "SUCCESS") {
                
                var result = response.getReturnValue();
                
                let displayMsg = '';
                let hasError = false;
                
                Object.keys(result).forEach(function(key) {
                    
                    if (result[key] && result[key].length > 0) {
                        
                        hasError = true;
                        
                        displayMsg +=
                            '<span><b>' +
                            key +
                            '</b></span>: <span>' +
                            result[key].join(', ') +
                            '</span><br/>';
                    }
                });
                
                if (hasError) {   
                    component.set("v.errorMessage", displayMsg);
                    $A.get("e.force:refreshView").fire();
                } else {
                if(component.get("v.fromRelatedList")){
                    var recId = component.get("v.recordId");
                    sforce.one.navigateToSObject(recId);
                }else{
                    $A.get("e.force:refreshView").fire();
                    //This closes the Action Window
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }                
                }
          
            }else if (state === "INCOMPLETE") {
                alert('Response is Incompleted');
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var errMsg = errors[0].message;
                        var splitErrMsgArray=errMsg.split(',');
                        var splitErrMsg = splitErrMsgArray[splitErrMsgArray.length -1];
                        this.showToast({
                            "mode": 'sticky',
                            "title": "Error!",
                            "type": "error",
                            "message": splitErrMsg.replace(': []', '')
                    	});
                    }
                }
                else {
                    alert("Unknown error");
                }
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
            alert(params.message);
        }
    },
})