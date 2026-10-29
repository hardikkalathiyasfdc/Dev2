import { LightningElement, track, wire } from 'lwc';
import getOfficeInfo from '@salesforce/apex/OfficeInfoAuraCtrl.getOfficeInfo';

export default class officeInfoSection extends LightningElement {
	data;

	@wire(getOfficeInfo)
	officeInfo(result) {
		if( result.data ) {
			let data = JSON.parse(result.data);
			data.sort((a,b) => {
				return a.Order__c>b.Order__c?1:a.Order__c<b.Order__c?-1:0;
			});
			
			this.data = data;
		}
	}
}