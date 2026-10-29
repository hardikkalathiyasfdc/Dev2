import { LightningElement, track, wire, api } from 'lwc';

import NAME_FIELD from '@salesforce/schema/Account.Name';
import BILLING_FIELD from '@salesforce/schema/Account.BillingAddress';

export default class orgCreation extends LightningElement {
	@api title;
	
	fields = [NAME_FIELD, BILLING_FIELD];

	handleCancel(event) {
		this.dispatchEvent(new CustomEvent('cancelation'));
	}

	handleAccountSuccess(event) {
		this.dispatchEvent(new CustomEvent('success', {detail:event.detail.id}));
	}
}