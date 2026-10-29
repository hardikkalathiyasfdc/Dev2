import { LightningElement, track, wire, api } from 'lwc';
import { createRecord, deleteRecord } from "lightning/uiRecordApi";
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningAlert from 'lightning/alert';
import getUnplannedGuests from '@salesforce/apex/EventMangementAuraCtrl.getUnplannedGuests';
import LightningConfirm from 'lightning/confirm';
const columns = [
	{ label: 'FirstName', fieldName: 'FirstName__c' },
	{ label: 'LastName', fieldName: 'LastName__c' },
	//{ label: 'Phone', fieldName: 'Phone__c', type: 'phone' },
	{ label: 'Notes', fieldName: 'Notes__c' }
];

export default class eventUnplannedGuests extends LightningElement {

	@api recordId;
	@track isModalOpen = false;
	selectedRow;
	guests;
	newRecordId
	guestsCount;
	showGuests = false;
	showContactCreate = false;
	columns = columns;
	wiredGuestResult;


	getSelectedRow(event) {
		const selectedRows = event.detail.selectedRows;
		if (selectedRows.length > 0)
			this.selectedRow = selectedRows[0];
	}

	get title() {
		return 'New Guests at Check-in (' + this.guestsCount + ')'
	}

	async handleAlertClick() {
		await LightningAlert.open({
			message: 'Please select a Guest',
			theme: 'error', // a red theme intended for error states
			label: 'Error', // this is the header text
		});
		//Alert has been closed
	}

	async handleDelete(event) {
		if (this.selectedRow) {
			this.isModalOpen = true;
			// alert('this.isModalOpen 51',this.isModalOpen);
			/*
			const result = await LightningConfirm.open({
				message: 'Are you sure you want to remove this guest?',
				label: 'Remove Guest',
				// setting theme would have no effect
			});
			if (result) {
				this.deleteUnplanedGuest(event)
			}
			*/
		}
		else {
			// this.handleAlertClick();
			this.dispatchEvent(
				new ShowToastEvent({
					title: "Error",
					message: 'Please select a Guest.',
					variant: "Error",
					mode: "dismissable"
				}),
			);
		}

	}
	handleDeleteFromModal(event) {
		this.isModalOpen = false;
		//alert('this.isModalOpen 68',this.isModalOpen);
		this.deleteUnplanedGuest(event);
	}
	closeModal() {
		this.isModalOpen = false;
	}

	deleteUnplanedGuest(event) {
		// alert('this.isModalOpen 76',this.isModalOpen);
		deleteRecord(this.selectedRow.Id)
			.then(() => {
				if (event) {
					this.dispatchEvent(
						new ShowToastEvent({
							title: "Success",
							message: 'Guest was successfully removed.',
							variant: "success",
						}),
					);
				}
				refreshApex(this.wiredGuestResult);
			})
			.catch((error) => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Error deleting record",
						message: error.body.message,
						variant: "error",
					}),
				);
			});

	}

	addGuestToCampaign(newContactCreated) {
		const fields = {};
		fields['ContactId'] = this.newRecordId;
		fields['CampaignId'] = this.recordId;
		fields['AttendedStatus__c'] = 'Yes - In Person';
		fields['Source__c'] = 'New Guest at Check-in';
		fields['UB_Notes__c'] = this.selectedRow.Notes__c;
		const recordInput = { apiName: 'CampaignMember', fields };
		let msg = newContactCreated ? 'New Contact has been created and added to this Event as Attended.' : 'Contact has been added to this Event as Attended.';
		createRecord(recordInput)
			.then((resp) => {
				this.deleteUnplanedGuest();
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Success",
						message: msg,
						variant: "success",
					}),
				);
			})
			.catch((error) => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Error Adding Guest to Event",
						message: (error.body && error.body.output && error.body.output.errors) ? 'Contact is already on the Event as a guest. Please find the guest to update their attendance and remove from New Guest at Check-in.' : error.body.message,
						variant: "error",
						mode: "sticky"
					}),
				);
			});
	}
	@wire(getUnplannedGuests, { eventId: '$recordId' })
	wireGuests(result) {
		this.wiredGuestResult = result;
		if (result.data) {
			let guests = JSON.parse(result.data);
			this.guests = guests;
			this.guestsCount = guests.length;
			if (guests.length > 0) {
				this.showGuests = true;
			}
		}
	}
	handleAdd(event) {
		if (this.selectedRow)
			this.showContactCreate = true;
		else {
			// this.handleAlertClick();
			this.dispatchEvent(
				new ShowToastEvent({
					title: "Error",
					message: 'Please select a Guest.',
					variant: "Error",
					mode: "dismissable"
				}),
			);
		}

	}
	handleCreationSuccess(event) {
		this.showContactCreate = false;
		this.newRecordId = event.detail.Id ? event.detail.Id : event.detail;
		this.addGuestToCampaign(event.detail.Id);

	}
	handleCreationCancel(event) {
		this.showContactCreate = false;
	}


}