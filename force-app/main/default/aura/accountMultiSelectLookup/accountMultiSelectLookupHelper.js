({
    searchHelper : function(component,event,getInputkeyWord) {
        // call the apex class method 
        let action = component.get("c.fetchAccountsByKeyword");
        
        // set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord
        });
        // set a callBack    
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            
            if (response.getState() === "SUCCESS") {
                let storeResponse = JSON.parse(response.getReturnValue());
                
                storeResponse.sort((a, b)=>{
                	return a.Name > b.Name?1:a.Name < b.Name?-1:0;
                });

                let existedIds = new Set();
                if( component.get("v.selectedRecords") !== undefined ){
                	component.get("v.selectedRecords").forEach( item => {
	                	existedIds.add(item.Id);
	                });
                }
                
                let results = [];
                storeResponse.forEach( x => {
                	if( existedIds.length === 0 ) {
                		results.push(x);
                	} else {
                		if( !existedIds.has(x.Id) ) {
                			results.push(x);
                		}
                	}
                });
                
                // if storeResponse size is equal 0 ,display No Records Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Records Found...');
                } else {
                    component.set("v.Message", '');
                    // set searchResult list with return value from server.
                }

                component.set("v.listOfSearchRecords", results); 
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    }
})