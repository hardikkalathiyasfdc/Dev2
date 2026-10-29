import { LightningElement, track, wire, api } from 'lwc';
import searchUser from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.searchUser';

export default class userSearch extends LightningElement {
	@api multiple;
	@api lookupLabel

	availableUsers;
	searchString;
	message;
	selectedUsers;

	handleSearchChange(event) {
		this.availableUsers = undefined;
		let searchString = event.target.value;
		if( searchString.length > 2 ) {
			this.searchUser(searchString);
			this.onfocus();
		} else {
			this.onblur();
			return;
		}
	}

	searchUser(searchString) {
		searchUser({
			'searchString': searchString
		})
		.then(result => {
			let availableUsers = JSON.parse(result);
			this.availableUsers = availableUsers;
			this.error = undefined;
		})
		.catch(error => {
			this.availableUsers = undefined;
			this.error = error;
		})
	}

	removeSelection(event) {
		let selectedRowId = event.currentTarget.id.split('-')[0];
		this.selectedUsers = this.selectedUsers.filter(element => element.Id !== selectedRowId);

		this.updateSelection();
	}

	getSelectedRows(event) {
		let selectedRowId = event.target.id.split('-')[0];

		let selected = {};
		this.availableUsers.forEach(item => {
			if( item.Id === selectedRowId ) {
				selected.Id = item.Id;
				selected.Name = item.Name;

			}
		});

		if( this.selectedUsers === undefined ) {
			this.selectedUsers = [];
		}

		let found = this.selectedUsers.find(element => element.Id === selected.Id);

		if( found === undefined ) {
			if( this.multiple === 'true' ) {
				this.selectedUsers.push(selected);
			} else {
				this.selectedUsers[0] = selected;
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
		const selectedEvent = new CustomEvent('selected', { detail: this.selectedUsers });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
	}

	onblur(event) {
		this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-close');
		this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-open');
	}

	onfocus(event) {
		this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-open');
		this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-close');
	}
}