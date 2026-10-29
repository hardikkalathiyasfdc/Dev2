({
	doInit : function(cmp, event, helper) {
		let navService = cmp.find("navService");
        let pageReference = {
        	type: 'standard__component',
        	attributes: {
            	componentName: 'c:ListViewInlineEditCmp'
        	},
        	state : {
            	c__id : cmp.get('v.recordId')
        	}
    	};
        navService.navigate(pageReference);
	}
})