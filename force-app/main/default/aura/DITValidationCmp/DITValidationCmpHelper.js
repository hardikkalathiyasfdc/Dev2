({
  setOrganizationTableHeaders: function (component, event) {
    let organizationColumnsList =[];
    organizationColumnsList.push({
      label:"Name",
      fieldName: "name",
      type: "text",
      initialWidth: 200,
    });
    organizationColumnsList.push({
      label: "AKA",
      fieldName: "description",
      type: "text",
      initialWidth: 200,
    });
        organizationColumnsList.push({
      label:"Billiing Street",
      fieldName: "street",
      type: "text",
   initialWidth: 300,
    });
    organizationColumnsList.push({
      label: "Billiing City",
      fieldName: "city",
      type: "text",
     initialWidth: 200,
    });
        organizationColumnsList.push({
      label:"Billing State",
      fieldName: "state",
      type: "text",
     initialWidth: 200,
    });
    organizationColumnsList.push({
      label: "Billing PostalCode",
      fieldName: "postalcode",
      type: "text",
      initialWidth: 200,
    });
     organizationColumnsList.push({
      label:"Billing Country",
      fieldName: "country",
      type: "text",
     initialWidth: 200,
    });
      
	component.set("v.duplicateAccountsColumns", organizationColumnsList);
  },
    setData: function (cmp) {
    let self = this;
    cmp.set("v.isLoading", true);
    this.util
      .controllerPromise(cmp, "getColumns")
      .then(
        $A.getCallback(function (columns) {
          return self.loadDataPromise(cmp, columns);
        })
      )
      .then(
        $A.getCallback(function (data) {
          let params = { type: "validate", data: data };
          return self.util.runWorker("$Resource.DITWorker", params);
        })
      )
      .then(
        $A.getCallback(function (results) {
          self.showTable(cmp, results);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        console.log(errMsg);
        self.util.showToastError(errMsg);
      });
  },
  showTable: function (cmp, results) {
    if (results.error) {
      throw Exception(results.error);
    }
    // BRME-4862: server (loadPreviewErrorData) already returns error rows only.
    cmp.set("v.oldPreviewData", results.data);
    let rowCount = results.data ? results.data.length : 0;
    cmp.set("v.errorRowCount", rowCount);
    // BRME-4862: no errors -> skip Preview entirely and advance to Review Errors.
    if (!rowCount) {
      cmp.set("v.isLoading", false);
      let skipEvent = cmp.getEvent("skipPreview");
      skipEvent.fire();
      return;
    }
    cmp.set("v.previewData", results.data);
    cmp.set("v.isLoading", false);
  },
  loadDataPromise: function (cmp, columns) {
    let self = this;
    let params = { dataLoadId: cmp.get("v.dataLoaderId") };
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        self.util
          .controllerPromise(cmp, "loadPreviewErrorData", params)
          .then(
            $A.getCallback(function (result) {
              let previewData = [];
              self.previewColumns = self.getPreviewColumns(
                result.colMap,
                columns
              );
              if (result.records && result.records.length) {
                self.setCreatedRow(previewData, result);
              }
              cmp.set("v.previewColumns", self.previewColumns);
              resolve(previewData);
            })
          )
          .catch((errMsg) => {
            reject(self.util.getErrMsg(errMsg));
          });
      })
    );
  },
  setCreatedRow: function (previewData, result) {
    let rows = [];
    for (let i = 0; i < result.records.length; i++) {
      let record = result.records[i];
      let row = {};
      row.id = record.Id;
      row.cells = [];
      for (let j = 0; j < this.previewColumns.length; j++) {
        let cell = this.getCell(this.previewColumns[j], record, result);
        row.cells.push(cell);
      }
      rows.push(row);
    }
      
    for (let i = 0; i < rows.length; i++) {
      previewData.push(rows[i]);
    }
  },
  showCreate: function (cmp, row, col) {
    let previewData = cmp.get("v.previewData");
    let cell = previewData[row].cells[col];
         
     
    if (cell.value && cell.value.length ) {
      this.showDupe(cmp, row, col, cell);
        cmp.set("v.selectedContact", selected); 
      return;
    }
    let selected = this.getSelected(cmp,cell, row, col);
     
    if (cell.obj == "Account") {
      cmp.set("v.selectedType", "org");
      cmp.set("v.selectedOrg", selected);
      cmp.set("v.showOrgCreate", true);
    } else  if(cell.api=="Significant_Other__c")
      {
          cmp.set("v.selectedType", "signOther");
          cmp.set("v.selectedContact", selected);
          cmp.set("v.isSignificantOther", true);
          
      }else {
      cmp.set("v.selectedType", "contact");
      cmp.set("v.selectedContact", selected);
      cmp.set("v.showContactCreate", true);
    }
      
  },
  showDupe: function (cmp, row, col, data) {
    let self = this;
    let previewData = cmp.get("v.previewData");
    cmp.set("v.isLoading", true);
    let params = {
      dupeName: data.value,
      row: row,
      col: col,
      objName: data.obj
    };
    this.util
      .controllerPromise(cmp, "getValidateDupes", params)
      .then(
        $A.getCallback(function (result) {
          cmp.set("v.dupeList", result);
          let cell = previewData[row].cells[col];
          let selected = self.getSelected(cmp,cell, row, col);
            if(cell.api=="Significant_Other__c")
            {
                cmp.set("v.selectedType", "signOther");
                
                cmp.set("v.selectedContact", selected);
            }
            else if (cell.obj == "Account") {
                cmp.set("v.selectedType", "org");
                cmp.set("v.selectedOrg", selected);
            } else {
                cmp.set("v.selectedType", "contact");
                cmp.set("v.selectedContact", selected);
            }
          if (result.length) {
            cmp.set("v.showDupe", true);
          } else if (cell.obj == "Account") {
            cmp.set("v.showOrgCreate", true);
          } 
              else  if(cell.api=="Significant_Other__c")
              {
                  cmp.set("v.isSignificantOther", true);    
              }else {
                  cmp.set("v.showContactCreate", true);
              }
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.util.showToastError(errMsg);
      });
  },
  updateLookups: function (cmp, row, col, id, name) {
    let data = cmp.get("v.previewData");
    let dataRow = data[row];
    let cell = data[row].cells[col];
    let lookup = this.lookupColumns[cell.api];
    if (!lookup) {
      return;
    }
    // BRME-4862: capture the edited cell's prior value before overwrite; the display row
    // index no longer aligns with the full oldPreviewData set once Preview is filtered.
    let priorValue = cell.value;
    let updateRecords = [];
    let update = {};
    update.Id = dataRow.id;
      update[lookup.idField] = (id)?id:'';
    update[cell.api] = (name)?name:'';
    update.IsConfirmed__c= false;
      if(update.Id)
    updateRecords.push(update);
   cell.id = id;
    cell.value = name;
      if(id){
    cell.requiredError = "";
          cell.class = "";}
     let myTable = cmp.find("myTable");
    myTable.updateUICell(row, col, cell);
    if(!cell.hasMultiple || cell.requiredError && cell.requiredError.length>2) 
   for (let i = 0; i < data.length; i++) {
       if(row==i)
           continue;
      let myRow = data[i];
      for (let j = 0; j < myRow.cells.length; j++) {
        let myCell = myRow.cells[j];
        if (
          myCell.api == cell.api &&
          myCell.value== priorValue 
            && myCell.requiredError &&  myCell.requiredError.length>2
         // && (!myCell.id || !myCell.id.length)
        ) {
          let newRec = {};
          newRec.Id = myRow.id;
          newRec[lookup.idField] = id;
          newRec[cell.api] = name;
            if(newRec.Id)
          updateRecords.push(newRec);
          myCell.value = name;
          myCell.id = id;
          myCell.requiredError = "";
          myCell.class = "";
             data[i].cells[j]=myCell;
          myTable.updateUICell(i, j, myCell);
        }
      }
   }
      cmp.set("v.previewData", data);
      let self = this;
      self.row=row;
      self.col =col;
      cmp.set("v.isLoading2", true);
      this.util
      .controllerPromise(cmp, "updateDataRecords", {
          dataRecords: updateRecords,isSignficantOther:cell.api=="Significant_Other__c"?true:false
      })
      .then(
          $A.getCallback(function (result) {
               cmp.set("v.isLoading2", false);
              let cell = data[row].cells[col]; 
             /* if(cell.api=="Significant_Other__c"){
                  if(result && result.length>0){
                      cell.hasMultiple= true;
                      cell.isSignificantOther=true;
                      cell.class ='red'; 
                      cell.requiredError = cell.value+" already exists as a Significant Other on another contact.";
                      
                      
                  }
                  else if(cell.requiredError && cell.requiredError.includes("is already exists as a Significant Other on another contact.")){
                      cell.hasMultiple= false;
                      cell.isSignificantOther=false;
                      cell.class =''; 
                      cell.requiredError = "";
                  }
                  
                  let myTable = cmp.find("myTable");
                  myTable.updateUICell(row, col, cell);
                  data[row].cells[col] =cell;
                  cmp.set("v.previewData", data);
              }*/
               cmp.set("v.isLoading2", false);
              cmp.set("v.isLoading", false);
              cmp.set("v.showDupe", false);
              cmp.set("v.showOrgCreate", false);
              cmp.set("v.showContactCreate", false);
          })
      )
      .catch((errMsg) => {
           cmp.set("v.isLoading2", false);
        cmp.set("v.isLoading", false);
        cmp.set("v.showDupe", false);
        cmp.set("v.showOrgCreate", false);
        cmp.set("v.showContactCreate", false);
        console.log(errMsg);
        self.util.showToastError(errMsg);
      });
  },
             
  getSelected: function (cmp,cell, rowNum, colNum) {
      let previewData = cmp.get("v.previewData");
    let selected = {};
    selected.Name = cell.value;
    selected.label = selected.Name;
    selected.row = rowNum;
    selected.col = colNum;
    if (cell.obj == "Contact") {
      selected.Email = "";
      selected.FirstName = "";
      selected.LastName = "";
        selected.Title ="Staff"
        for(let cell of previewData[rowNum].cells){
            if(cell.api=="Assistant_Title__c")
                selected.Title =cell.value ?cell.value:'Staff';
             else if(cell.api=="Assistant_Email__c")
                  selected.Email =cell.value;
            else if(cell.api=="Assistant_Business_Phone__c")
                selected.Assistant_Business_Phone = cell.value;
                else if(cell.api=="Assistant_Business_Phone_Country_Code__c"){
                    selected.options =cell.options;
                    selected.Assistant_Business_Phone_Code = cell.value;                    
                }
        }
       
      if (selected.Name && selected.Name.length) {
        selected.Name = selected.Name.trim();
        let names = selected.Name.split(" ");
         
        if (names.length == 1) {
          selected.LastName = names[0];
        } else if (names.length>1) {
          for(let i=0;i<names.length-1;i++){
             selected.FirstName += names[i]+' ';
          }
          selected.LastName = names[names.length - 1];
        }
          
          
      }
    }
    return selected;
  },
           getCellValue: function(row,fieldName){
              for (let j = 0; j < row.cells.length; j++) {
                  let cell = row.cells[j];
                  if(cell.api==fieldName)
                      return cell.value;
              }
              return '';
          },  
  saveCell: function (cmp, row, col) {
    let previewData = cmp.get("v.previewData");
         var rowData = previewData[row]
          let cell = previewData[row].cells[col];
    let record = {};
    record.Id = previewData[row].id;
    record[cell.api] =(cell.value)?cell.value:""; 
      record.IsConfirmed__c= false;
      if(cell.api =='Organization_Name__c'){
          record.Organization__c    = null;
          record.Organization_Id__c    = null;
          
      }
      else if(cell.api =='Significant_Other__c'){
          record.Significant_Other__c = null;
          record.Significant_Other_Link__c =null;
          
      }
          else if(cell.api =="Assistant_Name__c"){
              record.Assistant_Name__c = null;
              record.Assistant__c = null ;  
          }
  if(cell.value){
            cell.isRequired=false;
            cell.requiredError ='';
        }
    let self = this;
    cmp.set("v.isLoading", true);
    this.util
      .controllerPromise(cmp, "updateDataRecord", { dataRecord: record })
      .then(
        $A.getCallback(function (data) {
          self.updatedRecord = data;
          if (cell.type == "STRING" || cell.type == "EMAIL") {
            return cell;
          }
          let params = { type: "validate cell", cell: cell };
          return self.util.runWorker("$Resource.DITWorker", params);
        })
      )
      .then(
        $A.getCallback(function (myCell) {
          if (myCell && myCell.requiredError && myCell.requiredError.length) {
            self.setErrors(cmp, previewData, myCell, row, col);
          }
            previewData[row].cells[col] = myCell;
          
            cmp.set("v.previewData", previewData);
            
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.setErrors(
          cmp,
          previewData,
          cell,
          row,
          col,
          self.util.getErrMsg(errMsg)
        );
        console.log(errMsg);
        self.util.showToastError(errMsg);
      });
  },
  getCountryCell: function (cell, row) {
    if (!this.phoneCountryMap[cell.api]) {
      return null;
    }
    let colCountryIdx = this.phoneCountryMap[cell.api].colCountryIdx;
    let countryCell = row[colCountryIdx];
    if (!countryCell || !countryCell.options) {
      return null;
    }
    return countryCell;
  },
  updateCountryCode: function (cell, row) {
    let countryCell = this.getCountryCell(cell, row);
    if (!countryCell || !countryCell.options || !countryCell.options.length) {
      return;
    }
    let maxLen = 0;
    let countryMap = {};
    for (let i = 0; i < countryCell.options.length; i++) {
      let opt = countryCell.options[i];
      let countryCode = this.getCountryCode(opt.value);
      if (countryCode != null && !countryMap[countryCode]) {
        maxLen = Math.max(countryCode.length, maxLen);
        countryMap[countryCode] = i;
      }
    }
    let i = maxLen;
    let countryIdx = -1;
    let phoneNumber = this.getNumbers(cell.value);
    while (i >= 0) {
      let check = phoneNumber.substring(0, i);
      if (check == "1") {
        countryIdx = 0;
        break;
      }
      if (countryMap[check] != null) {
        countryIdx = countryMap[check];
        break;
      }
      i--;
    }

    countryCell.value =
      countryIdx >= 0 ? countryCell.options[countryIdx].value : "";
  },
  getNumbers: function (val) {
    if (!val || !val.length) {
      return "";
    }
    let nums = "";
    for (let i = 0; i < val.length; i++) {
      let c = val[i];
      if (c >= "0" && c <= "9") {
        nums += c;
      }
    }
    return nums;
  },
  getCountryCode: function (optVal) {
    if (!optVal || !optVal.length) {
      return null;
    }
    let countryCode = "";
    let isStart = false;
    for (let i = 0; i < optVal.length; i++) {
      let c = optVal[i];
      if (c == "+") {
        isStart = true;
      } else if (isStart && c >= "0" && c <= "9") {
        countryCode += c;
      } else if (isStart) {
        break;
      }
    }
    return !isNaN(countryCode) ? countryCode : null;
  },
  setErrors: function (cmp, previewData, cell, row, col, msg) {
    msg = !msg ? cell.requiredError : msg;
    previewData[row].cells[col] = cell;
    cmp.set("v.previewData", previewData);
  },
  getCell: function (previewCol, record, result) {
    let cell = JSON.parse(JSON.stringify(previewCol));
    cell.isEdit = true;
    let lookup = this.lookupColumns[cell.api];
    cell.value = record[cell.api] != null ? record[cell.api] : "";
    if (lookup) {
     // this.setLookupCell(cell, record, lookup, result);
    }
    
      else{  
            if((cell.api =='Last_Name__c' && !record['Last_Name__c'] )
        ){
          cell.isRequired= true;
      cell.requiredError =
        "Last Name is required";
         }
          
      if((cell.api =='HomePhoneCountryCode__c' && record['HomePhone__c'] && ! record['HomePhoneCountryCode__c'] ) ||
        (cell.api =='Mobile_Phone_Country_Code__c' && record['Cell__c'] && ! record['Mobile_Phone_Country_Code__c'] )||
          (cell.api =='Business_Phone_Country_Code__c' && record['Business_Phone__c'] && ! record['Business_Phone_Country_Code__c'] )||
        (cell.api =='AdditionalPhoneCountryCode__c' && record['AdditionalPhone__c'] && ! record['AdditionalPhoneCountryCode__c'] )
        ){
          cell.isRequired= true;
      cell.requiredError =
        "Please Enter the country code";
         }
      if((cell.api =='HomePhoneCountryCode__c'  && record['HomePhoneCountryCode__c'] ) ||
        (cell.api =='Mobile_Phone_Country_Code__c'  && record['Mobile_Phone_Country_Code__c'] )||
          (cell.api =='Business_Phone_Country_Code__c' && record['Business_Phone_Country_Code__c'] )||
        (cell.api =='AdditionalPhoneCountryCode__c' && record['AdditionalPhoneCountryCode__c'] )
        ){
          cell.isRequired= false;
         cell.requiredError ="";
       
      }
          }
    return cell;
  },
  setLookupCell: function (cell, record, lookup, result) {
    cell.type = "LOOKUP";
    cell.obj = lookup.obj;
    cell.icon = lookup.icon;
    cell.id = record[lookup.idField];
    if (!cell.value || !cell.value.length) {
      return;
    }
    let nameMap = {};
    if (cell.icon == "standard:account") {
      nameMap = result.orgs;
    } else {
      nameMap = result.contacts;
    }
    if (!nameMap || !Object.keys(nameMap).length) {
        if(!cell.id ){
          cell.requiredError =cell.value+' not found in BRM.';
          cell.isRequired =true;
          cell.class ='red';   
      }
      return;
    }
      
    let key = cell.value.toLowerCase();
    let names = nameMap[key];
      if (cell.icon != "standard:account" &&  !cell.id &&(!names || !Object.keys(names).length)) {
          cell.requiredError = cell.value+ ' not found in BRM' ;
          cell.class = "red";
          cell.isRequired = true;
          
          return;
      }
    if ((!names || !Object.keys(names).length) && !record.Organization_Id__c && !cell.id ) {
        cell.requiredError = cell.value+ ' not found in BRM' ;
        cell.class = "red";
        cell.isRequired = true;
        
      return;
    }
      if(names){
          if (Object.keys(names).length > 1 && !record.Organization_Id__c && cell.icon == "standard:account") {
              cell.requiredError =
                  "Multiple " +
                  cell.value +
                  " found in BRM.  Please search for correct one.";
              cell.hasMultiple = true;
              return;
          }
          else if(Object.keys(names).length > 1){
               cell.requiredError =
                  "Multiple " +
                  cell.value +
                  " found in BRM.  Please search for correct one.";
              cell.hasMultiple = true;
              return;
          }
           
          cell.id = Object.keys(names)[0];
      }
  },
  getPreviewColumns: function (colMap, columns) {
    let cols = [];
    this.phoneCountryMap = this.getPhoneCountryMap(columns);
    // BRME-4862: render only columns the file actually mapped (colMap has a header for the
    // api). Country-code companions are always kept when their phone column is shown, since
    // they can carry the "Please Enter the country code" error even if not directly mapped.
    colMap = colMap || {};
    let mappedApis = {};
    for (let api in colMap) {
      if (colMap[api]) {
        mappedApis[api] = true;
      }
    }
    let showColumn = {};
    for (let i = 0; i < columns.length; i++) {
      let col = columns[i];
      if (mappedApis[col.api]) {
        showColumn[col.api] = true;
      }
    }
    // keep country-code column whenever its phone column is shown
    for (let phoneApi in this.phoneColumns) {
      if (showColumn[phoneApi]) {
        showColumn[this.phoneColumns[phoneApi]] = true;
      }
    }
    let seenMap = {};
    let skipMap = {};
    for (let i = 0; i < columns.length; i++) {
      let col = columns[i];
      if (!showColumn[col.api]) {
        continue; // BRME-4862: skip unmapped columns
      }
      col.isSticky = this.stickyColumns[col.api];
      seenMap[col.api] = true;
      if (this.phoneCountryMap[col.api]) {
        let countryIdx = this.phoneCountryMap[col.api].countryIdx;
        skipMap[countryIdx] = true;
        if (!seenMap[this.phoneColumns[col.api]]) {
          cols.push(columns[countryIdx]);
        }
      }
      cols.push(col);
    }
    this.setColMapCountryIdx(cols);
    return cols;
  },
  setColMapCountryIdx: function (cols) {
    let colMap = {};
    for (let i = 0; i < cols.length; i++) {
      let col = cols[i];
      colMap[col.api] = i;
    }
    for (let key in this.phoneColumns) {
         if(this.phoneCountryMap[key])
      this.phoneCountryMap[key].colCountryIdx = colMap[this.phoneColumns[key]];
    }
  },
  getPhoneCountryMap: function (columns) {
    let countryCodeMap = {};
    let phoneMap = {};
    let phoneCountryMap = {};
    for (let key in this.phoneColumns) {
      let countryCode = this.phoneColumns[key];
      let phone = key;
      countryCodeMap[countryCode] = -1;
      phoneMap[phone] = -1;
    }

    for (let i = 0; i < columns.length; i++) {
      let col = columns[i];
      if (countryCodeMap[col.api] != null) {
        countryCodeMap[col.api] = i;
      } else if (phoneMap[col.api] != null) {
        phoneMap[col.api] = i;
      }
    }

    for (let i = 0; i < columns.length; i++) {
      let col = columns[i];
      if (this.phoneColumns[col.api]) {
        phoneCountryMap[col.api] = {};
        phoneCountryMap[col.api].phoneIdx = phoneMap[col.api];
        phoneCountryMap[col.api].countryIdx =
          countryCodeMap[this.phoneColumns[col.api]];
      }
    }
    return phoneCountryMap;
  },
  getColMap: function (cmp) {
    let colMap = {};
    let excelColumns = cmp.get("v.excelColumns");
    for (let i = 0; i < excelColumns.length; i++) {
      let excelCol = excelColumns[i];
      let cell = excelCol.cells[1];
      if (cell.value && cell.value.length) {
        colMap[cell.api] = cell.value;
      }
    }
    return colMap;
  },
  getNewCol: function (sfCol, exCol) {
    let col = exCol;
    col.label = sfCol.value;
    return col;
  }
});