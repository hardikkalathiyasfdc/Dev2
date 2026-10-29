({
    init: function (cmp, event, helper) {
        helper.util = new cmputil();
        helper.lockedColumns = {
            Organization_Name__c: true,
            Assistant_Name__c: true,
            First_Name__c: true,
            Last_Name__c: true
        };
        helper.requiredColumns = {
            First_Name__c: "First_Name__c",
            Last_Name__c: "Last_Name__c",
            Converted_Full_Name__c: "Converted_Full_Name__c",

        };

        helper.defaultColumns = {
            First_Name__c: "FirstName",
            Last_Name__c: "LastName",
            Middle_Name__c: "MiddleName",
            Title__c: "Title",
            Organization_Name__c: "AccountId",
            Business_Email__c: "Email",
            Personal_Email__c: "Alternate_Email__c",
            Additional_Email__c: "Business_Email_2__c",
        };
        helper.editColumns = {
            First_Name__c: true,
            Last_Name__c: true,
            Middle_Name__c: true,
            Title__c: true,
            Preferred_First_Name__c: true,
            Business_Email__c: true,
            Suffix__c: true,
            Personal_Email__c: true,
            Additional_Email__c: true,
        };

        helper.columnMap = {
            Contact_Alert_Reason__c: "Contact_Alert_Reason__c",
            FirstName: "FirstName",
            LastName: "LastName",
            First_Name__c: "FirstName",
            Last_Name__c: "LastName",
            Organization_Name__c: "AccountId",
            Title__c: "Title",
            Salutation__c: "Salutation",
            Middle_Name__c: "MiddleName",
            Suffix__c: "Suffix",
            Preferred_First_Name__c: "Preferred_First_Name__c",
            Business_Email__c: "Email",
            Personal_Email__c: "Alternate_Email__c",
            Additional_Email__c: "Business_Email_2__c",
            Personal_Email_2__c: "Personal_Email_2__c",
            HomePhoneCountryCode__c: "HomePhoneCountryCode__c",
            HomePhone__c: "HomePhone",
            Mobile_Phone_Country_Code__c: "Mobile_Phone_Country_Code__c",
            Cell__c: "MobilePhone",
            AdditionalPhoneCountryCode__c: "AdditionalPhoneCountryCode__c",
            AdditionalPhone__c: "AdditionalPhone__c",
            Business_Phone__c: "Phone",
            Business_Phone_Country_Code__c: "Office_Phone_Country_Code__c",
            Business_Street_1__c: "MailingStreet",
            Business_City__c: "MailingCity",
            Business_State__c: "MailingState",
            Business_Postal_Code__c: "MailingPostalCode",
            Business_Country__c: "MailingCountry",
            Home_Street_1__c: "OtherStreet",
            Home_City__c: "OtherCity",
            Home_State__c: "OtherState",
            Home_Postal_Code__c: "OtherPostalCode",
            Home_Country__c: "OtherCountry",
            UUID__c:"UUID__c",
            Preferred_Last_Name__c:"Preferred_Last_Name__c",
            Converted_FirstName__c: "Converted_FirstName__c",
            Converted_LastName__c:"Converted_LastName__c"

        };

        cmp.set('v.columns', [
            {label: 'Contact Alert Reason', api: 'Contact_Alert_Reason__c', type: 'STRING'},
            {label: 'First Name', api: 'FirstName', type: 'HYPERLINK'},
            {label: 'Middle Name', api: 'MiddleName', type: 'STRING'},
            {label: 'Last Name', api: 'LastName', type: 'HYPERLINK'},
            {label: 'Preferred First Name', api: 'Preferred_First_Name__c', type: 'STRING'},
            {label: 'Title', api: 'Title', type: 'STRING'},
            {label: 'Organization Name', api: 'Account.Name', type: 'STRING'},
            {label: 'Business Email', api: 'Email', type: 'STRING'},
            {label: 'Personal Email', api: 'Alternate_Email__c', type: 'STRING'},
            {label: 'Additional Email', api: 'Business_Email_2__c', type: 'STRING'},
            {label: 'Confidential Email', api: 'Personal_Email_2__c', type: 'STRING'},
            {label: 'Business Phone', api: 'Phone', type: 'STRING'},
            {label: 'Mobile Phone', api: 'MobilePhone', type: 'STRING'},
            {label: 'Additional Phone', api: 'AdditionalPhone__c', type: 'STRING'},
            {label: 'Significant Other', api: 'Significant_Name__c', type: 'STRING'},
            {label: 'UUID', api: 'UUID__c', type: 'STRING'}
        ]);

        helper.loadData(cmp);
    },
     navigateToRecord : function(component, event, helper) {
        // Retrieve the record ID from the data attribute of the anchor tag
        var recordId = event.target.name;
           window.open('/' + recordId, '_blank');
    },
    handleUndo: function(cmp, event, helper){
        cmp.set("v.disabledConfirm", false);
        cmp.set("v.disabledCreateAsNew", true);
        let con = cmp.get("v.selectedContact");
        con.isConfirmed =false;
        if(con.hasDuplicates && !con.isConfirmed ) {
            let recordsToDisplay = [];
            recordsToDisplay = helper.formatDataToDisplayInTable(recordsToDisplay, cmp.get('v.columns'), con.sfContacts);
            cmp.set("v.dupesData", recordsToDisplay);
            cmp.set('v.showDuplicatesModal', true);
            let myTable = cmp.find("myTable");
            if (myTable) {
                myTable.setWidth();
            }
        }
          let selected = cmp.get('v.selectedContact');
        for(let i = 0; i < selected.fields.length; i++){
            selected.fields[i].excel.isSelected = false;
            selected.fields[i].sf.isSelected = true;
        }
        helper.updateSelected(cmp, selected);
        helper.setButtonVisibility(cmp);
    },
    selectContact: function (cmp, event, helper) {
          cmp.set("v.disabledCreateAsNew", true);
        let name = event.getSource().get("v.name");
        if (isNaN(name)) {
            return;
        }
        let idx = Number(name);
        let data = cmp.get("v.contactList");
        for (let i = 0; i < data.length; i++) {
            let c = data[i];
            if (i != idx) {
                c.isSelected = false;
            } else {
                c.isSelected = true;
            }
        }
        let con = data[idx];
        con.idx = idx;
        cmp.set("v.selectedContact", con);
        cmp.set("v.contactList", data);
        let filterRecords = helper.filterDup(cmp);

        if(con.hasDuplicates && !con.isConfirmed && filterRecords.length>1) {
            let recordsToDisplay = [];
            recordsToDisplay = helper.formatDataToDisplayInTable(recordsToDisplay, cmp.get('v.columns'), con.sfContacts);
            cmp.set("v.dupesData", recordsToDisplay);
            cmp.set('v.showDuplicatesModal', true);
            let myTable = cmp.find("myTable");
            if (myTable) {
                myTable.setWidth();
            }
        } else {
            helper.processSelectContact(cmp, event, helper);
            if(filterRecords.length==1){
                helper.updateSFValues(cmp,cmp.get("v.selectedContact"),filterRecords[0]);
            }
            cmp.set("v.showDuplicatesModal", false);
        }
        helper.setButtonVisibility(cmp);
    },
    handleTableChange: function (cmp, event, helper) {
        let params = event.getParams();
        if (!params) {
            return;
        }
        let tableId = params.tableId;
        if (tableId != "multipleDupes") {
            return;
        }
        if (params.type == "action") {
            //  helper.showCreate(cmp, params.row, params.cell);
        } else {
            helper.updateTable(cmp, params);
        }
    },
    hideDuplicatesList: function (cmp, event, helper) {

        cmp.set('v.showDuplicatesModal', false);
    },
    confirmContact: function (cmp, event, helper) {
         cmp.set("v.disabledCreateAsNew", true);
        let selectedContact = cmp.get("v.selectedContact");
        if(selectedContact.errorMsg)
        {
            helper.util.showToastError(selectedContact.errorMsg);
            return;
        }
          selectedContact.isConfirmed = true;
        cmp.set("v.selectedContact", selectedContact);
        helper.confirmContact(cmp);
    },
    createContact: function (cmp, event, helper) {
        let selected = cmp.get('v.selectedContact');
        let excelUUID ;
        for(let i = 0; i < selected.fields.length; i++){
            if(selected.fields[i].api == "UUID__c" && selected.fields[i].excel.value)
            {
               excelUUID = selected.fields[i].excel.value;
        }
            if(selected.fields[i].api == "UUID__c" && selected.fields[i].sf.value && selected.fields[i].excel.value && selected.fields[i].excel.value ==  selected.fields[i].sf.value){
                helper.util.showToastError('Unable to create as a new contact, this UUID is already on an existing contact');
                return;
            }
        }
        if(excelUUID)
            helper.checkIfContactExistInBRM(cmp,selected,excelUUID);
        else
        {
            cmp.set("v.disabledConfirm", false);
            selected.isCreate = true;
            cmp.set("v.selectedContact", selected);
            helper.confirmContact(cmp);
          	cmp.set("v.disabledCreateAsNew", true);
        }

    },
    unconfirmContact: function (cmp, event, helper) {
         cmp.set("v.disabledConfirm", false);
        let sel = cmp.get("v.selectedContact");
        sel.isConfirmed = false;
        let idx = sel.idx;
        let data = cmp.get("v.contactList");
        data[idx].isConfirmed = false;
        data[idx].isCreate = false;
        cmp.set("v.selectedContact", sel);
        cmp.set("v.contactList", data);
        helper.showDupTable(cmp,idx);
        helper.updateSelected(cmp, sel);
    },
    deleteContact: function (cmp, event, helper) {
        cmp.set('v.showDuplicatesModal', false);
        let sel = cmp.get("v.selectedContact");
        let idx = sel.idx;
        let data = cmp.get("v.contactList");
        data[idx].isDeleted = true;
        data[idx].isSelected = false;
        let hasValues = false;
        for (let i = 0; i < data.length; i++) {
            if (!data[i].isDeleted) {
                hasValues = true;
                break;
            }
        }

        cmp.set("v.showDeleteConfirm", false);
        if (!hasValues) {
            cmp.set("v.selectedContact", null);
            cmp.set("v.isMergeReady", true);
            cmp.set("v.contactList", data);
            helper.updateSelected(cmp, sel);
            return;
        }
        let selected = idx;
        while (selected >= 0 && data[selected].isDeleted) {
            selected--;
        }
        if (selected < 0) {
            selected = 0;
            while (selected < data.length && data[selected].isDeleted) selected++;
        }

        cmp.set("v.selectedContact", data[selected]);
        data[selected].isSelected = true;
        cmp.set("v.contactList", data);
        helper.updateSelected(cmp, sel);
    },
    deleteConfirm: function (cmp, event, helper) {
        console.log ('delete 1 :::::::: ');
        cmp.set('v.showDuplicatesModal', false);
        cmp.set("v.showDeleteConfirm", true);
    },
    closeDelete: function (cmp) {
        cmp.set("v.showDeleteConfirm", false);
    },
    showAllFields: function (cmp, event, helper) {
        let selected = cmp.get("v.selectedContact");
        selected.showAllFields = true;
        for (let i = 0; i < selected.fields.length; i++) {
            let field = selected.fields[i];
            if (field.api === "Contact_Alert_Reason__c" && !field.sf.value) {
                field.isShow = false;
            } else {
                field.isShow = true;
            }
        }
        cmp.set("v.selectedContact", selected);
        setTimeout(function(){helper.updateRadio(cmp);}, 1000);
    },
    hideAllFields: function (cmp, event, helper) {
        let selected = cmp.get("v.selectedContact");
        selected.showAllFields = false;
        for (let i = 0; i < selected.fields.length; i++) {
            let field = selected.fields[i];
            if (field.api === "Contact_Alert_Reason__c") {
                field.isShow = !field.sf.value ? false : true;
            } else {
                field.isShow = (field.excel.value && field.excel.value.length) ? true : false;
            }
        }
        cmp.set("v.selectedContact", selected);
        helper.updateSelected(cmp);
    },
    selectAllExcel: function (cmp, event, helper) {
            cmp.set("v.disabledCreateAsNew", false);
         cmp.set("v.disabledConfirm", true);

        let matches = document.querySelectorAll(".excelRadio");
        for (let i = 0; i < matches.length; i++) {
            matches[i].click();
        }
        let selected = cmp.get('v.selectedContact');
        for(let i = 0; i < selected.fields.length; i++){
            selected.fields[i].excel.isSelected = true;
            selected.fields[i].sf.isSelected = false;
        }
       cmp.set("v.selectedContact", selected);
        helper.setButtonVisibility(cmp);
        helper.updateSelected(cmp, selected);
    },
    selectAllSf: function (cmp, event, helper) {
      cmp.set("v.disabledConfirm", false);
        let matches = document.querySelectorAll(".sfRadio");
        for (let i = 0; i < matches.length; i++) {
            matches[i].click();
        }
        let selected = cmp.get('v.selectedContact');
        for(let i = 0; i < selected.fields.length; i++){
            selected.fields[i].sf.isSelected = true;
            selected.fields[i].excel.isSelected = false;
        }
        selected.isCreate = false;
        cmp.set("v.selectedContact", selected);
        helper.setButtonVisibility(cmp);
        helper.updateSelected(cmp, selected);
          cmp.set("v.disbaledCreateAsNew", true);
    },
    handleExcelSelect: function (cmp, event, helper) {

        let selIdx = event.currentTarget.name;
        if (selIdx == null) {
            return;
        }
        let selected = cmp.get('v.selectedContact');
        selected.selIdx =selIdx;

        if( selected.fields[Number(selIdx)].sf.api === "Significant_Other__c"){
             var matches = document.querySelectorAll(".sfRadio");
                  cmp.set("v.isLoading", true);
            helper.util
            .controllerPromise(cmp, "checkIfAlredaySignOther", {
                contactName: selected.fields[Number(selIdx)].excel.value
            })
            .then(
                $A.getCallback(function(data) {
                    cmp.set("v.isLoading", false);
                    if(data){

                        matches[selIdx].setAttribute('checked',true);
                        selected.fields[Number(selIdx)].excel.isSelected = false;
                        selected.fields[Number(selIdx)].sf.isSelected = true;
                        cmp.set('v.selectedContact',selected);
                        helper.setButtonVisibility(cmp);
                        helper.util.showToastError('Selected Contact already exists as a Significant Other to a Contact');
                        return;
                    }
                    else{
                        cmp.set("v.disabledCreateAsNew", false);
                        selected.fields[Number(selIdx)].excel.isSelected = true;
                        selected.fields[Number(selIdx)].sf.isSelected = false;
                        cmp.set('v.selectedContact',selected);
                        helper.setButtonVisibility(cmp);
                        helper.updateSelected(cmp, selected);
                    }
                })
            )
            .catch((errMsg) => {
                cmp.set("v.isLoading", false);
                console.log(errMsg);
                self.util.showToastError(errMsg);
            });

            }
                else{
                cmp.set("v.disabledCreateAsNew", false);
                selected.fields[Number(selIdx)].excel.isSelected = true;
                selected.fields[Number(selIdx)].sf.isSelected = false;
                cmp.set('v.selectedContact',selected);
				helper.setButtonVisibility(cmp);
                helper.updateSelected(cmp, selected);
            }
    },
    handleSFSelect: function (cmp, event, helper) {
        cmp.set("v.disabledConfirm", false);
        let selIdx = event.currentTarget.name;
        if (selIdx == null) {
            return;
        }
        let selected = cmp.get('v.selectedContact');
        selected.fields[Number(selIdx)].sf.isSelected = true;
        selected.fields[Number(selIdx)].excel.isSelected = false;
        cmp.set('v.selectedContact',selected);
		helper.setButtonVisibility(cmp);
        let disabledCreateAsNew = true;
        for(let i = 0; i < selected.fields.length; i++){

            if(selected.fields[i].excel.isSelected){
                disabledCreateAsNew =false;
                break;
            }
        }
        cmp.set("v.disabledCreateAsNew", disabledCreateAsNew);
        helper.updateSelected(cmp, selected);
    },
    handleInputChange: function (cmp, event, helper) {
        let field = event.getSource().get("v.name");
        if(!field || !field.length){
            return;
        }
        helper.saveRecord(cmp, null, field);
    }
});