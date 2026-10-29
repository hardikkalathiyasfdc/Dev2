import { LightningElement, api, track } from 'lwc';
import {loadScript} from 'lightning/platformResourceLoader';
import LightningConfirm from 'lightning/confirm';
import XLSX from '@salesforce/resourceUrl/ExcelJS';
import getBudgetData from '@salesforce/apex/IMCheckoutBudgetController.getBudgetData';
import getBudgetTemplate from '@salesforce/apex/IMCheckoutBudgetController.getBudgetTemplate';
import {getErrorMessages} from 'c/utils';

import { 
    CONSTANTS, 
    ERROR_MESSAGES, 
    TOAST_HEADERS,
	initializeExcelLibrary,
	checkReadyState,
	getBudgetDataUtil,
    getTemplateContent,
    loadTemplate,
    hideBudgetCols,
    setYearColumnLabels,
    setBudgetData,
	sortBudgetRowsByPartnerUniqueId,
    downloadWorkbook,
	showErrorToast,
	closeModal
} from 'c/imBudgetUtils';

var regeneratorRuntime = undefined;
const FILENAME = 'IM_DownloadBudget.xlsx';

export default class ImDownloadBudget extends LightningElement {

    //VARIABLES
	_recordId;
	budgetWrapperData = {};
	@track excelStaticResourceLoaded = false;
	@track apexDataReceived = false;
	showSpinner = false;
	//JSON Objects
	templateMetadata;
	paramColumnMapping;
	budgetColumnMapping;
	periodColumnMapping;
	skipObj;
	//Budget Term Integer
	budgetTerm;
	initiativeId;
	fileName = FILENAME;

    @api set recordId(value) {
		this._recordId = value;
		this.getBudgetData();
	}

	get recordId() {
		return this._recordId;
	}

    /*
    Description: Connected Callback - used for loading Excel JS Library once the DOM is loaded
    */
	async connectedCallback() {
		const result = await LightningConfirm.open({
			message: 'This generated file cannot be used for Check In. Are you sure you want to proceed?',
			label: 'Confirmation',
			theme: 'warning'
		});
		if (result) {
			if (!window.regeneratorRuntime) {
				window.regeneratorRuntime = regeneratorRuntime;
			}
			Promise.all([loadScript(this, XLSX + '/unpkg/exceljs.min.js')]).then(() => {
				initializeExcelLibrary(this, () => {
					this.getBudgetTemplate();
				});
			}).catch((error) => {
				console.error('Error loading Excel library:', error);
				this.showSpinner = false;
			});
		} else {
			this.showSpinner = false;
			closeModal(this);
		}
	}

	/*
    Description: Requesting Budget Data from Apex for the Budget Record
    */
	async getBudgetData() {
		getBudgetDataUtil(
			this,
			this._recordId,
			getBudgetData,
			() => {
				// Success callback
				checkReadyState(this, () => {
					this.getBudgetTemplate();
				});
			},
			(errorMessage) => {
				// Error callback
				showErrorToast(this, TOAST_HEADERS.DOWNLOAD_FAIL_HEADER, errorMessage);
			},
		);
	}

	/**
	 * Description: Get the Budget Template from Apex based on the budget record
	 */
	async getBudgetTemplate() {
		try {
			const budgetTemplate = await getBudgetTemplate({budgetId: this._recordId, type:'Initiative Budget Download'});
			if (!budgetTemplate.error) {
				this.getTemplateContent(budgetTemplate);
			}
		} catch (error) {
			this.showSpinner = false;
			let errorMessages = getErrorMessages(error);
			showErrorToast(this, TOAST_HEADERS.DOWNLOAD_FAIL_HEADER, errorMessages[0]);
			closeModal(this);
		}
	}

	/**
	 * Description: Decode Budget Template recieved from Apex and convert it to Blob
	 */
	getTemplateContent(budgetTemplate) {
		const { templateMetadata, blob } = getTemplateContent(budgetTemplate);
		this.templateMetadata = templateMetadata;
		if (this.templateMetadata) {
			this.budgetColumnMapping = this.templateMetadata.Budget.ColumnMapping;
			this.periodColumnMapping = this.templateMetadata.Budget.PeriodColumnMapping;
			this.skipObj = this.templateMetadata.Budget.SkipColumnDataMapping;
		}
		this.loadTemplate(blob);
	}

	/**
	 * Description: Load the template file fetched from Files into excelJS workbook instance
	 */
	async loadTemplate(response) {
		try {
			loadTemplate(response, (workbook) => {
				this.setBudget(workbook);
			});
		} catch (error) {
			this.showSpinner = false;
			showErrorToast(this, TOAST_HEADERS.DOWNLOAD_FAIL_HEADER, ERROR_MESSAGES.LOAD_TEMP_ERROR + error);
		}
	}

	/**
	 * Description: Once the template is loaded, this function performs the Budget excel data manipulations.
	 */
	setBudget(workbook) {
		try {
			const budgetWorksheet = workbook.getWorksheet(CONSTANTS.BUDGET_TAB);
			if (!budgetWorksheet) {
				this.showSpinner = false;
				showErrorToast(this, TOAST_HEADERS.DOWNLOAD_FAIL_HEADER, CONSTANTS.BUDGET_TAB + ERROR_MESSAGES.NOT_FOUND);
			}
			if (this.budgetWrapperData) {
				//Column Hide Logic - STEP 1
				hideBudgetCols(budgetWorksheet, this.budgetColumnMapping, this.periodColumnMapping, this.budgetWrapperData.budgetRec, this.budgetTerm);
				setYearColumnLabels(budgetWorksheet, this.budgetWrapperData.periods, this.periodColumnMapping, this.templateMetadata);
				//Call setBudgetData - STEP 2
				const sortedBudgetRows = sortBudgetRowsByPartnerUniqueId(this.budgetWrapperData.budgetRowList);
				setBudgetData(budgetWorksheet, sortedBudgetRows, this.budgetColumnMapping, this.periodColumnMapping, this.skipObj, this.templateMetadata, false, false);
				this.download(workbook);
			} else {
				this.showSpinner = false;
				showErrorToast(this, TOAST_HEADERS.DOWNLOAD_FAIL_HEADER, ERROR_MESSAGES.NO_DATA + ' for' + CONSTANTS.BUDGET_TAB);
			}
		} catch (error) {
			this.showSpinner = false;
			showErrorToast(this, TOAST_HEADERS.DOWNLOAD_FAIL_HEADER, ERROR_MESSAGES.HIDE_COLS_ERROR + CONSTANTS.BUDGET_TAB + ' : ' + error);
		}
	}

	/**
	 * Description: Writes the excel Manipulations to the excelJS workbook instance, and downloads it.
	 */
	async download(workbook) {
		try {
			await downloadWorkbook(workbook, this.fileName);
			this.showSpinner = false;
			closeModal(this);
		} catch (error) {
			this.showSpinner = false;
			showErrorToast(this, TOAST_HEADERS.DOWNLOAD_FAIL_HEADER, ERROR_MESSAGES.DOWNLOAD_ERROR + error);
			closeModal(this);
		}
	}
}