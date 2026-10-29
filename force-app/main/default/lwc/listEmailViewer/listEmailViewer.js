import { api, wire, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEmailBody from '@salesforce/apex/ListEditCmpController.getEmailBody';
import getFormattedSubject from '@salesforce/apex/ListEditCmpController.getFormattedSubject';

export default class ListEmailViewer extends LightningElement {
	@api showPopup;
	@api recordId;
	@api emailField;
	@api emailTitle;
	@api emailSubjectField;
	@api emailStatus;
	@api emailSent;
	@api emailTemplateLastModified;
	showCC;
	showBCC;
	fields; 
	emailBody;
	showLoader;

	get showCCField() {
		return this.showCC;
	}

	get showBCCField() {
		return this.showBCC;
	}

	subjectValue;

    @wire(getFormattedSubject, {
        recId: '$recordId',
        subjectField: '$emailSubjectField'
    })
    wiredSubject({ error, data }) {
        if (data) {
            this.subjectValue = data;
        } else if (error) {
            this.subjectValue = '';
        }
    }

	connectedCallback() {
		getEmailBody({
			recId: this.recordId,
			fieldName: this.emailField
		}).then((result) => {
			this.emailBody = result && result.body;
			this.showCC = result && result.cc;
			this.showBCC = result && result.bcc;
		}).catch((error) => {
			this.showErrorToast(error);
		});
	}

	showErrorToast(msg) {
		msg = this.getErrMsg(msg);
		const evt = new ShowToastEvent({
			title: 'Error',
			message: msg,
			variant: 'error',
			mode: 'sticky'
		});
		this.dispatchEvent(evt);
	}

	getErrMsg(error) {
		if(!error) return null;
		let errMsg = null;
		if(Array.isArray(error)) {
			for(let i = 0; i < error.length; i++) {
				errMsg = this.getErrMsg(error[i]);
				if(errMsg) return errMsg;
			}
		} else if(typeof error === 'object' && error !== null) {
			for(let key in error) {
				if(key == 'message') {
					return error[key];
				} else {
					errMsg = this.getErrMsg(error[key]);
					if(errMsg) return errMsg;
				}
			}
		}
	}

	closeEmail() {
		const selectedEvent = new CustomEvent('closeemail');
		this.dispatchEvent(selectedEvent);
	}

	handleSubmit(event) {
		this.showLoader = true;
		this.fields = event.detail.fields;
		this.fields.id = this.recordId;
	}

	handleSuccess() {
		this.showLoader = false;
		const selectedEvent = new CustomEvent('closeemail', {
			composed: true,
			bubbles: true,
			cancelable: true,
			detail: {
				data: this.fields
			}
		});
		this.dispatchEvent(selectedEvent);
	}

	handleError(e) {
		this.showLoader = false;
		let msg = e.detail.detail;
		const event = new ShowToastEvent({
			title: 'Error',
			message: msg,
			variant: 'error',
			mode: 'sticky'
		});
		this.dispatchEvent(event);
	}

	handleClick() {
		const style = document.createElement('style');
		style.innerText = `p { padding-top: 0px !important; }`;
		if(this.template.querySelector('lightning-input-rich-text'))
			this.template.querySelector('lightning-input-rich-text').appendChild(style);
	}

	renderedCallback() {
		const style = document.createElement('style');
		style.innerText = `p { padding-top: 20px; } table { display: flex; flex-direction: column; align-items: center; justify-content: center; }`;
		if(this.template.querySelector('lightning-input-rich-text'))
			this.template.querySelector('lightning-input-rich-text').appendChild(style);
	}
}