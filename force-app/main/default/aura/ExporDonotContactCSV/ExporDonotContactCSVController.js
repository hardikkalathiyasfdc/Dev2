({
	doInit : function(component, event, helper) {
		var mypageRef = component.get("v.pageReference");
        var recordId = mypageRef.state.c__recordId;
        component.set("v.recordId",recordId);
	},
    reInit:function(component, event, helper){
        $A.get('e.force:refreshView').fire();
    }
})