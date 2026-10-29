import { LightningElement, track, wire, api } from 'lwc';
import searchPermissionSet from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.searchPermissionSet';

export default class permissionSetLookup extends LightningElement {
	@api multiple;
	@api lookupLabel

	permissions;
	searchString;
	message;
	selectedPermissions;

	handleSearchChange(event) {
		this.permissions = undefined;
		let searchString = event.target.value;
		if( searchString.length > 2 ) {
			this.searchPermissionSet(searchString);
			this.onfocus();
		} else {
			this.onblur();
			return;
		}
	}

	searchPermissionSet(searchString) {
		searchPermissionSet({
			'searchString':searchString
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

		this.updateSelection();
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
			if( this.multiple === 'true' ) {
				this.selectedPermissions.push(selected);
			} else {
				this.selectedPermissions[0] = selected;
			}
			
		}

		this.template.querySelector('[data-id="lookup-pill"]').classList.add('slds-is-close');
		this.template.querySelector('[data-id="lookup-pill"]').classList.remove('slds-is-open');

		this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-close');
		this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-open');
		this.availableUsers = undefined;
		this.template.querySelector('[data-id="user-copy-to"]').value=undefined;

		this.updateSelection();
	}

	updateSelection() {
		const selectedEvent = new CustomEvent('selected', { detail: this.selectedPermissions });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
	}
}