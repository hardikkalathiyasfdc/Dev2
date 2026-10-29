import { LightningElement, track, wire, api } from 'lwc';
import getListOrganizations from '@salesforce/apex/CampaignMembersAuraController.getListOrganizations';

export default class listOrganizations extends LightningElement {
	@api recordId;

	showButton = false;
	showAll = true;
	buttonLabel;
	error;
	listOrganizations;
	allOrgs;
	numberOfListOrganization;

	@wire(getListOrganizations, { organizationId: '$recordId' }) 
	getOrganizations(result){
		if( result.data ) {

			let retrunValues = result.data;

			let orgs = [];
            retrunValues.forEach(item => {
            	let org = {};
            	org.Id = item.Id;
            	org.Name = item.List__r.Name;
            	org.url = '/'+item.Id;

            	orgs.push(org);
            });

			orgs.sort((a, b) => {
                return a.Name > b.Name?1:a.Name < b.Name?-1:0;
            });

			this.allOrgs = orgs;

            if( retrunValues.length > 3) {
				this.listOrganizations = orgs.slice(0,3);
                this.showButton = true;
                this.showAll = false;
            } else {
				this.listOrganizations = orgs;
            	this.showButton = false;
            }
            
            this.numberOfListOrganization = retrunValues.length;
		}

		if( result.error ) {
			this.error = result.error;
		}
	}

	showContent(event) {
        
        if( this.showAll === true ) {
			this.listOrganizations = this.allOrgs.slice(0,3);
        	this.buttonLabel = 'Show Less';
            this.showAll = false;
        } else {
			this.listOrganizations = this.allOrgs;
        	this.buttonLabel = 'Show All';
            this.showAll = true;
        }
    }

}