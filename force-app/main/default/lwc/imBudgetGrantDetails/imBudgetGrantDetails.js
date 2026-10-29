import {LightningElement, wire, api} from 'lwc';
import {getObjectInfo, getPicklistValues} from 'lightning/uiObjectInfoApi';
import IM_GRANT_OBJECT from '@salesforce/schema/IM_Grant__c';
import BGIVE_SYNC_TYPE from '@salesforce/schema/IM_Grant__c.Bgive_IM_Connection__c';
import ALLOCATION_TYPE from '@salesforce/schema/IM_Grant__c.Funded_By_Multiple_Initiatives__c';
import getUSDCurrency from '@salesforce/apex/IMGrantViewController.getUSDCurrency';

export default class ImBudgetGrantDetails extends LightningElement {

	@api isBudgetGrantView;
	@api isNonBudgetGrantView;
	@api budgetGrant;
	@api imGrant;
	@api nonBudgetGrant;
	@api isNotInBgive;
	@api isPartnerOrgNotBlinked;
	@api isSingleBeforeCreation;
	@api isBgiveManaged;
	@api isBgiveManagedAfterCreation;
	@api isFund;
	@api inputAmountAttributes;
	@api isReadOnly;

	bgiveGrantRequest;

	isUSDAmountDifferent = false;
	isLocalAmountDifferent = false;
	isNonUSD = false;
	isDateEditable = false;
	defaultRecordTypeId;
	bgiveIMConnectionValues;
	fundedByMultipleValues;

	usdCurrency;
	selectedCurrency;
	localAmount;

	fundedByMultiple;
	startDate;
	endDate;

	partnerOrg;
	budgetAmountUSD;
	budgetAmountLocal;

	@api setGrantRequest(value) {
		this.bgiveGrantRequest = JSON.parse(JSON.stringify(value));
		// Added since date is returned as datetime from bgive and we need only date for the UI
		if (this.bgiveGrantRequest.grant_begins_at != null) {
			let startDate = this.bgiveGrantRequest.grant_begins_at;
			this.startDate = startDate.substring(0, startDate.indexOf('T'));
		}
		if (this.bgiveGrantRequest.grant_closed_at != null) {
			let endDate = this.bgiveGrantRequest.grant_closed_at;
			this.endDate = endDate.substring(0, endDate.indexOf('T'));
		}
		this.fundedByMultiple = this.bgiveGrantRequest.funded_by_multiple_initiatives;
	}

	connectedCallback() {
		if (this.isBudgetGrantView) {
			if ((this.isNotInBgive || this.isSingleBeforeCreation) && !this.isBgiveManagedAfterCreation && !this.isBgiveManaged) {
				this.isDateEditable = true;
			}
			this.partnerOrg = '/' + this.imGrant.Partner_Org__c;
			this.startDate = this.imGrant.Start_Date__c;
			this.endDate = this.imGrant.End_Date__c;
			this.fundedByMultiple = this.imGrant.Funded_By_Multiple_Initiatives__c;
			this.selectedCurrency = this.imGrant.Currency__c;
			if (this.imGrant.Currency__c != undefined && this.imGrant.Currency__c != this.usdCurrency) {
				this.isNonUSD = true;
				this.localAmount = this.budgetGrant.Budget_Amount_Local__c;
			} else {
				this.isNonUSD = false;
				this.localAmount = this.budgetGrant.Budget_Amount_USD__c;
			}
			if (
				this.budgetGrant.Confirmed_Budget_Amount_USD__c != undefined &&
				this.budgetGrant.Confirmed_Budget_Amount_USD__c != this.budgetGrant.Budget_Amount_USD__c
			) {
				this.isUSDAmountDifferent = true;
				if(this.isNonUSD){
					this.isLocalAmountDifferent = true;
				}
			}
		} else if(this.isNonBudgetGrantView) {
			this.partnerOrg = '/' + this.imGrant.Partner_Org__c;
			if (this.imGrant.Currency__c != undefined && this.imGrant.Currency__c != this.usdCurrency) {
				this.isNonUSD = true;
				this.budgetAmountLocal = this.nonBudgetGrant?.Budget_Amount_Local__c;
			} else {
				this.isNonUSD = false;
				this.budgetAmountUSD = this.nonBudgetGrant?.Budget_Amount_USD__c;
			}
		} else {
			this.partnerOrg = '/' + this.imGrant.Partner_Org__c;
			if (this.imGrant.Currency__c != undefined && this.imGrant.Currency__c != this.usdCurrency) {
				this.isNonUSD = true;
				this.budgetAmountLocal = this.imGrant?.Budget_Amount_Local__c;
			} else {
				this.isNonUSD = false;
				this.budgetAmountUSD = this.imGrant?.Budget_Amount_USD__c;
			}
		}
	}

	@wire(getObjectInfo, {objectApiName: IM_GRANT_OBJECT})
	results({error, data}) {
		if (data) {
			this.defaultRecordTypeId = data.defaultRecordTypeId;
		} else if (error) {
			console.error(error);
		}
	}

	@wire(getPicklistValues, {recordTypeId: '$defaultRecordTypeId', fieldApiName: BGIVE_SYNC_TYPE})
	bgiveConnection({error, data}) {
		if (data) {
			this.bgiveIMConnectionValues = data.values;
		} else if (error) {
			console.error(error);
		}
	}

	@wire(getPicklistValues, {recordTypeId: '$defaultRecordTypeId', fieldApiName: ALLOCATION_TYPE})
	fundedByMultipleOptions({error, data}) {
		if (data) {
			this.fundedByMultipleValues = data.values;
		} else if (error) {
			console.error(error);
		}
	}

	@wire(getUSDCurrency)
	currencyData(result) {
		const {data, error} = result;
		if (data) {
			this.usdCurrency = data.Id;
			// Adding check since below logic will not be required on IMGrant View as all fields are read-only
			if (this.isBudgetGrantView) {
				if (this.imGrant.Currency__c != this.usdCurrency) {
					this.isNonUSD = true;
					this.localAmount = this.budgetGrant.Budget_Amount_Local__c;
				} else {
					this.isNonUSD = false;
					this.localAmount = this.budgetGrant.Budget_Amount_USD__c;
				}
			}
		} else if (error) {
			console.error(error);
		}
	}

	handleCurrencyChange(event) {
		this.selectedCurrency = event.detail.recordId;
		if (event.detail.recordId != null) {
			if (event.detail.recordId != this.usdCurrency) {
				this.isNonUSD = true;
				let amountLocalElement = this.template.querySelector("lightning-input[data-id='BudgetAmountLocal']");
				if (amountLocalElement) amountLocalElement.value = '';
				this.localAmount = '';
			} else {
				this.isNonUSD = false;
				// IM-379: Set to USD amount in case of USD currency
				this.localAmount = this.budgetGrant.Budget_Amount_USD__c;
			}
			this.dispatchCustomEvent('currencychange', 'Currency', this.isNonUSD);
		}
	}

	handleLocalAmountChange(event) {
		this.localAmount = event.detail.value;
		this.dispatchCustomEvent('localamountchange', 'LocalAmount', event.detail.value);
	}

	handleSyncTypeChange(event) {
		if (event.detail.value == 'Bgive Managed') {
			this.isDateEditable = false;
		} else {
			this.isDateEditable = true;
		}
		this.dispatchCustomEvent('synctypechange', 'SyncType', event.detail.value);
	}

	handleAllocationTypeChange(event) {
		if (event.detail.value == 'No' && this.imGrant.Bgive_Id__c == undefined) {
			this.isDateEditable = true;
		} else {
			this.isDateEditable = false;
		}
		this.dispatchCustomEvent('allocationtypechange', 'AllocationType', event.detail.value);
	}

	handleStartDateChange(event) {
		this.dispatchCustomEvent('startdatechange', 'StartDate', event.detail.value);
	}

	handleEndDateChange(event) {
		this.dispatchCustomEvent('enddatechange', 'EndDate', event.detail.value);
	}

	handleFundChange(event) {
		this.dispatchCustomEvent('fundchange', 'Fund', event.detail.recordId);
	}

	@api getCurrency() {
		return this.selectedCurrency;
	}

	@api getLocalAmount() {
		return this.localAmount;
	}

	@api setLocalAmount(value) {
		this.localAmount = value;
	}

	@api getIsNonUSD() {
		return this.isNonUSD;
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