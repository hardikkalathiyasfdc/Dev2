import {LightningElement, api, track} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {loadScript} from 'lightning/platformResourceLoader';
import XLSX from '@salesforce/resourceUrl/ExcelJS';
import getBudgetData from '@salesforce/apex/IMCheckoutBudgetController.getBudgetData';
import getUserAccessLevel from '@salesforce/apex/IMUtil.getUserAccessLevel';
import getBudgetTemplate from '@salesforce/apex/IMCheckoutBudgetController.getBudgetTemplate';
import updateBudget from '@salesforce/apex/IMCheckoutBudgetController.updateBudgetCheckoutFields';
import getCheckoutInformation from '@salesforce/apex/IMCheckoutBudgetController.checkoutInformation';
import {getErrorMessages} from 'c/utils';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';

import { 
    CONSTANTS, 
    ERROR_MESSAGES, 
    TOAST_HEADERS,
	initializeExcelLibrary,
	checkReadyState,
    getTemplateContent,
    loadTemplate,
    setSystemSheet,
    hideBudgetParamCols,
    setBudgetParamsData,
    protect,
    hideBudgetCols,
    setYearColumnLabels,
    setBudgetData,
    sortBudgetRowsByPartnerUniqueId,
    downloadWorkbook,
    getBudgetDataWithCheckout,
	showErrorToast,
	closeModal
} from 'c/imBudgetUtils';

var regeneratorRuntime = undefined;
const FILENAME = 'IM_CheckoutBudget.xlsx';

export default class ImCheckoutBudget extends NavigationMixin(LightningElement) {
	//VARIABLES
	_recordId;
	budgetWrapperData;
	isPostApprovalCheckout = false;
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
	lockCellFill;

	@api set recordId(value) {
		this._recordId = value;
		this.getBudgetData();
	}

	get recordId() {
		return this._recordId;
	}

	/*
    Description: Connected Callback - used for loading Excel JS Library once the DOM is loaded
    Jira Story : IM-50
    */
	connectedCallback() {
		if (!window.regeneratorRuntime) {
			window.regeneratorRuntime = regeneratorRuntime;
		}
        Promise.all([loadScript(this, XLSX + '/unpkg/exceljs.min.js')]).then(() => {
            initializeExcelLibrary(this, XLSX, () => {
                this.getBudgetTemplate();
            });
        }).catch((error) => {
            console.error('Error loading Excel library:', error);
            this.showSpinner = false;
        });
	}

	/*
    Description: Requesting Budget Data from Apex for the Budget Record
    Jira Story : IM-50
    */
	async getBudgetData() {
		//IM-274: Check if the user access level is read, then throw an error
        const userAccess = await getUserAccessLevel({recordId: this._recordId});
        if (userAccess) {
            if (userAccess.MaxAccessLevel == 'Read') {
                this.showSpinner = false;
                this.showErrorToast(NOT_ALLOWED);
                navigateToRecordPage(this, this._recordId);
            } else {
                getBudgetDataWithCheckout(
                    this,
                    this._recordId,
                    getBudgetData,
                    getCheckoutInformation,
                    () => {
                        //Success callback
                        checkReadyState(this, () => {
                            this.getBudgetTemplate();
                        });
                    },
                    (errorMessage) => {
                        //Error callback
						showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, errorMessage);
                    },
                    (checkoutError) => {
                        // Checkout error callback
						showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, checkoutError);
                        closeModal(this);
                    },
                    TOAST_HEADERS.CHECKOUT_FAIL_HEADER
                );
            }
        }   
	}

	/**
	 * Description: Get the Budget Template from Apex based on the budget record
	 * Jira Story : IM-50
	 */
	async getBudgetTemplate() {
        try {
            const budgetTemplate = await getBudgetTemplate({ budgetId: this._recordId, type:'Initiative Budget'});
            if (!budgetTemplate.error) {
                this.getTemplateContent(budgetTemplate);
            }
        } catch (error) {
            this.showSpinner = false;
            let errorMessages = getErrorMessages(error);
            showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, errorMessages[0]);
        }
	}

	/**
	 * Description: Decode Budget Template recieved from Apex and convert it to Blob
	 * Jira Story : IM-50
	 */
	getTemplateContent(budgetTemplate) {
        const { templateMetadata, blob } = getTemplateContent(budgetTemplate);
        this.templateMetadata = templateMetadata;
        if (this.templateMetadata) {
            this.paramColumnMapping = this.templateMetadata.BudgetParameters.ColumnMapping;
            this.budgetColumnMapping = this.templateMetadata.Budget.ColumnMapping;
            this.periodColumnMapping = this.templateMetadata.Budget.PeriodColumnMapping;
            this.skipObj = this.templateMetadata.Budget.SkipColumnDataMapping;
        }
        this.loadTemplate(blob);
	}

	/**
	 * Description: Load the template file fetched from Files into excelJS workbook instance
	 * Jira Story : IM-50
	 */
	async loadTemplate(response) {
		try {
            loadTemplate(response, (workbook) => {
                //Calling BudgetParameter and Budget Functions for Data Manipulations
                this.setSystemSheet(workbook);
                this.setBudgetParams(workbook);
                this.setBudget(workbook);
            });
        } catch (error) {
            this.showSpinner = false;
            showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, ERROR_MESSAGES.LOAD_TEMP_ERROR + error);
        }
	}

	/**
	 * Description: Once the template is loaded, this function performs the Budget Parameters excel data manipulations.
	 * Jira Story : IM-50
	 */
	setSystemSheet(workbook) {
        try {
            this.lockCellFill = setSystemSheet(workbook, this._recordId);
        } catch (error) {
            this.showSpinner = false;
            showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, CONSTANTS.SYSTEM_TAB + ' : ' + error);
        }
	}

	/**
	 * Description: Once the template is loaded, this function performs the Budget Parameters excel data manipulations.
	 * Jira Story : IM-50
	 */
	setBudgetParams(workbook) {
		try {
            const budgetParamsWksht = workbook.getWorksheet(CONSTANTS.BUDGET_PARAM_TAB);
            if (!budgetParamsWksht) {
                this.showSpinner = false;
                showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, CONSTANTS.BUDGET_PARAM_TAB + ERROR_MESSAGES.NOT_FOUND);
            }
            if (this.budgetWrapperData.budgetParam) {
                //Column Hide Logic - STEP 1
                hideBudgetParamCols(budgetParamsWksht, this.paramColumnMapping, this.budgetWrapperData.budgetRec);
                //Call setBudgetParamsData - STEP 2 
                setBudgetParamsData(budgetParamsWksht, this.budgetWrapperData.budgetParam?.data, this.paramColumnMapping, this.templateMetadata);
                //Protect Worksheet - STEP 3
                protect(budgetParamsWksht, this.initiativeId);
            } else {
                this.showSpinner = false;
                showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, ERROR_MESSAGES.NO_DATA + ' for' + CONSTANTS.BUDGET_PARAM_TAB);
            }
        } catch (error) {
            this.showSpinner = false;
            showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, ERROR_MESSAGES.HIDE_COLS_ERROR + CONSTANTS.BUDGET_PARAM_TAB + ' : ' + error);
        }
	}

	/**
	 * Description: Once the template is loaded, this function performs the Budget excel data manipulations.
	 * Jira Story : IM-50
	 */
	setBudget(workbook) {
        try {
            const budgetWorksheet = workbook.getWorksheet(CONSTANTS.BUDGET_TAB);
            if (!budgetWorksheet) {
                this.showSpinner = false;
                showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, CONSTANTS.BUDGET_TAB + ERROR_MESSAGES.NOT_FOUND);
            }
            if (this.budgetWrapperData) {
                //Column Hide Logic - STEP 1
                hideBudgetCols(budgetWorksheet, this.budgetColumnMapping, this.periodColumnMapping, this.budgetWrapperData.budgetRec, this.budgetTerm);
                setYearColumnLabels(budgetWorksheet, this.budgetWrapperData.periods, this.periodColumnMapping, this.templateMetadata);
                //Call setBudgetData - STEP 2
                const sortedBudgetRows = sortBudgetRowsByPartnerUniqueId(this.budgetWrapperData.budgetRowList);
                setBudgetData(budgetWorksheet, sortedBudgetRows, this.budgetColumnMapping, this.periodColumnMapping, this.skipObj, this.templateMetadata, this.isPostApprovalCheckout, this.lockCellFill);
                //Protect Worksheet - STEP 3
                protect(budgetWorksheet, this.initiativeId);
                this.download(workbook);
            } else {
                this.showSpinner = false;
                showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, ERROR_MESSAGES.NO_DATA + ' for' + CONSTANTS.BUDGET_TAB);
            }
        } catch (error) {
            this.showSpinner = false;
            showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, ERROR_MESSAGES.HIDE_COLS_ERROR + CONSTANTS.BUDGET_TAB + ' : ' + error);
        }
	}

	/**
	 * Description: Writes the excel Manipulations to the excelJS workbook instance, and downloads it.
	 * Jira Story : IM-50
	 */
	async download(workbook) {
        try {
            await downloadWorkbook(workbook, this.fileName);
            //Call updateBudget function
            this.updateBudget(this._recordId);
        } catch (error) {
            this.showSpinner = false;
            showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, ERROR_MESSAGES.DOWNLOAD_ERROR + error);
            closeModal(this);
        }
	}

	/**
	 * Description : updates Budget Checkout fields
	 * Jira Story  : IM-100
	 */
	async updateBudget(budgetId) {
        try {
            let res = await updateBudget({ budgetId: budgetId });
            if (res) {
                getRecordNotifyChange([{recordId: budgetId}]);
            } else {
                showErrorToast(his, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, ERROR_MESSAGES.UPDATE_FAILED_ERROR);
            }
			this.showSpinner = false;
            closeModal(this);
        } catch (error) {
			this.showSpinner = false;
            showErrorToast(this, TOAST_HEADERS.CHECKOUT_FAIL_HEADER, ERROR_MESSAGES.UPDATE_FAILED_ERROR + ' : ' + error);
            closeModal(this);
        }
	}
}