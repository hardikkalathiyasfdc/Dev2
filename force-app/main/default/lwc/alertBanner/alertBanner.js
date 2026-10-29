import {LightningElement, api, wire, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getMessage from '@salesforce/apex/AlertBannerCntrl.getMessages';
import {getRecord} from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
export default class AlertBanner extends LightningElement {
	//Variables
	@track hasErrorMessage = false;
	@api type = 'warning';
	@api fieldApiName;
	@api header = 'Sync Warning';
	@api recordId;
	@api objectApiName;
	_errorMessage;
	messages;
	hasMessages;
	fields = [];

	//Getters and Setters
	get notifyClass() {
		if (this.type == 'warning') {
			return 'slds-color-text-icon-default slds-section-foreground';
		} else if (this.type == 'error') {
			return 'slds-color-text-icon-default slds-section-foreground';
		}
		return '';
	}

	get iconName() {
		if (this.type == 'warning') {
			return 'utility:info_alt';
		} else if (this.type == 'error') {
			return 'utility:error';
		}
		return '';
	}

	get messageClass() {
		if (this.type == 'warning') {
			return 'text-warning';
		} else if (this.type == 'error') {
			return 'text-error';
		}
		return '';
	}

	get sectionClass() {
		if (this.type == 'warning') {
			return 'slds-box slds-card alert-section-warning';
		} else if (this.type == 'error') {
			return 'slds-box slds-card alert-section-error';
		}
		return '';
	}

	get headerClass() {
		if (this.type == 'warning') {
			return 'header slds-text-color_warning';
		} else if (this.type == 'error') {
			return 'header slds-text-color_error';
		}
		return '';
	}

	@api
	set errorMessage(value) {
		this._errorMessage = value;
		this.hasErrorMessage = !!value;
	}

	get errorMessage() {
		return this._errorMessage;
	}

	//Wire Methods
	@wire(getRecord, {recordId: '$recordId', fields: '$fields'})
	wiredRecordResult({data, error}) {
		if (data) {
			refreshApex(this.messages);
		} else if (error) {
			this.showErrorToast('Error loading alert banner');
		}
	}

	@wire(getMessage, {fieldApiName: '$fieldApiName', objectApiName: '$objectApiName', recordId: '$recordId'})
	wireMessageResult(result) {
		this.messages = result;
		this.hasMessages = this.messages?.data?.length > 0;
	}

	/*
    Description: runs the DOM Loads
    Jira Story : 
    */
	connectedCallback() {
		if (this.fieldApiName != undefined) {
			this.fields = [this.objectApiName + '.' + this.fieldApiName];
		}
		//this.hasErrorMessage = this.errorMessage != undefined;
	}

	/*
    Description: shows Error as toast message with the message value received in parameter
    Jira Story : 
    */
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