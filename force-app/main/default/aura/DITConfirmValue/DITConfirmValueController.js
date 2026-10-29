({
	doInit : function(component, event, helper) { 
      let row =  component.get("v.row");
		 component.set("v.colValue",row[component.get("v.col")]);
	}
})