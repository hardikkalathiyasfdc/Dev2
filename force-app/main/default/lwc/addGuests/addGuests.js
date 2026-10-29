import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveContactGuests from '@salesforce/apex/EventMangementAuraCtrl.saveContactGuests';
import saveListGuests from '@salesforce/apex/EventMangementAuraCtrl.saveListGuests';
import getContactIdsByTagIds from '@salesforce/apex/EventMangementAuraCtrl.getContactIdsByTagIds';
import getRestrictedContactCount from '@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedContactCountFromLists';
import getRestrictedContactForContacts from '@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedContactForGenerateBio';
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';

export default class addGuests extends LightningElement {
	@api recordId;
	@track items;
	showSpinner = false;
	selectedLists;
	selectedContactIds;
	selectedRecommendedBy;
	actionLabel = 'Add Lists';
	value = [];
	selectedTagIds = [];
	error;
	selectedSource;
	tabValue = 'list';
	contactDisplayFields = ['Search_Display_Name__c', 'Title', 'Organization_Name_formula__c', 'Email'];
	contactSearchFields = ['Search_Display_Name__c', 'Email'];
	contactDisplayFieldPrefixes = ['', '', ''];
	listDisplayFields = ['Name', 'ListMemberCount__c', 'Event_Start_Date_Time__c'];
	listDisplayFieldPrefixes = ['', 'List Member Count', 'Event Start Date/Time'];
	listSearchConfig = JSON.stringify({
		primaryField: 'Name',
		primaryWeight: 100,
		convertedField: 'Converted_List_Name__c',
		convertedWeight: 80
	});
	listFilterClause = 'RecordType.DeveloperName != \'Organization\'';

	rsvpAttendanceOptions = {
		'RSVP': [
			{ label: 'Pend', value: 'Pend' },
			{ label: 'Yes', value: 'Yes' },
			{ label: 'Yes - Cocktails Only', value: 'Yes - Cocktails Only' },
			{ label: 'Yes - In Person', value: 'Yes - In Person' },
			{ label: 'Yes - Virtually', value: 'Yes - Virtually' },
			{ label: 'No', value: 'No' },
			{ label: 'Waitlist 1', value: 'Waitlist 1' },
			{ label: 'Waitlist 2', value: 'Waitlist 2' }
		],
		'Attendance': [
			{ label: 'Yes - Cocktails Only', value: 'Yes - Cocktails Only' },
			{ label: 'Yes - In Person', value: 'Yes - In Person' },
			{ label: 'Yes - Virtually', value: 'Yes - Virtually' },
			{ label: 'Did Not Attend', value: 'Did Not Attend' },
			{ label: 'Did Not Attend - Cancelled RSVP', value: 'Did Not Attend - Cancelled RSVP' }
		]
	};

	get shallDisableSaveButton() {
		return (this.tabValue == 'list' && !this.selectedLists) ||
			(this.tabValue == 'contact' && !this.selectedContactIds) ||
			(this.tabValue == 'Tags' && this.selectedTagIds.length == 0);
	}

	connectedCallback() {
		let items = [];
		items.push({ label: 'CC Staff', value: 'as' });
		this.items = items;
	}

	handleListUpdate(event) {
		const selectedRecords = event.detail.selectedRecords || [];
		this.selectedLists = selectedRecords.map(r => ({ Id: r.Id, Name: r.fields && r.fields.Name ? r.fields.Name : '' }));
		if (!this.selectedLists.length) this.selectedLists = undefined;
		this.error = undefined;
	}

	handleContactUpdateViaLookup(event) {
		this.selectedContactIds = event.detail.selectedIds;
		this.error = undefined;
	}

	handleRecommendedBy(event) {
		this.selectedRecommendedBy = event.detail;
	}

	handleRSVPAndAttendanceSelectionChange(event) {
		this.rsvpValue = event.detail?.RSVP;
		this.attendanceValue = event.detail?.Attendance;
	}

	handleActive(event) {
		this.tabValue = event.target.value;
		this.error = undefined;
		if (this.tabValue === 'list') {
			this.selectedContactIds = undefined;
			this.showListTierOption = true;
			this.actionLabel = 'Add Lists';
			this.template.querySelector('c-generic-lookup')?.clearSelection();
			this.items = this.items.filter(x => x.value !== 'waitingList');
		} else if (this.tabValue === 'contact') {
			this.selectedLists = undefined;
			this.showListTierOption = false;
			this.actionLabel = 'Add Contacts';
			this.template.querySelector('[data-id="list-lookup"]')?.clearSelection();
		} else {
			this.selectedLists = undefined;
			this.selectedContacts = undefined;
			this.showListTierOption = false;
			this.actionLabel = 'Add Tags';
			this.template.querySelector('[data-id="list-lookup"]')?.clearSelection();
			this.template.querySelector('c-generic-lookup')?.clearSelection();
		}
	}

	handleChange(event) {
		let value = event.detail.value;
		this.value = value;
	}

	handleSave() {
		this.showSpinner = true;
		this.error = undefined;
		if (this.selectedLists) {
			const listIds = this.selectedLists.map(item => item.Id);
			getRestrictedContactCount({ listIds: listIds })
				.then(result => {
					if (result > 0) {
						this.showRestrictedWarning(result);
					}
				}).catch((error) => {
					this.showNotification('Error', error.body.message, 'error');
				});

			saveListGuests({
				campaignIds: JSON.stringify(this.selectedLists),
				campaignId: this.recordId,
				option: this.value.join(''),
				rsvpValue: this.rsvpValue,
				attendanceValue: this.attendanceValue
			}).then(result => {
				this.showSpinner = false;
				let conts = result;
				let saveResult = true;
				let displayMsg = '';
				Object.keys(conts).forEach(x => {
					if (conts[x] && x != 'restrictedContactCount') {
						saveResult = false;
						displayMsg += '<span class="slds-text-color_error">' + x +
							'</span>: <span>' + conts[x].join(', ') +
							'</span><br/>';
					}
				})
				if (saveResult) {
					this.showNotification('Success', 'The members in List are added successfully.', 'success', 'dismissable');
					this.dispatchEvent(new CustomEvent('cancel'));
				} else {
					this.error = displayMsg;
				}
			}).catch(error => {
				this.showSpinner = false;
				this.showNotification('Error', error.body.message, 'error');
			})
		}
		if (this.selectedContactIds && this.selectedContactIds.length > 0) {
			let contactIds = this.selectedContactIds;
			this.addContactGuests(contactIds);
		}
		if (this.selectedTagIds) {
			let contactIds = [];
			getContactIdsByTagIds({
				tagIds: this.selectedTagIds
			}).then(result => {
				contactIds = result;
				if (contactIds.length > 0) {
					this.addContactGuests(contactIds);
				}
			}).catch(error => {
				console.error('Error:', error);
			});
		}
	}

	addContactGuests(contactIds) {
		getRestrictedContactForContacts({ contactIds: contactIds })
			.then(result => {
				if (result > 0) {
					this.showRestrictedWarning(result);
				}
			}).catch((error) => {
				this.showNotification('Error', error.body.message, 'error');
			});

		let recommendedByName = '';
		if (this.selectedSource) {
			recommendedByName = this.selectedSource;
		}
		let option = this.value.join('');
		saveContactGuests({
			campaignId: this.recordId,
			cntIds: contactIds.join(','),
			option: option,
			recommendedBy: recommendedByName,
			rsvpValue: this.rsvpValue,
			attendanceValue: this.attendanceValue
		}).then(result => {
			this.showSpinner = false;
			let conts = result;
			let saveResult = true;
			let displayMsg = '';
			Object.keys(conts).forEach(x => {
				if (conts[x] && x != 'restrictedContactCount') {
					saveResult = false;
					displayMsg += '<span class="slds-text-color_error">' + x +
						'</span>: <span>' + conts[x].join(', ') +
						'</span><br/>';
				}
			})
			if (saveResult) {
				this.showNotification('Success', 'The Contacts are added successfully.', 'success', 'dismissable');
				this.dispatchEvent(new CustomEvent('cancel'));
			} else {
				this.error = displayMsg;
			}
		}).catch(error => {
			this.showSpinner = false;
			this.showNotification('Error', error.body.message, 'error', 'dismissable');
		});

	}

	handleCancel() {
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	showRestrictedWarning(restrictedCount) {
		let message;
		if (hasPrivateNameFieldsAccess) {
			message = 'Your results contain ' + restrictedCount + ' Private Contact(s).';
		} else {
			message = `You've encountered a problem with some of the records you selected ` +
				`(${restrictedCount} records are not exporting). ` +
				`Please contact brmpartnerships@bloomberg.org for further assistance.`;
		}
		this.showNotification('Warning', message, 'warning', 'sticky');
	}

	showNotification(title, message, variant, mode) {
		const evt = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant,
			mode: mode,
		});
		this.dispatchEvent(evt);
	}

	handleInputChange(event) {
		this.selectedSource = event.detail.value;
	}

	tagSelected(event) {
		var selectedData = event.detail.arrItems;
		this.selectedTags = event.detail.arrItems;
		this.selectedTagIds = [];
		selectedData.forEach(selectedData => {
			this.selectedTagIds.push(selectedData.value);
		});
	}
}