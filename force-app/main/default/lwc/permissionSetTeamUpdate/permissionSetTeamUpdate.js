import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import searchTeamsByPermission from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.searchTeamsByPermission';
import removeTeamFromPermissionSet from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.removeTeamFromPermissionSet';

export default class permissionSetTeamUpdate extends LightningElement {

	selectedPermissionSetId;
	showSpinner = false;
	error;
	teamInfo;
	teams;

	@wire(searchTeamsByPermission, {permissionSetId: '$selectedPermissionSetId'})
	getTeams(result){
		this.teamInfo = result;
		if( result.data ) {
			let teams = [];
			JSON.parse(result.data).forEach(x => {
				let tmp = {};
				let values = x.split('|');
				tmp.label = values[0];
				tmp.value = values[1];
				teams.push(tmp);
			})
			teams.sort((a,b) => {
				return a.label>b.abel?1:a.label<b.label?-1:0;
			});

			this.teams = teams;
			this.error = undefined;
		}
		if( result.error ) {
			this.teams = undefined;
			this.error = error;
		}

	}

	handleSection(event) {
		this.selectedPermissionSetId = event.detail[0].Id;
		refreshApex(this.teamInfo);
	}

	handleDelete(event) {
		this.showSpinner = true;
		let teamName = event.target.id.split('-')[0];
		this.removeTeamFromPermissionSet(this.selectedPermissionSetId, teamName);
	}

	removeTeamFromPermissionSet(permissionSetId, team) {
		removeTeamFromPermissionSet({
			'permissionSetId':permissionSetId,
			'team': team
		})
		.then(result => {
			this.error = undefined;
			refreshApex(this.teamInfo);
			this.showSpinner = false;
			this.showNotification();

		})
		.catch(error => {
			this.error = error;
			this.showSpinner = false;
		})

	}

	showNotification() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'The selected team is removed from current permission set.',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }


	handleCancel() {
		this.dispatchEvent(new CustomEvent('cancel'));
	}
}