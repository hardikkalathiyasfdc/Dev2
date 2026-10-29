import { LightningElement, wire, api } from 'lwc';
import getContacts from "@salesforce/apex/EventMangementAuraCtrl.getContacts";

export default class ViewDuplicateContacts extends LightningElement {
    @api contactRecords;   
    @api duplicateRecordIds;
    
    connectedCallback() {
        this.getContacts();
    }

    get title() {
        var titleValue = 'Contacts (';
        if (this.contactRecords != null) {
            titleValue += this.contactRecords.length + ')';
        } else {
            titleValue += '0)';
        }
        console.log('#########: ' + titleValue);
        return titleValue;
    }

    closeModal(event) {
		this.dispatchEvent(new CustomEvent('cancelation'));
	}

    handleOpenContact(event) {
        var datasetContactId = event.target.dataset.name;
        this.dispatchEvent(new CustomEvent('selection', { detail:  datasetContactId}));
    }

    getContacts() {
		getContacts({contactIds: this.duplicateRecordIds}).
            then(data=>{
			console.log('#####getContacts: ' + JSON.stringify(data));
			//this.contactRecords = data;
            this.contactRecords = data.map(data => ({ href: '/' + data.Id, ...data }));
		}).catch(err=>{console.log('########eventGuestCreation-getContacts: ' + err);});
	}
}