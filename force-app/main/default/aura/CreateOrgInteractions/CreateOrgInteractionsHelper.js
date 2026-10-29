({
	createInteractions: function (component, event, helper) {
        var action = component.get("c.autoCreateOrgInteractions");
        action.setParams({
            'interactionIns' : event.getParam('fields'),
            'campId' : component.get("v.recordId"),
            'recordTypeId' : component.get('v.value')
        });   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.showToast({
                        "title": "Success!",
			        "message": "Interaction records are created successfully.",
			        "type": "success"
                    });
			   // var dismissActionPanel = $A.get("e.force:closeQuickAction");
               // dismissActionPanel.fire();
               helper.closeAction(component, event, helper);    
            }else if (state === "ERROR") {
                component.set('v.showSpinner', false);
                var errors = response.getError();
               
                if (errors) {
                    
                    errors.forEach( function (error){

				//top-level error.  there can be only one
				if (error.message){
                    helper.showToast({
                        "title": "Error!",
                        "type": "error",
                        "message": error.message
                    });
				}

				//page-level errors (validation rules, etc)
				if (error.pageErrors){
					error.pageErrors.forEach( function(pageError) {
                        helper.showToast({
                        "title": "Error!",
                        "type": "error",
                        "message": pageError.message
                    })
					});					
				}

				if (error.fieldErrors){
					//field specific errors					
					for (var fieldName in error.fieldErrors) {
						//each field could have multiple errors
						error.fieldErrors[fieldName].forEach( function (errorList){
                            helper.showToast({
                        "title": "Field Error on " + fieldName + " : ",
                        "type": "error",
                        "message": errorList.message
                    })
														
						});                                
					};  //end of field errors forLoop					
				} //end of fieldErrors if
			}); //end Errors forEach

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
            //alert(params.message);
            sforce.one.showToast(params);
        }
    },

    checkCreationPermission: function(component) {
        let helper = this;
        let action = component.get('c.checkOrgRecentEngagementCreationPermission');
        action.setCallback(this, function(response) {
            if( response.getState() === 'SUCCESS' ) {
                if( response.getReturnValue() === true ) {
                    helper.countMem(component, event, helper);
                } else {
                    helper.showToast({
                        "title": "Error!",
                        "message": $A.get('$Label.c.List_Create_Org_Engagement_Button_Permission_Error'),
                        "type": "error"
                    });
                   // var dismissActionPanel = $A.get("e.force:closeQuickAction");
                   // dismissActionPanel.fire();
                   helper.closeAction(component, event, helper);    
                }
            }
        });

        $A.enqueueAction(action);
    },
	closeAction: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    getCampaignDefaultTeam: function(component) {
        let action = component.get('c.getCampaignDefaultTeam');
        action.setParams({
            campId: component.get('v.recordId')
        });

        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
                component.set('v.defaultTeamId', response.getReturnValue());
                this.applyCampaignTeamDefault(component);
            }
        });

        $A.enqueueAction(action);
    },

    applyCampaignTeamDefault: function(component) {
        let defaultTeamId = component.get('v.defaultTeamId');
        let interactionFields = component.get('v.interactionFields');

        if (!defaultTeamId || !interactionFields || interactionFields.length === 0) {
            return;
        }

        interactionFields.forEach(item => {
            if (item.fieldPath === 'Teams__c' && !item.value) {
                item.value = defaultTeamId;
            }
        });

        component.set('v.interactionFields', interactionFields);
    },

    countMem: function(component, event, helper) {    
        var action = component.get("c.conOrgsCount");
        action.setParams({
            'campId' : component.get("v.recordId")
        });   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
            	component.set("v.memCount",response.getReturnValue());
            	var countMem = response.getReturnValue();
            	if(countMem != null && countMem == 0){
            		var dismissActionPanel = $A.get("e.force:closeQuickAction");
	                dismissActionPanel.fire();
            		var toastEvent = $A.get("e.force:showToast");
				    toastEvent.setParams({
				        "title": "Cannot create Interactions !",
				        "message": "There are no List Organization on this List.",
				        "type": "error"
				    });
				    toastEvent.fire();				    
            	} else {
            		helper.getExistingRecordTypes(component);
            	}
            }
        });           
        $A.enqueueAction(action);
    },

    getExistingRecordTypes: function(component) {
    	let helper = this;
        let action = component.get('c.getRecordTypes');
        action.setCallback(this, function(response) {
            
            if (response.getState() === "SUCCESS") {
                let result = JSON.parse(response.getReturnValue());
                let recordTypes =[];

                let selectedType = result.find(x => x.developerName === 'Recent_Engagement');
                helper.getFieldsByRecordType(component, selectedType.developerName);
                component.set('v.value', selectedType.recordTypeId);
                helper.getCampaignDefaultTeam(component);
            }
        });
        $A.enqueueAction(action);
    },

    getFieldsByRecordType: function(component, devName) {
        let action = component.get('c.getFieldsByRecordType');
        action.setParams({'devName': devName});
        action.setCallback(this, function(response) {
            
            if (response.getState() === "SUCCESS") {
                let result = JSON.parse(response.getReturnValue());
                let idx = 0;
                let interactionFields = [];
                let requiredFields = [];
                result.forEach(item => {
                    if( idx === 2 ) {
                        idx = 0;
                    }
                    item.order = idx;

                    if( item.required === true ) {
                        let tmpField = {};
                        tmpField.value = item.fieldPath;
                        tmpField.label = item.label;
                        requiredFields.push(tmpField);
                    }
                    interactionFields.push(item);
                    idx += 1;
                });
                
                component.set('v.requiredFields', requiredFields);
                component.set('v.interactionFields', interactionFields);
                this.applyCampaignTeamDefault(component);
                
            }
        });
        $A.enqueueAction(action);
    }
})