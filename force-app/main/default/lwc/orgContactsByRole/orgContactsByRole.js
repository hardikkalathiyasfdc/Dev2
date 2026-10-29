import { LightningElement, track, wire, api } from 'lwc';
import getContactsByOrgId from '@salesforce/apex/OrgContactsByRoleAuraCtrl.getContactsByOrgId';

export default class orgContactsByRole extends LightningElement {
	@api recordId;
	allContacts;
	error;
	contacts;
	
	@wire(getContactsByOrgId, {orgId:'$recordId'})
	getContacts(result) {
		this.allContacts = result;
		if(result.data) {
			
			let tmpResult = JSON.parse(result.data);
			let tmp = {};
			for( let i = 0; i < tmpResult.length; i++ ) {
				let item = tmpResult[i];

				if( item.Role__c === undefined ) {
					item.Role__c = '';
				}
				/** 06/16/2021 - update by Remy to display Employee Role
				 * https://app.asana.com/0/1172234592458529/1200149991371707
				if( item.Role__c === 'Employee' ) {
					continue;
				}**/
				if( tmp[item.Role__c] === undefined ) {
					tmp[item.Role__c] = [];
				}

				tmp[item.Role__c].push(item);
			}
				
			

			let tmpContacts = [];
			let emptyRoleContacts = {};
			Object.keys(tmp).forEach(item => {
				let tmpCont = {};
				tmpCont.role = item;
				let tmpConts=[];
				if( tmp[item] !== undefined ) {
					tmp[item].forEach( x => {
						let cont = {};
						cont.url = '/'+x.Contact_Name__r.Id;
						cont.id = x.Contact_Name__r.Id;
						cont.name = x.Contact_Name__r.Name;

						let find = tmpConts.find( existed => existed.id === x.Contact_Name__r.Id);
						if( find === undefined) {
							tmpConts.push(cont);
						}
						
					});

					tmpConts.sort((a, b) => {
						return a.name>b.name?1:a.name<b.name?-1:0;
					});

					tmpCont.contacts = tmpConts;
				}
				
				tmpCont.count = tmpConts.length;
				if( item === '' ) {
					emptyRoleContacts = tmpCont;
				} else {
					tmpContacts.push(tmpCont);
				}
				
			});

			tmpContacts.sort((a, b) => {
				if( a.role === '' ) {
					return -1;
				} else if( b.role === '' ) {
					return -1;
				} else {
					return a.role>b.role?1:a.role<b.role?-1:0;
				}
				
			});

			tmpContacts.push(emptyRoleContacts);

			if( tmpContacts.length > 0 ) {
				this.contacts = tmpContacts;
			}
			
			this.error = undefined;
		}
		if( result.error ) {
			this.error = result.error;
			this.contacts = undefined;
		}
	}
}