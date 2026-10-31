({
	doInit: function (cmp, event, helper) {
		let data = cmp.get("v.data");
		helper.applyEditState(cmp);
		cmp.set("v.oldData", data);
		cmp.set("v.tableData", data);
		cmp.set("v.isLoading", false);
		cmp.set("v.isInit", true);
		helper.syncTopWidth(cmp);
	},
	// BRME-4862: keep the top scrollbar and main table horizontal scroll in sync.
	syncTopScroll: function (cmp, event, helper) {
		let top = event.target;
		let main = cmp.find("myTable");
		if (main && main.getElement) {
			main.getElement().scrollLeft = top.scrollLeft;
		}
	},
	syncMainScroll: function (cmp, event, helper) {
		let main = event.target;
		let top = cmp.find("topScroll");
		if (top && top.getElement) {
			top.getElement().scrollLeft = main.scrollLeft;
		}
	},
	setWidth: function (cmp, event, helper) {
    console.log('set width :::: ');
		helper.setWidths(cmp);
	},
	updateUICell: function (cmp, event, helper) {

		let params = event.getParam('arguments');
		if (!params || isNaN(params.row) || isNaN(params.col)) {
			return;
		}
		helper.updateUICell(cmp, params.row, params.col, params.cell);
	},
	scrollTable: function (component, event, helper) {
		helper.scroll(component);
	},
	handleCellClick: function (cmp, event, helper) {
		// BRME-4862: enter edit mode for the clicked read-only cell.
		let key = event.currentTarget.getAttribute("data-cell");
		if (key) {
			cmp.set("v.editKey", key);
			helper.applyEditState(cmp);
		}
	},
	handleInputChange: function (cmp, event, helper) {
		// BRME-4862: leaving the input returns the cell to read-only (unless it still has an error).
		cmp.set("v.editKey", "");
		helper.applyEditState(cmp);
		let name = event.getSource().get("v.name");
		if (!name) {
			return;
		}
		let errMsg = event.getSource().checkValidity() ? null : "invalid format.";
		// if(errMsg || errMsg !=null)
		//    return;
		helper.updateCell(cmp, name, null, null, errMsg);


		let row = name.split('-')[0];
		let col = name.split('-')[1];
		let data = cmp.get("v.data");
		let cell = data[row].cells[col];
		if (cell.type == 'PHONE' || cell.api.includes('Code')) {
			if (cell.api.includes('Code')) {
				if (cell.value) {
					cell.isRequired = false;
					cell.requiredError = "";
				}
				// else
				// cell.requiredError ="Please Enter the country code";
			}

          var codemap={'HomePhone__c':'HomePhoneCountryCode__c','Cell__c':'Mobile_Phone_Country_Code__c',
                       'Business_Phone__c':'Business_Phone_Country_Code__c','AdditionalPhone__c':'AdditionalPhoneCountryCode__c'};

			for (let i = 0; i < data[row].cells.length; i++) {
              if(codemap[cell.api] && cell.value && data[row].cells[i].api ==codemap[cell.api] && !data[row].cells[i].value)
              {
					data[row].cells[i].requiredError = "Please Enter the country code";
					data[row].cells[i].isRequired = true;
					helper.updateUICell(cmp, row, i, data[row].cells[i]);
				}
				else {
					if (data[row].cells[i].api == cell.api) {
						data[row].cells[i].requiredError = "";
						data[row].cells[i].isRequired = false;
						helper.updateUICell(cmp, row, i, data[row].cells[i]);
					}
				}
			}

		}
		helper.updateUICell(cmp, row, col, cell);


	},
	handleCheckboxChange: function (cmp, event, helper) {
		console.log('0.1 ::::::::: ');
		let name = event.getSource().get("v.name");
		let isChecked = event.getSource().get("v.checked");
		console.log('0.2 ::::::::: ' + name + ' :::: ' + isChecked);
		if (!name) {
			return;
		}
		helper.updateCheckboxes(cmp, name, isChecked);
	},
	handleLookupClick: function (cmp, event, helper) {
		let name = event.getSource().get("v.name");
		if (!name) {
			return;
		}
		helper.updateCell(cmp, name, null, "action");
	},
	handleLookup: function (cmp, event, helper) {
		let record = event.getParam("recordByEvent");
		let name = event.getParam("cmpId");
		let row = name.split('-')[0];
		let col = name.split('-')[1];
		let data = cmp.get("v.data");
		let cell = data[row].cells[col];
		let oldData = cmp.get("v.oldData");
		if (cell.api == "Assistant_Name__c" && (!record || !record.Id || !name || !name.length || !cell.value)) {

			cell.requiredError = '';
			cell.isRequired = false;
			cell.hasMultiple = false;
			cell.class = '';
			for (let i = 0; i < data[row].cells.length; i++) {
				if (data[row].cells[i].api == "Assistant_Title__c" || data[row].cells[i].api == "Assistant_Email__c"
					|| data[row].cells[i].api == "Assistant_Business_Phone__c" || data[row].cells[i].api == "Assistant_Business_Phone_Country_Code__c") {
					data[row].cells[i].value = "";
					data[row].cells[i].isReadOnly = false;
					helper.updateUICell(cmp, row, i, data[row].cells[i]);
				}
			}
		}

		if (record && record.Id) {
			cell.requiredError = '';
			cell.isRequired = false;
			cell.hasMultiple = false;
			cell.class = '';
			data[row].cells[col] = cell;
			// cmp.set("v.tableData",data);
			// helper.updateUICell(cmp, row, col,cell);
			helper.updateCell(cmp, name, record);
			return;
		}
		/*  if(cell.value  && !cell.id && ((record && !record.Id) || !record)){
			  cell.requiredError =cell.value+' not found in BRM.';
			  cell.isRequired =true;
			  cell.class ='red';
			  }
		  else if(!cell.value){
			   cell.requiredError ='';
			  cell.isRequired =false;
			  cell.hasMultiple = false;
			  cell.class ='';
		  }
		  else if(cell.value && record && record.Id)
		  {
			  cell.requiredError ='';
			  cell.isRequired =false;
			  cell.hasMultiple = false;
			  cell.class ='';
		  }
		*/
		/*   let tableData = cmp.get("v.tableData");
		  tableData[row].cells[col] =cell;
		  cmp.set("v.tableData",tableData);
		  */
		data[row].cells[col] = cell;
		cmp.set("v.tableData", data);

		helper.updateUICell(cmp, row, col, cell);
		helper.updateCell(cmp, name, record);

	},
	colMouseUp: function (cmp, evt, helper) {
		helper.mouseStart = null;
		helper.oldWidth = null;
		helper.selectedCol = null;
	},
	calculateWidth: function (component, event, helper) {
		var childObj = event.target;
		var parObj = childObj.parentNode;
		var count = 1;
		while (parObj.tagName != "TH") {
			parObj = parObj.parentNode;
			count++;
		}
		console.log("final tag Name" + parObj.tagName);
		helper.selectedCol = parObj;
		helper.mouseStart = event.clientX;
		helper.oldWidth = parObj.offsetWidth;
	},
	setNewWidth: function (component, event, helper) {
		if (helper.mouseStart && helper.oldWidth != null && helper.selectedCol) {
			var newWidth =
				event.clientX -
				parseFloat(helper.mouseStart) +
				parseFloat(helper.oldWidth);
			helper.selectedCol.style.width = newWidth + "px";
		}
	}
});