import {LightningElement, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import {NavigationMixin} from 'lightning/navigation';
import { getErrorMessages } from 'c/utils';
import hasPushToBgivePermission from '@salesforce/customPermission/IM_Push_Grants_To_Bgive';
import hasUnlinkPermission from '@salesforce/customPermission/IM_Unlink_Grant';
import hasRefreshPermission from '@salesforce/customPermission/IM_Refresh_Grant';
import getBudgetGrant from '@salesforce/apex/IMGrantViewController.getBudgetGrant';
import getIMGrant from '@salesforce/apex/IMGrantViewController.getIMGrant';
import getNonBudgetGrant from '@salesforce/apex/IMGrantViewController.getNonBudgetGrant';
import getFiscalSponsor from '@salesforce/apex/IMGrantViewController.getFiscalSponsor';
import updateIMGrant from '@salesforce/apex/IMGrantViewController.updateIMGrant';
import updateBudgetGrant from '@salesforce/apex/IMGrantViewController.updateBudgetGrant';
import getContact from '@salesforce/apex/IMGrantViewController.getContact';
import pushToBGive from '@salesforce/apex/IMGrantViewController.pushToBGive';
import getPersonalFund from '@salesforce/apex/IMGrantViewController.getPersonalFund';
import getUSDCurrency from '@salesforce/apex/IMGrantViewController.getUSDCurrency';
import deleteIMGrant from '@salesforce/apex/IMGrantViewController.deleteIMGrant';
import getBgiveGrant from '@salesforce/apex/IMGrantViewController.getBgiveGrant';
import createRequestAmendment from '@salesforce/apex/IMGrantViewController.createRequestAmendment';
import unlinkGrant from '@salesforce/apex/IMGrantViewController.unlinkGrant';
import getPicklistValues from '@salesforce/apex/IMGrantViewController.getPicklistValues';
import getBgiveGrantURL from '@salesforce/apex/IMGrantViewController.getBgiveGrantURL';
import getAllIMGrantChildren from '@salesforce/apex/IMGrantViewController.getAllIMGrantChildren';
import getPartnerChangeDetails from '@salesforce/apex/IMGrantViewController.getPartnerChangeDetails';
import getAmendmentsByRequestId from '@salesforce/apex/IMGrantViewController.getAmendmentsByRequestId';
import getFoundationInitiative from '@salesforce/apex/IMGrantViewController.getFoundationInitiative';
import refresh from '@salesforce/apex/IMGrantViewController.refresh';
import AmendmentDetails from 'c/imAmendmentDetails';
import UnlinkGrantAction from 'c/imUnlinkGrant';
import AmountChangeConfirmation from 'c/imAmountChangeConfirmation';
import PartnerChange from 'c/imGranteeChange';

const NOT_APPLICABLE = 'Not Applicable';
const IM_MANAGED = 'IM Managed';
const BGIVE_MANAGED = 'Bgive Managed';
const YES = 'Yes';
const NO = 'No';
const SINGLE_CREATE = 'SINGLE_CREATE';
const PARTIAL_FIRST_ALLOCATION = 'PARTIAL_FIRST_ALLOCATION';
const PARTIAL_SUBSEQUENT_ALLOCATION = 'PARTIAL_SUBSEQUENT_ALLOCATION';
const OTHER = 'OTHER';
const OBJECT_NAME = 'IM_Budget__c';
const COMPLETED = 'Completed';
const DELETE_SUCCESS = 'An email to delete the corresponding request in Bgive has been sent to the Helpdesk. The request and any related records will be deleted within 24 hours.';
const DELETE_EMAIL_FAIL = 'Grant deleted successfully in BIM but failed to send email notification to the Bgive Helpdesk. Please contact Bgive Helpdesk to confirm deletion of the request in Bgive.';
const UNLINK_CONFIRM = 'Are you sure you want to unlink this grant?';
const OPEN_AMENDMENT_ERROR = 'This change requires an amendment, and an open amendment already exists for the grant. Please complete or close the existing amendment before proceeding.';
const BGIVE_MANAGED_CONFIRM = 'This is a Bgive Managed grant, please proceed to Bgive to ensure the grant is consistent with BIM.';
const BGIVE_DECREASED_AMOUNT_ERROR = 'Please adjust the payments amounts accordingly in Bgive first.';
const CONFIRM_PARTNER_CHANGE = 'Please review and update the payee on all related payments in Bgive.';

export default class ImGrantView extends NavigationMixin(LightningElement) {
	_recordId;
	_objectApiName;
	isPartnerOrgNotBlinked = false;
	isFiscalSponsorNotBlinked = false;
	isDataReceived = false;
	isDataJSONEmpty = false;
	isBgiveGrantDetails = false;
	isSingleBeforeCreation = false;
	isSingleAfterCreation = false;
	isPartialBeforeCreation = false;
	isPartialAfterCreation = false;
	isNotInBgive = false;
	isBgiveManaged = false;
	isBgiveManagedAfterCreation = false;
	isParticipatingList = false;
	isAmendment = false;
	isFund = false;
	isPaymentScheduled = false;
	hasPaymentReset = false;
	showPersonalSubfund = false;

	isSave = false;
	isPushToBgive = false;
	isUnlink = false;
	isRefresh = false;
	isChangePartner = false;

	showSpinner = false;
	isBudgetGrantView = false;
	isNonBudgetGrantView = false;
	isBudgetGrantHeader = false;
	isNonBudgetGrantHeader = false;

	selectedBgiveIMConnection;
	selectedFundedByMultiple;
	selectedProgramContact;
	selectedGrantContact;
	isProgramContactChanged = false;
	isGrantsContactChanged = false;
	selectedBgiveGrant;
	selectedIMGrant;

	initiative;
	foundation_initiatives;
	segment;
	team;
	programContact;
	grantsTeamContact;
	campaign;
	advocacy;

	budgetGrant;
	imGrant;
	nonBudgetGrant;
	dataJSON;
	grantDetails;
	paymentDetails;

	dataMap = {};
	initiativeURL;
	budgetGrantURL;
	partnerOrgURL;
	budgetGrantLabel;
	fiscalSponsor;
	fiscalSponsorOrgName;

	imGrantDetailsData;
	personalFundId;

	pushButtonLabel = 'Push to Bgive';

	isError = false;
	errorMessages = [];

	isUsdCurrency;
	usdCurrency;

	isGrantReparented = false;
	newParentGrant;

	imGrantHeader1;
	imGrantHeader2;

	startDate;
	endDate;
	selectedCurrency;
	selectedLocalAmount;
	selectedFund;
	isMarkedForPartial = false;

	bgiveGrant;
	bgiveGrantToDelete;

	amendmentDetails;

	futureAmount;
	isFutureAmount = true;

	picklistValues;
	isPushDisabled = true;
	isChangeInvalid = false;
	isFundedByInvalid = false;
	isCurrencyChanged = false;
	isFundedByChanged = false;
	isBGiveConnectionChanged = false;

	bgiveBaseUrl;

	amendmentTotalAmount;
	totalGrantChildren;
	fetchedIMGrant;

	allBudgetGrants;
	allBudgetIds;
	allBudgetOrgIds;

	inputAmountAttributes = {
		max: "9999999999.99",
		step: "0.01",
		messageWhenRangeOverflow: "Value cannot exceed 13 digits",
		messageWhenStepMismatch: "Please enter a maximum of 2 decimal places"
	}

	@api set recordId(value) {
		this._recordId = value;
	}

	get recordId() {
		return this._recordId;
	}

	@api set objectApiName(value) {
		this._objectApiName = value;
		if (this._objectApiName == 'IM_Budget_Grant__c') {
			this.isBudgetGrantHeader = true;
			this.getBudgetGrant();
		} else if (this._objectApiName == 'IM_Non_Budget_Grant__c') {
			this.getNonBudgetGrant();
		}else {
			this.getAllIMGrantChildren(this._recordId);
		}
	}

	get objectApiName() {
		return this._objectApiName;
	}

	@wire(getPicklistValues)
	picklistOptions(result) {
		const {data, error} = result;
		if (data) {
			this.picklistValues = data;
		} else if (error) {
			console.error(error);
		}
	}

	@wire(getPersonalFund)
	personalFund(result) {
		const {data, error} = result;
		if (data) {
			this.personalFundId = data;
		} else if (error) {
			console.error(error);
		}
	}

	@wire(getUSDCurrency)
	currencyData(result) {
		const {data, error} = result;
		if (data) {
			this.usdCurrency = data.Id;
		} else if (error) {
			console.error(error);
		}
	}

	handleBgiveIMConnectionChange(event) {
		this.selectedBgiveIMConnection = event.detail.data.value;
		this.getMode(event.detail.data.value, NO);
		if (this.isSingleBeforeCreation) {
			this.selectedFundedByMultiple = NO;
		}
		if (this.imGrant.Bgive_IM_Connection__c == undefined && event.detail.data.value == IM_MANAGED) {
			let isNonUSD = this.template.querySelector('c-im-budget-grant-details').getIsNonUSD();
			this.isUsdCurrency = !isNonUSD;
		}
		this.isBGiveConnectionChanged = this.selectedBgiveIMConnection != this.imGrant.Bgive_IM_Connection__c;
		this.setPushEnable();
		// Enable the push button if there is Pending Action and a valid change
		if (
			this.imGrant?.Pending_Action__c &&
			this.isPushDisabled &&
			!this.isBGiveConnectionChanged &&
			!this.isFundedByChanged &&
			!this.isCurrencyChanged &&
			this.imGrant.Bgive_IM_Connection__c !== BGIVE_MANAGED &&
			this.imGrant?.Bgive_Id__c != ''
		) {
			this.isPushDisabled = false;
		}
	}

	handleFundedByMultipleChange(event) {
		this.selectedFundedByMultiple = event.detail.data.value;
		this.isFundedByChanged = this.imGrant.Funded_By_Multiple_Initiatives__c !== this.selectedFundedByMultiple;
		if (this.imGrant.Funded_By_Multiple_Initiatives__c == YES && event.detail.data.value == NO) {
			this.isPushDisabled = true;
			this.isFundedByInvalid = true;
			this.showErrorToast('Grant cannot be changed from partial allocation to single allocation');
		} else {
			this.isFundedByInvalid = false;
			if (this.selectedBgiveIMConnection == undefined) {
				this.getMode(this.imGrant.Bgive_IM_Connection__c, event.detail.data.value);
			} else {
				this.getMode(this.selectedBgiveIMConnection, event.detail.data.value);
			}
			if (this.imGrant.Bgive_Id__c != undefined && this.imGrant.Funded_By_Multiple_Initiatives__c == NO && event.detail.data.value == YES) {
				this.isMarkedForPartial = true;
			}
			this.setPushEnable();
			// Enable the push button if there is Pending Action and a valid change
			if (
				this.imGrant?.Pending_Action__c &&
				this.isPushDisabled &&
				!this.isBGiveConnectionChanged &&
				!this.isFundedByChanged &&
				!this.isCurrencyChanged &&
				this.imGrant.Bgive_IM_Connection__c !== BGIVE_MANAGED &&
				this.imGrant?.Bgive_Id__c != ''
			) {
				this.isPushDisabled = false;
			}
		}
	}

	handleCurrencyChange() {
		let isNonUSD = this.template.querySelector('c-im-budget-grant-details').getIsNonUSD();
		this.isUsdCurrency = !isNonUSD;
		this.selectedCurrency = this.template.querySelector('c-im-budget-grant-details').getCurrency();
		this.isCurrencyChanged = this.imGrant.Currency__c !== this.selectedCurrency;
		this.setPushEnable();
		// Enable the push button if there is Pending Action and a valid change
		if (
			this.imGrant?.Pending_Action__c &&
			this.isPushDisabled &&
			!this.isBGiveConnectionChanged &&
			!this.isFundedByChanged &&
			!this.isCurrencyChanged &&
			this.imGrant.Bgive_IM_Connection__c !== BGIVE_MANAGED &&
			this.imGrant?.Bgive_Id__c != ''
		) {
			this.isPushDisabled = false;
		}
	}

	// IM-369: Method to enable/disable the Push button
	setPushEnable() {
		if (this.imGrant.Bgive_IM_Connection__c === BGIVE_MANAGED && this.imGrant?.Bgive_Id__c != '') {
			this.isPushDisabled = true;
		} else {
			if (this.isBGiveConnectionChanged && !this.isChangeInvalid && !this.isFundedByChanged && !this.isCurrencyChanged) {
				this.isPushDisabled = false;
			} else if (!this.isBGiveConnectionChanged && this.isFundedByChanged && !this.isFundedByInvalid && !this.isCurrencyChanged) {
				this.isPushDisabled = false;
			} else if (!this.isBGiveConnectionChanged && !this.isFundedByChanged && this.isCurrencyChanged) {
				this.isPushDisabled = false;
			} else if (this.isBGiveConnectionChanged && !this.isChangeInvalid && this.isFundedByChanged && !this.isFundedByInvalid && !this.isCurrencyChanged) {
				this.isPushDisabled = false;
			} else if (this.isBGiveConnectionChanged && !this.isChangeInvalid && !this.isFundedByChanged && this.isCurrencyChanged) {
				this.isPushDisabled = false;
			} else if (!this.isBGiveConnectionChanged && this.isFundedByChanged && !this.isFundedByInvalid && this.isCurrencyChanged) {
				this.isPushDisabled = false;
			} else if (this.isBGiveConnectionChanged && !this.isChangeInvalid && this.isFundedByChanged && !this.isFundedByInvalid && this.isCurrencyChanged) {
				this.isPushDisabled = false;
			} else {
				this.isPushDisabled = true;
			}
		}
	}

	handleStartDateChange(event) {
		this.startDate = event.detail.data.value;
		this.imGrant.Start_Date__c = event.detail.data.value;
	}

	handleEndDateChange(event) {
		this.endDate = event.detail.data.value;
		this.imGrant.End_Date__c = event.detail.data.value;
	}

	handleLocalAmountChange(event) {
		this.selectedLocalAmount = event.detail.data.value;
		if (this.isBgiveGrantDetails) {
			this.template.querySelector('c-im-bgive-grant-details').calculateFutureAmount(this.selectedLocalAmount);
		}
	}

	handleFundChange(event) {
		this.selectedFund = event.detail.data.value;
	}

	handleGrantRequestChange(event) {
		this.errorMessages = [];
		this.isError = false;
		if (event.detail.data.key == 'GrantRequest') {
			this.selectedBgiveGrant = event.detail.data.value;
			this.template.querySelector('c-im-budget-grant-details').setGrantRequest(this.selectedBgiveGrant);
		} else if (event.detail.data.key == 'Error') {
			this.selectedBgiveGrant = event.detail.data.value.grantRequest;
			this.template.querySelector('c-im-budget-grant-details').setGrantRequest(this.selectedBgiveGrant);
			this.errorMessages = event.detail.data.value.errors;
			this.isError = true;
			this.showErrorToast('Please fix the errors mentioned at top and try again');
		}
	}

	handleSchedulePayment() {
		this.isError = false;
		this.errorMessages = [];
		this.selectedCurrency = this.template.querySelector('c-im-budget-grant-details').getCurrency();
		this.imGrant.Currency__c = this.selectedCurrency;
		let localAmount = this.template.querySelector('c-im-budget-grant-details').getLocalAmount();
		
		this.selectedLocalAmount = localAmount;

		localAmount != undefined ? this.budgetGrant.Budget_Amount_Local__c = localAmount : this.budgetGrant.Budget_Amount_Local__c = 0;
		let imGrantData = this.template.querySelector('c-im-grant-details').grantDetails();
		this.imGrantDetailsData = JSON.parse(JSON.stringify(imGrantData));
		this.campaign = this.imGrantDetailsData.political_campaign_expenses;
		this.advocacy = this.imGrantDetailsData.lobbying_advocacy;
		let projectTitle = this.template.querySelector('c-im-grant-details').getprojectTitle();
		this.imGrant.Project_Title_Internal__c = projectTitle != undefined ? projectTitle : this.imGrant.Project_Title_Internal__c;
		let fund = this.template.querySelector('c-im-grant-details').getFund();
		this.imGrant.Fund__c = fund != null ? fund : this.imGrant.Fund__c;
		this.validateContacts('Push');
	}

	handleResetPayments() {
		this.hasPaymentReset = true;
		this.isPaymentScheduled = false;
		this.isError = false;
		this.errorMessages = [];
	}

	handleRefresh() {
		this.showSpinner = true;
		this.refreshGrant();
	}

	handleBack() {
		window.history.back();
	}

	handleUnlink() {
		this.confirmChange(UNLINK_CONFIRM, 'Unlink');
	}

	handlePartnerChange() {
		this.getPartnerChangeDetails();
	}

	handleSave() {
		this.isError = false;
		this.errorMessages = [];

		let selectedCurrency = this.template.querySelector('c-im-budget-grant-details').getCurrency();
		this.imGrant.Currency__c = selectedCurrency;
		let localAmount = this.template.querySelector('c-im-budget-grant-details').getLocalAmount();
		if (localAmount != undefined) {
			this.budgetGrant.Budget_Amount_Local__c = localAmount;
		} else {
			this.budgetGrant.Budget_Amount_Local__c = 0;
		}
		if (this.isFund) {
			this.imGrant.Fund__c = this.selectedFund;
		}
		this.budgetGrant.Confirmed_Budget_Amount_USD__c = this.budgetGrant.Budget_Amount_USD__c;
		this.budgetGrant.Confirmed_Budget_Amount_Local__c = this.budgetGrant.Budget_Amount_Local__c;
		if (this.isSingleBeforeCreation) {
			let imGrantData = this.template.querySelector('c-im-grant-details').grantDetails();
			this.imGrantDetailsData = JSON.parse(JSON.stringify(imGrantData));
			this.campaign = this.imGrantDetailsData.political_campaign_expenses;
			this.advocacy = this.imGrantDetailsData.lobbying_advocacy;
			let projectTitle = this.template.querySelector('c-im-grant-details').getprojectTitle();
			this.imGrant.Project_Title_Internal__c = projectTitle;
			let fund = this.template.querySelector('c-im-grant-details').getFund();
			this.imGrant.Fund__c = fund;
			let paymentDetails = this.template.querySelector('c-im-payment-scheduler').getPaymentRowsData(localAmount);
			this.paymentDetails = JSON.parse(JSON.stringify(paymentDetails));
			this.validateContacts('Save');
		} else {
			this.validateData('Save');
		}
	}

	handlePushToBgive() {
		this.isError = false;
		this.errorMessages = [];
		this.selectedCurrency = this.template.querySelector('c-im-budget-grant-details').getCurrency();
		this.imGrant.Currency__c = this.selectedCurrency;
		let localAmount = this.template.querySelector('c-im-budget-grant-details').getLocalAmount();
		
		this.selectedLocalAmount = localAmount;
		if (this.isSingleBeforeCreation) {
			localAmount != undefined ? this.budgetGrant.Budget_Amount_Local__c = localAmount : this.budgetGrant.Budget_Amount_Local__c = 0;
			let imGrantData = this.template.querySelector('c-im-grant-details').grantDetails();
			this.imGrantDetailsData = JSON.parse(JSON.stringify(imGrantData));
			this.campaign = this.imGrantDetailsData.political_campaign_expenses;
			this.advocacy = this.imGrantDetailsData.lobbying_advocacy;
			let projectTitle = this.template.querySelector('c-im-grant-details').getprojectTitle();
			this.imGrant.Project_Title_Internal__c = projectTitle != undefined ? projectTitle : this.imGrant.Project_Title_Internal__c;
			let fund = this.template.querySelector('c-im-grant-details').getFund();
			this.imGrant.Fund__c = fund != null ? fund : this.imGrant.Fund__c;
			let paymentDetails = this.template.querySelector('c-im-payment-scheduler').getPaymentRowsData(localAmount);
			this.paymentDetails = JSON.parse(JSON.stringify(paymentDetails));
			this.validateContacts('Push');
		} else if (this.isPartialBeforeCreation) {
			localAmount != undefined ? this.budgetGrant.Budget_Amount_Local__c = localAmount : this.budgetGrant.Budget_Amount_Local__c = 0;
			let grantRequestData = this.template.querySelector('c-im-bgive-grant-details').selectedGrantRequest();
			this.selectedBgiveGrant = JSON.parse(JSON.stringify(grantRequestData));
			this.validateData('Push');
		} else if (this.isBgiveManaged) {
			localAmount != undefined ? this.budgetGrant.Budget_Amount_Local__c = localAmount : this.budgetGrant.Budget_Amount_Local__c = 0;
			let grantRequestData = this.template.querySelector('c-im-bgive-grant-details').selectedGrantRequest();
			this.selectedBgiveGrant = JSON.parse(JSON.stringify(grantRequestData));
			this.imGrant.Start_Date__c = this.selectedBgiveGrant.grant_begins_at;
			this.imGrant.End_Date__c = this.selectedBgiveGrant.grant_closed_at;
			this.imGrant.Project_Title_Internal__c = this.selectedBgiveGrant.project_title_internal;
			this.imGrant.Bgive_Status__c = this.selectedBgiveGrant.state;
			this.imGrant.Bgive_Amount_Local__c = this.selectedBgiveGrant.amount_recommended_local;
			this.validateData('Push');
		} else if (this.isAmendment) {
			localAmount != undefined ? this.budgetGrant.Budget_Amount_Local__c = localAmount : this.budgetGrant.Budget_Amount_Local__c = 0;
			this.validateData('Push');
		} else {
			// Only check for amount change confirmation when a non USD grant has amount change through budget
			// Additiona check for USD amounts is because this logic is triggered for single after creation when marking for partial aalocation
			if(!this.isUsdCurrency && localAmount != undefined && localAmount == this.budgetGrant.Budget_Amount_Local__c && this.budgetGrant.Budget_Amount_USD__c != this.budgetGrant.Confirmed_Budget_Amount_USD__c){
				this.validateAmountChange();
			}else{
				localAmount != undefined ? this.budgetGrant.Budget_Amount_Local__c = localAmount : this.budgetGrant.Budget_Amount_Local__c = 0;
				this.validateData('Push');
			}
		}
		
	}

	// IM-529: For Non-USD Amount Grants
	async validateAmountChange() {
		const result = await AmountChangeConfirmation.open({
			size: "medium",
			description: "Confirm budget amount local change from user when they don't update it in case of Non USD grant",
			budgetGrant: this.budgetGrant,
		});
		if(result != null){
			this.selectedLocalAmount = result;
			this.budgetGrant.Budget_Amount_Local__c = this.selectedLocalAmount;
			this.template.querySelector('c-im-budget-grant-details').setLocalAmount(this.selectedLocalAmount);
			if (this.isBgiveGrantDetails) {
				this.template.querySelector('c-im-bgive-grant-details').calculateFutureAmount(this.selectedLocalAmount);
			}
			this.validateData('Push');
		}
	}

	validateContacts(eventType) {
		if (this.imGrantDetailsData.program_lead_id != null) {
			this.getProgramContact(this.imGrantDetailsData.program_lead_id, eventType);
		} else if (this.imGrantDetailsData.operations_contact != null) {
			this.getGrantContact(this.imGrantDetailsData.operations_contact, eventType);
		} else {
			if (eventType == 'Save') {
				this.validateData('Save');
			} else {
				this.validateData('Push');
			}
		}
	}

	validateData(eventType) {
		this.validateCurrency();
		this.validateLocalAmount();
		this.validateBgiveIMConnection();
		this.validateFundedByMultiple();

		if (this.isSingleBeforeCreation) {
			this.validateProgramContact(eventType);
			this.validateGrantContact(eventType);
			if(this.isPaymentScheduled){
			this.validatePayments(eventType);
			}
			if (eventType == 'Push') {
				//IM-296: Allow Grant Save even when partner is not B-Linked
				this.validatePartnerOrg();
				this.validateFiscalSponsor();
				this.validateDataJSON();
			}
		} else if (this.isPartialBeforeCreation && eventType == 'Push') {
			this.validateBgiveGrant();
		} else if (this.isBgiveManaged && eventType == 'Push') {
			if (this.imGrant.Bgive_Id__c == null || this.imGrant.Bgive_Id__c == '' || this.imGrant.Bgive_Id__c == undefined) {
				this.validateBgiveGrant();
			}
		}
		if (eventType == 'Push') {
			if(this.isSingleBeforeCreation && this.isPaymentScheduled){
				this.getFoundationInitiative(eventType);
			} else if(this.isSingleBeforeCreation && !this.isPaymentScheduled && !this.isError){
				this.showPersonalSubfund = this.selectedFund == this.personalFundId && (this.campaign == YES || this.advocacy == YES);
				this.isPaymentScheduled = true;
			} 
			if(!this.isSingleBeforeCreation){
			this.updateIMGrantDetails('Push');
			}
		} else {
			this.updateIMGrantDetails('Save');
		}
	}

	// IM-346: Currency required while pushing to Bgive
	validateCurrency() {
		if (this.selectedCurrency == null || this.selectedCurrency == undefined) {
			this.isError = true;
			this.errorMessages.push('Please select Currency before pushing to Bgive.');
		}
	}

	validateLocalAmount() {
		let localAmount = this.template.querySelector('c-im-budget-grant-details').getLocalAmount();
		if (this.budgetGrant.Budget_Amount_USD__c != 0 && !this.isUsdCurrency && (localAmount == 0 || localAmount == '' || localAmount == undefined)) {
			this.isError = true;
			this.errorMessages.push('Local Amount should be provided for non USD currency.');
		}
	}

	validateBgiveIMConnection() {
		if (this.imGrant.Bgive_IM_Connection__c == BGIVE_MANAGED && this.selectedBgiveIMConnection == IM_MANAGED) {
			this.isError = true;
			this.errorMessages.push('Grant cannot be changed from Bgive Managed to IM Managed.');
		} else if (this.imGrant.Bgive_IM_Connection__c == BGIVE_MANAGED && this.selectedBgiveIMConnection == NOT_APPLICABLE) {
			this.isError = true;
			this.errorMessages.push('Grant cannot be changed from Bgive Managed to Not Applicable.');
		} else if (this.imGrant.Bgive_IM_Connection__c == IM_MANAGED && this.selectedBgiveIMConnection == NOT_APPLICABLE) {
			this.isError = true;
			this.errorMessages.push('Grant cannot be changed from IM Managed to Not Applicable.');
		}
	}

	validateFundedByMultiple() {
		if (this.imGrant.Funded_By_Multiple_Initiatives__c == YES && this.selectedFundedByMultiple == NO) {
			this.isError = true;
			this.errorMessages.push('Grant cannot be changed from partial allocation to single allocation.');
		}
	}


	validatePartnerOrg() {
		if (this.imGrant.Partner_Org__c == undefined || this.imGrant.Partner_Org__r.Bgive_Id__c == undefined) {
			this.isError = true;
			this.errorMessages.push('Partner Org is not B-linked. Please link and try again.');
		}
	}

	validateFiscalSponsor() {
		if (this.fiscalSponsor != null) {
			if (
				this.fiscalSponsor.Payee_Fiscal_Sponsor__c != undefined &&
				this.fiscalSponsor.Payee_Fiscal_Sponsor__r.Organization__r.Bgive_Id__c == undefined
			) {
				this.isError = true;
				this.errorMessages.push('Fiscal sponsor is not B-linked. Please link and try again.');
			}
		}
	}

	validateProgramContact(eventType) {
		if (!this.isProgramContactChanged && this.selectedProgramContact == null && eventType == 'Push') {
			this.isError = true;
			this.errorMessages.push('Please add a program contact');
		} else if (this.isProgramContactChanged && this.selectedProgramContact == null) {
			this.isError = true;
			this.errorMessages.push('Please link program contact user to a contact and try again.');
		} else if (this.selectedProgramContact != null && this.selectedProgramContact.Bgive_Id__c == undefined) {
			this.isError = true;
			this.errorMessages.push('Program Contact is not B-linked. Please link and try again.');
		}
	}

	validateGrantContact(eventType) {
		if (!this.isGrantsContactChanged && this.selectedGrantContact == null && eventType == 'Push') {
			this.isError = true;
			this.errorMessages.push('Please add a grant contact');
		} else if (this.isGrantsContactChanged && this.selectedGrantContact == null) {
			this.isError = true;
			this.errorMessages.push('Please link grant contact user to a contact and try again.');
		} else if (this.selectedGrantContact != null && this.selectedGrantContact.Bgive_Id__c == undefined) {
			this.isError = true;
			this.errorMessages.push('Grants Contact is not B-linked. Please link and try again.');
		}
	}

	validateDataJSON() {
		if (this.grantDetails['segment_id'] == null && this.imGrantDetailsData['segment_id'] == null) {
			this.isError = true;
			this.errorMessages.push('Please add Segment');
		}
		if (
			this.grantDetails['grant_agreement_required'] == '' &&
			(this.imGrantDetailsData['grant_agreement_required'] == '' || this.imGrantDetailsData['grant_agreement_required'] == undefined)
		) {
			this.isError = true;
			this.errorMessages.push('Please select Grant Agreement Required value.');
		}
		if (
			this.imGrantDetailsData['grant_agreement_required'] == 'Yes' &&
			this.grantDetails['type_of_agreement'] == '' &&
			(this.imGrantDetailsData['type_of_agreement'] == '' || this.imGrantDetailsData['type_of_agreement'] == undefined)
		) {
			this.isError = true;
			this.errorMessages.push('Please select Type of Agreement if grant agreement required is yes.');
		}
		if (this.imGrant.Project_Title_Internal__c == undefined) {
			this.isError = true;
			this.errorMessages.push('Please add Project Title (internal).');
		}
		if (this.imGrant.Fund__c == undefined) {
			this.isError = true;
			this.errorMessages.push('Please add a fund value.');
		}
	}

	validatePayments(eventType) {
		let isNonZeroAmount = false;
		let isFundEmpty = false;
		let isDateEmpty = false;
		let isPersonalSubFundEmpty = false;
		let idsToRemove = [];
		if (eventType == 'Push') {
			if (this.paymentDetails != null && this.paymentDetails.isSuccess != undefined && !this.paymentDetails.isSuccess) {
				this.isError = true;
				this.errorMessages.push(this.paymentDetails.error);
			} else if (this.paymentDetails.request_transaction.length == 0) {
				this.isError = true;
				this.errorMessages.push('Please add at least one payment before pushing to Bgive');
			}
		}

		if (this.paymentDetails.request_transaction.length != 0) {
			this.paymentDetails.request_transaction.forEach((payment) => {
				if (payment.amount_due_local == null && payment.due_at == null && payment.fund == null) {
					idsToRemove.push(payment.id);
				} else {
					if (payment.amount_due_local == null || payment.amount_due_local == 0) {
						isNonZeroAmount = true;
					}
					if (payment.fund == null) {
						isFundEmpty = true;
					}
					if (payment.due_at == null) {
						isDateEmpty = true;
					}
				}
				if(this.selectedFund === this.personalFundId && payment.personal_subfund == null && (this.campaign == YES || this.advocacy == YES)){
					isPersonalSubFundEmpty = true;
				} else if(this.selectedFund != this.personalFundId || (this.campaign === NO && this.advocacy === NO)) {
					payment.personal_subfund = null;
				}
			});
			if (isNonZeroAmount) {
				this.isError = true;
				this.errorMessages.push('Payment amount has to be Non Zero');
			}
			if (isFundEmpty) {
				this.isError = true;
				this.errorMessages.push('Fund cannot be empty. Please populate fund');
			}
			if (isDateEmpty) {
				this.isError = true;
				this.errorMessages.push('Scheduled Date cannot be empty. Please populate a Scheduled Date');
			}
			if(isPersonalSubFundEmpty){
				this.isError = true;
				this.errorMessages.push('Please select a Personal Subfund for all payments.');
			}
			this.paymentDetails.request_transaction = this.paymentDetails.request_transaction.filter((payment) => !idsToRemove.includes(payment.id));
		}
	}

	validateBgiveGrant() {
		let grantRequestCurrency = this.template.querySelector('c-im-bgive-grant-details').getGrantRequestCurrency();
		if (this.selectedBgiveGrant == null || this.selectedBgiveGrant == undefined || Object.keys(this.selectedBgiveGrant).length === 0) {
			this.isError = true;
			this.errorMessages.push('Please search for a grant before pushing to Bgive');
		} else if (grantRequestCurrency != null && this.selectedCurrency != null && this.selectedCurrency != grantRequestCurrency) {
			this.isError = true;
			this.errorMessages.push('Currencies for both grants does not match. Please change currency or select another grant');
		} else {
			let validationErrors = this.template.querySelector('c-im-bgive-grant-details').getErrors();
			let errorMessages = JSON.parse(JSON.stringify(validationErrors));
			if (errorMessages.length > 0) {
				this.isError = true;
				this.errorMessages = errorMessages;
			}
		}
	}

	// IM-579: Populate the latest foundation initiative value while pushing to bgive
	async getFoundationInitiative(eventType) {
		try {
			const result = await getFoundationInitiative({ budgetGrantId: this.budgetGrant?.Id });
			this.dataJSON.IM_Grant__c.foundation_initiatives = result.Budget__r.Initiative__c != undefined ? result.Budget__r.Initiative__r?.Foundation_Code__r?.Foundation_Code__c : '';
			this.updateIMGrantDetails('Push');
		} catch (error) {
			this.showErrorToast(error);
		}
	}

	updateIMGrantDetails(eventType) {
		if (!this.isError) {
			this.imGrant.Bgive_IM_Connection__c = this.selectedBgiveIMConnection;
			this.imGrant.Funded_By_Multiple_Initiatives__c = this.selectedFundedByMultiple;
			if (this.isSingleBeforeCreation) {
				Object.keys(this.grantDetails).forEach((key) => {
					if (this.imGrantDetailsData[key] != undefined) {
						this.grantDetails[key] = this.imGrantDetailsData[key];
					} else {
						if (eventType == 'Save') {
							// Allowing user to save without below values
							if (key == 'segment_id' || key == 'program_lead_id' || key == 'operations_contact') {
								this.grantDetails[key] = this.imGrantDetailsData[key];
							}
						}
					}
				});
				this.dataJSON.request_transaction = this.paymentDetails.request_transaction;
				this.dataJSON.totalAmountsMap = this.paymentDetails.totalAmountsMap;
				this.dataJSON.IM_Grant__c = this.grantDetails;
				this.imGrant.Data_JSON__c = JSON.stringify(this.dataJSON);
			} else if (this.isPartialBeforeCreation) {
				this.budgetGrant.IM_Grant__c = this.selectedBgiveGrant.brm_id;
				this.isGrantReparented = true;
			} else if (this.isBgiveManaged) {
				if (this.imGrant.Bgive_Id__c == null || this.imGrant.Bgive_Id__c == '' || this.imGrant.Bgive_Id__c == undefined) {
					if (this.selectedBgiveGrant.brm_id != null && this.selectedBgiveGrant.brm_id != '') {
						this.budgetGrant.IM_Grant__c = this.selectedBgiveGrant.brm_id;
						this.isGrantReparented = true;
					} else {
						this.imGrant.Bgive_Id__c = this.selectedBgiveGrant.id.toString();
						this.imGrant.Bgive_Contig_Id__c = this.selectedBgiveGrant.contig_id;
						if (this.selectedBgiveGrant.funded_by_multiple_initiatives == undefined) {
							this.imGrant.Funded_By_Multiple_Initiatives__c = 'No';
						} else {
							this.imGrant.Funded_By_Multiple_Initiatives__c = this.selectedBgiveGrant.funded_by_multiple_initiatives;
						}
					}
				}
			}
			if (eventType == 'Push' && !this.isSingleBeforeCreation && this.imGrant.Pending_Action__c && !this.isBgiveManaged) {
				if (this.isPartialBeforeCreation) {
					this.getIMGrantFromBgiveGrant(eventType, this.selectedBgiveGrant.brm_id)
				} else {
					this.getBgiveGrant(eventType, this.imGrant.Bgive_Contig_Id__c);
				}
			} else if (this.totalGrantChildren == 1 && this.imGrant.Bgive_Id__c != null && this.selectedLocalAmount == 0 && this.isBgiveManaged) {
				// Bgive Managed Zero Amount Scenario - Allow Unlink with confirmation
				this.confirmChange(UNLINK_CONFIRM, 'Unlink');
			} else {
				if(this.isBgiveManaged && this.isBgiveManagedAfterCreation){
					// Allowing to confirm amounts in IM for Bgive Managed grants after creation
					this.confirmChange(BGIVE_MANAGED_CONFIRM, 'Push');
				}else{
					this.budgetGrant.Confirmed_Budget_Amount_USD__c = this.budgetGrant.Budget_Amount_USD__c;
					this.budgetGrant.Confirmed_Budget_Amount_Local__c = this.budgetGrant.Budget_Amount_Local__c;
					this.showSpinner = true;
					this.updateIMGrant(this.imGrant, eventType);
				}
			}
		} else {
			this.showErrorToast('Please fix the errors mentioned at top and try again');
		}
	}

	async getIMGrantFromBgiveGrant(eventType, imGrantId) {
		getIMGrant({imGrantId: imGrantId, isCurrentGrant: false})
			.then((result) => {
				this.fetchedIMGrant = JSON.parse(JSON.stringify(result));
				this.getBgiveGrant(eventType, this.selectedBgiveGrant.contig_id);
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	async getBgiveGrant(eventType, grantRequestContigId) {
		getBgiveGrant({grantRequestContigId: grantRequestContigId})
			.then((result) => {
				this.bgiveGrant = JSON.parse(JSON.stringify(result));
				if (this.budgetGrant.Confirmed_Budget_Amount_Local__c == undefined) {
					this.budgetGrant.Confirmed_Budget_Amount_Local__c = 0;
				}
				// IM-549: Show options popup if the Grant is Zero amount even if its completed in bgive
				if (this.totalGrantChildren == 1 && this.imGrant.Bgive_Id__c != null && this.selectedLocalAmount == 0) {
					this.handleGetUnlinkAction();
				}else{
					if (this.bgiveGrant.state == 'closed') {
						this.isError = true;
						this.errorMessages.push('Cannot push to Bgive as the grant status is closed');
				} else if (this.bgiveGrant.granted == 0) {
						// Bgive grant is not yet approved
						let difference = this.selectedLocalAmount - this.budgetGrant.Confirmed_Budget_Amount_Local__c;
						if(this.isPartialBeforeCreation){
							this.futureAmount = this.fetchedIMGrant.Total_Amount_Local__c + difference;
						}else{
							this.futureAmount = this.imGrant.Total_Amount_Local__c + difference;
						}
						if (this.bgiveGrant.amount_recommended_local < this.futureAmount) {
							let warningMsg = 'Bgive Request Amount will be increased. Please adjust the payment amounts accordingly in Bgive after confirming. Bgive Request Id: '+this.bgiveGrant.contig_id;
							this.confirmChange(warningMsg, 'Push');
						} else if (this.bgiveGrant.amount_recommended_local > this.futureAmount) {
							let warningMsg =
								'Bgive Request Amount will be decreased. Please adjust the payment amounts accordingly in Bgive first and then confirm the change. Bgive Request Id: '+this.bgiveGrant.contig_id;
							this.confirmChange(warningMsg, 'Push');
						} else {
							this.budgetGrant.Confirmed_Budget_Amount_USD__c = this.budgetGrant.Budget_Amount_USD__c;
							this.budgetGrant.Confirmed_Budget_Amount_Local__c = this.budgetGrant.Budget_Amount_Local__c;
							this.showSpinner = true;
							this.updateIMGrant(this.imGrant, eventType);
						}
					} else {
						// Bgive grant is approved
						// check for open amendment in bgive
						if(this.isPartialBeforeCreation){
							this.checkOpenAmendments(this.bgiveGrant.id);
						}else{
							this.checkOpenAmendments(this.imGrant.Bgive_Id__c);
						}
					}
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	// IM-513: Method to check if there are any open amendments in Bgive.
	async checkOpenAmendments(requestId) {
		getAmendmentsByRequestId({requestId: requestId})
			.then((result) => {
				let requestAmendments = JSON.parse(JSON.stringify(result));
				if (requestAmendments?.length > 0) {
					// There is an open amendment
					this.isError = true;
					this.errorMessages.push(OPEN_AMENDMENT_ERROR);
				}else{
					// There is no open amendment, proceed with creating amendment in bgive
					if (this.isAmendment) {
						this.showSpinner = true;
						this.budgetGrant.Confirmed_Budget_Amount_USD__c = this.budgetGrant.Budget_Amount_USD__c;
						this.budgetGrant.Confirmed_Budget_Amount_Local__c = this.budgetGrant.Budget_Amount_Local__c;
						if (this.isPartialBeforeCreation) {
							this.createRequestAmendment(this.selectedBgiveGrant.id);
						} else {
							this.createRequestAmendment(this.imGrant.Bgive_Id__c);
						}
					} else {
							this.amendmentTotalAmount = this.template.querySelector('c-im-bgive-grant-details').getFutureAmount();
						this.isAmendment = true;
						this.handleGetAmendmentDetails();
					}
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	async confirmChange(errorMessage, eventType) {
		const result = await LightningConfirm.open({
			message: errorMessage,
			variant: 'header',
			label: 'Confirmation',
			theme: 'warning',
		});
		if (result) {
			if (eventType == 'Unlink') {
				this.showSpinner = true;
				this.unlinkGrant('Unlink');
			} else if(eventType == 'Change Partner'){
				let successMsg = 'The Partner for this grant has been updated successfully';
				this.showSuccessToast('Success', successMsg);
				this.navigateToRecordPage(this.budgetGrant.Id);
			} else {
				// Subsequent grant (in case of partial allocation)
				this.budgetGrant.Confirmed_Budget_Amount_USD__c = this.budgetGrant.Budget_Amount_USD__c;
				this.budgetGrant.Confirmed_Budget_Amount_Local__c = this.budgetGrant.Budget_Amount_Local__c;
				this.showSpinner = true;
				this.updateIMGrant(this.imGrant, eventType);
			}
		} else{
			if(eventType == 'Change Partner') {
				let successMsg = 'The Partner for this grant has been updated successfully';
				this.showSuccessToast('Success', successMsg);
				this.navigateToRecordPage(this.budgetGrant.Id);
			}
		}
	}

	// IM-519: Method to show options to user when unlinking grants in case of zero amount scenario (IM Managed)
	async handleGetUnlinkAction() {
		const result = await UnlinkGrantAction.open({
			label: 'Select Action',
			size: "medium",
			description: "Select Action for Unlink",
			imGrant: this.imGrant,
			budgetGrant: this.budgetGrant,
			bgiveBaseUrl: this.bgiveBaseUrl,
		});
		if(result === 'Decline'){
			let successMsg = 'Grant Declined Successfully'
			this.showSuccessToast('Success', successMsg);
			this.navigateToRecordPage(this.budgetGrant.Budget__c);
		} else if(result === 'Delete'){
			this.showSuccessToast('Email Sent', DELETE_SUCCESS);
			this.navigateToRecordPage(this.budgetGrant.Budget__c);
		} else if(result === 'Unlink'){
			let successMsg = 'Grant Unlinked Successfully'
			this.showSuccessToast('Success', successMsg);
			this.navigateToRecordPage(this.budgetGrant.Budget__c);
		} else if(result === 'Email Failed') {
			this.showSuccessToast('Success', DELETE_EMAIL_FAIL);
			this.navigateToRecordPage(this.budgetGrant.Budget__c);
		}
	}

	// IM-570: Method to change partner for a grant
	async changePartner() {
		const result = await PartnerChange.open({
			label: 'Change Partner',
			size: "medium",
			description: "Select New Partner for the Grant",
			imGrant: this.imGrant,
			budgetGrant: this.budgetGrant,
			allBudgetGrants: this.allBudgetGrants,
			allBudgetIds: this.allBudgetIds,
			allBudgetOrgIds: this.allBudgetOrgIds,
		});
		if(result === 'success'){
			this.confirmChange(CONFIRM_PARTNER_CHANGE, 'Change Partner');
		} else if(result === 'error'){
			this.showErrorToast('An error occurred while changing the partner. Please try again.');
			this.navigateToRecordPage(this.budgetGrant.Id);
		} 
	}

	// IM-488: Method to show Amendment Details Modal when there is a change in amount while pushing to Bgive
	async handleGetAmendmentDetails() {
		const result = await AmendmentDetails.open({
			size: "medium",
			description: "Create Amendment Details Modal",
			imGrant: this.imGrant,
			amendmentTotalAmount: this.amendmentTotalAmount
		});
		if(result === undefined || result === 'close'){
			this.isAmendment = false;
		}else{
			this.amendmentDetails = result.amendmentDetails;
			this.handlePushToBgive();
		}
	}

	async createRequestAmendment(imGrantBgiveId) {
		createRequestAmendment({
			imGrantBgiveId: imGrantBgiveId,
			amendmentDetails: this.amendmentDetails,
		})
			.then((result) => {
				let grant;
				if (this.isPartialBeforeCreation) {
					grant = JSON.parse(JSON.stringify(this.template.querySelector('c-im-bgive-grant-details').getSelectedIMGrant()));
				} else {
					grant = this.imGrant;
				}
				grant.Amendment_Bgive_Id__c = result.AmendmentBgiveID;
				grant.Amendment_Future_Amount_Local__c = result.AmendmentFutureAmountLocal;
				grant.Amendment_Future_End_Date__c = result.AmendmentFutureEndDate;
				this.updateIMGrant(grant, 'Amendment');
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	// IM-497: Method to unlink grants in case of non-zero amount scenario or zero amount Bgive Managed Grant
	// (acceptable action types are 'Decline', 'Delete' and 'Unlink')
	async unlinkGrant(actionType) {
		unlinkGrant({imGrant: this.imGrant, budgetGrant: this.budgetGrant, actionType: actionType})
			.then((result) => {
				this.showSpinner = false;
				let successMsg = 'Grant Unlinked Successfully'
				this.showSuccessToast('Success', successMsg);
				if(this.imGrant.Budget_Amount_USD__c == 0){
					// For Bgive Managed Zero Amount Grants
					this.navigateToRecordPage(this.budgetGrant.Budget__c);
				}else{
					// For Unlinking any non zero amount IM Managed Grants
					window.location.reload();
				}
			})
			.catch((error) => {
				this.showSpinner = false;
				this.showErrorToast(error);
			});
	}

	async getAllIMGrantChildren(imGrantId) {
		getAllIMGrantChildren({imGrantId: imGrantId})
			.then((result) => {
				if(this._objectApiName == 'IM_Budget_Grant__c'){
					this.totalGrantChildren = result.length;
					this.getIMGrant(imGrantId, true);
				} else if(this._objectApiName == 'IM_Non_Budget_Grant__c'){
					this.totalGrantChildren = result.length;
					this.getIMGrant(imGrantId, true);
				} else if(this._objectApiName == 'IM_Grant__c'){
					if(result.length == 1){
						this.navigateToRecordPage(result[0]);
					}else{
						this.getIMGrant(this._recordId, false);
					}
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}
    
    async getPartnerChangeDetails() {
		try {
			const result = await getPartnerChangeDetails({ imGrant: this.imGrant });
			if(result){
				if(result.isCheckedOut){
					this.showErrorToast('This grant is associated with a budget(s) that is currently checked out. Please confirm all corresponding budgets are checked in and try again.');
				}else{
					this.allBudgetGrants = JSON.parse(JSON.stringify(result.budgetGrants));
					this.allBudgetIds = JSON.parse(JSON.stringify(result.budgetIds));
					this.allBudgetOrgIds = JSON.parse(JSON.stringify(result.budgetOrgIds));
					this.changePartner();
				}
			}
		} catch (error) {
			this.showErrorToast(error);
		}
	}

	// IM-552: Method to get Non-Budget Grant
	async getNonBudgetGrant() {
		try {
			const nonBudgetGrant = await getNonBudgetGrant({
				nonBudgetGrantId: this._recordId,
			});
			this.nonBudgetGrant = JSON.parse(JSON.stringify(nonBudgetGrant));
			if(this.nonBudgetGrant){
				this.isNonBudgetGrantHeader = true;
				this.isNonBudgetGrantView = true;
				this.getAllIMGrantChildren(this.nonBudgetGrant.IM_Grant__c);


			}
		} catch (error) {
			this.showErrorToast(error);
		}
	}

	// Method to get Budget Grant
	async getBudgetGrant() {
		try {
			const budgetGrant = await getBudgetGrant({
				budgetGrantId: this._recordId,
			});
			this.budgetGrant = JSON.parse(JSON.stringify(budgetGrant));
			this.isBudgetGrantView =
				this.budgetGrant.Is_Active__c &&
				(hasPushToBgivePermission != undefined ? hasPushToBgivePermission : false) &&
				this.budgetGrant.Budget__r.Initiative__r.Status__c != COMPLETED;
			if (budgetGrant) {
				this.getFiscalSponsor(budgetGrant);
			}
		} catch (error) {
			this.showErrorToast(error);
		}
	}

	async getFiscalSponsor(budgetGrant) {
		getFiscalSponsor({budgetGrantId: budgetGrant.Id})
			.then((result) => {
				this.fiscalSponsor = JSON.parse(JSON.stringify(result));
				this.fiscalSponsorOrgName = this.fiscalSponsor?.Payee_Fiscal_Sponsor__r?.Organization__r?.Name;
				//IM-316: Show Not B-Linked if the org is not B-Linked
				let orgName = this.fiscalSponsorOrgName;
				let bgiveId = this.fiscalSponsor?.Payee_Fiscal_Sponsor__r?.Organization__r?.Bgive_Id__c;
				this.isFiscalSponsorNotBlinked = this.checkIsFiscalSponsorBlinked(orgName, bgiveId);
				this.getAllIMGrantChildren(budgetGrant.IM_Grant__c);
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	/*
    Description: Checks if the fiscal sponsor is Blinked or not, and returns a boolean
    Jira Story : IM-316
    */
	checkIsFiscalSponsorBlinked(orgName, bgiveId) {
		if (orgName != null && (bgiveId == '' || bgiveId == null)) {
			return true;
		}
		return false;
	}

	async getIMGrant(imGrantId, isCurrentGrant) {
		getIMGrant({imGrantId: imGrantId, isCurrentGrant: isCurrentGrant})
			.then((result) => {
				this.imGrant = JSON.parse(JSON.stringify(result));
				if (this.imGrant?.Bgive_IM_Connection__c === BGIVE_MANAGED && this.imGrant?.Budget_Amount_USD__c == this.imGrant?.Confirmed_Budget_Amount_USD__c) {
					this.isPushDisabled = true;
				} else {
					this.isPushDisabled = !this.imGrant?.Pending_Action__c || this.imGrant?.Pending_Action_Alert_Message__c?.includes('Partner Org');
				}
				if(hasUnlinkPermission && this.imGrant?.Bgive_Id__c && this.totalGrantChildren == 1 && this.budgetGrant?.Budget_Amount_USD__c != 0){
					this.isUnlink = true;
				}
				if(hasRefreshPermission && this.imGrant?.Bgive_Id__c != null){
					this.isRefresh = true;
				}
				if(this.imGrant?.Bgive_Id__c != null && this.imGrant?.Funded_By_Multiple_Initiatives__c == 'No'){
					this.isChangePartner = true;
				}
				if (this.isBudgetGrantHeader) {
					this.initiativeURL = '/' + this.budgetGrant.Budget__r.Initiative__c;
					this.budgetGrantURL = '/' + this.budgetGrant.Id;
					let uniqueIdentifier = this.budgetGrant.Unique_Identifier__c != undefined ? '-' + this.budgetGrant.Unique_Identifier__c : '';
					this.budgetGrantLabel = this.imGrant.Partner_Org__r.Name + uniqueIdentifier;
				} else if (this.isNonBudgetGrantHeader) {
					this.initiativeURL = '/' + this.nonBudgetGrant.Initiative__c;
					this.nonBudgetGrantURL = '/' + this.nonBudgetGrant.Id;
					this.nonBudgetGrantLabel = this.nonBudgetGrant?.IM_Grant__r?.Partner_Org__c != undefined ? this.nonBudgetGrant.IM_Grant__r.Partner_Org__r.Name : '';
				} else {
					this.partnerOrgURL = '/' + this.imGrant.Partner_Org__c;
					this.imGrantHeader1 = ' (' + this.imGrant.Amount_Term__c + ': ';
					this.imGrantHeader2 = ')';
				}
				if (this.imGrant.Data_JSON__c != undefined) {
					this.dataJSON = JSON.parse(this.imGrant.Data_JSON__c);
					this.grantDetails = this.dataJSON.IM_Grant__c;
					this.selectedCurrency = this.imGrant.Currency__c;
					if(this.dataJSON.request_transaction != undefined && this.dataJSON.request_transaction.length > 0){
						this.isPaymentScheduled = true;
					}
					this.isDataJSONEmpty = false;
				} else if (this.imGrant.Bgive_Id__c == null) {
					this.getDataJSON();
					this.grantDetails = this.dataJSON.IM_Grant__c;
					this.selectedCurrency = this.imGrant.Currency__c;
					this.imGrant.Data_JSON__c = JSON.stringify(this.dataJSON);
					this.imGrant.Start_Date__c =
						this.budgetGrant.Budget__r.Initiative__r.Start_Date__c != undefined ? this.budgetGrant.Budget__r.Initiative__r.Start_Date__c : '';
					this.imGrant.End_Date__c =
						this.budgetGrant.Budget__r.Initiative__r.End_Date__c != undefined ? this.budgetGrant.Budget__r.Initiative__r.End_Date__c : '';

					this.isDataJSONEmpty = true;
				}
				//IM-316: Show Not B-Linked if the org is not B-Linked
				if (this.imGrant?.Partner_Org__r.Bgive_Id__c == '' || this.imGrant?.Partner_Org__r.Bgive_Id__c == null) {
					this.isPartnerOrgNotBlinked = true;
				}
				this.startDate = this.imGrant.Start_Date__c;
				this.endDate = this.imGrant.End_Date__c;
				this.selectedFund = this.imGrant.Fund__c;
				this.getMode(this.imGrant.Bgive_IM_Connection__c, this.imGrant.Funded_By_Multiple_Initiatives__c);
				this.setAmountFields();
				this.getBgiveGrantURL();
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	getDataJSON() {
		let fiscalSponsor;
		let fiscalSponsorExists;
		let teamBRMId;
		if (this.fiscalSponsor != null && this.fiscalSponsor.Payee_Fiscal_Sponsor__c != undefined) {
			fiscalSponsor = this.fiscalSponsor?.Payee_Fiscal_Sponsor__r?.Organization__r?.Bgive_Id__c;
			fiscalSponsorExists = YES;
		} else {
			fiscalSponsor = '';
			fiscalSponsorExists = NO;
		}
		teamBRMId = this.budgetGrant.Budget__r.Initiative__r.Team__c != undefined ? this.budgetGrant.Budget__r.Initiative__r.Team__c : null;
		this.initiative = this.budgetGrant.Budget__r.Initiative__c != undefined ? this.budgetGrant.Budget__r.Initiative__r.Bgive_Id__c : '';
		this.foundation_initiatives =
			this.budgetGrant.Budget__r.Initiative__c != undefined ? this.budgetGrant.Budget__r.Initiative__r.Foundation_Code__r.Foundation_Code__c : '';
		this.segment = this.budgetGrant.Budget__r.Initiative__r.Segment__c != undefined ? this.budgetGrant.Budget__r.Initiative__r.Segment__c : null;
		this.programContact =
			this.budgetGrant.Budget__r.Initiative__r.Program_Contact__c != undefined ? this.budgetGrant.Budget__r.Initiative__r.Program_Contact__c : null;
		this.grantsTeamContact =
			this.budgetGrant.Budget__r.Initiative__r.Grants_Team_Contact__c != undefined
				? this.budgetGrant.Budget__r.Initiative__r.Grants_Team_Contact__c
				: null;
		this.team = this.budgetGrant.Budget__r.Initiative__r.Team__c != undefined ? this.budgetGrant.Budget__r.Initiative__r.Team__r.Bgive_Id__c : null;
		if (this.imGrant.Fund__c != undefined) {
			if (this.imGrant.Fund__c != this.personalFundId) {
				this.campaign = NO;
				this.advocacy = NO;
			} else {
				if (this.imGrant.Type_of_Work__c == 'Electoral') {
					this.campaign = YES;
				} else {
					this.campaign = NO;
				}
				if (this.imGrant.Type_of_Work__c == 'Advocacy') {
					this.advocacy = YES;
				} else {
					this.advocacy = NO;
				}
			}
		} else {
			this.campaign = NO;
			this.advocacy = NO;
		}
		this.dataJSON = {
			'IM_Grant__c': {
				'initiative_relationship': this.initiative,
				'foundation_initiatives': this.foundation_initiatives,
				'segment_id': this.segment,
				'fiscal_organization_exists': fiscalSponsorExists,
				'fiscal_organization_id': fiscalSponsor,
				'program_id': this.team,
				'program_sfid': teamBRMId,
				'model_theme_id': 'BP Grant/SPA',
				'program_lead_id': this.programContact,
				'operations_contact': this.grantsTeamContact,
				'bbg_department_on_behalf_of': '78BF - Philanthropies',
				'request_type': this.imGrant.Type_of_Work__c == 'Service Provider' ? 'Service Provider' : 'Grant',
				'state': 'Draft',
				'type_of_support': 'Mission Support',
				'grant_agreement_required': '',
				'type_of_agreement': '',
				'is_this_grant_restricted': 'Restricted',
				'political_campaign_expenses': this.campaign,
				'lobbying_advocacy': this.advocacy,
			},
			'request_transaction': null,
		};
	}

	// Method to get mode for Grant record
	getMode(bgiveIMConnection, fundedByMultiple) {
		if (this.imGrant.Bgive_IM_Connection__c == BGIVE_MANAGED && bgiveIMConnection == IM_MANAGED) {
			this.isChangeInvalid = true;
			this.showErrorToast('Grant cannot be changed from Bgive Managed to IM Managed');
		} else if (this.imGrant.Bgive_IM_Connection__c == BGIVE_MANAGED && bgiveIMConnection == NOT_APPLICABLE) {
			this.isChangeInvalid = true;
			this.showErrorToast('Grant cannot be changed from Bgive Managed to Not Applicable');
		} else if (this.imGrant.Bgive_IM_Connection__c == IM_MANAGED && bgiveIMConnection == NOT_APPLICABLE) {
			this.isChangeInvalid = true;
			this.showErrorToast('Grant cannot be changed from IM Managed to Not Applicable');
		} else if (bgiveIMConnection == undefined || bgiveIMConnection == NOT_APPLICABLE) {
			this.isBgiveManaged = false;
			this.isNotInBgive = true;
			this.isSingleBeforeCreation = false;
			this.isPartialBeforeCreation = false;
			this.isPartialAfterCreation = false;
			this.isBgiveGrantDetails = false;
			this.isPushToBgive = false;
			this.isSave = true;
			this.isChangeInvalid = false;
			if (bgiveIMConnection == NOT_APPLICABLE) {
				this.isFund = true;
			}
		} else if (bgiveIMConnection == IM_MANAGED) {
			this.isChangeInvalid = false;
			this.setModeIMManaged(fundedByMultiple);
		} else if ((bgiveIMConnection = BGIVE_MANAGED)) {
			this.isChangeInvalid = false;
			this.setModeBgiveManaged(fundedByMultiple);
		}
	}

	setModeIMManaged(fundedByMultiple) {
		this.isFund = false;
		if (this.imGrant.Bgive_Id__c == undefined && fundedByMultiple == NO) {
			this.isBgiveManaged = false;
			this.isBgiveManagedAfterCreation = false;
			this.isNotInBgive = false;
			this.isSingleBeforeCreation = true;
			this.isSingleAfterCreation = false;
			this.isPartialBeforeCreation = false;
			this.isPartialAfterCreation = false;
			this.isBgiveGrantDetails = false;
			this.isPushToBgive = true;
			this.isSave = true;
			this.pushButtonLabel = 'Push To Bgive';
		} else if (this.imGrant.Bgive_Id__c != undefined && fundedByMultiple == NO) {
			this.isBgiveManaged = false;
			this.isNotInBgive = false;
			this.isSingleBeforeCreation = false;
			this.isSingleAfterCreation = true;
			this.isPartialBeforeCreation = false;
			this.isPartialAfterCreation = false;
			this.isBgiveGrantDetails = true;
			this.isPushToBgive = true;
			this.isSave = false;
		} else if (this.imGrant.Bgive_Id__c == undefined && fundedByMultiple == YES) {
			this.isBgiveManaged = false;
			this.isNotInBgive = false;
			this.isSingleBeforeCreation = false;
			this.isSingleAfterCreation = false;
			this.isPartialBeforeCreation = true;
			this.isPartialAfterCreation = false;
			this.isBgiveGrantDetails = true;
			this.isPushToBgive = true;
			this.isSave = false;
		} else if (this.imGrant.Bgive_Id__c != undefined && fundedByMultiple == YES) {
			this.isBgiveManaged = false;
			this.isNotInBgive = false;
			this.isSingleBeforeCreation = false;
			this.isSingleAfterCreation = false;
			this.isPartialBeforeCreation = false;
			this.isPartialAfterCreation = true;
			this.isBgiveGrantDetails = true;
			this.isPushToBgive = true;
			this.isSave = false;
			this.isParticipatingList = true;
		}
	}

	setModeBgiveManaged(fundedByMultiple) {
		this.isFund = false;
		this.pushButtonLabel = 'Confirm';
		if (this.imGrant.Bgive_Id__c != undefined && fundedByMultiple == NO) {
			this.isFutureAmount = false;
			this.isBgiveManagedAfterCreation = true;
			this.isBgiveManaged = true;
			this.isNotInBgive = true;
			this.isSingleBeforeCreation = false;
			this.isSingleAfterCreation = false;
			this.isPartialBeforeCreation = false;
			this.isPartialAfterCreation = false;
			this.isBgiveGrantDetails = true;
			this.isPushToBgive = true;
			this.isSave = false;
		} else if (this.imGrant.Bgive_Id__c != undefined) {
			this.isFutureAmount = false;
			this.isBgiveManagedAfterCreation = true;
			this.isBgiveManaged = true;
			this.isNotInBgive = true;
			this.isSingleBeforeCreation = false;
			this.isSingleAfterCreation = false;
			this.isPartialBeforeCreation = false;
			this.isPartialAfterCreation = false;
			this.isBgiveGrantDetails = true;
			this.isPushToBgive = true;
			this.isSave = false;
			this.isParticipatingList = true;
		} else {
			this.isFutureAmount = false;
			this.isBgiveManaged = true;
			this.isNotInBgive = true;
			this.isSingleBeforeCreation = false;
			this.isSingleAfterCreation = false;
			this.isPartialBeforeCreation = false;
			this.isPartialAfterCreation = false;
			this.isBgiveGrantDetails = true;
			this.isPushToBgive = true;
			this.isSave = false;
		}
	}

	// IM-338: Method to set Local Amount fields on initial page load
	setAmountFields() {
		if (this.isBudgetGrantView) {
			if (this.imGrant.Currency__c != undefined) {
				this.isUsdCurrency = !(this.imGrant.Currency__c != this.usdCurrency);
				this.selectedLocalAmount = this.isUsdCurrency ? this.budgetGrant.Budget_Amount_USD__c : this.budgetGrant.Budget_Amount_Local__c;
			}
		}
	}

	/**
	 * Description: Method to get the Bgive Base URL
	 * Jira Story : IM-507
	 */
	async getBgiveGrantURL() {
		getBgiveGrantURL()
			.then((result) => {
				this.bgiveBaseUrl = result;
				// Check for Data Json field on initial load
				if(this.isDataJSONEmpty){
					this.isDataJSONEmpty = false;
					this.updateIMGrant(this.imGrant, '');
				}else{
					// Set the variable to true so that the page is rendered only after the URL is fetched
					this.isDataReceived = true;
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	async updateIMGrant(imGrant, eventType) {
		updateIMGrant({imGrant: imGrant})
			.then((result) => {
				if (!this.isDataReceived && this.dataJSON != undefined) {
					this.isDataReceived = true;
				} else {
					this.updateBudgetGrant(eventType);
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	// Method to update Budget Grant
	async updateBudgetGrant(eventType) {
		updateBudgetGrant({budgetGrant: this.budgetGrant})
			.then((result) => {
				if (eventType == 'Push') {
					if (this.isSingleBeforeCreation) {
						this.pushToBGive(this.imGrant.Id, SINGLE_CREATE);
					} else if (this.isMarkedForPartial && this.isPartialAfterCreation) {
						// they also make chg from no to yes
						this.pushToBGive(this.imGrant.Id, PARTIAL_FIRST_ALLOCATION);
					} else if (this.isPartialBeforeCreation) {
						this.pushToBGive(this.selectedBgiveGrant.brm_id, PARTIAL_SUBSEQUENT_ALLOCATION);
					} else if (this.isBgiveManaged) {
						if (this.selectedBgiveGrant != null && (this.selectedBgiveGrant.brm_id == null || this.selectedBgiveGrant.brm_id == '')) {
							this.pushToBGive(this.imGrant.Id, BGIVE_MANAGED);
						} else if (this.imGrant.Bgive_Id__c != null) {
							this.showSpinner = false;
							this.showSuccessToast('Changes are saved successfully');
							window.location.reload();
						} else {
							this.deleteIMGrant('');
						}
					} else {
						this.pushToBGive(this.imGrant.Id, OTHER);
					}
				} else if (eventType == 'Amendment') {
					if(this.isGrantReparented){
						// In case of partial allocation scenario, need to soft delete the current IM Grant
						this.deleteIMGrant(eventType);
					}else{
						this.showSpinner = false;
						this.showSuccessToast('Amendment has been created successfully in Bgive.');
						window.location.reload();
					}
				} else {
					this.showSpinner = false;
					this.dispatchEvent(
						new ShowToastEvent({
							title: 'Success',
							message: 'Details Saved Successfully',
							variant: 'success',
						})
					);
					window.location.reload();
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	// Method to push data to bgive
	async pushToBGive(imGrantId, type) {
		pushToBGive({imGrantId: imGrantId, type: type})
			.then((result) => {
				if (this.isGrantReparented) {
					this.deleteIMGrant('');
				} else if (this.isSingleBeforeCreation) {
					this.showSuccessToast('Grant Created Successfully in Bgive');
					this.showSpinner = false;
				} else if (this.isBgiveManaged && this.isBgiveManagedAfterCreation) {
					// Changes are only saved in IM in case of Bgive Managed Grants
					this.showSuccessToast('Changes are saved successfully');
					this.showSpinner = false;
				} else {
					this.showSuccessToast('Grant Synced Successfully with Bgive');
					this.showSpinner = false;
				}
				window.location.reload();
			})
			.catch((error) => {
				let errorMessages = getErrorMessages(error);
				if (errorMessages.length > 0) {
					let errorMessage = errorMessages[0];
					errorMessage = errorMessage.replace('IMGrantServiceException:[]:', '');
					errorMessage = errorMessage.replace('BGiveCalloutException:[]: BGive Callout Error :', '');
					errorMessage = errorMessage.replace('["', '');
					errorMessage = errorMessage.replace('"] ( Code : 100 )', '');
					if(errorMessage.includes('Amount recommended local')) {
						errorMessage += '. ' + BGIVE_DECREASED_AMOUNT_ERROR;
					}
					this.showErrorToast(errorMessage);
				}
				this.showSpinner = false;
			});
	}

	// Method to soft delete IM Grant in case of Partial or other scenarios
	async deleteIMGrant(eventType) {
		deleteIMGrant({imGrant: this.imGrant})
			.then((result) => {
				if (this.isBgiveManaged) {
					this.getNewParentGrant(this.selectedBgiveGrant.brm_id);
				} else if(eventType == 'Amendment'){
					this.showSpinner = false;
					this.showSuccessToast('Amendment created Successfully in Bgive');
					window.location.reload();
				}else {
					this.showSuccessToast('Grant Synced Successfully with Bgive');
					this.showSpinner = false;
					window.location.reload();
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	// Method to get selected IM Grant in case of Bgive Managed (to which we will reparent the budget grant)
	async getNewParentGrant(parentId) {
		getIMGrant({imGrantId: parentId, isCurrentGrant: false})
			.then((result) => {
				this.newParentGrant = JSON.parse(JSON.stringify(result));
				this.newParentGrant.Funded_By_Multiple_Initiatives__c = this.selectedBgiveGrant.funded_by_multiple_initiatives;
				this.updateParentIMGrant();
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	// Updating the parent IM Grant's Funded By field with data from current bgive grant
	async updateParentIMGrant() {
		updateIMGrant({imGrant: this.newParentGrant})
			.then(() => {
				this.showSuccessToast('Grant Synced Successfully with Bgive');
				this.showSpinner = false;
				window.location.reload();
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	async getProgramContact(userId, eventType) {
		getContact({userId: userId})
			.then((result) => {
				this.selectedProgramContact = JSON.parse(JSON.stringify(result));
				this.isProgramContactChanged = true;
				if (this.imGrantDetailsData.operations_contact != null) {
					this.getGrantContact(this.imGrantDetailsData.operations_contact, eventType);
				} else {
					if (eventType == 'Save') {
						this.validateData('Save');
					} else {
						this.validateData('Push');
					}
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	async getGrantContact(userId, eventType) {
		getContact({userId: userId})
			.then((result) => {
				this.selectedGrantContact = JSON.parse(JSON.stringify(result));
				this.isGrantsContactChanged = true;
				if (eventType == 'Save') {
					this.validateData('Save');
				} else {
					this.validateData('Push');
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	async refreshGrant() {
		refresh({imGrant: this.imGrant})
			.then((result) => {
				this.showSuccessToast('Grant successfully refreshed from Bgive.');
				this.showSpinner = false;
				window.location.reload();
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	navigateToRecordPage(recordId) {
		this.showSpinner = false;
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: recordId,
				objectApiName: OBJECT_NAME,
				actionName: 'view',
			},
		});
	}

	showErrorToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: 'Error',
			message: displayMessage,
			variant: 'error',
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}

	showSuccessToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: 'Success',
			message: displayMessage,
			variant: 'success',
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}

	showSuccessToast(title, displayMessage) {
		const successEvt = new ShowToastEvent({
			title: title,
			message: displayMessage,
			variant: 'success',
			mode: 'sticky',
		});
		this.dispatchEvent(successEvt);
	}
}