import { LightningElement, track, wire, api} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Account.Organization_Alert__c',
    'Account.Organization_Alert_Reason__c',
];

export default class organizationAlertNotification extends LightningElement {
	@api recordId;
	alertResult;
	alertReason;
	error;

	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    getAccount(result){
    	if( result.data ) {
    		if( result.data.fields.Organization_Alert__c.value === true ) {
	    		this.alertResult = 'Organization Alert';
	    		this.alertReason = result.data.fields.Organization_Alert_Reason__c.value;
	    	}
    	}

    	if( result.error ) {
    		this.error = result.error;
    	}
    }

    renderedCallback() {

        if( this.alertResult !== '' ) {
            this.sectionClass = "alertSection slds-card";
        } else {
            this.sectionClass = "emptySection slds-card";
        }
    }
}