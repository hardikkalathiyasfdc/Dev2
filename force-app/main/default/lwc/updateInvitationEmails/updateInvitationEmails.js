import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getOrgEmails from '@salesforce/apex/EventMangementAuraCtrl.getOrgEmails';
import getOrgEmailsByEvent from '@salesforce/apex/EventMangementAuraCtrl.getOrgEmailsByEvent';
import updateOrgEmails from '@salesforce/apex/EventMangementAuraCtrl.updateOrgEmails';

export default class updateInvitationEmails extends LightningElement {
	@api recordId;
	emails;
	invitaitons;
	updatedEmails;
	allEmails;
	emailId;
	displayName;
	showNoEmailNotification = false;

	@wire(getOrgEmailsByEvent, {eventId: '$recordId'})
	wireGetOrgEmailsByEvent(result) {
		this.allEmails = result;
		if( result.data ) {
			let emails = JSON.parse(result.data);
			if( emails.length > 0 ) {
				this.emailId = emails[0].Id;
				this.displayName = emails[0].DisplayName;
			}
		}
	}

	@wire(getOrgEmails)
	wireGetOrgEmails(result) {
		
		if( result.data ) {
			let emails = JSON.parse(result.data);
			
			this.emails = emails;
			let invitations = []
			invitations.push( { label: ' ', value: '' });
			emails.forEach( x => {
				invitations.push( { label: x.Address, value: x.Id });
			});
			this.invitaitons = invitations;
		}
	}

	handleChange(event) {
		this.displayName = event.detail.value;
	}

	handleEmailChange(event) {
		this.emailId = event.detail.value;
		let email = this.emails.find( x => x.Id === this.emailId);
		this.displayName = email.DisplayName;
	}

	handleCancel(event) {
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	handleSave(event) {
		if( this.emailId === '' ) {
			return;
		}

		let email = this.emails.find( x => x.Id === this.emailId);

		let emails = {Id: this.emailId, Address: email.Address, DisplayName: this.displayName};

		updateOrgEmails({
			updatedEmails: JSON.stringify(emails),
			eventId: this.recordId
		})
		.then( result => {
			if( result === 'success' ) {
				this.showNotification('Success', 'The Invitation Email From Name is updated successfully.', 'success');
			} 
			refreshApex(this.allEmails);
			this.dispatchEvent(new CustomEvent('cancel'));
		})
		.catch( error => {
			console.log(JSON.stringify(error));
			this.showNotification('Error', error.body.message, 'error');
		});

	}

	showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}