import { LightningElement, track, wire, api } from 'lwc';
import getContactFields from '@salesforce/apex/listMemberMoreInfoAuraCtrl.getContactFields';
import getContactId from '@salesforce/apex/listMemberMoreInfoAuraCtrl.getContactId';

import contactSpaceFields from '@salesforce/label/c.LWC_ContactSpaceFields';

export default class listMemberContactAdditionalInfo extends LightningElement {
	@api recordId;
	
	contactFields;
	contactId;
	error;

    @wire(getContactId, {campaignMemberId: '$recordId'})
    getCOntactId({error, data}) {
    	if( data ) {
    		this.contactId = data;
    	}
    }

	@wire(getContactFields)
	getFilesInfo(result) {
		if( result.data ) {
			let allFields = JSON.parse(result.data);

			let tmpFields = {};
			tmpFields.left = [];
			tmpFields.right = [];
			let fields = contactSpaceFields.split(',');
			
			allFields.forEach( x => {
				
				if( x.accessible === true) {
					//tmpFields.push('Contact.'+x.fieldName);
					if( fields.indexOf(x.fieldName) !== -1 ) {
						x.breakLine = true;
					} else {
						x.breakLine = false;
					}
					if( x.fieldLabel.includes('Business') || x.fieldLabel.includes('Other') || x.fieldLabel.includes('Additional') ) {
						tmpFields.left.push(x);
					} else {
						tmpFields.right.push(x);
					}
				}
				
			});

			let maxLength = tmpFields.left.length;
			if (tmpFields.right.length > tmpFields.left.length ) {
				maxLength = tmpFields.right.length;
			}
			let total = [];
			for( let i = 0; i < maxLength; i++ ) {
				let tmp = {};
				if (i < tmpFields.left.length ) {
					tmp.first = tmpFields["left"][i];
				} 
				if (i < tmpFields.right.length ) {
					tmp.second = tmpFields["right"][i];
				}

				total.push(tmp);
			}

			//this.contactFields = tmpFields;
			this.contactFields = total;
			//refreshApex(this.contactInfo);
		}
	}
}