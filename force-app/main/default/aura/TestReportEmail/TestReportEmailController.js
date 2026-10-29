({
	testMayorReport : function(component, event, helper) {
		var action = component.get('c.sendMayorReportEmail'); 
        // method name i.e. getEntity should be same as defined in apex class
        // params name i.e. entityType should be same as defined in getEntity method
       
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                helper.showToastAlert('Email Sent Successfully' , 'success');
            }else{
                 helper.showToastAlert('Error while sending report' , 'error');
            }
        });
        $A.enqueueAction(action);
	},
    testBPMemberReport : function(component, event, helper) {
		var action = component.get('c.sendBoardMemberReportEmail'); 
        // method name i.e. getEntity should be same as defined in apex class
        // params name i.e. entityType should be same as defined in getEntity method
       
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                helper.showToastAlert('Email Sent Successfully' , 'success');
            }else{
                 helper.showToastAlert('Error while sending report' , 'error');
            }
        });
        $A.enqueueAction(action);
	},
    
})