import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Contact.Contact_Alert__c',
    'Contact.Contact_Alert_Reason__c',
];

export default class contactAlertNotification extends LightningElement {
	@api recordId;
    sectionClass;
    alertResult;
    alertReason;
    error;


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    getContact(result){
        if( result.data ) {
            if( result.data.fields.Contact_Alert__c.value === true ) {
                this.alertResult = 'Contact Alert';
                this.alertReason = result.data.fields.Contact_Alert_Reason__c.value;
                console.log(this.alertReason);
            }
        }

        if( result.error ) {
            this.error = result.error;
        }
    }

    renderedCallback() {
        if( this.alertResult !== undefined ) {
            this.sectionClass = "alertSection slds-card";
        } else {
            this.sectionClass = "emptySection slds-card";
        }
    }

}