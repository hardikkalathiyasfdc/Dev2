import { LightningElement, track, wire } from 'lwc';

export default class boarMemberDateSelection extends LightningElement {
	fromDate;
	toDate;
	showIframe = false;
	fullUrl;
	error;

	handleDateSelection(event) {
		this.error = undefined;
		const field = event.target.name;
        if (field === 'fromDate') {
            this.fromDate = event.target.value.replaceAll('-', '');
        } else if (field === 'toDate') {
            this.toDate = event.target.value.replaceAll('-', '');
        }

        if(this.fromDate !== undefined && this.toDate !== undefined && this.toDate < this.fromDate ) {
        	this.error = '*Please select To Date greater than From Date';
        }
	}

	handleGenerateReport(event) {
		if( this.fromDate === undefined || this.toDate === undefined ) {
			this.error = '*Please select both From Date and To Date to generate Board Member Report';
		} else {
			this.error = undefined;
			this.showIframe = true;
			this.fullUrl = '/apex/BoardMemberInteractions?from='+this.fromDate+'&to='+this.toDate;
		}
	}

	handleGenerateMayorReport(event) {
		if( this.fromDate === undefined || this.toDate === undefined ) {
			this.error = '*Please select both From Date and To Date to generate Mayor And City View Interaction Report';
		} else {
			this.error = undefined;
			this.showIframe = true;
			this.fullUrl = '/apex/MayorAndCityViewInteractionReport?from='+this.fromDate+'&to='+this.toDate;
		}
	}
}