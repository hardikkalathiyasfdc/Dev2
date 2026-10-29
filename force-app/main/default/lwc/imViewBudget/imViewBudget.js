import {LightningElement, api} from 'lwc';
import XLSX from '@salesforce/resourceUrl/ExcelJS';
import {loadScript} from 'lightning/platformResourceLoader';
import {NavigationMixin} from 'lightning/navigation';
import {CloseActionScreenEvent} from 'lightning/actions';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getBudget from '@salesforce/apex/IMBudgetViewsController.getBudget';
import getData from '@salesforce/apex/IMBudgetViewsController.getData';
import getBudgetTemplate from '@salesforce/apex/IMBudgetViewsController.getBudgetTemplate';
const TAB_NAME_VALIDATION = 'Tab Name must be unique across sheets, and should be alpha numeric only.';
const FILENAME = '_View Only.xlsx';
const REDIRECT_OBJECT = 'IM_Budget__c';
const HIDE_ROW_NUMBER_INDEX = 304;
const GRANT_OPTION = 'Grant';
const GRANT_EXPORT_FIELDS = ['Partner__r.Organization__r.Name', 'Unique_Identifier__c'];
const GRANT_EXPORT_FIELD_LABELS = {'Partner__r.Organization__r.Name': 'Partner', Unique_Identifier__c: 'Unique Identifier'}

var regeneratorRuntime = undefined;

export default class ImViewBudget extends NavigationMixin(LightningElement) {

	columnOptions = [];
	selectedColumnsTab1 = [];
	selectedColumnsTab2 = [];
	selectedColumnsTab3 = [];
	selectedColumnsTab4 = [];

	tab1Name = 'Sheet 1';
	tab2Name = 'Sheet 2';
	tab3Name = 'Sheet 3';
	tab4Name = 'Sheet 4';

	tab1data;
	tab2data;
	tab3data;
	tab4data;

	_recordId;
	templateStructure;
	columnMapping;
	totalAmountObj;

	isBudgetDataLoaded = false;
	isExportDisabled = true;

	budgetWrapperData;
	budgetPeriodsMap;
	periodColumnMapping;
	columnConfig;

	colsToDisplay;
	fieldsToTab;
	blob;
	fileName;

	@api set recordId(value) {
		this._recordId = value;
	}

	get recordId() {
		return this._recordId;
	}

	async connectedCallback() {
		if (!window.regeneratorRuntime) {
			window.regeneratorRuntime = regeneratorRuntime;
		}
		Promise.all([loadScript(this, XLSX + '/unpkg/exceljs.min.js')])
			.then(() => {
				this.getBudgetTemplate();
			})
			.catch((error) => {
				console.error(error);
				this.showErrorToast('Error', 'error', 'Cannot load excel');
				this.navigateToRecordPage();
			});
	}

	handleClose() {
		this.columnOptions = [];
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	handleTab1NameChange() {
		let tab1Name = this.template.querySelector('.tab1')?.getTabName();
		this.tab1Name = tab1Name.trim() !== '' ? tab1Name : 'Sheet 1';
		//IM-383: Perform Tab Name Validations
		if (
			String(this.tab1Name).toLowerCase() ===
				(String(this.tab2Name).toLowerCase() || String(this.tab3Name).toLowerCase() || String(this.tab4Name).toLowerCase()) ||
			!this.isAlphaNumeric(this.tab1Name)
		) {
			//Reset Tab Name, show Toast
			this.showErrorToast('Warning', 'warning', TAB_NAME_VALIDATION);
			this.tab1Name = 'Sheet 1';
		}
	}

	handleTab2NameChange() {
		let tab2Name = this.template.querySelector('.tab2')?.getTabName();
		this.tab2Name = tab2Name.trim() !== '' ? tab2Name : 'Sheet 2';
		//IM-383: Perform Tab Name Validations
		if (
			String(this.tab2Name).toLowerCase() ===
				(String(this.tab1Name).toLowerCase() || String(this.tab3Name).toLowerCase() || String(this.tab4Name).toLowerCase()) ||
			!this.isAlphaNumeric(this.tab2Name)
		) {
			//Reset Tab Name, show Toast
			this.showErrorToast('Warning', 'warning', TAB_NAME_VALIDATION);
			this.tab2Name = 'Sheet 2';
		}
	}

	handleTab3NameChange() {
		let tab3Name = this.template.querySelector('.tab3')?.getTabName();
		this.tab3Name = tab3Name.trim() !== '' ? tab3Name : 'Sheet 3';
		//IM-383: Perform Tab Name Validations
		if (
			String(this.tab3Name).toLowerCase() ===
				(String(this.tab1Name).toLowerCase() || String(this.tab2Name).toLowerCase() || String(this.tab4Name).toLowerCase()) ||
			!this.isAlphaNumeric(this.tab3Name)
		) {
			//Reset Tab Name, show Toast
			this.showErrorToast('Warning', 'warning', TAB_NAME_VALIDATION);
			this.tab3Name = 'Sheet 3';
		}
	}

	handleTab4NameChange() {
		let tab4Name = this.template.querySelector('.tab4')?.getTabName();
		this.tab4Name = tab4Name.trim() !== '' ? tab4Name : 'Sheet 4';
		//IM-383: Perform Tab Name Validations
		if (
			String(this.tab4Name).toLowerCase() ===
				(String(this.tab1Name).toLowerCase() || String(this.tab2Name).toLowerCase() || String(this.tab3Name).toLowerCase()) ||
			!this.isAlphaNumeric(this.tab4Name)
		) {
			//Reset Tab Name, show Toast
			this.showErrorToast('Warning', 'warning', TAB_NAME_VALIDATION);
			this.tab4Name = 'Sheet 4';
		}
	}

	/*
	Description: checks if the tabName is alphaNumeric using regEx.
	Jira Story : IM-383
	*/
	isAlphaNumeric(tabName) {
		return /^[a-z0-9 ]+$/i.test(String(tabName));
	}

	// Check if tab1's first column is populated
	handleColChange(event) {
		this.isExportDisabled = event.detail.data.value === 'None';
	}

	handleSave() {
		let tab1 = this.template.querySelector('.tab1')?.getSelectedColumns();
		if (tab1) {
			this.tab1data = JSON.parse(JSON.stringify(tab1));
			this.tab1data.tabName = this.tab1Name;
		}

		let tab2 = this.template.querySelector('.tab2')?.getSelectedColumns();
		if (tab2) {
			this.tab2data = JSON.parse(JSON.stringify(tab2));
			this.tab2data.tabName = this.tab2Name;
		}

		let tab3 = this.template.querySelector('.tab3')?.getSelectedColumns();
		if (tab3) {
			this.tab3data = JSON.parse(JSON.stringify(tab3));
			this.tab3data.tabName = this.tab3Name;
		}

		let tab4 = this.template.querySelector('.tab4')?.getSelectedColumns();
		if (tab4) {
			this.tab4data = JSON.parse(JSON.stringify(tab4));
			this.tab4data.tabName = this.tab4Name;
		}

		if(this.hasGrantAndPartnerSelection(this.tab1data) || 
			this.hasGrantAndPartnerSelection(this.tab2data) ||
			this.hasGrantAndPartnerSelection(this.tab3data) ||
			this.hasGrantAndPartnerSelection(this.tab4data)) {
				this.showErrorToast('Error', 'error', 'Please select either Partner or Grant, not both.');
				return;
		}
		

		// Tab 1 data
		this.selectedColumnsTab1 = this.getSelectedColumns(this.tab1data);
		// Tab 2 data
		this.selectedColumnsTab2 = this.getSelectedColumns(this.tab2data);
		// Tab 3 data
		this.selectedColumnsTab3 = this.getSelectedColumns(this.tab3data);
		// tab 4 data
		this.selectedColumnsTab4 = this.getSelectedColumns(this.tab4data);

		// Forming map of tabName and corresponding data
		const tabToColsMap = new Map();
		if (this.selectedColumnsTab1.length > 0) {
			tabToColsMap.set(this.tab1data.tabName, this.selectedColumnsTab1);
		}
		if (this.selectedColumnsTab2.length > 0) {
			tabToColsMap.set(this.tab2data.tabName, this.selectedColumnsTab2);
		}
		if (this.selectedColumnsTab3.length > 0) {
			tabToColsMap.set(this.tab3data.tabName, this.selectedColumnsTab3);
		}
		if (this.selectedColumnsTab4.length > 0) {
			tabToColsMap.set(this.tab4data.tabName, this.selectedColumnsTab4);
		}
		const obj = Object.fromEntries(tabToColsMap);
		const tabToColsMapping = JSON.stringify(obj);
		this.colsToDisplay = JSON.parse(tabToColsMapping);
		this.getData(tabToColsMapping);
	}

	// IM-370: Method to get the selected columns from each budget tab
	getSelectedColumns(tabData) {
		const selectedColumns = new Map();
		if (tabData) {
			if (tabData.col1 !== undefined && tabData.col1 !== 'None') {
				this.addColumnSelection(selectedColumns, tabData.col1);
			}
			if (tabData.col2 !== undefined && tabData.col2 !== 'None') {
				this.addColumnSelection(selectedColumns, tabData.col2);
			}
			if (tabData.col3 !== undefined && tabData.col3 !== 'None') {
				this.addColumnSelection(selectedColumns, tabData.col3);
			}
			if (tabData.col4 !== undefined && tabData.col4 !== 'None') {
				this.addColumnSelection(selectedColumns, tabData.col4);
			}
		}
		return [...selectedColumns.values()];
	}

	addColumnSelection(selectedColumns, columnKey) {
		if(columnKey === GRANT_OPTION) {
			const grantColumns = GRANT_EXPORT_FIELDS;
			grantColumns.forEach((fieldApi) => {
				selectedColumns.set(`${columnKey}_${fieldApi}`, fieldApi);
			});
			return;
		}
		if(this.columnConfig?.[columnKey]?.GroupByFields) {
			selectedColumns.set(columnKey, this.columnConfig[columnKey].GroupByFields);
		}
	}

	// Method to get budget data
	async getBudget() {
		try {
			let result = await getBudget({budgetId: this.recordId});
			if (result) {
				this.budget = JSON.parse(JSON.stringify(result));
				this.fileName = this.budget.Name + FILENAME;
				let nonVal = {value: 'None', label: 'None'};
				this.columnOptions = [...this.columnOptions, nonVal];

				Object.keys(this.columnConfig).forEach((key) => {
					if (this.budget[this.columnConfig[key].BudgetOptionsField]) {
						let addVal = {value: key, label: this.columnConfig[key].Label};
						this.columnOptions = [...this.columnOptions, addVal];
					}
				});
				const hasGrantInputs = !!this.budget?.Partner__c && !!this.budget?.Unique_Identifier__c;
				if(hasGrantInputs) {
					this.columnOptions = [...this.columnOptions, {value:GRANT_OPTION, label:GRANT_OPTION}];
				}
				this.isBudgetDataLoaded = true;
			}
		} catch (error) {
			console.error(error);
			this.showErrorToast('Error', 'error', 'Cannot get budget data');
			this.navigateToRecordPage();
		}
	}

	// Method to get aggregated data as per user input
	async getData(tabToColsMap) {
		try {
			let result = await getData({budgetId: this._recordId, tabToColsMapping: tabToColsMap});
			if (result) {
				this.budgetWrapperData = JSON.parse(JSON.stringify(result));
				if (this.budgetWrapperData) {
					this.loadTemplate(this.blob);
					this.budgetPeriodsMap = this.budgetWrapperData.budgetPeriodsMap;
				}
			}
		} catch (error) {
			console.error(error);
			this.showErrorToast('Error', 'error', 'Unable to get the requested aggregate data');
			this.navigateToRecordPage();
		}
	}

	// Method to get view budget template
	async getBudgetTemplate() {
		try {
			const budgetTemplate = await getBudgetTemplate({budgetId: this._recordId});

			if (!budgetTemplate.error) {
				this.getTemplateContent(budgetTemplate);
			}
		} catch (error) {
			this.showErrorToast('Error', 'error', 'Cannot find excel file to load data' + error);
			this.navigateToRecordPage();
		}
	}

	getTemplateContent(budgetTemplate) {
		this.templateStructure = JSON.parse(budgetTemplate.metadata);
		if (this.templateStructure) {
			this.columnMapping = this.templateStructure.ColumnMapping;
			this.totalAmountObj = this.templateStructure.TotalColumnMapping;
			this.periodColumnMapping = this.templateStructure.PeriodColumnMapping;
			this.columnConfig = this.templateStructure.ColumnConfig;
		}
		const base64Data = budgetTemplate.template;
		const binaryData = atob(base64Data);
		const byteArray = new Uint8Array(binaryData.length);
		for (let i = 0; i < binaryData.length; i++) {
			byteArray[i] = binaryData.charCodeAt(i);
		}
		this.blob = new Blob([byteArray], {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'});
		this.getBudget();
	}

	async loadTemplate(response) {
		try {
			const reader = new FileReader();

			reader.onload = async () => {
				const arrayBuffer = reader.result;
				const ExcelJS = window.ExcelJS;
				const workbook = new ExcelJS.Workbook();
				await workbook.xlsx.load(arrayBuffer);
				this.setBudget(workbook);
			};
			reader.readAsArrayBuffer(response);
		} catch (error) {
			this.showErrorToast('Error', 'error', 'Error loading excel file' + error);
			this.navigateToRecordPage();
		}
	}

	// Method to populate template with budget data
	setBudget(workbook) {
		try {
			let count = 1;
			if (this.budgetWrapperData) {
				Object.keys(this.budgetWrapperData.aggregateDataMap).forEach((key) => {
					let currentTab = 'Sheet ' + count;
					const worksheet = workbook.getWorksheet(currentTab);
					worksheet.name = key;
					this.setBudgetData(worksheet, this.budgetWrapperData.aggregateDataMap[key], this.colsToDisplay[worksheet.name]);
					this.setYearColumnLabels(worksheet);
					this.hideBudgetCols(worksheet, this.colsToDisplay[worksheet.name]);
					this.hideExcessRows(worksheet, this.budgetWrapperData.aggregateDataMap[key].length);
					count++;
				});
			}
			if (count < 5) {
				this.hideExcessSheets(workbook, count);
			}
			this.download(workbook);
			this.columnOptions = [];
			this.navigateToRecordPage();
		} catch (error) {
			this.showErrorToast('Error', 'error', 'Error loading excel file with data' + error);
			this.navigateToRecordPage();
		}
	}

	hideBudgetCols(budgetWorksheet, currentFields) {
		try {
			Object.keys(this.columnMapping).forEach((key) => {
				if (key.split('n')[1] > currentFields.length) {
					let col = budgetWorksheet.getColumn(this.columnMapping[key]);
					col.hidden = true;
				}
			});
			// hide year columns
			Object.keys(this.periodColumnMapping).forEach((key) => {
				let col = budgetWorksheet.getColumn(this.periodColumnMapping[key]);
				if (key.includes('period')) {
					let periodNumber = parseInt(key.split('d')[1]);
					if (periodNumber > this.budget.Budget_Term_Years__c) {
						col.hidden = true;
					}
				}
			});
		} catch (error) {
			this.showErrorToast('Error', 'error', 'Error while loading data in excel file' + error);
			this.navigateToRecordPage();
		}
	}

	hideExcessSheets(workbook, count) {
		for (let i = count; i <= 4; i++) {
			const worksheet = workbook.getWorksheet('Sheet ' + i);
			worksheet.state = 'veryHidden';
		}
	}

	setBudgetData(worksheet, budgetRows, currentFields) {
		try {
			const headerIndex = this.templateStructure.SecondaryHeaderRowIndex;
			currentFields.forEach((field, index) => {
				const row = worksheet.getRow(headerIndex);
				let col = index + 1;
				row.getCell(this.columnMapping['column' + col]).value = this.getExportLabel(field);
			});
			budgetRows.forEach((record, index) => {
				const rowIndex = index + this.templateStructure.DataRowStartIndex;
				const row = worksheet.getRow(rowIndex);

				Object.keys(this.columnMapping).forEach((key) => {
					if (key in record && !(key in this.totalAmountObj)) {
						row.getCell(this.columnMapping[key]).value = record[key] || '';
					}
				});
				Object.keys(this.periodColumnMapping).forEach((key) => {
					if (key in record && !(key in this.totalAmountObj)) {
						row.getCell(this.periodColumnMapping[key]).value = record[key] || '';
					}
				});
				Object.keys(this.totalAmountObj).forEach((key) => {
					if (row.getCell(this.totalAmountObj[key]).value.formula) {
						row.getCell(this.totalAmountObj[key]).value = {formula: row.getCell(this.totalAmountObj[key]).value.formula, result: record[key]} || '';
					} else if (row.getCell(this.totalAmountObj[key]).value.sharedFormula) {
						row.getCell(this.totalAmountObj[key]).value =
							{sharedFormula: row.getCell(this.totalAmountObj[key]).value.sharedFormula, result: record[key]} || '';
					}
				});
			});
		} catch (error) {
			this.showErrorToast('Error', 'error', 'Error while loading data in excel file' + error);
			this.navigateToRecordPage();
		}
	}

	getExportLabel(fieldApi) {
		if(GRANT_EXPORT_FIELD_LABELS[fieldApi]) {
			return GRANT_EXPORT_FIELD_LABELS[fieldApi];
		} else {
			return this.columnConfig[fieldApi.substring(0, fieldApi.indexOf('_c') + 2)].Label;
		}
		return fieldApi;
	}

	hasGrantAndPartnerSelection(tabData) {
		if(!tabData) {
			return false;
		}
		const selectedValues = [tabData.col1, tabData.col2, tabData.col3, tabData.col4].filter((value) => value && value !== 'None');
		const hasGrant = selectedValues.includes(GRANT_OPTION);
		const hasPartner = selectedValues.some((value) => this.isPartnerColumn(value));
		return hasGrant && hasPartner;
	}

	isPartnerColumn(columnKey) {
		const label = this.columnConfig?.[columnKey]?.Label;
		return typeof label === 'string' && label.trim().toLowerCase() === 'partner';
	}

	hideExcessRows(worksheet, numberOfRows) {
		let startIndexToHide = this.templateStructure.DataRowStartIndex + numberOfRows;
		for (let i = startIndexToHide; i <= HIDE_ROW_NUMBER_INDEX; i++) {
			const row = worksheet.getRow(i);
			row.hidden = true;
		}
	}

	setYearColumnLabels(budgetWorksheet) {
		let headerIndex = this.templateStructure.SecondaryHeaderRowIndex;
		const row = budgetWorksheet.getRow(headerIndex);
		Object.keys(this.periodColumnMapping).forEach((key) => {
			let periodNumber = parseInt(key.split('d')[1]);
			row.getCell(this.periodColumnMapping[key]).value = this.budgetPeriodsMap[periodNumber] || '';
		});
	}

	async download(workbook) {
		try {
			const buffer = await workbook.xlsx.writeBuffer();
			if (!buffer || buffer.bytelength === 0) {
				this.showErrorToast('Error', 'error', 'Failed to generate Excel File Buffer');
			}
			const blobFile = new Blob([buffer], {type: 'application/octet-stream'});
			const link = document.createElement('a');
			link.href = URL.createObjectURL(blobFile);
			link.download = this.fileName;
			document.body.appendChild(link);
			link.click();
			document.body.removeChild(link);
		} catch (error) {
			this.showErrorToast('Error', 'error', 'Cannot download file' + error);
			this.navigateToRecordPage();
		}
	}

	// Method to navigate to budget record page
	navigateToRecordPage() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this._recordId,
				objectApiName: REDIRECT_OBJECT,
				actionName: 'view',
			},
		});
	}

	showErrorToast(title, variant, displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: title,
			message: displayMessage,
			variant: variant,
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}
}