import { LightningElement, track, wire } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';

export default class docPop extends NavigationMixin(LightningElement) {

	lastMeetingDate;

	handleCancel(event) {
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	handleDateChange(event) {
		this.lastMeetingDate = event.target.value;
	}

	handleSave(event) {
		let url = '/apex/EventDocGeneration';
		if( this.lastMeetingDate ) {
			url += '?last='+this.lastMeetingDate;
		}

		this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: url
            },
        }).then(url => {
            window.open(url);
            this.dispatchEvent(new CustomEvent('cancel'));
        });
	}
}