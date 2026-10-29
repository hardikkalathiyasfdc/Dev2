import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBPOrgDefaults from '@salesforce/apex/GenerateBioReportAuraCtrl.getBPOrgDefaults';
import getCanAccessShortBio from '@salesforce/apex/GenerateBioReportAuraCtrl.getCanAccessShortBio';
import getRestrictedContactForGenerateBio from '@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedContactForGenerateBio';
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';

export default class generateBioReport extends NavigationMixin(LightningElement) {

	selectedContactIds = [];
	selectedListId;
	url;
	BPOrgDefaults;
	disableSaveButton = false;
	accessShortBio;
	callShortBio = 'false';
	includeListsEvents = false;
	includeListsEventsOnContactsTab = true;
	includeRSVPMembers = false;
	contactDisplayFields = ['Search_Display_Name__c', 'Title', 'Email_Org_Name__c'];
	contactSearchFields = ['Search_Display_Name__c', 'Email'];
	contactDisplayFieldPrefixes = ['', '', ''];
	disableNewRecord = false;
	showRecentlyViewed = true;

	@wire(getCanAccessShortBio) wireAccessShortBio(result) {
		if (result.data) {
			this.accessShortBio = result.data == 'true';
		}
	}

	@wire(getBPOrgDefaults) getDefaultValues(result) {
		if (result.data) {
			this.BPOrgDefaults = JSON.parse(result.data);
		}
	}

	handleCancel() {
		this.selectedContactIds = [];
		this.template.querySelector('c-generic-lookup').clearSelection();
		this.template.querySelector('c-list-selection').clearSelection();
	}

	listSelected(event) {
		this.selectedListId = event.detail.listId;
		this.includeListsEvents = event.detail.includeListsEvents;
		this.includeRSVPMembers = event.detail.includeRSVPMembers;
		this.disableSaveButton = false;
		if (parseInt(event.detail.count, 10) > 2000) {
			this.disableSaveButton = true;
			this.showToast('Warning', 'This list is over the limit, for assistance contact bpsalesforceteam@e.bloomberg.org.', 'warning', 'sticky');
		}
	}

	handleShortBioSave() {
		this.callShortBio = 'true';
		this.handleSave();
	}

	handleSave() {
		let include = this.includeListsEvents === true ? 'yes' : 'no';
		let includeListsEventsOnContactsTab = this.includeListsEventsOnContactsTab === true ? 'yes' : 'no';
		let includeRsvp = this.includeRSVPMembers === true ? 'yes' : 'no';
		let actionName = this.callShortBio == 'true' ? 'shortBio' : 'bio';
		if (this.selectedListId !== undefined) {
			this.url = '/apex/DocGeneration?docGenerateType=MultiBioDoc&actionName=' + actionName +
				'&short=' + this.callShortBio + '&includeListsEvents=' + include + '&includeRSVPMembers=' +
				includeRsvp + '&listId=' + this.selectedListId + '&retURL=/lightning/n/Generate_Bio_Report';
			this.navigateToWebPage();
			this.selectedListId = undefined;
		}
		if (this.selectedContactIds.length > 0) {
			getRestrictedContactForGenerateBio({
				contactIds: this.selectedContactIds
			}).then((result) => {
				if (result) {
					let message = 'This List you selected has ' + result + ' Private Contact(s).';

					if (!hasPrivateNameFieldsAccess) {
						message +=
							'\n\n' +
							`You've encountered a problem with some of the records you selected ` +
							`(${result} records are not exporting). ` +
							`Please contact brmpartnerships@bloomberg.org for further assistance.`;
					}
					this.showToast('Warning!', message, 'warning', 'sticky');
				}
			}).catch((error) => {
				this.showToast('Error', error.body.message, 'error', 'dismissible');
			});
			let selectedIds = this.selectedContactIds.join(";");
			this.url = '/apex/DocGeneration?docGenerateType=MultiBioDoc&&actionName=' + actionName +
				'&short=' + this.callShortBio + '&includeListsEvents=' + includeListsEventsOnContactsTab + '&includeRSVPMembers=' +
				includeRsvp + '&id=' + selectedIds + '&retURL=/lightning/n/Generate_Bio_Report';
			// Now, navigate to the webpage after the toast logic, if toast is enabled comment below webpage call.
			this.navigateToWebPage();
		}
	}

	showToast(title, message, variant, mode) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant,
			mode: mode
		});
		this.dispatchEvent(event);
	}

	navigateToWebPage() {
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__webPage',
			attributes: {
				url: this.url
			}
		}).then(url => {
			window.open(url, "_self");
		});
	}

	handleCheckboxChange(event) {
		this.includeListsEvents = event.detail;
	}

	handleCheckboxChangeOnContactTab(event) {
		this.includeListsEventsOnContactsTab = event.detail.checked;
	}

	handleRSVPChange(event) {
		this.includeRSVPMembers = event.detail;
	}

	contactSelected(event) {
		this.selectedContactIds = event.detail.selectedIds;
	}
}