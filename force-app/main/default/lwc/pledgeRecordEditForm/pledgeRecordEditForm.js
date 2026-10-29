import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { publish, createMessageContext } from 'lightning/messageService';
import SAMPLEMC from '@salesforce/messageChannel/PledgePageRefresh__c';
import saveChildRecords from '@salesforce/apex/PledgeRecordEditFormController.createChildRecords';
import getFERecId from '@salesforce/apex/PledgeRecordEditFormController.getParentIds';
import getchildRecords from '@salesforce/apex/PledgeRecordEditFormController.getPledgeChilds';
import hasOutstandingPrimaryPledge from '@salesforce/apex/PledgeRecordEditFormController.hasOutstandingPrimaryPledge';
import UserId from '@salesforce/user/Id';

const FIELDS = ['Pledge__c.Pledge_Type__c', 'Pledge__c.Pledge_Type_Details__c', 'Pledge__c.Status__c',
				'Pledge__c.Organization__c', 'Pledge__c.Tier__c', 'Pledge__c.Payments_NOT_Tracked__c',
				'Pledge__c.Fundraising_Mode__c', 'Pledge__c.Fundraising_Effort__c', 'Pledge__c.Pledge_Amount__c',
				'Pledge__c.Total_Number_of_Payments__c', 'Pledge__c.Report_Amount_USD__c', 'Pledge__c.Pledge_Currency__c'];

export default class PledgeRecordEditForm extends NavigationMixin(LightningElement) {
	@api recordId;
	@api parentRecordId;
	@api objectApiName;
	@api benefitsData = [];
	@track opps = [];
	@track donorsData = [];
	@track PaymentNotTracked;
	@track pledgeAmount;
	adddonor;
	pledgeamountRequired = false;
	pledgedetailsRequired = false;
	isQuickAction = false;
	currentpledgeStatus;
	pledgeRecordId;
	pledTypKind = true;
	isRead = true;
	isEdit = false;
	showListLookup = false;
	selectedIds;
	selectedIdsMap = new Map();
	selectedRecords = [];
	context = createMessageContext();
	header;
	fieldLabel;
	donorType;
	tierRecordId;
	ReciRecId;
	FModeRecId;
	FEId;
	FECurr;
	paymentSchedule;
	paymentNotScheduled;
	currentRecordId;
	isRecordID;
	numberOfpledgePayments;
	pledgeReportAmount;
	pledgeCurrency;
	isParentRequired = true;
	modeRequired = true;
	orgRequired = true;
	orgDisplayFields = ['Search_Display_Name__c', 'Computed_AKA__c', 'Legal_Name__c', 'Website'];
	orgSearchFields = ['Search_Display_Name__c'];
	pledgeAmountValidate = false;
	pledgeAmountClicked = 0;
	activeSections = ['A', 'B', 'C', 'D', 'E', 'F'];
	PledgeStatus = ['Pledged'];
	benefitsColumns;
	donorsColumns;
	upserDonorRecords = [];
	upserBeniftRecords = [];
	delDonorD = [];
	isLoading = false;
	schedulevalue;
	pledgeValue;
	pledgeValueUSD;
	pledgeValueUSD1;
	outstandingOverrideAck = false;
	outstandingOverrideKey = null;
	warnedDonorKey = null;

	get containerClass() {
		return this.isQuickAction
			   ? 'slds-m-top_small slds-m-bottom_small pledge-wide-container'
			   : 'slds-m-top_x-large slds-m-bottom_x-large slds-m-left_x-large slds-m-right_x-large';
	}

	get reciRecDefaultIds() {
		return this.ReciRecId ? [this.ReciRecId] : [];
	}

	get recipientOrgFilterClause() {
		return this.FEId ? `Id IN (SELECT Organization__c FROM Recipient_Organization__c WHERE Fundraising_Project__c = '${this.FEId}')` : '';
	}

	@wire(CurrentPageReference)
	pageRef(ref) {
		if(ref && ref.type === 'standard__quickAction') {
			this.isQuickAction = true;
		}
		if(ref && ref.state && ref.state.recordId) {
			const idPrefix = ref.state.recordId.substring(0, 3);
			if(idPrefix === '003' || idPrefix === '001') {
				this.sourceRecordId = ref.state.recordId;
				this.objectApiName = idPrefix === '003' ? 'Contact' : 'Account';
				this.initDonorFromSource();
			}
		}
	}

	connectedCallback() {
		this.pledgeRecordId = this.recordId;
		this.header = this.recordId ? 'Edit Ask/Pledge' : 'New Ask/Pledge';
		this.isRecordID = this.recordId ? false : true;
		this.currUerId = UserId;
		if(this.recordId) {
			this.isLoading = true;
			this.currentRecordId = this.recordId;
			this.getDonorsBenefits(this.recordId);
		}
		if(this.parentRecordId != null && this.parentRecordId != undefined && this.parentRecordId != '') {
			this.getParentRecord();
		}
		this.addColumns();
	}

	initDonorFromSource() {
		const isContact = this.objectApiName === 'Contact';
		const newRow = {
			Donor_Type__c: isContact ? 'Contact' : 'Organization',
			Credit_Type__c: 'Donor - Primary',
			Contact__c: isContact ? this.sourceRecordId : null,
			Organization__c: isContact ? null : this.sourceRecordId,
			isShowContact: isContact,
			benefitsDefaultIds: [],
			contactDefaultIds: isContact ? [this.sourceRecordId] : [],
			organizationDefaultIds: isContact ? [] : [this.sourceRecordId]
		};
		this.donorsData = [newRow];
	}

	addColumns() {
		this.donorsColumns = [
			{ label: 'Donor Type', fieldName: 'Donor_Type__c', required: true, isDonorTypeShow: true },
			{ label: 'Donor', fieldName: '', required: true, isvaluerest: true },
			{ label: 'Credit Type', fieldName: 'Credit_Type__c', required: false, isCreditshow: true },
			{ label: 'Donor Amount', fieldName: 'Amount__c', required: false, isvalueshow: true }
		];
		this.benefitsColumns = [
			{ label: 'Benefit', fieldName: '', required: false },
			{ label: 'Quantity', fieldName: 'Quantity__c', required: false },
			{ label: 'Listing Location', fieldName: 'Listing_Location__c', required: false },
			{ label: 'Listing Text', fieldName: 'Listing_Text__c', required: false }
		];
	}

	getParentRecord() {
		this.isLoading = true;
		getFERecId({
			recordId: this.parentRecordId
		}).then((result) => {
			this.isLoading = false;
			this.tierRecordId = result.PTId;
			this.FModeRecId = result.FEModeId;
			this.FEId = result.FEId;
			this.FECurr = result.FECurr;
			if(this.FECurr != null && this.FECurr != 'USD') {
				this.pledgeReportAmount = true;
			}
			this.ReciRecId = result.recOrgId;
			if(result.PaymentNotTracked != undefined)
				this.PaymentNotTracked = result.PaymentNotTracked;
		}).catch((error) => {
			this.isLoading = false;
			console.log('getParentId> error::: ', JSON.stringify(error));
		});
	}

	getDonorsBenefits(recordId) {
		this.isLoading = true;
		getchildRecords({
			recordId: recordId
		}).then((result) => {
			if(result) {
				this.donorsData = result.donors ? result.donors : [];
				this.benefitsData = (result.pBenefits) ? result.pBenefits : [];
				this.isLoading = false;
			}
		}).catch(error => {
			this.isLoading = false;
			console.log('get child records error >>>>>', error);
		})
	}

	@wire(getRecord, {
		recordId: '$currentRecordId',
		fields: FIELDS
	}) wiredRecord({ error, data }) {
		if(error) {
			console.log('record data error>>>', error);
		} else if(data) {
			this.currentpledgeStatus = getFieldValue(data, 'Pledge__c.Status__c');
			var donorType = getFieldValue(data, 'Pledge__c.Donor_Type__c');
			this.tierRecordId = getFieldValue(data, 'Pledge__c.Tier__c');
			this.ReciRecId = getFieldValue(data, 'Pledge__c.Organization__c');
			this.FModeRecId = getFieldValue(data, 'Pledge__c.Fundraising_Mode__c');
			this.FEId = getFieldValue(data, 'Pledge__c.Fundraising_Effort__c');
			this.FEId = getFieldValue(data, 'Pledge__c.Fundraising_Effort__c');
			this.PaymentNotTracked = getFieldValue(data, 'Pledge__c.Payments_NOT_Tracked__c');
			this.hasDonarContact = 'Contact' == donorType;
			this.hasDonarOrganization = 'Organization' == donorType;
			this.pledgeAmount = getFieldValue(data, 'Pledge__c.Pledge_Amount__c');
			this.numberOfpledgePayments = getFieldValue(data, 'Pledge__c.Total_Number_of_Payments__c');
			this.handlePaymentScheduleonload();
			this.pledgeValueUSD1 = getFieldValue(data, 'Pledge__c.Report_Amount_USD__c');
			this.pledgeCurrency = getFieldValue(data, 'Pledge__c.Pledge_Currency__c');
			if(this.pledgeCurrency != null && this.pledgeCurrency != 'USD') {
				this.pledgeReportAmount = true;
				this.pledgeValueUSD = this.pledgeValueUSD1;
			}
			this.pledgedetailsRequired = (getFieldValue(data, 'Pledge__c.Pledge_Type__c') != 'Cash') ? false : true;
			if(this.pledgeAmount == null && this.PledgeStatus.includes(this.currentpledgeStatus)) {
				this.pledgeAmountValidate = true;
				this.pledgeamountRequired = true;
			} else {
				this.pledgeamountRequired = false;
			}
		}
	}

	handleOwnerChange(event) {
		const dtype = event.detail.value;
		this.hasDonarContact = 'Contact' == dtype;
		this.hasDonarOrganization = 'Organization' == dtype;
	}

	handleFEChange(event) {
		const fEfortId = event.target.value;
		this.FEId = fEfortId;
		this.outstandingOverrideAck = false;
		this.outstandingOverrideKey = null;
		this.ReciRecId = '';
		this.FModeRecId = '';
		getFERecId({
			recordId: this.FEId
		}).then((result) => {
			this.isLoading = false;
			this.FECurr = result.FECurr;
			this.ReciRecId = result.recOrgId;
			this.FModeRecId = result.FEModeId;
			if(this.FECurr != null && this.FECurr != 'USD') {
				this.pledgeReportAmount = true;
			}
		}).catch((error) => {
			this.isLoading = false;
			console.log('getParentId> error::: ', JSON.stringify(error));
		});
	}

	handlePledgeType(event) {
		const pledgeTye = event.target.value;
		this.pledgedetailsRequired = false;
		this.pledTypKind = pledgeTye == 'In-Kind' ? false : true;
	}

	handlePledgeAmount(event) {
		const pledgeVal = event.target.value;
		this.pledgeAmount = pledgeVal;
		const donorCmp = this.template.querySelector('c-add-pledge-donors-benefites');
		if(donorCmp && typeof donorCmp.updateAllAmounts === 'function') {
			donorCmp.updateAllAmounts(pledgeVal);
		}
		this.pledgeValue = (pledgeVal > 0);
		if(this.numberOfpledgePayments > 0 || (this.recordId && this.PaymentNotTracked)) {
			this.paymentNotScheduled = false;
		} else if(this.pledgeAmount > 0 && !this.PaymentNotTracked) {
			this.paymentNotScheduled = this.pledgeValue;
		} else {
			this.paymentNotScheduled = false;
		}
		this.pledgeamountRequired = ((this.pledgeAmount == null || this.pledgeAmount == "") &&
		 						     this.PledgeStatus.includes(this.currentpledgeStatus));
	}

	handlePaymentScheduleonload() {
		if(this.numberOfpledgePayments == 0 && this.pledgeAmount > 0) {
			this.paymentNotScheduled = true;
		}
	}

	handlePaymentSchedule(event) {
		const paymentSchedule = event.target.value;
		this.PaymentNotTracked = event.target.value;
		this.schedulevalue = (!paymentSchedule) ? true : false;
		this.paymentNotScheduled = this.schedulevalue;
		if(this.numberOfpledgePayments > 0 && paymentSchedule && paymentSchedule == 0) {
			this.paymentNotScheduled = false;
		} else if(this.pledgeAmount > 0 && !this.PaymentNotTracked && this.numberOfpledgePayments == 0) {
			this.paymentNotScheduled = true;
		}
		if(this.numberOfpledgePayments > 0) {
			this.paymentNotScheduled = false;
		}
	}

	handlePledgeReport(event) {
		this.pledgeCurrency = event.target.value;
		if(this.pledgeCurrency != 'USD') {
			this.pledgeReportAmount = true;
			this.pledgeValueUSD = this.pledgeValueUSD1;
		} else {
			this.pledgeReportAmount = false;
			this.pledgeValueUSD = this.pledgeAmount;
		}
	}

	handleCancel() {
		if(this.recordId) {
			this.handleNavigate(this.recordId);
		} else if(this.parentRecordId) {
			this.handleNavigate(this.parentRecordId);
		} else {
			this.handleListViewNavigation();
		}
	}

	handleMandatory(event) {
		event.preventDefault();
		const statusPledge = event.target.value;
		if(!this.PledgeStatus.includes(statusPledge)) {
			this.pledgeamountRequired = false;
		}
		if(this.pledgeAmount == null && this.PledgeStatus.includes(statusPledge)) {
			this.pledgeAmountValidate = true;
			this.pledgeamountRequired = true;
		} else {
			this.pledgeamountRequired = false;
		}
	}

	handleSubmit(event) {
		event.preventDefault();
		let deleteDonordata = [];
		const donorCmp = this.template.querySelector("c-add-pledge-donors-benefites");
		const benefitCmp = this.template.querySelector(".benefitClass");
		const isrowdeleted = donorCmp ? donorCmp.handleDnordelete() : null;
		const isrowdeletedben = benefitCmp ? benefitCmp.handleDnordelete() : null;
		if(isrowdeleted) {
			isrowdeleted.forEach(d => { if(d) deleteDonordata.push.apply(deleteDonordata, d); });
		}
		if(isrowdeletedben) {
			isrowdeletedben.forEach(d => { if(d) deleteDonordata.push.apply(deleteDonordata, d); });
		}
		this.delDonorD = deleteDonordata;
		const fields = event.detail.fields;
		let hasValid = true;
		let hasValidrecp = true;
		const appealCmp = this.template.querySelector("c-custom-single-select-lookup-lwc");
		if(appealCmp && typeof appealCmp.isValidAppeal === 'function') {
			hasValid = appealCmp.isValidAppeal();
			if(!hasValid) {
				this.dispatchEvent(new ShowToastEvent({ title: 'Fill Mandatory required field', message: 'Please add Appeal.', variant: 'error' }));
			}
		}
		const recpCmp = this.template.querySelector("c-organization-custom-look-up");
		if(recpCmp && typeof recpCmp.isValidRecp === 'function') {
			hasValidrecp = recpCmp.isValidRecp();
			if(!hasValidrecp) {
				this.dispatchEvent(new ShowToastEvent({ title: 'Fill Mandatory required field', message: 'Please add Recipient Organization.', variant: 'error' }));
			}
		}
		let isamountValid = true;
		if(donorCmp && typeof donorCmp.validAmountCheck === 'function') {
			const totalPrimary = donorCmp.validAmountCheck();
			if(Number(totalPrimary) !== Number(fields.Pledge_Amount__c)) {
				isamountValid = false;
				this.dispatchEvent(new ShowToastEvent({ title: '', message: 'Primary Donor Amounts need to equal the Pledge Amount.', variant: 'error' }));
			}
		}
		let hasPledgeAmount;
		if((fields.Pledge_Amount__c == null) && this.PledgeStatus.includes(fields.Status__c)) {
			hasPledgeAmount = false;
			this.pledgeAmountValidate = true;
			this.pledgeamountRequired = true;
			this.dispatchEvent(new ShowToastEvent({ title: 'Pledge Amount Required', message: 'Please fill Pledge Amount.', variant: 'error' }));
		} else if((!this.pledgeAmount > 0 || this.pledgeAmount == null) && this.PledgeStatus.includes(fields.Status__c)) {
			hasPledgeAmount = false;
			this.pledgeamountRequired = true;
			this.pledgeAmountValidate = true;
			this.dispatchEvent(new ShowToastEvent({ title: 'Pledge Amount Required', message: 'Please fill Pledge Amount.', variant: 'error' }));
		} else {
			hasPledgeAmount = true;
			this.pledgeAmountValidate = false;
			this.pledgeAmountClicked = 0;
			this.pledgeamountRequired = false;
		}
		let isValidBenefit = true;
		let benefitsData = [];
		if(benefitCmp) {
			if(typeof benefitCmp.isValid === 'function') {
				isValidBenefit = benefitCmp.isValid();
			}
			if(isValidBenefit && typeof benefitCmp.handleSave === 'function') {
				const bData = benefitCmp.handleSave();
				if(bData) benefitsData.push.apply(benefitsData, bData);
			}
		}
		let isvalidDonor = true;
		let isValidDonorCredit = false;
		let childDonorData = [];
		const donors = this.template.querySelectorAll('.donorClass');
		if(donors && donors.length) {
			donors.forEach(d => {
				if(typeof d.isValid === 'function' && !d.isValid()) {
					isvalidDonor = false;
				}
			});
			if(donorCmp && typeof donorCmp.isValidCredit === 'function') {
				isValidDonorCredit = donorCmp.isValidCredit();
			}
			if(!isValidDonorCredit) {
				this.dispatchEvent(new ShowToastEvent({
					title: 'Fill Mandatory required field',
					message: 'Please add at least one Primary Donor.',
					variant: 'error' }));
			}
			if(isvalidDonor && isValidDonorCredit) {
				donors.forEach(d => {
					if(typeof d.handleSave === 'function') {
						childDonorData.push.apply(childDonorData, d.handleSave());
					}
				});
			}
		}
		if(childDonorData.length === 0 && isValidDonorCredit) {
			isvalidDonor = false;
			this.adddonor = true;
			this.dispatchEvent(new ShowToastEvent({
				title: 'Error creating record',
				message: 'Please add Donor.',
				variant: 'error' }));
		} else {
			this.adddonor = false;
		}
		if(!(hasPledgeAmount && isvalidDonor && isValidBenefit && hasValid && hasValidrecp && isValidDonorCredit && isamountValid)) {
			return;
		}
		this.upserDonorRecords = childDonorData;
		this.upserBeniftRecords = benefitsData;
		const proceedToSubmit = () => {
			fields.Tier__c = this.tierRecordId;
			fields.Organization__c = this.ReciRecId;
			fields.Fundraising_Mode__c = this.FModeRecId;
			if(fields.Pledge_Currency__c === 'USD') {
				fields.Report_Amount_USD__c = fields.Pledge_Amount__c;
			}
			if(fields.Status__c != 'Pledged') fields.Exclude_from_Donor_memo__c = true;
			this.template.querySelector('lightning-record-edit-form').submit(fields);
		};
		const primaryDonor = childDonorData.find(d => d.Credit_Type__c === 'Donor - Primary');
		const donorContactId = primaryDonor && primaryDonor.Contact__c ? primaryDonor.Contact__c : null;
		const donorOrgId = primaryDonor && primaryDonor.Organization__c ? primaryDonor.Organization__c : null;
		const donorKeyId = donorContactId || donorOrgId || null;
		const fundraisingEffortId = fields.Fundraising_Effort__c || this.FEId || null;
		const excludePledgeId = this.recordId;
		if(!fundraisingEffortId || !donorKeyId) {
			this.outstandingOverrideAck = false;
			this.warnedDonorKey = null;
			proceedToSubmit();
			return;
		}
		const newWarnKey = `${fundraisingEffortId}:${donorKeyId}`;
		if(this.warnedDonorKey !== newWarnKey) {
			this.outstandingOverrideAck = false;
		}
		hasOutstandingPrimaryPledge({
			fundraisingEffortId,
			donorContactId,
			donorOrgId,
			excludePledgeId
		}).then(hasOutstanding => {
			if(hasOutstanding && !this.outstandingOverrideAck) {
				this.outstandingOverrideAck = true;
				this.warnedDonorKey = newWarnKey;
				this.dispatchEvent(new ShowToastEvent({
					title: 'Warning',
					message: 'This primary donor already has another pledge with an outstanding balance in this Fundraising Project. Click Save again to continue.',
					variant: 'warning',
					mode: 'sticky'
				}));
				return;
			}
			proceedToSubmit();
		}).catch(() => {
			proceedToSubmit();
		});
		return;
	}

	handleError(event) {
		this.isLoading = false;
		const fieldErrors = event.detail.output.fieldErrors;
		const separator = ' ';
		let message = Object.values(fieldErrors).map(field => {
			return field.map(error => error.message).join(separator);
		}).join(separator);
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Error creating record',
				message: message,
				variant: 'error',
			}),
		);
	}

	handleSuccess(event) {
		const message = true;
		var savedId = event.detail.id;
		this.handlecreateChildRecords(savedId);
		this.handleNavigate(savedId);
		this.outstandingOverrideAck = false;
		this.outstandingOverrideKey = null;
	}

	handlecreateChildRecords(savedId) {
		saveChildRecords({
			recordId: savedId,
			donorsList: this.upserDonorRecords,
			benefitsList: this.upserBeniftRecords,
			delId: this.delDonorD
		}).then((result) => {
				this.isLoading = false;
				this.handleNavigate(savedId);
		}).catch((error) => {
			this.isLoading = false;
			console.log('Save records error::: ', JSON.stringify(error));
		});
	}

	handleOppsChange(event) {
		let record = event.detail;
		this.selectedIds = '';
		if(record) {
			record.forEach(record => {
				this.selectedIds += record.id + ';';
			});
		}
	}

	handleNavigate(recordId) {
		setTimeout(() => {
			const RecData = { recordId: recordId };
			publish(this.context, SAMPLEMC, RecData);
		}, 1);
		let paramData = { Name: recordId };
		let ev = new CustomEvent('childmethod', { detail: paramData });
		this.dispatchEvent(ev);
	}

	lookupTRecord(event) {
		event.preventDefault();
		var rec = event.detail.selectedRecord;
		this.tierRecordId = rec.Id;
	}

	lookupReciRecord(event) {
		event.preventDefault();
		this.ReciRecId = event.detail.selectedIds ? event.detail.selectedIds[0] : null;
	}

	lookupFpmRecord(event) {
		event.preventDefault();
		var rec = event.detail.selectedRecord;
		this.FModeRecId = rec.Id;
	}

	handleListViewNavigation() {
		// Navigate to the Accounts object's Recent list view.
		this[NavigationMixin.Navigate]({
			type: 'standard__objectPage',
			attributes: {
				objectApiName: 'Pledge__c',
				actionName: 'list'
			},
			state: {
				filterName: 'Recent'
			}
		});
	}
}