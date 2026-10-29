({
  init: function (cmp, event, helper) {
      helper.setOrganizationTableHeaders(cmp,event);
    helper.util = new cmputil();
    helper.lookupColumns = {
      Organization_Name__c: {
        obj: "Account",
        icon: "standard:account",
        idField: "Organization_Id__c"
      },
      Assistant_Name__c: {
        obj: "Contact",
        icon: "standard:contact",
        idField: "Assistant__c"
      },
      Significant_Other__c: {
        obj: "Contact",
        icon: "standard:contact",
        idField: "Significant_Other_Link__c"
      }
    };
    helper.stickyColumns = {
      Organization_Name__c: false,
      First_Name__c: false,
      Last_Name__c: false
    };
    helper.phoneColumns = {
      AdditionalPhone__c: "AdditionalPhoneCountryCode__c",
      HomePhone__c: "HomePhoneCountryCode__c",
      Office__c: "Office_Phone_Country_Code__c",
      Cell__c: "Mobile_Phone_Country_Code__c"
    };
    helper.batchSize = 50;
    helper.setData(cmp);
  },
    handleSignificantCreate: function (cmp, event, helper) {
        let data = cmp.get("v.previewData");
         let selected = cmp.get("v.selectedContact");
            let row =selected.row;
            let col =selected.col;
          let cell = data[row].cells[col];
        let conRec = event.getParams('data');
          helper.updateLookups(
            cmp,
            selected.row,
            selected.col,
             conRec.Id,
            conRec.FirstName+ ' '+conRec.LastName
          );
        //  cmp.set("v.selectedContact", null);
          cmp.set("v.isSignificantOther", false);
          cmp.set("v.isLoading", false);

    },
  handleCellChange: function (cmp, event, helper) {
    let params = event.getParams();
    if (!params) {
      return;
    }
    let tableId = params.tableId;
    if (tableId != "previewTable") {
      return;
    }
    if (params.type == "action") {
      helper.showCreate(cmp, params.row, params.cell);
    } else {
      helper.saveCell(cmp, params.row, params.cell);
    }
  },
  closeDupeModal: function (cmp) {
    cmp.set("v.showDupe", false);
  },
  closeCreateOrg: function (cmp) {
    cmp.set("v.showOrgCreate", false);
  },
  closeCreateContact: function (cmp) {
    cmp.set("v.showContactCreate", false);
      cmp.set("v.isSignificantOther", false);
  },
  handleOrgCreate: function (cmp, event, helper) {
    let selected = cmp.get("v.selectedOrg");
    let orgName = selected.Name;
    cmp.set("v.isLoading", true);
    helper.util
      .controllerPromise(cmp, "createOrg", { orgName: orgName,dataLoaderId:cmp.get("v.dataLoaderId")  })
      .then(
        $A.getCallback(function (org) {
          let data = cmp.get("v.previewData");
          let cell = data[selected.row].cells[selected.col];
          cell.id = org.Id;
          cell.value = org.Name;
          helper.updateLookups(
            cmp,
            selected.row,
            selected.col,
            cell.id,
            cell.value
          );
          cmp.set("v.selectedOrg", null);
          cmp.set("v.data", data);
          cmp.set("v.isLoading", false);
          cmp.set("v.showDupe", false);
          cmp.set("v.showOrgCreate", false);
          cmp.set("v.showContactCreate", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        cmp.set("v.showDupe", false);
        cmp.set("v.showOrgCreate", false);
        cmp.set("v.showContactCreate", false);
        console.log(errMsg);
        helper.util.showToastError(errMsg);
      });
  },
  handleContactCreate: function (cmp, event, helper) {
    let selected = cmp.get("v.selectedContact");
    let firstName = selected.FirstName;
    let lastName = selected.LastName;
    let email = selected.Email;
      let title = selected.Title;
    cmp.set("v.isLoading", true);
    helper.util
    .controllerPromise(cmp, "createContact", {
        title:title,
        firstName: firstName,
        lastName: lastName,
        myEmail: email,
        assistantPhone:selected.Assistant_Business_Phone,
        assistantPhoneCode:selected.Assistant_Business_Phone_Code
    })
      .then(
        $A.getCallback(function (resp) {
          let data = cmp.get("v.previewData");
            let row =selected.row;
            let col =selected.col;
          let cell = data[row].cells[col];
          cell.id = data[row].id;
          cell.value = selected.FirstName + " " + selected.LastName;
          cell.class = "";
          cell.requiredError = "";
            cell.hasMultiple = false;

            let myTable = cmp.find("myTable");
            data[row].cells[col + 1].value = selected.Title;
            data[row].cells[col + 2].value =selected.Email ;
            data[row].cells[col + 3].value = selected.Assistant_Business_Phone_Code;
            data[row].cells[col + 4].value =selected.Assistant_Business_Phone ;


            
            myTable.updateUICell(selected.row, selected.col, cell);
			myTable.updateUICell(row, col+1, data[row].cells[col + 1]);
            myTable.updateUICell(row, col+2, data[row].cells[col + 2]);
            myTable.updateUICell(row, col+3, data[row].cells[col + 3]);
            myTable.updateUICell(row, col+4, data[row].cells[col + 4]);

            data[selected.row].cells[selected.col] =cell;
               let dataloadRecord ={};
            dataloadRecord.Assistant__c =resp.Id;

            dataloadRecord.Id =cell.id;
            dataloadRecord[ data[row].cells[col + 1].api]= data[row].cells[col + 1].value;
            dataloadRecord[ data[row].cells[col + 2].api]= data[row].cells[col + 2].value;
            dataloadRecord[ data[row].cells[col + 3].api]= data[row].cells[col + 3].value;
            dataloadRecord[ data[row].cells[col + 4].api]= data[row].cells[col + 4].value;
            helper.util.controllerPromise(cmp, "updateDataRecord", { dataRecord: dataloadRecord })
            .then(
                $A.getCallback(function (data) {}));
            
            helper.updateLookups(
            cmp,
            selected.row,
            selected.col,
            resp.Id,
            cell.value
          );
          cmp.set("v.selectedContact", null);
          cmp.set("v.data", data);
          cmp.set("v.isLoading", false);
          cmp.set("v.showDupe", false);
          cmp.set("v.showOrgCreate", false);
          cmp.set("v.showContactCreate", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        cmp.set("v.showDupe", false);
        cmp.set("v.showOrgCreate", false);
        cmp.set("v.showContactCreate", false);
        console.log(errMsg);
        helper.util.showToastError(errMsg);
      });
  },
    
          handleUseExisting: function (cmp, event, helper) {
              let dupe=  cmp.get("v.selectedDup");
              if (!dupe) {
                  return;
              }
               let data = cmp.get("v.previewData");
              let cell = data[dupe.row].cells[dupe.col];
              cell.id = dupe.id;
              cell.value = dupe.name;
              cell.isRequired=false;
              //let myTable = cmp.find("myTable");
              //myTable.updateUICell(dupe.row, dupe.col, cell);
              helper.updateLookups(cmp, dupe.row, dupe.col, dupe.id, dupe.name);
          },
  handleDupeAction: function (cmp, event, helper) {
    var selectedRows = event.getParam('selectedRows');
    if (!selectedRows.length>0) {
      return;
    }
   
    let dupeList = cmp.get("v.dupeList");
     let dupe = selectedRows.length>0 ?selectedRows[0] :'';
      cmp.set("v.selectedDup", dupe);
      
   
  },
  handleDupeCreate: function (cmp, event, helper) {
    cmp.set("v.showDupe", false);
       let data = cmp.get("v.previewData");
    let selectedType = cmp.get('v.selectedType');
      let selected = cmp.get("v.selectedContact");
    if (selectedType == 'org') {
      cmp.set("v.showOrgCreate", true);

    }
      else  if(selectedType=="signOther")
      {
           cmp.set("v.showOrgCreate", false);
          cmp.set("v.showOrgCreate", false);
          cmp.set("v.isSignificantOther", true);
          
      }else {
      cmp.set("v.showOrgCreate", false);
      cmp.set("v.showContactCreate", true);
    }
  }
});