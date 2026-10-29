import {LightningElement, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getPersonalFund from '@salesforce/apex/IMGrantViewController.getPersonalFund';

export default class ImGrantDetails extends LightningElement {
	@api budgetGrant;
	@api imGrant;
	@api fiscalSponsor;
	@api isFiscalSponsorNotBlinked;
	@api isSingleBeforeCreation;
	@api jsonData;
	@api picklistValues;
	@api isReadOnly;
	isPersonalFund = false;
	isAgreementRequired = false;
	dataJSON;

	campaign;
	advocacy;
	segment;
	theme;
	businessUnit;
	requestType;
	supportType;
	typeOfAgreement;
	agreementRequired;
	grantRestriction;
	programContact;
	grantContact;
	personalFundId;
	selectedFundId;

	projectTitle;
	campaignLabel =
		'Are there any Political Campaign Expenses in this Grant (activities that favor or oppose a candidate for office)?';
	advocacyLabel =
		'Is there lobbying or legislative advocacy associated with this project?';

	connectedCallback() {
		this.getPersonalFundId(this.imGrant.Fund__c);
		if (this.jsonData != undefined) {
			this.dataJSON = JSON.parse(JSON.stringify(this.jsonData));
			this.campaign =
				this.dataJSON.IM_Grant__c.political_campaign_expenses;
			this.advocacy = this.dataJSON.IM_Grant__c.lobbying_advocacy;
			this.segment = this.dataJSON.IM_Grant__c.segment_id;
			this.theme = this.dataJSON.IM_Grant__c.model_theme_id;
			this.businessUnit =
				this.dataJSON.IM_Grant__c.bbg_department_on_behalf_of;
			this.requestType = this.dataJSON.IM_Grant__c.request_type;
			this.supportType = this.dataJSON.IM_Grant__c.type_of_support;
			this.agreementRequired =
				this.dataJSON.IM_Grant__c.grant_agreement_required;
			this.typeOfAgreement = this.dataJSON.IM_Grant__c.type_of_agreement;
			this.grantRestriction =
				this.dataJSON.IM_Grant__c.is_this_grant_restricted;
			this.programContact = this.dataJSON.IM_Grant__c.program_lead_id;
			this.grantContact = this.dataJSON.IM_Grant__c.operations_contact;

			this.isAgreementRequired = this.agreementRequired == 'Yes';
		} else {
			this.evaluateFundOptions(this.imGrant.Fund__c);
		}
	}

	get restrictionOptions() {
		return this.getPicklistOptions(
			this.picklistValues.is_this_grant_restricted
		);
	}

	get supportOptions() {
		return this.getPicklistOptions(this.picklistValues.type_of_support);
	}

	get agreementRequiredOptions() {
		return this.getPicklistOptions(
			this.picklistValues.grant_agreement_required
		);
	}

	get agreementTypeOptions() {
		return this.getPicklistOptions(this.picklistValues.type_of_agreement);
	}

	get themeOptions() {
		return this.getPicklistOptions(this.picklistValues.model_theme_id);
	}

	get BusinessUnitOptions() {
		return this.getPicklistOptions(
			this.picklistValues.bbg_department_on_behalf_of
		);
	}

	get requestTypeValues() {
		return this.getPicklistOptions(this.picklistValues.request_type);
	}

	get campaignOptions() {
		return this.getPicklistOptions(
			this.picklistValues.political_campaign_expenses
		);
	}

	get advocacyOptions() {
		return this.getPicklistOptions(this.picklistValues.lobbying_advocacy);
	}

	handleSegmentChange(event) {
		this.segment = event.detail.recordId;
	}

	handleThemeChange(event) {
		this.theme = event.detail.value;
	}

	handleProgramContactChange(event) {
		this.programContact = event.detail.recordId;
	}

	handleGrantContactChange(event) {
		this.grantContact = event.detail.recordId;
	}

	handleProjectTitleChange(event) {
		this.projectTitle = event.detail.value;
	}

	handleBusinessUnitChange(event) {
		this.businessUnit = event.detail.value;
	}

	handleRequestTypeChange(event) {
		this.requestType = event.detail.value;
	}

	handleSupportTypeChange(event) {
		this.supportType = event.detail.value;
	}

	handleAgreementRequiredChange(event) {
		this.agreementRequired = event.detail.value;
		if (event.detail.value === 'Yes') {
			this.isAgreementRequired = true;
		} else {
			this.isAgreementRequired = false;
			this.typeOfAgreement = undefined;
		}
	}

	handleTypeOfAgreementChange(event) {
		this.typeOfAgreement = event.detail.value;
	}

	handleGrantRestrictionChange(event) {
		this.grantRestriction = event.detail.value;
	}

	handleFundChange(event) {
		this.selectedFundId = event.detail.recordId;
		this.dispatchCustomEvent('fundchange', 'Fund', event.detail.recordId);
		this.evaluateFundOptions(this.selectedFundId);
	}

	handleCampaignChange(event) {
		this.campaign = event.detail.value;
	}

	handleAdvocacyChange(event) {
		this.advocacy = event.detail.value;
	}

	evaluateFundOptions(selectedFundId) {
		if (selectedFundId != this.personalFundId) {
			this.isPersonalFund = false;
			this.campaign = 'No';
			this.advocacy = 'No';
		} else {
			this.isPersonalFund = true;
			if (this.imGrant.Type_of_Work__c == 'Electoral') {
				this.campaign = 'Yes';
			} else {
				this.campaign = 'No';
			}
			if (this.imGrant.Type_of_Work__c == 'Advocacy') {
				this.advocacy = 'Yes';
			} else {
				this.advocacy = 'No';
			}
		}
	}

	getPersonalFundId(selectedFundId) {
		getPersonalFund()
			.then((result) => {
				this.personalFundId = result;
				if (selectedFundId != this.personalFundId) {
					this.isPersonalFund = false;
				} else {
					this.isPersonalFund = true;
				}
			})
			.catch((error) => {
				this.showErrorToast(
					'Error fetching Personal Fund' +
						JSON.stringify(error.body.message)
				);
			});
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

	@api
	grantDetails() {
		let grantJSONData = {
			'segment_id': this.segment,
			'model_theme_id': this.theme,
			'program_lead_id': this.programContact,
			'operations_contact': this.grantContact,
			'bbg_department_on_behalf_of': this.businessUnit,
			'request_type': this.requestType,
			'type_of_support': this.supportType,
			'grant_agreement_required': this.agreementRequired,
			'type_of_agreement': this.typeOfAgreement,
			'is_this_grant_restricted': this.grantRestriction,
			'political_campaign_expenses': this.campaign,
			'lobbying_advocacy': this.advocacy,
		};
		return grantJSONData;
	}

	@api
	getprojectTitle() {
		return this.projectTitle;
	}

	@api
	getFund() {
		return this.selectedFundId;
	}

	getPicklistOptions(fieldName) {
		let picklistValues = [];
		Object.values(fieldName).forEach((value) => {
			picklistValues.push({
				label: value,
				value: value,
			});
		});
		return picklistValues;
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
}