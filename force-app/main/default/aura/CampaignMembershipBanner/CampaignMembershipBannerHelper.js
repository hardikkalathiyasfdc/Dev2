({
    getMyDomainURL: function(component, event, helper) {

        var action = component.get("c.getMyDomain");  
        action.setParams({ });  
        action.setCallback(this, function(response){

            var state = response.getState();

            if(component.isValid() && state === "SUCCESS"){
                var url = response.getReturnValue();
                component.set("v.myDomainURL", url);
            } else {
                var errors = response.getError(); 
                console.log('Error: ' + JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);     
    },
    getCampaignBanner : function(component, event, helper) {
        debugger;
        var action=component.get("c.isActiveCampaignMember");
        action.setParams({
            "recordId":component.get("v.recordId"),
            "sObjectName":component.get("v.sObjectName")
        });
        action.setCallback(this,function(response)
        {
            debugger;    
            var state=response.getState();

            if(state=="SUCCESS") {
                var storeResponse = response.getReturnValue();   
                component.set("v.isCampaignMember", storeResponse.isActiveCampaignMember);
                component.set("v.toEmailAddress", storeResponse.toEmailAddress);
            }
        });
        $A.enqueueAction(action);
    },
    getUserInfo: function(component, event, helper) {
        
        var currentUserId = $A.get("$SObjectType.CurrentUser.Id");

        var action = component.get("c.getUser");  
        action.setParams({
            "userId": currentUserId
        });  

        action.setCallback(this, function(response){

            var state = response.getState();
            
            if(component.isValid() && state === "SUCCESS"){
                var user = response.getReturnValue();
                component.set("v.userName", user.Name);
            } else {
                var errors = response.getError(); 
                console.log('Error: ' + JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);     
    },
    getRecordInfo: function(component, event, helper) {

        var action = component.get("c.getContact"); 
        var objectName = component.get("v.sObjectName");

        if (objectName == 'Account') {
            action = component.get("c.getAccount"); 
        }

        action.setParams({
            "recordId": component.get("v.recordId")
        });  

        action.setCallback(this, function(response){
            var state = response.getState();
            
            if(component.isValid() && state === "SUCCESS"){
                var record = response.getReturnValue();
                component.set("v.contactName", record.Name);
                component.set("v.contactId", record.Id);
            } else {
                var errors = response.getError(); 
                console.log('Error: ' + JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);     
    }
})