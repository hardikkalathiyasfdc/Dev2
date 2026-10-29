import {LightningElement, api, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';
import {loadScript} from 'lightning/platformResourceLoader';
import LightningConfirm from 'lightning/confirm';
import XLSX from '@salesforce/resourceUrl/ExcelJS';
import {getErrorMessages} from 'c/utils';
import getUserAccessLevel from '@salesforce/apex/IMUtil.getUserAccessLevel';
import deleteBudgetFile from '@salesforce/apex/IMCheckinBudgetController.deleteBudgetFile';
import getBudget from '@salesforce/apex/IMCheckinBudgetController.getBudget';
import getTotalAmountsByPartner from '@salesforce/apex/IMCheckinBudgetController.getTotalAmountsByPartner';
import getBudgetTemplate from '@salesforce/apex/IMCheckinBudgetController.getBudgetTemplate';
import fetchOrgMapping from '@salesforce/apex/IMCheckinBudgetController.fetchOrgMapping';
import saveBudget from '@salesforce/apex/IMCheckinBudgetController.saveBudget';
import getAccountAKA from '@salesforce/apex/IMCheckinBudgetController.getAccountAKA';
import {updateRecord} from 'lightning/uiRecordApi';
import {CloseActionScreenEvent} from 'lightning/actions';
import {getRecordNotifyChange} from 'lightning/uiRecordApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BUDGET_OBJECT from '@salesforce/schema/IM_Budget__c';
var regeneratorRuntime = undefined;

//Constants
//Generic
const TOTAL_AMOUNT = 'Total_Amount__c';
const REDIRECT_OBJECT = 'IM_Budget__c';
const GEOGRAPHY = 'Geography__c';
const COMPONENT = 'Component__c';
const SUBCOMPONENT = 'SubComponent__c';
const PARTNER = 'Partner__c';
const UNIQUEIDENTIFIER = 'Unique_Identifier__c';
const SUBPARTNER = 'Sub_Partner__c';
const SUBPARTNERTYPE = 'Sub_Partner_Type__c';
const PAYEE = 'Payee_Fiscal_Sponsor__c';
const TYPEOFWORK = 'Type_of_Work__c';
const YEAR = 'Year';
const SUPPLEMENTAL = 'Supplemental';
const OFFSET = 'Offset';
const PARTNERFUND = 'Partner_Fund__c';
const ISLOCKED = 'Is_Locked__c';

//Modal Related
const CHECKIN_BUDGET_LABEL = 'Check In Budget';
const UPLOAD_TITLE = 'Please upload the Initiative Budget file';
const STEP1LABEL = 'Upload Budget';
const STEP2LABEL = 'Validations';
const STEP3LABEL = 'Confirmation';

//Tabs
const BUDGET_PARAM_TAB = 'Budget Parameters';
const BUDGET_TAB = 'Budget';
const SYSTEM_TAB = 'System';

//Errors Related
const COLS_NOT_MATCHING = 'Columns are not matching the Budget configuration';
const MISSING_AMOUNT = 'Missing amounts';
const ROW_NUMBER = ' on Row ';
const MISSING_VALUE = 'Missing values in column ';
const INVALID_VALUE = 'You have selected an invalid value ';
const NOT_PRESENT = ' which is not present under ';
const TOTAL_AMOUNT_CANNOT_CHANGE = 'Total Budget Amount cannot change.';
const TOTAL_AMOUNT_ZERO = 'Total Budget Amount can never be zero, BP Amount should always be present.';
const BP_AMOUNT_CANNOT_CHANGE = 'BP Amount cannot be changed during post approval checkin.';
const PARTNER_AMOUNT_CANNOT_CHANGE = 'Individual Partner\'s Amounts cannot be changed during post approval checkin.';

const DIFF_USER = 'The person who checked out the budget must be the one to check it back in.';
const NOT_ALLOWED = 'You do not have the permission to perform this action.';
const RECTIFY_HEADER = 'Please rectify the below errors.';
const INVALID_FILE = 'Invalid Budget file, Checkin file is not same as Checkout file.';
const WORKSHEETS_NOT_FOUND = ' - Worksheets not found in the uploaded Budget file. ';
const CONFIRM_HEADER = 'Are you sure? ';
const RESET_WARNING = 'Going back will restart the check in process.';
const GENERIC_CHECKIN_FAIL_HEADER = 'Check In Failed';
const TYPE_OF_WORK_PAYEE_VALIDATION = ' Payee and/or Type of Work should be same for all related budget rows';
const BUDGETED_INITIATIVE = 'Budgeted Initiative';
const AMENDMENT_INITIATIVE = 'Amendment';

export default class ImCheckinBudget extends NavigationMixin(LightningElement) {
	//Variables
	_recordId;

	//TotalAmounts
	totalBpMoney = 0;
	totalNewBpMoney = 0;
	totalGatesMoney = 0;
	totalNewGatesMoney = 0;
	totalAgerupMoney = 0;
	totalNewAgerupMoney = 0;
	totalDfatMoney = 0;
	totalNewDfatMoney = 0;

	//Strings
	budgetFileDocId;
	currentStep = '1';
	checkinBudgetLabel = CHECKIN_BUDGET_LABEL;
	uploadTitle = UPLOAD_TITLE;
	step1Label = STEP1LABEL;
	step2Label = STEP2LABEL;
	step3Label = STEP3LABEL;
	rectifyErros = RECTIFY_HEADER;
	budgetParamWksheet = BUDGET_PARAM_TAB; // used on UI
	budgetWksheet = BUDGET_TAB; // used on UI

	//Booleans
	isPrevDisabled = true;
	showSpinner = false;
	hardStop = false;
	hasErrors = false;
	showUploadBudget = true;
	showValidations = false;
	showConfirmData = false;
	showConfirmPartners = false;
	isSaveDisabled = true;
	isCreateNewDisabled = true;
	navigate = false;
	isPostApprovalCheckin = false;
	@track isBudgetDataValid = true;
	@track messages = [];
	@track uniqueOrgs = [];
	fileVersionId;

	@track validations = [
		{
			'Name': 'File Validation',
			'helpText': 'Checks if the file is same as checkout file',
			'variant': 'base-autocomplete',
			'pillClass': 'pill',
			'progressValue': 0,
		},
		{
			'Name': 'Columns Validation',
			'helpText': 'Checks if checkin file has proper columns in Bugdet Param Or Budget sheet as per Budget configuration',
			'active-step': 'expired',
			'pillClass': 'pill',
			'progressValue': 0,
		},
		{
			'Name': 'Data Validation',
			'helpText': 'Checks if data is valid as per Budget configuration',
			'variant': 'active-step',
			'pillClass': 'pill',
			'progressValue': 0,
		},
	];

	//Budget parameter
	budParamErrorsArray = [];
	currentBudgetParamColumns = [];
	missingDataForBudParamCols = [];
	paramDataMap = new Map();
	partnersDataMap = new Map();
	uniqueOrgList = new Set();

	//Budget
	budgetErrorsArray = [];
	currentBudgetColumns = [];
	missingDataForBudgetCols = [];
	budgetRowsRecords = [];

	//Budget Orgs, Geographies, Components
	geographyList = [];
	compList = [];
	subCompList = [];
	compSubCompMap = new Map();
	yearsDataRow = [];
	partnerList = [];
	subPartnerList = [];
	payeeList = [];

	//Missing Amount Rows
	missingAmountsRow = [];

	//JSON Objects
	templateMetadata;
	partnerUniqueIdentifierMap = new Map();

	//Budget Parameter
	budgetParamColumnMapping;
	budgetParamHeaderIndex;
	budgetParamDataRowIndex;
	budgetParamMaxRowIndex;

	//Budget
	budgetColumnMapping;
	budgetHeaderIndex;
	budgetDataRowIndex;
	budgetPeriodColumnMapping;
	budgetMaxRowIndex;
	//JSON Objects

	//Budget Rec
	budgetRecord;

	//Budget Term Integer
	budgetTerm;

	displayInfo = {
		primaryField: "Name",
		additionalFields: ["AKA__c"],
	};

	matchingInfo = {
		primaryField: { fieldPath: "Name", mode: "contains" },
		additionalFields: [{ fieldPath: "AKA__c" }],
	};

	@api set recordId(value) {
		this._recordId = value;
		this.getBudget();
	}

	get recordId() {
		return this._recordId;
	}

	get acceptedFormats() {
		return ['.xlsx'];
	}

	get isBudgetedInitiative() {
		return this.budgetRecord?.Initiative__r?.RecordType?.Name === BUDGETED_INITIATIVE;
	}

	get isAmendmentInitiative() {
		return this.budgetRecord?.Initiative__r?.RecordType?.Name === AMENDMENT_INITIATIVE;
	}

	shouldValidateEmptyRow() {
		if(this.isPostApprovalCheckin) {
			return !this.isBudgetDataValid && this.isAmendmentInitiative;
		}
		return true;
	}

	shouldValidateMissingAmt() {
		return !this.isPostApprovalCheckin && this.isBudgetedInitiative;
	}

	shouldValidateMissingValue() {
		return this.isBudgetedInitiative || this.isAmendmentInitiative;
	}

	/*
	Description: Connected Callback - used for loading Excel JS Library once the DOM is loaded
	Jira Story : IM-106
	*/
	async connectedCallback() {
		if (!window.regeneratorRuntime) {
			window.regeneratorRuntime = regeneratorRuntime;
		}
		this.showSpinner = true;
		this.showUploadBudget = true; //STEP 1
		Promise.all([loadScript(this, XLSX + '/unpkg/exceljs.min.js')]).then(() => {
			this.showSpinner = false;
		});
	}

	setValidationStatus(index, progressValue, message, isSuccess) {
		let self = this;
		if (progressValue < 100) {
			self.validations[index].variant = 'active-step';
			self.validations[index].pillClass = 'pill inprogress';
			self.validations[index].progressValue = progressValue;
			if (message && message.length > 0) self.messages.push(...message);
		} else if (isSuccess) {
			self.validations[index].pillClass = 'pill success';
			self.validations[index].variant = 'base-autocomplete';
			self.validations[index].progressValue = progressValue;
			if (message && message.length > 0) self.messages.push(...message);
		} else if (!isSuccess) {
			self.validations[index].pillClass = 'pill error';
			self.validations[index].variant = 'expired';
			self.validations[index].progressValue = progressValue;
			self.isSaveDisabled = true;
			self.showSpinner = false;
			if (message && message.length > 0) self.messages.push(...message);
		}
	}

	/*
	Description: get the Budget and Check if the current user is same as the checkout user, if not then throw an error
	Jira Story : IM-106
	*/
	async getBudget() {
		try {
			//Show spinner if it is set false.
			!this.showSpinner ? (this.showSpinner = true) : (this.showSpinner = false);
			//IM-274: Check if the user access level is read, then throw an error
			const userAccess = await getUserAccessLevel({recordId: this._recordId});
			if (userAccess) {
				if (userAccess.MaxAccessLevel == 'Read') {
					this.showSpinner = false;
					this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, NOT_ALLOWED);
					this.navigate = true;
					this.navigateToRecordPage();
				} else {
					let result = await getBudget({budgetId: this.recordId});
					if (result) {
						this.budgetRecord = result.budget;
						this.budgetTerm = result.budget.Budget_Term_Years__c;
						this.showSpinner = false;
						if (result.isDiffUser) {
							this.showSpinner = false;
							this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, DIFF_USER);
							this.navigate = true;
							this.navigateToRecordPage();
						}
						//Check if we need to perform post checkin validations - Applicable only for approved budget
						if (result.isBudgetApproved) {
							this.isPostApprovalCheckin = true;
							this.getTotalAmountsByPartner();
							//get the budget rows partner totals grouped by partner to check for validation and update their respective total variables
						}
					}
				}
			}
		} catch (error) {
			this.showSpinner = false;
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' getBudget' + error);
		}
	}

	/*
	Description: get the total amounts by partner, including BP money where funding partner is empty
	Jira Story : IM-151
	*/
	async getTotalAmountsByPartner() {
		try {
			let result = await getTotalAmountsByPartner({budgetId: this.recordId});
			if (result) {
				//Capture the current approved each partner total amounts, including BP
				this.totalGatesMoney = result.totalGatesMoney ?? 0;
				this.totalAgerupMoney = result.totalAgerupMoney ?? 0;
				this.totalDfatMoney = result.totalDfatMoney ?? 0;
				this.totalBpMoney = result.totalBpMoney ?? 0;
			}
		} catch (error) {
			this.showSpinner = false;
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' getTotalAmountsByPartner' + error);
		}
	}

	/**
	 * Description : Called on uploadFinished event, when a budget file is uploaded.
	 * Jira        :  IM-51
	 */
	handleUploadFinished(event) {
		try {
			this.budgetFileDocId = event.detail.files[0].documentId;
			this.showUploadBudget = false;
			this.currentStep = '2';
			this.showValidations = true; //STEP 2
			this.isPrevDisabled = false;
			this.fileVersionId = event.detail.files[0].contentVersionId;
			this.fetchUploadedBudget();
			this.setValidationStatus(0, 25, [], false);
		} catch (error) {
			this.showSpinner = false;
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' HandleUploadFinished' + error);
		}
	}

	/*
	Description: Fetch the template data from Apex using the Contentdocument id and the budget id 
	Jira Story : IM-106
	*/
	async fetchUploadedBudget() {
		try {
			this.showSpinner = true;
			let templateWrapper = await getBudgetTemplate({budgetId: this._recordId, documentId: this.budgetFileDocId});
			this.templateMetadata = templateWrapper.metadata ? JSON.parse(templateWrapper.metadata) : '';
			if (this.templateMetadata) {
				//Term Years Object
				this.budgetPeriodColumnMapping = this.templateMetadata.Budget.PeriodColumnMapping;
				//Budget Param Objects
				this.budgetParamColumnMapping = this.templateMetadata.BudgetParameters.ColumnMapping;
				this.budgetParamHeaderIndex = this.templateMetadata.BudgetParameters.HeadersIndex;
				this.budgetParamDataRowIndex = this.templateMetadata.BudgetParameters.DataRowStartIndex;
				this.budgetParamMaxRowIndex = this.templateMetadata.BudgetParameters.MaxRowIndex;
				//Budget Objects
				this.budgetColumnMapping = this.templateMetadata.Budget.ColumnMapping;
				this.budgetHeaderIndex = this.templateMetadata.Budget.HeadersIndex;
				this.budgetDataRowIndex = this.templateMetadata.Budget.DataRowStartIndex;
				this.budgetMaxRowIndex = this.templateMetadata.Budget.MaxRowIndex;
			}
			this.blobConversion(templateWrapper.versionData);
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' fetchUploadedBudget' + error);
		}
	}

	/*
	Description: converts the budgetVersionData to blob to be used in excelJs Library
	Jira Story : IM-106
	*/
	blobConversion(budgetVersionData) {
		try {
			const binaryData = atob(budgetVersionData);
			const byteArray = new Uint8Array(binaryData.length);
			for (let i = 0; i < binaryData.length; i++) {
				byteArray[i] = binaryData.charCodeAt(i);
			}
			const blob = new Blob([byteArray], {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'});
			this.loadTemplate(blob);
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' blobConversion' + error);
		}
	}

	/**
	 * Description: Load the template file fetched into excelJS workbook instance
	 * Jira Story : IM-106
	 */
	async loadTemplate(response) {
		try {
			const reader = new FileReader();
			reader.onload = async () => {
				const arrayBuffer = reader.result;
				const ExcelJS = window.ExcelJS;
				const workbook = new ExcelJS.Workbook();
				await workbook.xlsx.load(arrayBuffer);
				//Perform Validations
				this.performValidations(workbook);
			};
			reader.readAsArrayBuffer(response);
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' loadTemplate' + error);
		}
	}

	/**
	 * Description: Perform Data Validations to make sure the uploaded file is same as checkout file and it has proper data/tab/cols
	 * Jira Story : IM-106
	 */
	performValidations(workbook) {
		try {
			let hasError = this.fileValidations(workbook);
			if (!hasError) {
				this.setValidationStatus(0, 100, [], true);
				//Perform Budget Parameters Worksheet Validations

				this.columnValidations(workbook);
				if (!this.hasErrors) this.dataValidations(workbook);
				if (this.isBudgetDataValid && !this.hasErrors) {
					this.confirmBudgetParam();
					this.showValidations = false;
					this.currentStep = '3';
					this.showConfirmData = true; //STEP 3
					this.isPrevDisabled = false;
				}
			}
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' ' + error);
		}
	}

	/**
	 * Description: Performs file validations and checks for system sheet, and tabs
	 * Jira Story : IM-106
	 */
	fileValidations(workbook) {
		let hasError = false;
		let systemSheet = workbook.getWorksheet(SYSTEM_TAB);
		if (systemSheet) {
			if (systemSheet.getRow(1).getCell(2).value != 'BP' + this._recordId) {
				hasError = true;
				this.setValidationStatus(0, 100, [INVALID_FILE], false);
			}
		} else {
			hasError = true;
			this.setValidationStatus(0, 100, [INVALID_FILE], false);
		}

		var budgetParamsWksht = workbook.getWorksheet(BUDGET_PARAM_TAB);
		if (!budgetParamsWksht) {
			hasError = true;
			this.setValidationStatus(0, 100, [BUDGET_PARAM_TAB + ' Tabs' + WORKSHEETS_NOT_FOUND], false);
		}

		var budgetWorksheet = workbook.getWorksheet(BUDGET_TAB);
		if (!budgetWorksheet) {
			hasError = true;
			this.setValidationStatus(0, 100, [BUDGET_TAB + ' Tabs' + WORKSHEETS_NOT_FOUND], false);
		}
		return hasError;
	}

	/**
	 * Description: Perform validations to make sure the uploaded file is same as checkout file and it has proper data/tab/cols
	 * Jira Story : IM-106
	 */
	columnValidations(workbook) {
		this.setValidationStatus(1, 25, [], true);
		var budgetParamsWksht = workbook.getWorksheet(BUDGET_PARAM_TAB);
		if (budgetParamsWksht) this.budgetParameterColumnValidatons(budgetParamsWksht);

		this.setValidationStatus(1, 50, [], true);
		var budgetSheet = workbook.getWorksheet(BUDGET_TAB);
		if (budgetSheet) this.budgetColumnValidatons(budgetSheet);
	}

	/**
	 * Description: Perform Budget Parameter Validations to make sure the uploaded file is same as checkout file and it has proper data/tab/cols
	 * Jira Story : IM-106
	 */
	budgetParameterColumnValidatons(budgetParamsWksht) {
		try {
			let headersRow = budgetParamsWksht.getRow(this.budgetParamHeaderIndex);
			if (this.budgetParamColumnMapping) {
				Object.keys(this.budgetParamColumnMapping).forEach((columnKey) => {
					// e.g columnKey = 'Component__c';
					let columns = this.budgetParamColumnMapping[columnKey];
					let dataColumnIndex = columns.dataColumnIndex;
					let totalColumnIndex = columns.totalColumnIndex;
					//e.g columns = {dataColumnIndex:"B" , "totalColumnIndex":"C"}
					let header = headersRow.getCell(dataColumnIndex).value;
					if (header) {
						let dataColumn = budgetParamsWksht.getColumn(dataColumnIndex);
						let totalColumn = budgetParamsWksht.getColumn(totalColumnIndex);
						let budgetOption = this.budgetRecord[columnKey];
						// check if column is not hidden and budget option is hidden(i.e false)
						if (!budgetOption) {
							if ((dataColumn && !dataColumn.hidden) || (totalColumn && !totalColumn.hidden)) {
								if (!this.budParamErrorsArray.includes(COLS_NOT_MATCHING)) {
									this.budParamErrorsArray.push(COLS_NOT_MATCHING);
								}
							}
						} else if (this.budgetRecord[columnKey]) {
							// check if column is hidden and budget option is not hidden(i.e true)
							if ((dataColumn && dataColumn.hidden) || (totalColumn && totalColumn.hidden)) {
								if (!this.budParamErrorsArray.includes(COLS_NOT_MATCHING)) {
									this.budParamErrorsArray.push(COLS_NOT_MATCHING);
								}
							} else {
								if (!this.currentBudgetParamColumns.includes(columnKey)) {
									this.currentBudgetParamColumns.push(columnKey);
								}
							}
						}
					}
				});
			}
			if (this.budParamErrorsArray.length < 1) {
				this.setValidationStatus(1, 50, [], true);
			} else {
				this.hasErrors = true;
				this.setValidationStatus(1, 50, [COLS_NOT_MATCHING], false);
			}
			//Budget Parameter Values Validations
			if (this.currentBudgetParamColumns.length > 0) {
				this.createBudgetParamerDataList(budgetParamsWksht);
			}
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, 'Budget_Param_Column_Validation' + error);
		}
	}

	/**
	 * Description: Perform Budget Validations to make sure the uploaded file is same as checkout file and it has proper data/tab/cols
	 * Jira Story : IM-106
	 */
	budgetColumnValidatons(budgetWorksheet) {
		try {
			/** e.g of column metadata
			* "Component__c": 
			{
			"columnIndex" : "B",
			"required" : true,
			"dependentReuiredColumnKey" : "",
			"BudgetParameterKey" : "",
			"enableGrantValidation" : false,
			"alwaysDisplayed" : false
			},
			*/
			let headersRow = budgetWorksheet.getRow(this.budgetHeaderIndex);
			if (this.budgetColumnMapping) {
				Object.keys(this.budgetColumnMapping).forEach((columnKey) => {
					// e.g Component__c
					if (this.budgetColumnMapping[columnKey]) {
						let columnMetadata = this.budgetColumnMapping[columnKey];
						let isBudgetOptionExist = columnKey in this.budgetRecord && this.budgetRecord[columnKey];
						let isColumnAlwaysDisplayed = columnMetadata.alwaysDisplayed;
						let header = headersRow.getCell(columnMetadata.columnIndex).value;
						if (header) {
							let col = budgetWorksheet.getColumn(columnMetadata.columnIndex);
							// e.g notes,desc column should always be displayed
							if (isColumnAlwaysDisplayed && (!col || col.hidden)) {
								if (!this.budgetErrorsArray.includes(COLS_NOT_MATCHING)) {
									this.budgetErrorsArray.push(COLS_NOT_MATCHING);
								}
							} else if (!isColumnAlwaysDisplayed) {
								// column is not hidden and Budget option is hidden
								if (col && !col.hidden && !isBudgetOptionExist && columnKey != ISLOCKED) {
									if (!this.budgetErrorsArray.includes(COLS_NOT_MATCHING)) {
										this.budgetErrorsArray.push(COLS_NOT_MATCHING);
									}
								} else if (isBudgetOptionExist) {
									if (!col || col.hidden) {
										if (!this.budgetErrorsArray.includes(COLS_NOT_MATCHING)) {
											this.budgetErrorsArray.push(COLS_NOT_MATCHING);
										}
									} else {
										if (!this.currentBudgetColumns.includes(columnKey)) {
											this.currentBudgetColumns.push(columnKey);
										}
									}
								} else if(columnKey == ISLOCKED){
									this.currentBudgetColumns.push(columnKey);
								}
							} else {
								if (!this.currentBudgetColumns.includes(columnKey)) {
									this.currentBudgetColumns.push(columnKey);
								}
							}
						}
					}
				});
			}
			//Budget Year Validations
			this.budgetYearColumnValidations(budgetWorksheet, headersRow);
			if (this.budgetErrorsArray.length < 1) {
				this.setValidationStatus(1, 100, [], true);
			} else {
				this.hasErrors = true;
				this.setValidationStatus(1, 100, [COLS_NOT_MATCHING], false);
			}
			//Budget Values Validations
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, 'Budget_Column_Validations' + error);
		}
	}

	/**
	 * Description: Perform Data Validations to make sure the uploaded file has proper Budget Paramaters Data/Cols/Tab
	 * Jira Story : IM-106
	 */
	createBudgetParamerDataList(budgetParamsWksht) {
		try {
			//Check For All Rows, for each key in "currentBudgetParamColumns" if there is data or not
			this.currentBudgetParamColumns.forEach((columnKey) => {
				// e.g Component__c
				let valuesEntered = [];
				let dataColumnIndex = this.budgetParamColumnMapping[columnKey].dataColumnIndex;
				for (let rowNumber = this.budgetParamDataRowIndex; rowNumber < this.budgetParamMaxRowIndex; rowNumber++) {
					let dataRow = budgetParamsWksht.getRow(rowNumber);
					let cellValue = dataRow.getCell(dataColumnIndex).value;
					if (cellValue) {
						valuesEntered.push(cellValue?.trim());
					}
				}
				//Fill paramDataMap Map with Keys and Values
				this.paramDataMap.set(columnKey, valuesEntered);
			});
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' createBudgetParamerDataList' + error);
		}
	}

	/**
	 * Description: Perform Data Validations to make sure the uploaded file has proper Budget Data/Cols/Tab
	 * Jira Story : IM-106
	 */
	dataValidations(workbook) {
		this.setValidationStatus(2, 0, [], true);
		var budgetWorksheet = workbook.getWorksheet(BUDGET_TAB);
		try {
			let newBudgetTotal = 0;
			//Check For All Rows, for each key in "currentBudgetColumns" if there is data or not based on Total Amount Value
			for (let rowIndex = this.budgetDataRowIndex; rowIndex < this.budgetMaxRowIndex; rowIndex++) {
				let dataRow = budgetWorksheet.getRow(rowIndex);
				let totalColumnMetadata = this.budgetColumnMapping[TOTAL_AMOUNT];
				let totalAmountValue = dataRow.getCell(totalColumnMetadata.columnIndex).value;
				if (totalAmountValue.result) {
					newBudgetTotal += totalAmountValue.result;
					//If Result exists, then the formula has been evaluated and the result is non zero
					this.validateBudgetRowData(budgetWorksheet, dataRow, rowIndex, true, totalAmountValue.result);
					//It is possible that there is no Partner Fund column, hence the entire money is BP money
					if (!this.currentBudgetColumns.includes(PARTNERFUND)) {
						this.totalNewBpMoney += totalAmountValue.result;
					}
				} else {
					this.validateBudgetRowData(budgetWorksheet, dataRow, rowIndex, false, totalAmountValue.result);
				}
			}
			this.totalNewBpMoney = parseFloat(this.totalNewBpMoney.toFixed(2));
			this.totalNewGatesMoney = parseFloat(this.totalNewGatesMoney.toFixed(2));
			this.totalNewAgerupMoney = parseFloat(this.totalNewAgerupMoney.toFixed(2));
			this.totalNewDfatMoney = parseFloat(this.totalNewDfatMoney.toFixed(2));
			//Perform post approval checkin validations, now that we have total amounts computed
			if (this.isPostApprovalCheckin) {
				if (newBudgetTotal != 0) {
					newBudgetTotal = parseFloat(newBudgetTotal.toFixed(2));
					this.doTotalAmountValidations(newBudgetTotal);
				} else {
					this.hasErrors = true;
					this.setValidationStatus(2, 100, [TOTAL_AMOUNT_ZERO], false);
				}
			}
			//Handle Errors, if any
			this.handleErrors();
		} catch (error) {
			this.setValidationStatus(2, 100, [], false);
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' budgetRowsValidation' + error);
		}
	}

	/**
	 * Description: stores the budget parameters in their respective arrays
	 * Jira Story : IM-106
	 */
	async confirmBudgetParam() {
		try {
			let self = this;
			this.uniqueOrgList = new Set();
			this.paramDataMap.forEach((value, key) => {
				if (key == GEOGRAPHY) {
					this.geographyList.push(...value);
				} else if (key == COMPONENT) {
					this.compList.push(...value);
				} else if (key == SUBCOMPONENT) {
					this.subCompList.push(...value);
				} else if (key == PARTNER) {
					this.partnerList.push(...value);
					value.forEach((e) => self.uniqueOrgList.add(e));
				} else if (key == SUBPARTNER) {
					this.subPartnerList.push(...value);
					value.forEach((e) => self.uniqueOrgList.add(e));
				} else if (key == PAYEE) {
					this.payeeList.push(...value);
					value.forEach((e) => self.uniqueOrgList.add(e));
				}
			});

			this.getOrgMappings(this.uniqueOrgList);
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' confirmBudgetParam' + error);
		}
	}

	/*
	Description: get the org mappings from apex
	Jira Story : IM-106
	*/
	async getOrgMappings(orgsList) {
		let self = this;
		self.uniqueOrgs = [];
		try {
			const result = await fetchOrgMapping({orgNames: Array.from(orgsList), budgetId: this._recordId});
			if (result) {
				self.partnersDataMap = result;
				let totalMatchedPartnersCount = 0;
				self.uniqueOrgList.forEach(function (org) {
					const account = result[org];
					self.uniqueOrgs.push({
						Id: account?.Id,
						Name: org,
						AKA: account?.AKA__c ?? null,
					});
					if (result[org]) {
						totalMatchedPartnersCount++;
					}
				});
				this.showConfirmPartners = self.uniqueOrgs.length > 0;
				this.isSaveDisabled = self.uniqueOrgs.length != totalMatchedPartnersCount;
				this.isCreateNewDisabled = !this.isSaveDisabled;
			}
		} catch (error) {
			self.handleCheckinReset();
			self.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' confirmBudgetParamHelper' + error);
		}
	}

	/**
	 * Description: handle record change event from record picker
	 * Jira Story : IM-106
	 */
	async handlePartnerChange(event) {
		try {
			const recordId = event.detail.recordId;
			const rowId = event.target.dataset.id;

			let matchedOrg = this.uniqueOrgs.filter((e) => e.Name == rowId);
			if (matchedOrg.length > 0) {
				matchedOrg[0].Id = recordId;
				matchedOrg[0].AKA = null;
				if(recordId) {
					matchedOrg[0].AKA = await getAccountAKA({accountId: recordId});
				}
			}
			this.checkEnableSave();
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' handlePartnerChange' + error);
		}
	}

	/**
	 * Description: check if all selections have been made, if yes then enable the save button
	 * Jira Story : IM-106
	 */
	checkEnableSave() {
		let inputFields = this.template.querySelectorAll('lightning-record-picker');
		let isValid = true;
		for (let i = 0; i < inputFields.length; i++) {
			inputFields[i].reportValidity();
			isValid = isValid ? inputFields[i].checkValidity() : false;
		}

		this.isSaveDisabled = !isValid && this.messages.length <= 0;
		this.isCreateNewDisabled = !this.isSaveDisabled;
	}

	/**
	 * Description: Perform Data Validations to make sure the uploaded file has proper Budget Data/Cols/Tab
	 * Jira Story : IM-106
	 */
	budgetYearColumnValidations(budgetWorksheet, headersRow) {
		try {
			if (this.budgetPeriodColumnMapping) {
				Object.keys(this.budgetPeriodColumnMapping).forEach((periodColumnKey) => {
					let periodColumnMetadata = this.budgetPeriodColumnMapping[periodColumnKey];
					let columnIndex = periodColumnMetadata.columnIndex;
					let header = headersRow.getCell(columnIndex).value;
					if (header.toString().startsWith(YEAR)) {
						let col = budgetWorksheet.getColumn(columnIndex);
						const periodNumberMatch = periodColumnKey.match(/\d+/);
						if (periodNumberMatch) {
							let periodNumber = parseInt(periodNumberMatch[0]);
							if (periodNumber <= this.budgetTerm) {
								if (col.hidden) {
									if (!this.budgetErrorsArray.includes(COLS_NOT_MATCHING)) {
										this.budgetErrorsArray.push(COLS_NOT_MATCHING);
									}
								} else {
									this.yearsDataRow.push(periodColumnKey);
								}
							} else {
								if (!col.hidden) {
									if (!this.budgetErrorsArray.includes(COLS_NOT_MATCHING)) {
										this.budgetErrorsArray.push(COLS_NOT_MATCHING);
									}
								}
							}
						}
					}
				});
			}
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' budgetYearColumnValidations' + error);
		}
	}

	/*
	Description: validates the budget rows data
	Jira Story : IM-106
	*/
	validateBudgetRowData(budgetWorksheet, dataRow, rowIndex, totalAmount, totalAmountValue) {
		try {
			let headersArray = [];
			let budgetRowRecord = {}; //'sobjectType': 'IM_Budget_Row__c'
			let componentValue;
			let subComponentValue;
			let subComponentColumnExist;
			let isError;
			let self = this;
			let partner = '';
			let uniqueIdentifier = '';
			let partnerUniqueIdentifierKey = '';
			let typeOfWork = '';
			let payeeFiscalSponsor = '';
			let typeOfWorkPayeeValue = '';
			this.currentBudgetColumns.forEach((columnKey) => {
				//e.g Component__c
				let columnMetadata = this.budgetColumnMapping[columnKey];
				let columnIndex = columnMetadata.columnIndex;
				let columnValue = dataRow.getCell(columnIndex).value;
				let isColumnRequired = columnMetadata.required;
				let dependentColumnKey = columnMetadata.dependentReuiredColumnKey;
				let header = budgetWorksheet.getRow(this.budgetHeaderIndex).getCell(columnIndex).value;
				// Header Construction
				if (typeof header == 'object') {
					let objArray = header.richText;
					let headerVal = '';
					objArray.forEach((record) => {
						headerVal = headerVal + record.text.toString();
					});
					header = headerVal;
				}

				//Compute total BPMoney if the partnerFund is empty
				if (columnKey == PARTNERFUND && totalAmount) {
					if (!columnValue) {
						this.totalNewBpMoney += totalAmountValue;
					} else if (columnValue == 'Gates') {
						this.totalNewGatesMoney += totalAmountValue;
					} else if (columnValue == 'Agerup') {
						this.totalNewAgerupMoney += totalAmountValue;
					} else if (columnValue == 'DFAT') {
						this.totalNewDfatMoney += totalAmountValue;
					}
				}

				// if data present, check invalid column value
				// If data present, check for total Amount == 0
				// If Data not present for required column and total amount is not 0

				if (columnValue && typeof columnValue != 'object') {
					//Sub Partner Type has a dependent required column, it needs to be populated
					if (columnKey == SUBPARTNERTYPE) {
						let dependentColumnValue = dataRow.getCell(this.budgetColumnMapping[dependentColumnKey].columnIndex).value;
						if (!dependentColumnValue) {
							headersArray.push('Sub Partner');
							isError = true;
						}
					}
					//data present
					// Invalid Value Check
					if (typeof columnValue == 'string') columnValue = columnValue?.trim(); // to truncate white space
					//Capture Unique Identfier to construct PartnerUniqueIdentifierMap
					if (columnKey == UNIQUEIDENTIFIER) {
						uniqueIdentifier = columnValue;
					}
					//Capture Unique Identfier to construct TypeOfWorkPayeeMap
					if (columnKey == TYPEOFWORK) {
						typeOfWork = columnValue;
					}
					if (this.paramDataMap.has(columnKey)) {
						let parameterValuesForColumn = this.paramDataMap.get(columnKey);
						if (!parameterValuesForColumn.includes(columnValue)) {
							this.missingDataForBudParamCols.push(INVALID_VALUE + "'" + columnValue + "'" + NOT_PRESENT + header);
							isError = true;
						} else {
							if (columnKey == PARTNER) {
								partner = columnValue;
							}
							if (columnKey == PAYEE) {
								payeeFiscalSponsor = columnValue;
							}
						}
					}
					//check for total Amount == 0 when non-amount column data is present (budgeted pre-approval only)
					if (!totalAmount && this.shouldValidateMissingAmt()) {
						if (!this.missingAmountsRow.includes(rowIndex)) {
							this.missingAmountsRow.push(rowIndex);
						}
						isError = true;
					}
					budgetRowRecord[columnKey] = columnValue;
					if (columnKey == COMPONENT) {
						componentValue = columnValue;
					} else if (columnKey == SUBCOMPONENT) {
						subComponentValue = columnValue;
						subComponentColumnExist = true;
					}
				} else {
					if (isColumnRequired && !dependentColumnKey) {
						if (!totalAmount && rowIndex == this.budgetDataRowIndex && this.shouldValidateEmptyRow()) {
							headersArray.push(header);
							isError = true;
						}
						else if (totalAmount && this.shouldValidateMissingValue()) {
							headersArray.push(header);
							isError = true;
						}
					} else if (isColumnRequired && dependentColumnKey) {
						/*let dependentColumnValue = dataRow.getCell(this.budgetColumnMapping[dependentColumnKey].columnIndex).value;
						if (dependentColumnValue || (!totalAmount && rowIndex == this.budgetDataRowIndex)) {
							headersArray.push(header);
							isError = true;
						} 
						else if (totalAmount && this.shouldValidateMissingValue()) {
							headersArray.push(header);
							isError = true;
						}*/
						let dependentColumnValue = this.getCellValue(
							dataRow.getCell(this.budgetColumnMapping[dependentColumnKey].columnIndex)
						);
						/*if (typeof dependentColumnValue == 'string') {
							dependentColumnValue = dependentColumnValue.trim();
						}*/
						// Only require this column when its dependent column is populated
						if (
							dependentColumnValue &&
							((!totalAmount && rowIndex == this.budgetDataRowIndex && this.shouldValidateEmptyRow()) ||
								(totalAmount && this.shouldValidateMissingValue()))
						) {
							headersArray.push(header);
							isError = true;
						}
					}
				}
			});
			//set the partnerUniqueIdentifierMap and typeOfWorkPayeeValue
			if (payeeFiscalSponsor != '' && typeOfWork != '') {
				typeOfWorkPayeeValue = typeOfWork + '-' + payeeFiscalSponsor;
			}
			if (partner != '') {
				partnerUniqueIdentifierKey = partner;
				if (uniqueIdentifier != '') {
					partnerUniqueIdentifierKey = partnerUniqueIdentifierKey + '-' + uniqueIdentifier;
				}
			}
			//Set the map, if value present compare and add validation error
			if (partnerUniqueIdentifierKey != '' && typeOfWorkPayeeValue != '') {
				if (!this.partnerUniqueIdentifierMap.has(partnerUniqueIdentifierKey)) {
					this.partnerUniqueIdentifierMap.set(partnerUniqueIdentifierKey, typeOfWorkPayeeValue);
				} else {
					if (this.partnerUniqueIdentifierMap.get(partnerUniqueIdentifierKey) != typeOfWorkPayeeValue) {
						this.missingDataForBudgetCols.push('For a Grant ' + partnerUniqueIdentifierKey + TYPE_OF_WORK_PAYEE_VALIDATION);
					}
				}
			}
			if (Object.keys(budgetRowRecord).length != 0) {
				//Description and Notes
				this.yearsDataRow.forEach((year) => {
					let periodColumnMetadata = this.budgetPeriodColumnMapping[year];
					let periodCell = dataRow.getCell(periodColumnMetadata.columnIndex);
					let periodAmount = self.getCellValue(periodCell);
					budgetRowRecord[year] = periodAmount || 0;
				});

				if(this.isPostApprovalCheckin) {
					budgetRowRecord[ISLOCKED] = true;
				}
				
				this.budgetRowsRecords.push(budgetRowRecord);
				if (subComponentColumnExist) {
					this.compSubCompMap.set(componentValue + '_' + subComponentValue, {'Component': componentValue, 'SubComponent': subComponentValue});
				}
			}
			this.setValidationStatus(2, Math.floor(rowIndex / 2), [], isError);
			headersArray.length > 0 ? this.missingDataForBudgetCols.push(MISSING_VALUE + headersArray.toString() + ROW_NUMBER + rowIndex) : '';
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' Budget_Data_Validation' + error);
		}
	}

	/*
	Description: perform total amount validations based on initiative partner funding type and previous approved values on the budget
	Jira Story : IM-151
	*/
	doTotalAmountValidations(newBudgetTotal) {
		//Check for Partner Funding Type
		if (this.budgetRecord.Initiative__r?.Partner_Funding_Type__c != null) {
			if (this.budgetRecord.Initiative__r.Partner_Funding_Type__c == SUPPLEMENTAL) {
				//In this scenario, the total amounts from partners can change (increase or decrease), but make sure the BP amount remains same.
				this.bpTotalAmountValidation();
			}else if(this.budgetRecord.Initiative__r.Partner_Funding_Type__c == OFFSET){
				// IM-541: Need to check total amounts for Offset type as well
				this.totalAmountValidations(newBudgetTotal);
			}
		} else {
			this.totalAmountValidations(newBudgetTotal);
		}
	}

	/*
	Description: Check if BP money and Partner money are same in case of Offset post approval
	Jira Story : IM-541
	NOTE       : In case of Offset total budget amount remains same and in turn BP and Partner money remain same
	*/
	totalAmountValidations(newBudgetTotal) {
		if (newBudgetTotal != this.budgetRecord.Total_Budget_Amount__c) {
			this.hasErrors = true;
			this.isBudgetDataValid = false;
			this.setValidationStatus(2, 100, [TOTAL_AMOUNT_CANNOT_CHANGE], false);
		} else {
			//The individual partner total amounts cannot change and make sure the BP amount also remains the same.
			this.bpTotalAmountValidation();
			this.partnersTotalAmountValidation();
		}
	}

	/*
	Description: check if the BP total amount has changed for post approval checkin, if changed throw an error
	Jira Story : IM-151
	NOTE       : BP Money will never be zero, if a budget is approved it will always have BP Money.
	*/
	bpTotalAmountValidation() {
		if (this.totalBpMoney != this.totalNewBpMoney) {
			this.hasErrors = true;
			this.isBudgetDataValid = false;
			this.setValidationStatus(2, 100, [BP_AMOUNT_CANNOT_CHANGE], false);
		}
	}

	/*
	Description: check if the Partner total amount has changed for post approval checkin, if changed throw an error
	Jira Story : IM-151
	*/
	partnersTotalAmountValidation() {
		if (
			this.totalGatesMoney != this.totalNewGatesMoney ||
			this.totalAgerupMoney != this.totalNewAgerupMoney ||
			this.totalDfatMoney != this.totalNewDfatMoney
		) {
			this.hasErrors = true;
			this.isBudgetDataValid = false;
			this.setValidationStatus(2, 100, [PARTNER_AMOUNT_CANNOT_CHANGE], false);
		}
	}

	/*
	Description: checks if the cell is of type formula
	Jira Story : IM-106
	*/
	isFormulaCell(cell) {
		return typeof cell.value == 'object' && cell.formulaType != undefined;
	}

	/*
	Description: gets the cell value
	Jira Story : IM-106
	*/
	getCellValue(cell) {
		return this.isFormulaCell(cell) ? cell.value.result : cell.value;
	}

	/*
	Description: Handles Errors if any.
	Jira Story : IM-106
	*/
	handleErrors() {
		if (this.missingAmountsRow.length > 0) {
			this.budgetErrorsArray.push(MISSING_AMOUNT + ROW_NUMBER + this.missingAmountsRow.toString());
			this.isBudgetDataValid = false;
			this.setValidationStatus(2, 100, [MISSING_AMOUNT + ROW_NUMBER + this.missingAmountsRow.toString()], false);
		}
		if (this.missingDataForBudgetCols.length > 0) {
			this.budgetErrorsArray.push(...this.missingDataForBudgetCols);
			this.isBudgetDataValid = false;
			this.setValidationStatus(2, 100, this.missingDataForBudgetCols, false);
		}
		if (this.missingDataForBudParamCols.length > 0) {
			this.budgetErrorsArray.push(...this.missingDataForBudParamCols);
			this.isBudgetDataValid = false;
			this.setValidationStatus(2, 100, this.missingDataForBudParamCols, false);
		}
	}

	/**
	 * Description : called upon the click of Save in confirm data tab
	 * Jira        : IM-106
	 */
	async handleSave() {
		try {
			let params = new Map();
			params['Partners'] = this.formPartnerListForSave(this.partnerList);
			params['Payee'] = this.formPartnerListForSave(this.payeeList);
			params['SubPartners'] = this.formPartnerListForSave(this.subPartnerList);
			params['Components'] = this.compList;
			params['SubComponents'] = this.subCompList;
			params['Geographies'] = this.geographyList;
			params['SubComponentMapping'] = this.formComponentMapping();
			params['OrgMapping'] = this.formOrgMapping();
			params['BudgetRows'] = this.budgetRowsRecords;

			//All Budget Rows and Budget Parameters
			this.showSpinner = true;

			const saveResult = await saveBudget({budgetId: this.recordId, dataMap: params});
			if (saveResult) {
				this.updateFileStatus();
				this.navigate = true;
				getRecordNotifyChange([{recordId: this.recordId}]);
				this.navigateToRecordPage();
				this.closeModal();
			}
		} catch (error) {
			this.handleCheckinReset();
			let errorMessages = getErrorMessages(error);
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, errorMessages[0]);
		}
	}

	/*
	Description: Handles the partnerList variable formation.
	Jira Story : IM-106
	*/
	formPartnerListForSave(partners) {
		let partnerIds = [];
		let self = this;
		if (partners) {
			partners.forEach(function (p) {
				let matchedOrg = self.uniqueOrgs.filter((e) => e.Name == p);
				//IM-250: Added logic to check for the Id in partnerIds array, if it already exisits then do not push.
				if (matchedOrg.length > 0 && !partnerIds.includes(matchedOrg[0].Id)) {
					partnerIds.push(matchedOrg[0].Id + '');
				}
			});
		}

		return partnerIds;
	}

	/*
	Description: Handles component mapping formation.
	Jira Story : IM-106
	*/
	formComponentMapping() {
		let compMapping = new Map();
		let self = this;
		Array.from(this.compSubCompMap?.values()).forEach(function (c, i) {
			compMapping[c.SubComponent + '_Sub' + i] = c.Component;

			let index = self.subCompList.indexOf(c.SubComponent);
			if (index > -1) {
				self.subCompList.splice(index, 1); // Removes 1 element at index
			}
		});

		// add unused subcomponents to placeholder component
		this.subCompList.forEach(function (c, i) {
			compMapping[c] = 'TBD';
		});
		return compMapping;
	}

	/*
	Description: Handles the Org Mapping
	Jira Story : IM-106
	*/
	formOrgMapping() {
		let orgMapping = new Map();
		this.uniqueOrgs.forEach(function (c) {
			orgMapping[c.Name] = c.Id;
		});
		return orgMapping;
	}

	/**
	 * Description : called upon the click of Previous Button in modal footer
	 * Jira        : IM-106
	 */
	handlePrevious() {
		try {
			LightningConfirm.open({
				message: RESET_WARNING,
				variant: 'header',
				theme: 'warning',
				label: CONFIRM_HEADER,
			}).then((result) => {
				if (result) {
					this.handleCheckinReset();
				}
			});
		} catch (error) {
			this.handleCheckinReset();
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' handlePrevious' + error);
		}
	}

	/*
	Description: Show Success Toast Message on success
	Jira Story : IM-106
	*/
	showSuccessToast(title, displayMessage) {
		const successEvt = new ShowToastEvent({
			title: title,
			message: displayMessage,
			variant: 'success',
			mode: 'dismissable',
		});
		this.dispatchEvent(successEvt);
	}

	/*
	Description: Show Error Toast Message when error occurs
	Jira Story : IM-106
	*/
	showErrorToast(title, displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: title,
			message: displayMessage,
			variant: 'error',
			mode: 'sticky',
		});
		this.dispatchEvent(errorEvt);
	}

	/*
	Description: Navigates to the BudgetRecord Page once the Budget file is Checked in successfully.
	Jira Story : IM-106
	*/
	navigateToRecordPage() {
		if (this.navigate) {
			this.showSpinner = false;
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: this._recordId,
					objectApiName: BUDGET_OBJECT.objectApiName,
					actionName: 'view',
				},
			});
		}
	}

	/**
	 * Description : Handle Checkin Reset.
	 * Jira        :  IM-106
	 */
	handleCheckinReset() {
		try {
			//Totals
			this.totalNewGatesMoney = 0;
			this.totalNewAgerupMoney = 0;
			this.totalNewDfatMoney = 0;
			this.totalNewBpMoney = 0;
			//Generic Booleans
			this.showSpinner = false;
			this.isPrevDisabled = true;
			//Progress Related
			this.currentStep = '1';
			this.showUploadBudget = true;
			this.showValidations = false;
			this.showConfirmData = false;
			this.isSaveDisabled = true;
			//Error Booleans
			this.hasErrors = false;
			this.hasBudgetParamErrors = false;
			this.hardStop = false;
			this.isBudgetDataValid = true;
			//Generic Error Arrays
			this.geographyList = [];
			this.compList = [];
			this.subCompList = [];
			this.partnerList = [];
			this.subPartnerList = [];
			this.payeeList = [];

			//Bud Param Error Arrays
			this.budParamErrorsArray = [];
			this.currentBudgetParamColumns = [];
			this.missingDataForBudParamCols = [];
			this.missingAmountsRow = [];
			this.paramDataMap = new Map();
			this.partnersDataMap = new Map();
			this.budgetRowsRecords = [];

			//Bud Error Array
			this.budgetErrorsArray = [];
			this.currentBudgetColumns = [];
			this.missingDataForBudgetCols = [];
			this.messages = [];

			this.validations = [
				{
					'Name': 'File Validation',
					'helpText': 'Checks if the file is same as checkout file',
					'variant': 'base-autocomplete',
					'pillClass': 'pill',
					'progressValue': 0,
				},
				{
					'Name': 'Columns Validation',
					'helpText': 'Checks if checkin file has proper columns in Bugdet Param Or Budget sheet as per Budget configuration',
					'active-step': 'expired',
					'pillClass': 'pill',
					'progressValue': 0,
				},
				{
					'Name': 'Data Validation',
					'helpText': 'Checks if data is valid as per Budget configuration',
					'variant': 'active-step',
					'pillClass': 'pill',
					'progressValue': 0,
				},
			];
			//Delete Earlier Budget File
			this.deleteBudget();
		} catch (error) {
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' handleCheckinReset' + error);
		}
	}

	/*
	Description: Handles deletion of previous uploaded budget file in case of checkin reset.
	Jira Story : IM-106
	*/
	async deleteBudget() {
		try {
			if (this.budgetFileDocId) {
				let res = await deleteBudgetFile({documentId: this.budgetFileDocId});
			}
		} catch (error) {
			this.showErrorToast(GENERIC_CHECKIN_FAIL_HEADER, ' deleteBudget' + JSON.stringify(error));
		}
	}

	/*
	Description: Handles update
	Jira Story : IM-106
	*/
	async updateFileStatus() {
		const fields = {};
		fields['Id'] = this.fileVersionId;
		fields['Active__c'] = true;
		const recordInput = {fields: fields};
		//6. Invoke the method updateRecord()
		updateRecord(recordInput).then((record) => {
			//Record is updated
		});
	}

	/*
	Description: Handles the creation of new Org when clicked from UI
	Jira Story : IM-352
	*/
	handleNewOrgCreation() {
		// Navigate the user to the new account creation page
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__objectPage',
			attributes: {
				objectApiName: ACCOUNT_OBJECT.objectApiName,
				actionName: 'new',
			},
		}).then((url) => {
			window.open(url, '_blank');
		});
	}

	/*
	Description: Handles the close event
	Jira Story : IM-106
	*/
	closeModal() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}