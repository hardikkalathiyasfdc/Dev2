({
	doInit : function(cmp, event, helper) {
        let action = cmp.get("c.getCampaignMembers");
        action.setParams({ contactId: cmp.get("v.recordId"), isActive: cmp.get("v.showActiveLists") });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let campaignMembers = response.getReturnValue();
                //console.log("campaignMembers");
                //console.log(campaignMembers);
                //Sort the campaign name by alpha
                campaignMembers.sort((a, b) => {
                    return a.Campaign.Name > b.Campaign.Name?1:a.Campaign.Name < b.Campaign.Name?-1:0;
                });
                cmp.set("v.allCampaignMembers", campaignMembers);
                if( campaignMembers.length > 3) {
                    cmp.set("v.campaignMembers", campaignMembers.slice(0, 3));
                    cmp.set('v.showButton', true);
                } else {
                    cmp.set("v.campaignMembers", campaignMembers);
                    cmp.set('v.showButton', false);
                    cmp.set('v.showAll', true);
                }
                cmp.set("v.numberOfMembers", campaignMembers.length);
            }
            else {
                let toastEvent = $A.get("e.force:showToast");
                let toastParams = {title:"Error",message:"",type:"error"};
                if (state === "INCOMPLETE") {
                    toastParams.message = "No response from server or client is offline.";
                }
                else if (state === "ERROR") {
                    let errors = response.getError();
                    console.log(errors);
                    // Pass the error message if any
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        for (let i = 0; i < errors.length; i++) { 
                            message = message +'Error'+ i + ':' + errors[i].message;
                        }
                        toastParams.message = message;
                    }
                    toastEvent.setParams(toastParams);
                }
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
	},

    showContent: function(component, event, helper) {
        let showAll = component.get('v.showAll');
        let allCampaignMember = component.get('v.allCampaignMembers');
        if( showAll === true ) {
            component.set("v.campaignMembers", allCampaignMember.slice(0, 3));
            showAll = false;
        } else {
            component.set("v.campaignMembers", allCampaignMember);
            showAll = true;
        }

        component.set('v.showAll', showAll);
    }
})