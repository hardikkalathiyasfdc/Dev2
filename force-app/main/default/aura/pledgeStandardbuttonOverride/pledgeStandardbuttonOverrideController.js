({
    doInit : function(component, event, helper) { 
         component.set("v.refresh",false);
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.refresh",true);
            }), 
            500
        );
        if($A.util.isUndefinedOrNull(component.get("v.recordId"))){
            var parentId = '';
            var pageRef = component.get("v.pageReference");
            var state = pageRef.state; // state holds any query params
            console.log('the state is'+state);
            var base64Context = state.inContextOfRef;
            console.log('the base is'+base64Context);
            if (base64Context.startsWith("1\.")) {
                base64Context = base64Context.substring(2);
            }
            var addressableContext = JSON.parse(window.atob(base64Context));
            parentId = addressableContext.attributes.recordId;
            console.log('the parentId is'+parentId);
            component.set("v.parentRecordId", parentId); 
             
        }   
    },
  
    onPageReferenceChanged: function(cmp, event, helper) {
        debugger;
     
        $A.get('e.force:refreshView').fire();
           
        
    },
	handleClick: function(component, event) {
        var name = event.getParam('Name');
     	console.log('parentcall',name);
 		window.location.href = '/'+name ;
      
        
    },
      
})