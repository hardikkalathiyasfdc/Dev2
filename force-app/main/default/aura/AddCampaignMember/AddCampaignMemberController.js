({
    doInit: function(component, event, helper) {
        component.set('v.contactDisplayFields', ['Search_Display_Name__c', 'Title', 'Email_Org_Name__c']);
        component.set('v.contactSearchFields', ['Search_Display_Name__c', 'Email']);
        component.set('v.contactDisplayFieldPrefixes', ['', '', '', '']);
    },

    loadData: function(component, event, helper) {
        helper.loadData(component, event,helper);
        var device = $A.get("$Browser.formFactor");
        if(device == 'DESKTOP'){
            component.set('v.columns', [
                {label: 'Name', fieldName: 'Name', type: 'text', 
                actions:[
                    {label: 'All',
                    checked: false,
                    name:'All'},
                    {label: 'Active',
                    checked: false,
                    name:'Active'}]},
                {label: 'Title', fieldName: 'Title', type: 'text'},
                {label: 'Organization Name', fieldName: 'OrgName', type: 'text'},
                {label: 'Phone', fieldName: 'Phone', type: 'phone'},
                {label: 'Business Email', fieldName: 'Email', type: 'email'}
            ]);
        }else{
            component.set('v.columns', [
                {label: 'Name', fieldName: 'Name', type: 'text', 
                actions:[
                    {label: 'All',
                    checked: false,
                    name:'All'},
                    {label: 'Active',
                    checked: false,
                    name:'Active'}]},
                {label: 'Organization Name', fieldName: 'OrgName', type: 'text'},
                {label: 'Business Email', fieldName: 'Email', type: 'email'}
            ]);
        }
        //added empty list for clear filter action
        component.set('v.wrapperList', []);
        helper.getContacts(component, event,helper);
    },

    applyFilters : function(component, event, helper) {        
        helper.getContacts(component, event,helper);
    },

    handleCategoryChange: function (component, event, helper) {
        //Get the Selected values   
        var selectedValues = event.getParam("value");         
        //Update the Selected Values  
        component.set("v.selectedCategories", selectedValues);
    },

    /**
     * This method will keep record of all selected rows
     * */
    onRowSelection : function(component, event, helper) {
        // Avoid any operation if page has changed
        // as this event will be fired when new data will be loaded in page 
        // after clicking on next or prev page
        if(!component.get("v.hasPageChanged") || component.get("v.initialLoad")){
            //set initial load to false
            component.set("v.initialLoad", false);
            //Get currently select rows, This will only give the rows available on current page
            var selectedRows = event.getParam('selectedRows');
            
            //Get all selected rows from datatable, this will give all the selected data from all the pages
            var allSelectedRows = component.get("v.selection");
            
            //Get current page number
            var currentPageNumber = component.get("v.pageNumber");
            
            //Process the rows now
            //Condition 1 -> If any new row selected, add to our allSelectedRows attribute
            //Condition 2 -> If any row is deselected, remove from allSelectedRows attribute
            //Solution - Remove all rows from current page from allSelectedRows attribute and then add again
    
            //Removing all rows coming from curent page from allSelectedRows
            var i = allSelectedRows.length;
            while (i--) {
                var pageNumber = allSelectedRows[i].split("-")[1];
                if (pageNumber && pageNumber == currentPageNumber) { 
                    allSelectedRows.splice(i, 1);
                } 
            }
            
            //Adding all the new selected rows in allSelectedRows
            selectedRows.forEach(function(row) {
                allSelectedRows.push(row.Id);
            });
            
            //Setting new value in selection attribute
            component.set("v.selection", allSelectedRows);
            
        } else {
            component.set("v.hasPageChanged", false);
        }
        if(component.get("v.selection").length > 0){
			component.set('v.disableAddConButton', false);
		} else {
			component.set('v.disableAddConButton', true);
		}
    },

    onNext : function(component, event, helper) { 
        //get current page number
        var pageNumber = component.get("v.pageNumber");
        //Setting current page number
        component.set("v.pageNumber", pageNumber+1);
        //Setting pageChange variable to true
        component.set("v.hasPageChanged", true);        
        helper.getContacts(component, event,helper);
    },
    
    onPrev : function(component, event, helper) {        
        //get current page number
        var pageNumber = component.get("v.pageNumber");
        //Setting current page number
        component.set("v.pageNumber", pageNumber-1);
        //Setting pageChange variable to true
        component.set("v.hasPageChanged", true);        
        helper.getContacts(component, event,helper);
    },

    addSelectedContacts: function (component, event, helper) {
        helper.AddMemberContact(component, event);
    },

    addSelectedContactsBasic: function (component, event, helper) {
        var selectedRecs = component.get("v.selectedLookUpRecords");
        if(selectedRecs != null && selectedRecs.length > 0){
        	helper.AddMemberContactBasic(component, event);
        } else {
            helper.showToast({
                "title": "Error!",
                "type": "error",
                "message": "Please select atleast one contact record."
            });
        }            
    },

    handleLookupSelectionChange: function(component, event, helper) {
        var detail =  JSON.parse(JSON.stringify(event.getParams()));
        var selectedRecords = detail.selectedRecords || [];
        const flattenedObject = selectedRecords.map(r => {
            const out = { Id: r.Id };
            const f = r.fields || {};
            Object.keys(f).forEach(k => out[k] = f[k]);
            return out;
        });
        component.set("v.selectedLookUpRecords", flattenedObject);
    },

    closeAction: function (component, event, helper) {
        if(component.get("v.fromRelatedList")) {
            var recId = component.get("v.recordId");
            sforce.one.navigateToSObject(recId);
        } else {
            $A.get("e.force:closeQuickAction").fire();
        }        
    },
})