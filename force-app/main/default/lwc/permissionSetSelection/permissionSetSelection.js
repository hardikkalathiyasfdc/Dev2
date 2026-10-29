import { LightningElement, track, wire } from 'lwc';
import searchPermissionSet from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.searchPermissionSet';
import savePermissionSets from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.savePermissionSets';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TEAM_FIELD from '@salesforce/schema/User.BP_Team__c';

export default class permissionSetSelection extends LightningElement {
	searchString;
	value = [];

	@track selectedPermissions;

	@track permissions;
	error;
	teams;

	@wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: TEAM_FIELD })
     wiredPickListValue({ data, error }){
            if(data){
                
                let results = [];
                data.values.forEach(item => {
                	let tmp = {};
                	tmp.label = item.label;
                	tmp.value = item.value;
                	results.push(tmp);
                });
                
                results.sort((a, b) => {
                	return a.label > b.label?1:a.label<b.label?-1:0;
                });

                this.teams = results;
                this.error = undefined;
            }
            if(error){
                this.error = error;
                this.pickListvalues = undefined;
            }
        }

	connectedCallback() {
	}

	changePermissionSetSearch(event) {
		let searchString = event.target.value;
		if( searchString.length < 2 ) {
			return;
		}
		
		this.searchString = searchString;
		this.searchPermissionSet();
		
	}

	handleChange(e) {
        this.value = e.detail.value;
    }

	searchPermissionSet() {
		searchPermissionSet({
			'searchString':this.searchString
		})
		.then(result => {
			this.showSearchResult = true;
			let tmpResult = JSON.parse(result);
			this.permissions = tmpResult;
			this.error = undefined;

		})
		.catch(error => {
			this.error = error;
			this.permissions = undefined;
		});
	}

	onblur(event) {
		this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-close');
		this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-open');
	}

	onfocus(event) {
		this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-open');
		this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-close');
	}

	removeSelection(event) {
		let selectedRowId = event.currentTarget.id.split('-')[0];
		this.selectedPermissions = this.selectedPermissions.filter(element => element.Id !== selectedRowId);
	}

	getSelectedRows(event) {
		let selectedRowId = event.target.id.split('-')[0];

		let selected = {};
		this.permissions.forEach(item => {
			if( item.Id === selectedRowId ) {
				selected.Id = item.Id;
				selected.Label = item.Label;

			}
		});

		if( this.selectedPermissions === undefined ) {
			this.selectedPermissions = [];
		}

		let found = this.selectedPermissions.find(element => element.Id === selected.Id);

		if( found === undefined ) {
			this.selectedPermissions.push(selected);
		}

		this.template.querySelector('[data-id="lookup-pill"]').classList.add('slds-is-close');
		this.template.querySelector('[data-id="lookup-pill"]').classList.remove('slds-is-open');

		this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-close');
		this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-open');
	}


	handleCancel() {
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	handleSave() {
		if( this.selectedPermissions === undefined || this.value.length === 0) {
			this.error = 'Please select at least one Permission Set and one Team to save.';
			return;
		}

		let permissionSetIds = this.selectedPermissions.map(element => element.Id);

		savePermissionSets({'permissionSet':JSON.stringify(permissionSetIds), 'teams':JSON.stringify(this.value)})
			.then(result => {
				this.dispatchEvent(new CustomEvent('cancel'));
				this.error = undefined;
			})
			.catch(error => {
				console.log(error);
				this.error = error;
			});
	}

}