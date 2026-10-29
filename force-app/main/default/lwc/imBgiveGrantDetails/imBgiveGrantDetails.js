import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getBgiveGrant from '@salesforce/apex/IMGrantViewController.getBgiveGrant';
import getIMGrant from '@salesforce/apex/IMGrantViewController.getIMGrant';
import getIMGrantByBgiveId from '@salesforce/apex/IMGrantViewController.getIMGrantByBgiveId';
import getCurrencyByBgiveId from '@salesforce/apex/IMGrantViewController.getCurrencyByBgiveId';

const CURRENCY_MISMATCH = 'Currencies for both grants does not match. Please change currency or select another grant';
const PARTNER_ORG_MISMATCH = 'Partner Org for both grants does not match. Please select another grant';
const BGIVE_IM_CONNECTION_MISMATCH = 'Bgive IM Connection does not match. Please select another grant';
const TYPE_OF_WORK_MISMATCH = 'Type of Work for both grants does not match. Please select another grant';
const AMOUNT_MISMATCH = 'The amounts are different for both grants';
const GRANT_CLOSED_OR_REJECTED = 'Bgive Grant is Closed or Rejected. Please select another grant';
const IM_NOT_MARKED_PARTIAL = 'The existing Bgive grant is not marked for partial allocation. Please go update it in Salesforce before proceeding.';
const BGIVE_NOT_MARKED_PARTIAL = 'The existing Bgive grant is not marked for partial allocation. Please go update it in Bgive before proceeding.';

export default class ImBgiveGrantDetails extends LightningElement {

	@api isBudgetGrantView;
	@api budgetGrant;
	@api imGrant;
	@api isSingleBeforeCreation;
	@api isSingleAfterCreation;
	@api isPartialBeforeCreation;
	@api isBgiveManaged;
	@api isBgiveManagedAfterCreation;
	@api selectedBgiveIMConnection;
	@api selectedCurrency;
	@api isUsdCurrency;
	@api selectedLocalAmount;
	@api isMarkedForPartial;
	@api isFutureAmount;
	@api bgiveBaseUrl;
	isContigIdEditable = false;
	grantRequest = {};
	futureAmount;
	@track grantErrorMessage = 'Test';
	isError = false;
	errorMessages = [];
	fetchedBRMGrant;
	brmIMGrant;
	bgiveGrantCurrency;
	bgiveGrantURL;

	isAmendment = false;

	connectedCallback() {
		if(this.imGrant?.Bgive_Id__c != null){
			this.bgiveGrantURL = this.bgiveBaseUrl + this.imGrant.Bgive_Id__c;
		}
		this.grantRequest.program_org_name = this.imGrant.Bgive_Grantee_Name__c;
		this.grantRequest.state = this.imGrant.Bgive_Status__c;
		this.grantRequest.project_title_internal = this.imGrant.Project_Title_Internal__c;
		this.grantRequest.amount_recommended_local = this.imGrant.Bgive_Amount_Local__c;
		if ((this.isPartialBeforeCreation || this.isBgiveManaged) && !this.isBgiveManagedAfterCreation) {
			this.isContigIdEditable = true;
		} else {
			this.isContigIdEditable = false;
		}
		if (this.imGrant.Amendment_Bgive_Id__c != null) {
			this.isAmendment = true;
		}
		if (this.isBgiveManaged || this.isBgiveManagedAfterCreation) {
			this.isFutureAmount = false;
		} else {
			if (this.isBudgetGrantView) {
				this.calculateFutureAmount(this.selectedLocalAmount);
			}else{
				this.isFutureAmount = false;
			}
		}

	}


	handleGrantSearch() {
		let contigId = this.template.querySelector('.contigId').value;
		this.getBgiveGrant(contigId);
	}

	async getBgiveGrant(grantRequestContigId) {
		getBgiveGrant({grantRequestContigId: grantRequestContigId})
			.then((result) => {
				let grantRequest = JSON.parse(JSON.stringify(result));
				if (!grantRequest) {
					this.isError = true;
					this.grantErrorMessage = 'Grant does not exist with given contig id';
				} else {
					this.isError = false;
					this.errorMessages = [];
					let budgetGrantAmountLocal = 0;
					if (this.isUsdCurrency) {
						budgetGrantAmountLocal = parseFloat(this.selectedLocalAmount) || this.budgetGrant.Budget_Amount_Local__c;
					} else {
						budgetGrantAmountLocal = parseFloat(this.selectedLocalAmount) || 0;
					}
					this.grantRequest = JSON.parse(JSON.stringify(result));
					this.grantRequest.amount_recommended_local = this.grantRequest.amount_recommended_local || 0;
					if (!this.isBgiveManaged) {
						if (this.grantRequest != null && this.grantRequest.brm_id != null && this.grantRequest.brm_id != '') {
							this.getIMGrant(this.grantRequest.brm_id, budgetGrantAmountLocal);
						} else {
							this.errorMessages.push('Fetched Grant is not linked with BRM');
							const grantRequestData = {
								errors: this.errorMessages,
								grantRequest: this.grantRequest,
							};
							this.dispatchCustomEvent('grantrequestchange', 'Error', grantRequestData);
						}
					} else {
						if (this.grantRequest != null && this.grantRequest.brm_id != null && this.grantRequest.brm_id != '') {
							this.getIMGrant(this.grantRequest.brm_id, budgetGrantAmountLocal);
						} else {
							this.getIMGrantByBgiveId(this.grantRequest.id);
						}
					}
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	async getIMGrant(imGrantId, budgetGrantAmountLocal) {
		getIMGrant({imGrantId: imGrantId, isCurrentGrant: false})
			.then((result) => {
				this.fetchedBRMGrant = JSON.parse(JSON.stringify(result));
				if (this.fetchedBRMGrant && this.isPartialBeforeCreation) {
					this.futureAmount = this.fetchedBRMGrant.Total_Amount_Local__c + budgetGrantAmountLocal;
				}
				this.validateGrantRequest();
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	async getIMGrantByBgiveId(grantBgiveId) {
		getIMGrantByBgiveId({grantBgiveId: grantBgiveId})
			.then((result) => {
				this.errorMessages = [];
				this.brmIMGrant = JSON.parse(JSON.stringify(result));
				if (this.brmIMGrant != null) {
					this.errorMessages.push('Grant already exists in BRM with the provided id');
					const grantRequestData = {
						errors: this.errorMessages,
						grantRequest: this.grantRequest,
					};
					this.dispatchCustomEvent('grantrequestchange', 'Error', grantRequestData);
				} else {
					if (this.grantRequest.fx_type_id != null) {
						this.getCurrencyByBgiveId(this.grantRequest.fx_type_id);
					} else {
						this.validateGrantRequestBgiveManaged();
					}
				}
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	validateGrantRequest() {
		this.errorMessages = [];
		if (this.fetchedBRMGrant.Bgive_Id__c == undefined) {
			this.errorMessages.push('Grants link is broken. Please try again with another grant');
		}
		if (this.grantRequest.funded_by_multiple_initiatives != 'Yes') {
			if (this.isBgiveManaged) {
				this.errorMessages.push(BGIVE_NOT_MARKED_PARTIAL);
			} else {
				this.errorMessages.push(IM_NOT_MARKED_PARTIAL);
			}
		}
		if (this.grantRequest.state == 'closed' || this.grantRequest.state == 'rejected') {
			this.errorMessages.push(GRANT_CLOSED_OR_REJECTED);
		}
		if (this.grantRequest.fx_type_id == null) {
			this.errorMessages.push('Grant Request does not have a currency. Please update currency in Bgive');
		}
		if (this.selectedBgiveIMConnection != undefined && this.selectedBgiveIMConnection != this.grantRequest.bgive_im_connection) {
			this.errorMessages.push(BGIVE_IM_CONNECTION_MISMATCH);
		} else if (this.selectedBgiveIMConnection == undefined && this.imGrant.Bgive_IM_Connection__c != this.grantRequest.bgive_im_connection) {
			this.errorMessages.push(BGIVE_IM_CONNECTION_MISMATCH);
		}
		if (this.selectedCurrency != null && this.selectedCurrency != this.fetchedBRMGrant.Currency__c) {
			this.errorMessages.push(CURRENCY_MISMATCH);
		}
		if (!this.isBgiveManaged && this.fetchedBRMGrant != null && this.imGrant.Type_of_Work__c != this.fetchedBRMGrant.Type_of_Work__c) {
			this.errorMessages.push(TYPE_OF_WORK_MISMATCH);
		}
		if (this.imGrant.Partner_Org__r.Bgive_Id__c != this.grantRequest.program_organization_id) {
			this.errorMessages.push(PARTNER_ORG_MISMATCH);
		}
		if (this.errorMessages.length > 0) {
			const grantRequestData = {
				errors: this.errorMessages,
				grantRequest: this.grantRequest,
			};
			this.dispatchCustomEvent('grantrequestchange', 'Error', grantRequestData);
		} else {
			this.dispatchCustomEvent('grantrequestchange', 'GrantRequest', this.grantRequest);
		}
	}

	validateGrantRequestBgiveManaged() {
		this.errorMessages = [];
		if (!this.isBgiveManaged && this.grantRequest.funded_by_multiple_initiatives != 'Yes') {
			this.errorMessages.push(BGIVE_NOT_MARKED_PARTIAL);
		}
		if (this.grantRequest.state != null && (this.grantRequest.state == 'closed' || this.grantRequest.state == 'rejected')) {
			this.errorMessages.push(GRANT_CLOSED_OR_REJECTED);
		}
		if (this.grantRequest.program_organization_id != null && this.imGrant.Partner_Org__r.Bgive_Id__c != this.grantRequest.program_organization_id) {
			this.errorMessages.push(PARTNER_ORG_MISMATCH);
		}
		if (this.grantRequest.bgive_im_connection != undefined && this.selectedBgiveIMConnection != this.grantRequest.bgive_im_connection) {
			this.errorMessages.push(BGIVE_IM_CONNECTION_MISMATCH);
		}
		if (this.selectedCurrency != null && this.selectedCurrency != this.bgiveGrantCurrency.Id) {
			this.errorMessages.push(CURRENCY_MISMATCH);
		} else {
			if (this.grantRequest.funded_by_multiple_initiatives != 'Yes') {
				if (this.isUsdCurrency && this.grantRequest.amount_recommended_local != this.budgetGrant.Budget_Amount_USD__c) {
					this.errorMessages.push(AMOUNT_MISMATCH);
				}
				if (
					!this.isUsdCurrency &&
					this.selectedLocalAmount != undefined &&
					this.grantRequest.amount_recommended_local != parseFloat(this.selectedLocalAmount)
				) {
					this.errorMessages.push(AMOUNT_MISMATCH);
				} else if (
					!this.isUsdCurrency &&
					this.selectedLocalAmount == undefined &&
					this.grantRequest.amount_recommended_local != this.budgetGrant.Budget_Amount_Local__c
				) {
					this.errorMessages.push(AMOUNT_MISMATCH);
				}
			}
		}
		if (this.errorMessages.length > 0) {
			const grantRequestData = {
				errors: this.errorMessages,
				grantRequest: this.grantRequest,
			};
			this.dispatchCustomEvent('grantrequestchange', 'Error', grantRequestData);
		} else {
			this.dispatchCustomEvent('grantrequestchange', 'GrantRequest', this.grantRequest);
		}
	}

	@api calculateFutureAmount(selectedLocalAmount) {
		this.selectedLocalAmount = selectedLocalAmount;
		if (this.budgetGrant.Confirmed_Budget_Amount_Local__c != undefined) {
			let difference = this.selectedLocalAmount - this.budgetGrant.Confirmed_Budget_Amount_Local__c;
			if(this.isPartialBeforeCreation){
				this.futureAmount = this.fetchedBRMGrant.Total_Amount_Local__c + difference;
			}else{
				this.futureAmount = this.imGrant.Total_Amount_Local__c + difference;
			}
			if (this.futureAmount == this.grantRequest.amount_recommended_local || this.selectedLocalAmount == 0) {
				this.isFutureAmount = false;
			} else if (
				this.imGrant.Amendment_Bgive_Id__c != null
			) {
				this.isFutureAmount = false;
			} else {
				this.isFutureAmount = true;
			}
		}
	}


	async getCurrencyByBgiveId(bgiveCurrencyId) {
		getCurrencyByBgiveId({bgiveCurrencyId: bgiveCurrencyId})
			.then((result) => {
				this.bgiveGrantCurrency = JSON.parse(JSON.stringify(result));
				this.validateGrantRequestBgiveManaged();
			})
			.catch((error) => {
				this.showErrorToast(error);
			});
	}

	@api selectedGrantRequest() {
		return this.grantRequest;
	}

	@api getErrors() {
		return this.errorMessages;
	}

	@api getSelectedIMGrant() {
		return this.fetchedBRMGrant;
	}

	@api getGrantRequestCurrency() {
		if (this.fetchedBRMGrant != null) {
			return this.fetchedBRMGrant.Currency__c;
		} else if (this.bgiveGrantCurrency != null) {
			return this.bgiveGrantCurrency.Id;
		} else {
			return null;
		}
	}

	@api getFutureAmount() {
		return this.futureAmount;
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

	showErrorToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: 'Error',
			message: displayMessage,
			variant: 'error',
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}


	/*
	* Getter to check if URL should be displayed.
	*/
	get hasBgiveURL() {
		return this.bgiveGrantURL !== null && this.bgiveGrantURL !== undefined;
	}
}