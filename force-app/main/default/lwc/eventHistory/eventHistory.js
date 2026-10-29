import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getEventsByContact from '@salesforce/apex/EventHistoryAuraCtrl.getEventsByContact';
import getEventPrintButtonAccess from '@salesforce/apex/EventHistoryAuraCtrl.getEventPrintButtonAccess';
import EVENT_IMAGE from '@salesforce/resourceUrl/Events';

export default class eventHistory extends NavigationMixin(LightningElement) {
	@api recordId;
	events;
	showButton = false;
	showAll = false;
	buttonLabel;
	allEvents;
	isPrintBtnAccessible;
    eventHistoryLogo = EVENT_IMAGE;
	isPhone = false;
	isDesktop = false;

	@wire(getEventPrintButtonAccess)
	wireEventPrintButtonAccess(result) {
		if(result.data) {
			this.isPrintBtnAccessible = result.data;
		}
	}

	connectedCallback() {
		if(FORM_FACTOR == 'Small') {
			this.isPhone = true;
		} else this.isDesktop = true;
	}

	@wire(getEventsByContact, {contactId: '$recordId'})
	wireEventsByContact(result) {
		if(result.data) {
			let events = JSON.parse(result.data);
			events.forEach(x => {
				x.url = '/' + x.id;
			});
			this.allEvents = events;
			this.events = events;
			if(events.length > 3) {
                this.showButton = true;
                this.buttonLabel = 'Show More';
                this.events = events.slice(0, 3);
            } 
		}
	}

	handleContentDisplay() {
		if(this.showAll === false) {
			this.showAll = true;
			if(this.isPrintBtnAccessible) {
               this.events = this.allEvents;
			} else {
				this.events = this.allEvents.slice(0, 10);
			}
			this.buttonLabel = 'Show Less';
		} else {
			this.showAll = false;
			this.events = this.allEvents.slice(0, 3);
			this.buttonLabel = 'Show More';
		}
	}

	handlePrint() {
		let url = '/apex/EventHistoryGeneration?id='+this.recordId;
		window.open(url);
	}
}