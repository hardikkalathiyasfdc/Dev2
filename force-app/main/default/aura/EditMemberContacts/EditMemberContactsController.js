({
	init: function (cmp, event, helper) {
           helper.showSpinner(cmp, event, helper);
        cmp.set('v.columns', [
            {label: 'Name', fieldName: 'linkName', type: 'url', sortable: true, 
            typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
            {label: 'Salutation', fieldName: 'Salutation', type: 'text', sortable: true, editable: true},
            {label: 'First Name', fieldName: 'FirstName', type: 'text', sortable: true, editable: true},
            {label: 'Last Name', fieldName: 'LastName', type: 'text', sortable: true, editable: true},
            {label: 'Title', fieldName: 'Title', type: 'text', sortable: true, editable: true},
            {label: 'Business Street', fieldName: 'MailingStreet', type: 'text', editable: true},
            {label: 'Business City', fieldName: 'MailingCity', type: 'text', editable: true},
            {label: 'Business State', fieldName: 'MailingState', type: 'text', editable: true},
            //commenting phone column after adding country code functionality update.
            //{label: 'Phone', fieldName: 'Phone', type: 'phone', editable: true},
            {label: 'Email', fieldName: 'Email', type: 'email', editable: true}
        ]);

        helper.getContactsToEdit(cmp, event,helper);        
    },
	
    handleSave: function (component, event, helper) {
        helper.updateContacts(component, event,helper);        
        var msg = component.get("v.validateConMsg");
        if(msg == null || msg == ''){
            var a = component.get('c.init');
            $A.enqueueAction(a);
            component.set("v.isValChanged",false);
        }        
    },
	
    handleCancel: function (component, event, helper) {
        var a = component.get('c.init');
        $A.enqueueAction(a);
        component.set("v.isValChanged",false);       
    },

    handleCellChange: function (component, event, helper) {
        var changedValues = event.getParam('draftValues');
        helper.validateContacts(component, event,helper);
        if(changedValues != null && changedValues != ''){
            component.set("v.isValChanged",true);
        }else{
            component.set("v.isValChanged",false);
        }       
    },
    
    closeAction: function (component) {
        // do nothing for now...
        if(component.get("v.fromRelatedList")){
            var recId = component.get("v.recordId");
            sforce.one.navigateToSObject(recId);
        }else{
            $A.get("e.force:closeQuickAction").fire();
        }
    },

    filter: function(component, event, helper) {       
        var selectedCons = component.get("v.selectedData");
        var data = component.get("v.data"),
            term = component.get("v.filter"),
            results = data, regex;
        try {
            regex = new RegExp(term, "i");
            // filter checks each row, constructs new array where function returns true
            results = data.filter(row=>regex.test(row.Name));
        } catch(e) {
            // invalid regex, use full list
        }
        component.set("v.selectedData",selectedCons);
        component.set("v.filteredData", results);
        if(selectedCons != null)
            component.set('v.selectedRowsCount', selectedCons.length);
        helper.hideSpinner(component);
        
        var a2 = component.get('c.setRowsSelected');
        $A.enqueueAction(a2); 
    },

    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },

   setRowsSelected: function(component, event, helper) {
        var selectedRows = component.get('v.selectedData');
        if(selectedRows != null)
            component.set('v.selectedRowsCount', selectedRows.length);
        var setRows = [];
        for (var i = 0; i < selectedRows.length; i++){
            setRows.push(selectedRows[i].Id);
        }

        component = component.find("editTable");
        component.set("v.selectedRows", setRows);
    },

   updateSelectedRecs: function (component, event) {   	
        
        var allSelectedRows = component.get('v.selectedData');        
        var selectedRows = event.getParam('selectedRows');
        var filterVal = component.get("v.filter");
        if(allSelectedRows != null && filterVal != null && filterVal != ''){        
        //Adding all the new selected rows in allSelectedRows
            selectedRows.forEach(function(row) {
                allSelectedRows.push(row);
            });
            
        } else {allSelectedRows = selectedRows;} 
            //Setting new value in selection attribute
            var uniqueObjs = {};
            //create a object with unique contacts
            allSelectedRows.forEach(function(conItem){
              uniqueObjs[conItem.Id] = conItem;
            });
            //reinitialise con array
            allSelectedRows = [];
            var keys = Object.keys(uniqueObjs);

            //fill up con again
            keys.forEach(function(key){
              allSelectedRows.push(uniqueObjs[key]);
            });
        component.set("v.selectedData", allSelectedRows); 
        if(allSelectedRows != null)   
            component.set('v.selectedRowsCount', allSelectedRows.length);
    }
})