import {LightningElement, api, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import getPaymentRows from '@salesforce/apex/IMPaymentScheduler.getPaymentRows';
import getGlAccount from '@salesforce/apex/IMPaymentScheduler.getGlAccount';

import getPartnerFunds from '@salesforce/apex/IMPaymentScheduler.getPartnerFunds';
const TOAST_HEADER = 'Exception Occured - Payment Rows Failed';


export default class ImPaymentScheduler extends LightningElement {

	//Variables
	_recordId;
	//These values are passed from Parent component where this payments component is exposed
	@api budgetGrant;
	@api startDate;
	@api endDate;
	@api fundRecordId;
	@api typeOfSupport;
	@api isThisPaymentRestricted;
	@api isUsdCurrency = false;
	@api inputAmountAttributes;
	@api showPersonalSubfund;
	@api hasPaymentReset;
	//data related
	@track data = [];
	@track originalData = [];
	@track partnerTotals;
	@track fundingPartnerValues = [];
	@track personalSubFundValues = [];
	//Boolean
	errorOccured = false;
	showSchedule = true;
	showPayments = false;
	showFundingPartner = true;

	partnerFunds;
	initiativeStartDate;

	get fundingPartnerValues() {
		return this.fundingPartnerValues;
	}

	get personalSubFundValues() {
		return this.personalSubFundValues;
	}

	/*
    Description: connectedCallback
    Jira Story : IM-133
    */
	connectedCallback() {
		try {
			this.initiativeStartDate = this.budgetGrant?.Budget__r?.Initiative__r?.Start_Date__c ?? this.startDate;
			if (this.budgetGrant?.Id) {
				this._recordId = this.budgetGrant?.Id;
				this.checkForDataJson(this._recordId);
			}
		} catch (error) {
			this.showErrorToast(' connectedCallback' + error);
		}
	}

	/*
    Description: Method to get Partner Funds (Partner-BFF & Partner-DAF)
    Jira Story : IM-324
    */
	@wire(getPartnerFunds)
	partnerFundsResult(result) {
		const {data, error} = result;
		if (data) {
			this.partnerFunds = data;
		} else if (error) {
			console.error(error);
		}
	}

	/*
    Description: returns paymentRows json when called
    Jira Story : IM-133
    */
	@api getPaymentRowsData(localAmount) {

		let paymentObj;
		this.errorOccured = false;

		//Check new totals vs apex calculated totals
		const newPartnerTotals = {
			'Gates': 0,
			'Agerup': 0,
			'DFAT': 0,
			'BP': 0,
            'TotalGrantAmount' : 0
        }

        this.data.forEach(record => {
			const partner = record.partner_name;
			if (newPartnerTotals.hasOwnProperty(partner)) {
				newPartnerTotals[partner] += Number(record.amount_due_local || 0);
			} else {
				newPartnerTotals.BP += Number(record.amount_due_local || 0);
			}
			newPartnerTotals.TotalGrantAmount += Number(record.amount_due_local || 0);
		});

		newPartnerTotals.BP = parseFloat(newPartnerTotals.BP.toFixed(2));
		newPartnerTotals.Gates = parseFloat(newPartnerTotals.Gates.toFixed(2));
		newPartnerTotals.Agerup = parseFloat(newPartnerTotals.Agerup.toFixed(2));
		newPartnerTotals.DFAT = parseFloat(newPartnerTotals.DFAT.toFixed(2));
		newPartnerTotals.TotalGrantAmount = parseFloat(newPartnerTotals.TotalGrantAmount.toFixed(2));

		//Perform Validations
		if (this.data.length > 0) {
			this.partnerTotals.TotalGrantAmount = localAmount;
			paymentObj = this.validatePayments(newPartnerTotals);
		}

		//If all validations pass successfully, return the payment json
		if (!this.errorOccured) {
			//Compute PaymentObj to Return - Remove id,Period which are not bgive fields
			const newData = this.data.map(({period, ...record}) => record);
			paymentObj = {
				'isSuccess': true,
				'request_transaction': newData,
                'totalAmountsMap':this.partnerTotals
			};
		}
		return paymentObj;
	}

	/*
    Description: validate payments before returning to the parent component
    Jira Story : IM-133
    */
	validatePayments(newPartnerTotals) {
		//Compare totals and store error messages
		const newData = this.data.map(({period, ...record}) => record);
		let errorObj = {
			'isSuccess': false,
			'request_transaction': newData,
			'totalAmountsMap': this.partnerTotals,
            'error':null
		};
		if (this.isUsdCurrency) {
			if (newPartnerTotals.Gates != this.partnerTotals?.Gates) {
				this.errorOccured = true;
				errorObj.error = 'Total Scheduled Amount for Partner "Gates" is not matching approved amount.';
			}
			if (newPartnerTotals.Agerup != this.partnerTotals?.Agerup) {
				this.errorOccured = true;
				errorObj.error = 'Total Scheduled Amount for Partner "Agerup" is not matching approved amount.';
			}
			if (newPartnerTotals.DFAT != this.partnerTotals?.DFAT) {
				this.errorOccured = true;
				errorObj.error = 'Total Scheduled Amount for Partner "DFAT" is not matching approved amount.';
			}
			if (newPartnerTotals.BP != this.partnerTotals?.BP) {
				this.errorOccured = true;
				errorObj.error = 'Total Scheduled Amount for BP  is not matching approved amount.';
			}
		}
		if (newPartnerTotals.TotalGrantAmount < this.partnerTotals?.TotalGrantAmount) {
			this.errorOccured = true;
            errorObj.error = 'You\'ve under scheduled payments, please increase the payment amounts to match the grant amount.';
		} else if (newPartnerTotals.TotalGrantAmount > this.partnerTotals?.TotalGrantAmount) {
			this.errorOccured = true;
            errorObj.error = 'You\'ve over scheduled payments, please decrease the payment amounts to match the grant amount.';
		}
		return errorObj;
	}

	/*
    Description: checks if the IMGrant record is having data json for payments
    Jira Story : IM-133
    */
	async checkForDataJson(budgetGrantId) {
		try {


			this.getPaymentRows();

		} catch (error) {
			this.showErrorToast(' checkForDataJson' + error);
		}
	}

	/*
    Description: get the aggregated Payment Rows by Partner Fund
    Jira Story : IM-133
    */
	async getPaymentRows() {
		try {
            const result = await getPaymentRows({ budgetGrantId: this._recordId, startDate: this.startDate, endDate: this.endDate, fund: this.fundRecordId,
                typeOfSupport: this.typeOfSupport, isThisPaymentRestricted: this.isThisPaymentRestricted, isUsdCurrency: this.isUsdCurrency, initiativeStartDate: this.initiativeStartDate, hasPaymentReset: this.hasPaymentReset });
			if (result) {
				this.showPayments = true;
				this.showSchedule = false;
				//Assigning partner totlas to check in validations later
				this.partnerTotals = {
					'Gates': result.totalGatesMoney ? result.totalGatesMoney : 0,
					'Agerup': result.totalAgerupMoney ? result.totalAgerupMoney : 0,
					'DFAT': result.totalDfatMoney ? result.totalDfatMoney : 0,
					'BP': result.totalBpMoney ? result.totalBpMoney : 0,
                    'TotalGrantAmount' : result.totalGrantMoney ? result.totalGrantMoney : 0
				};
				this.data = result.allPayments.map((record, index) => {
					// Check if personal subfund is populated
					if(record?.personal_subfund) {
						this.showPersonalSubfund = true;
					}
					// IM-324: Checking if the partner fund is one of two types of Partner
					if (this.partnerFunds?.some((partnerFund) => partnerFund.Id === record.fund)) {
						record.partnerFundDisabled = false;
						record.isFundingPartnerRequired = true;
					} else {
						record.partnerFundDisabled = true;
					}
					return {
						id: index,
						...record,
					};
				});
				this.originalData = this.data.map(record => ({...record}));
				//Setting the Funding Partner Picklist values based on the data available
				this.setValues(result.allFundingPartners, result.allPersonalSubfunds);
			}
		} catch (error) {
			this.data = [];
			this.showErrorToast(' getPaymentRows' + error);
		}
	}


	/*
    Description: handles the funding partner picklist values
    Jira Story : IM-133
    */
	setValues(allFundingPartners, allPersonalSubfunds) {
		try {
            allFundingPartners.forEach(record => {
				this.fundingPartnerValues.push({label: record, value: record});
			});
			if (this.fundingPartnerValues.length < 1) {
				this.showFundingPartner = false;
			}
			allPersonalSubfunds.forEach(record => {
				this.personalSubFundValues.push({label: record, value: record});
			});
		} catch (error) {
			this.showErrorToast(' setValues' + error);
		}
	}

	/*
    Description: handles the reset of payment rows
    Jira Story : IM-133
    */
	handleReset() {
		this.dispatchCustomEvent('resetpayments', 'resetpayments', true);
	}

	/*
    Description: handles the addition of new Rows
    Jira Story : IM-133
    */
	handleNewPayment() {
		try {
			this.data.push({
				id: this.data.length,
				period: null,
				due_at: null,
				fund: null,
				partner_name: null,
				partnerFundDisabled: null,
				amount_due_local: null,
				partnerFundDisabled: null,
				type_of_support: null,
				is_this_payment_restricted: null,
				type_of_payment: 'Pending',
				state: 'new',
				request_id: null,
				gl_account: null,
                isFundingPartnerRequired : null

			});
			this.data = [...this.data];
		} catch (error) {
			this.showErrorToast(' handleNewPayment' + error);
		}
	}

	/*
    Description: handles the selection of scheduled Date
    Jira Story : IM-133
    */
	handleDateChange(event) {
		try {
            this.data.forEach(record =>{
				if (record.id == event.currentTarget.dataset.id) {
					record.due_at = event.detail.value;
				}
			});
		} catch (error) {
			this.showErrorToast(' handleDateChange' + error);
		}
	}

	/*
    Description: handles the selection of new Fund
    Jira Story : IM-133
    */
	async handleFundSelection(event) {
		try {
			let fundId = event.detail.recordId;
			let paymentId = event.currentTarget.dataset.id;
			if (fundId != null) {
				let glAccount = this.getGlAccountValue(fundId, paymentId);
                let matchedPayment = this.data?.filter(payment => payment.id == paymentId );
				if (matchedPayment.length > 0) {
					//matchedPayment[0].gl_account = glAccount;
					matchedPayment[0].fund = fundId;
					// IM-324: Checking if the partner fund is one of two types of Partner
					if (this.partnerFunds?.some((partnerFund) => partnerFund.Id === fundId?.toString())) {
						matchedPayment[0].isFundingPartnerRequired = true;
						matchedPayment[0].partnerFundDisabled = false;
						if (this.fundingPartnerValues.length == 1) {
							matchedPayment[0].partner_name = this.fundingPartnerValues[0].value;
						}
					} else {
						matchedPayment[0].partnerFundDisabled = true;
						matchedPayment[0].partner_name = null;
						matchedPayment[0].isFundingPartnerRequired = false;
					}
				}

			}
		} catch (error) {
			this.showErrorToast(' handleFundSelection' + error);
		}
	}

	handlePersonalSubFundChange(event) {
		try {
            let paymentId = event.currentTarget.dataset.id;
			let matchedPayment = this.data?.filter(payment => payment.id == paymentId );
			if (matchedPayment.length > 0) {
				matchedPayment[0].personal_subfund = event.detail.value;
			}
		} catch (error) {
			this.showErrorToast(' handlePersonalSubFundChange' + error);
		}
	}

	/*
    Description: call apex to get the glAccount value
    Jira Story : IM-133
    */
	getGlAccountValue(fundId, paymentId) {
        getGlAccount({fundName : null, fundRecId:fundId}).then(result => {
            let matchedPayment = this.data?.filter(payment => payment.id == paymentId );
				if (matchedPayment.length > 0) {
					matchedPayment[0].gl_account = result;
            };
        }).catch(error => {
				this.showErrorToast(' getGlAccountValue' + error);
			});
	}

	/*
    Description: handles the selection of new Funding Partner
    Jira Story : IM-133
    */
	handleFundingPartnerSel(event) {
		try {
            this.data.forEach(record =>{
				if (record.id == event.currentTarget.dataset.id) {
					record.partner_name = event.detail.value;
				}
			});
		} catch (error) {
			this.showErrorToast(' handleFundingPartnerSel' + error);
		}
	}

	/*
    Description: handles the selection of new Funding Partner
    Jira Story : IM-133
    */
	handleScheduledAmount(event) {
		try {
            this.data.forEach(record =>{
				if (record.id == event.currentTarget.dataset.id) {
					record.amount_due_local = event.detail.value;
				}
			});
		} catch (error) {
			this.showErrorToast(' handleScheduledAmount' + error);
		}
	}

	/*
    Description: Show Error Toast Message when error occurs
    Jira Story : IM-133
    */
	showErrorToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: TOAST_HEADER,
			message: displayMessage,
			variant: 'error',
            mode: 'dismissable'
		});
		this.dispatchEvent(errorEvt);
	}

	handleDelete(event) {
		try {
			const recordId = event.currentTarget.dataset.id;
			this.data = this.data.filter(record => record.id != recordId);
		} catch (error) {
			this.showErrorToast('Error while deleting Payment data: ' + error);
		}
	}

	dispatchCustomEvent(eventName, key, value) {
		this.dispatchEvent(
			new CustomEvent(eventName, {
				composed: true,
				bubbles: true,
				cancelable: true,
				detail: {
					data: {key: key, value: value},
				},
			})
		);
	}
}