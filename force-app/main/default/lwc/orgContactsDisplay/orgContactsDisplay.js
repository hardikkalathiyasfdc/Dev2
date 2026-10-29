import { LightningElement, track, api } from 'lwc';


export default class orgContactsDisplay extends LightningElement {
	@api contacts;

	displayedContacts;
	showViewAll = false;
	showLess = false;
	displayCount = 6;

	connectedCallback() {
		if( this.contacts.length > this.displayCount ) {
			this.displayedContacts = this.contacts.slice(0, this.displayCount);
			this.showViewAll = true;
		} else {
			this.displayedContacts = this.contacts;
			this.showViewAll = false;
		}
	}

	handleViewAll(event) {
		this.displayedContacts = this.contacts;
		this.showLess = true;
		this.showViewAll = false;
	}

	handleLess(event) {
		this.displayedContacts = this.contacts.slice(0, this.displayCount);
		this.showLess = false;
		this.showViewAll = true;
	}
}