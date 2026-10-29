import { LightningElement, wire, track } from 'lwc';
import { getErrorMessages } from 'c/utils';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import searchContacts from '@salesforce/apex/BlinkContactController.searchContacts';
import getBgiveContact from '@salesforce/apex/BlinkContactController.getBgiveContact';
import brmLink from '@salesforce/apex/BlinkContactController.brmLink';
import bgiveLink from '@salesforce/apex/BLinkContactService.bgiveLink';
import brmUnlink from '@salesforce/apex/BlinkContactController.brmUnlink';
import bgiveUnlink from '@salesforce/apex/BLinkContactService.bgiveUnlink';
import getContact from '@salesforce/apex/BlinkContactController.getContact';
import isBgiveMasterContactInfoEnabled from '@salesforce/apex/BlinkContactController.isBgiveMasterContactInfoEnabled';
import updateBrmContact from '@salesforce/apex/BLinkContactService.updateBRMContact';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
const BGIVE_COLUMNS = [
	{
		label: 'First Name',
		fieldName: 'first_name',
		initialWidth: 120,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Middle Name',
		fieldName: 'middle_initial',
		initialWidth: 120,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Last Name',
		fieldName: 'last_name',
		initialWidth: 120,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Preferred First Name',
		fieldName: 'preferred_first_name',
		initialWidth: 140,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Linked Status',
		fieldName: 'brmIdLink',
		initialWidth: 140,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
		type: 'url',
		typeAttributes: { label: { fieldName: 'brmLinked' }, target: '_blank' },
	},
	{
		label: 'Organization',
		fieldName: 'primary_org_sort_name',
		initialWidth: 200,
		typeAttributes: { tooltip: { fieldName: 'organization' } },
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Title',
		fieldName: 'title',
		initialWidth: 100,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Email',
		fieldName: 'email',
		initialWidth: 100,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Bgive Id',
		fieldName: 'bgiveRecordLink',
		initialWidth: 100,
		type: 'url',
		typeAttributes: { label: { fieldName: 'id' }, target: '_blank' },
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
];

const BRM_COLUMNS = [
	{
		label: 'First Name',
		fieldName: 'FirstName',
		initialWidth: 200,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Middle Name',
		fieldName: 'MiddleName',
		initialWidth: 150,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Last Name',
		fieldName: 'LastName',
		initialWidth: 200,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Preferred First Name',
		fieldName: 'Preferred_First_Name__c',
		initialWidth: 200,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{ label: 'Linked Status', fieldName: 'bgiveLinked', initialWidth: 140 },   
	{
		label: 'Organization',
		fieldName: 'organization',
		initialWidth: 200,
		typeAttributes: { tooltip: { fieldName: 'organization' } },
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Title',
		fieldName: 'Title',
		initialWidth: 100,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Email',
		fieldName: 'Email',
		initialWidth: 100,
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
	{
		label: 'Bgive Id',
		fieldName: 'bgiveRecordLink',
		initialWidth: 100,
		type: 'url',
		typeAttributes: { label: { fieldName: 'Bgive_Id__c' }, target: '_blank' },
		cellAttributes: {
			class: { fieldName: 'linkedColor' },
		},
	},
];

export default class BlinkContact extends NavigationMixin(LightningElement) {
	/**
	 * Booleans
	 */
	showSpinner = false;
	disableSearch = true;
	showSearchResults = false;
	showSaveButton = false;
	isButtonDisabled = true;
	isFromContact = false;
	isLinked = false;
	isUnlinkChecked = false;
	isBgiveMasterContactInfoEnabled = false;
	_isBgiveLinkButtonDisabled = false;

	/**
	 * Arrays and Objects
	 */
	bgiveData = [];
	@track brmData = [];
	brmContactDetails = {};
	solicitorHistoryOptions = [
		{ label: 'Enabled', value: 'Enabled' },
		{ label: 'Disabled', value: 'Disabled' },
	];
	linkOptions = [
		{ label: 'Linked', value: 'Linked' },
		{ label: 'Unlinked', value: 'Unlinked' },
	];

	/**
	 * Strings
	 */
	solicitorStatus = 'Enabled';
	noBRMContactsMessage = 'There are no matching contacts in BRM.';
	noBgiveContactsMessage = 'There are no matching contacts in Bgive.';

	/**
	 * Cols and Global undefined
	 */
	_buttonLabelOverride;
	bgiveColumns = BGIVE_COLUMNS;
	bgiveLinkedStatusValue;
	_preSelectedRow;
	preSelectedContact;
	recordId;
	firstName;
	lastName;
	middleName;
	preferredFirstName;
	searchKeyFirstName;
	searchKeyLastName;
	brmContactOrganizationName;
	selectedBgiveRow;
	selectedBRMRow;
	currentPageReference;
	bgiveContact;
	objectInfo;
    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        }
    }

    get canReadRestricted() {
        return  this.objectInfo && this.objectInfo.fields?.Restricted__c;
    }

	get brmColumns() {
		let columns = [...BRM_COLUMNS];
		if (this.canReadRestricted) {
			const privateColumn = {
				label: 'Private',
				fieldName: 'Restricted__c',
				initialWidth: 140,
				type: 'boolean',
				cellAttributes: {
			class: { fieldName: 'linkedColor' },
		      },
			};

			// find index after "Legal Name"
			const insertIndex = columns.findIndex(
				col => col.fieldName === 'Preferred_First_Name__c'
			);

			if (insertIndex !== -1) {
				columns.splice(insertIndex + 1, 0, privateColumn);
			}
		}
		return columns;
	}

	/**
	 * Getters and setters
	 */
	get isBRMData() {
		return this.brmData.length === 0 ? false : true;
	}

	get preSelectedRow() {
		return this._preSelectedRow;
	}

	set preSelectedRow(value) {
		this._preSelectedRow = value;
	}

	get isBgiveData() {
		return this.bgiveData.length === 0 ? false : true;
	}

	get showLinkedStatus() {
		return this.isFromContact && this.brmContactDetails?.Bgive_Id__c ? true : false;
	}

	set buttonLabel(value) {
		this._buttonLabelOverride = value;
	}

	get buttonLabel() {
		//If override present, it takes precedence
		if (this._buttonLabelOverride != null) {
			return this._buttonLabelOverride;
		}
		if (this.brmData.length === 0 && !this.isFromContact) {
			return 'Create in BRM and Link';
		} else if (this.isFromContact) {
			return 'Save';
		} else {
			return 'Link';
		}
	}

	get showMasterContactInfo() {
		return (this.bgiveData.length != 0 && this.brmData.length != 0) ||
			(this.bgiveData.length != 0 && this.brmData.length == 0) ||
			this.isFromContact ||
			this.showSearchResults
			? true
			: false;
	}

	get fromContactMasterInfo() {
		return this.brmContactDetails?.Bgive_Id__c == undefined ? false : true;
	}

	get showSearchSection() {
		return this.isFromContact && this.isLinked ? false : true;
	}

	get showBgiveContactCard() {
		return this.isFromContact && this.isLinked ? true : false;
	}

	get isBgiveLinkButtonDisabled() {
		return this._isBgiveLinkButtonDisabled;
	}

	get bgiveLinkedStatusOptions() {
		if (!this._isBgiveLinkButtonDisabled) {
			if (!this.isLinked) {
				return [{ label: 'Linked', value: 'Linked' }];
			} else {
				return [
					{ label: 'Linked', value: 'Linked' },
					{ label: 'Unlinked', value: 'Unlinked' },
				];
			}
		}
	}

	/*
	Description: ConnectedCallback, runs when DOM is loaded
	Jira Story : IM-21
	*/
	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			this.isFromContact = currentPageReference.state?.c__isFromContact;
			if (this.isFromContact) {
				this.showSaveButton = true;
				this.disableSearch = false;
			}
			this.recordId = currentPageReference.state?.c__recordId;
		}
	}

	/*
	Description: ConnectedCallback, runs when DOM is loaded
	Jira Story : IM-21
	*/
	@wire(getContact, { Id: '$recordId' })
	wiredContacts({ error, data }) {
		if (data) {
			this.brmContactDetails = data;
			this.brmContactOrganizationName = data.Account?.Name;
			let bgiveId = data.Bgive_Id__c;
			this.firstName = data.FirstName;
			this.lastName = data.LastName;
			this.searchKeyFirstName = data.Restricted__c ?  data.RestrictedFirstName__c :  data.FirstName;
			this.searchKeyLastName = data.Restricted__c ?  data.RestrictedLastName__c : data.LastName;
			this.middleName = this.brmContactDetails.MiddleName;
			this.preferredFirstName = this.brmContactDetails.Preferred_First_Name__c;
			this.showSearchResults = true;
			if (bgiveId) {
				this.getBgiveContact(bgiveId);
			} else {
				this.searchContacts(this.searchKeyFirstName, this.searchKeyLastName);
			}
		} else if (error) {
			console.error('Unhandled Exception Occurred in wiredContacts ', getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: ConnectedCallback, runs when DOM is loaded
	Jira Story : IM-21
	*/
	connectedCallback() {
		isBgiveMasterContactInfoEnabled()
			.then((result) => {
				this.isBgiveMasterContactInfoEnabled = result;
			})
			.catch((error) => {
				console.error('Error retrieving metadata setting:', getErrorMessages(error));
				this.isBgiveMasterContactInfoEnabled = false;
				this.handleError(error);
			});
	}

	/*
	Description: handles first name input change
	Jira Story : IM-21
	*/
	handleSearchKeyFirstInputChange(event) {
		this.searchKeyFirstName = event.detail.value;
	}

	/*
	Description: handles last name input change
	Jira Story : IM-21
	*/
	handleSearchKeyLastInputChange(event) {
		this.searchKeyLastName = event.detail.value;
		if (this.searchKeyLastName.length === 0) {
			this.disableSearch = true;
		} else {
			this.disableSearch = false;
		}
	}

	/*
	Description: handles the search function
	Jira Story : IM-21
	*/
	handleSearch() {
		this.selectedBgiveRow = null;
		this.selectedBRMRow = null;
		this.buttonLabel = null;
		this.firstName = '';
		this.lastName = '';
		this.middleName = '';
		this.preferredFirstName = '';
		this.bgiveData = [];
		this.brmData = [];
		this.isDirectContact = false;
		this.showSearchResults = true;
		this.isButtonDisabled = true;
		//IM-404: Search is not working if the Name has spaces at start or end, it is not possible to have space at either start or end, hence trimming.
		this.searchContacts(String(this.searchKeyFirstName).trimEnd().trimStart(), String(this.searchKeyLastName).trimEnd().trimStart());
	}

	/*
	Description: handles the first name change
	Jira Story : IM-21
	*/
	handleFirstNameChange(event) {
		this.firstName = event.detail.value;
	}

	/*
	Description: handles the middle name change
	Jira Story : IM-21
	*/
	handleMiddleNameChange(event) {
		this.middleName = event.detail.value;
	}

	/*
	Description: handles the last name change
	Jira Story : IM-21
	*/
	handleLastNameChange(event) {
		this.lastName = event.detail.value;
	}

	/*
	Description: handles the preferred first name name change
	Jira Story : IM-21
	*/
	handlePreferredFirstNameChange(event) {
		this.preferredFirstName = event.detail.value;
	}

	/*
	Description: handles the solicitor change
	Jira Story : IM-21
	*/
	handleSolicitorChange(event) {
		this.solicitorStatus = event.detail.value;
	}

	/*
	Description: handles the Bgive link change picklist value change
	Jira Story : IM-21
	*/
	handleBgiveLinkedChange(event) {
		try {
			let value = event.detail.value;
			//Check if you should enable the button or not?
			if (this.bgiveLinkedStatusValue == value) {
				this.isButtonDisabled = true;
			} else {
				this.isUnlinkChecked = value === 'Unlinked';
				if (this.isUnlinkChecked) {
					this.isButtonDisabled = false;
				} else {
					this.isButtonDisabled = !this.selectedBgiveRow;
				}
			}
		} catch (error) {
			console.error('Unhandled Exception Occurred in handleBgiveLinkedChange ', getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: handles the selection of BRM row from the give data
	Jira Story : IM-21
	*/
	handleBRMRowSelection(event) {
		try {
			this.preSelectedRow = [];
			this.selectedBRMRow = event.detail.selectedRows[0];
			this.firstName = this.selectedBRMRow.FirstName;
			this.lastName = this.selectedBRMRow.LastName;
			this.middleName = this.selectedBRMRow.MiddleName;
			this.preferredFirstName = this.selectedBRMRow.preferredFirstName;
			//Perform validations to enable Save Button
			this.brmRowSelectionSaveButtonValidation();
		} catch (error) {
			console.error('Unhandled Exception Occurred in handleBRMRowSelection ', getErrorMessages(error));
		}
	}

	/*
	Description: Perform validations to enable Save Button when brm row is selected
	Jira Story : IM-404
	*/
	brmRowSelectionSaveButtonValidation() {
		if (this.selectedBRMRow.Bgive_Id__c || !this.selectedBgiveRow) {
			this.isButtonDisabled = true;
		} else if (!this.selectedBgiveRow?.brm_id) {
			this.isButtonDisabled = false;
			this.buttonLabel = 'Link';
		}
	}

	/*
	Description: handles the selection of Bgive row from the given data
	Jira Story : IM-21
	*/
	handleBgiveRowSelection(event) {
		try {
			this.selectedBgiveRow = event.detail.selectedRows[0];
			this._isBgiveLinkButtonDisabled = !this.isFromContact && !this.isLinked;
			//Auto Populate the Status to Linked
			if (!this._isBgiveLinkButtonDisabled) {
				this.bgiveLinkedStatusValue = 'Linked';
			}
			this.selectedBgiveContigId = this.selectedBgiveRow.contig_id;
			if (this.brmData.length === 0) {
				// if there is no BRM contacts and user selects BGive contact, we need to populate the firstname
				// lastname, middlename and preferredFirstName on Master Contact Info section.
				this.firstName = this.selectedBgiveRow.first_name;
				this.lastName = this.selectedBgiveRow.last_name;
				this.middleName = this.selectedBgiveRow.middle_initial;
				this.preferredFirstName = this.selectedBgiveRow.preferred_first_name;
			}
			//Perform validations to enable Save Button
			this.bgiveRowSelectionSaveButtonValidation();
		} catch (error) {
			console.error('Unhandled Exception Occurred in handleBgiveRowSelection ', getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: Perform validations to enable Save Button when bgive row is selected
	Jira Story : IM-404
	*/
	bgiveRowSelectionSaveButtonValidation() {
		if (this.selectedBgiveRow.brm_id) {
			this.isButtonDisabled = true;
		} else if (!this.selectedBRMRow && !this.isFromContact) {
			this.isButtonDisabled = false;
			this.buttonLabel = 'Create in BRM and Link';
		} else if (!this.selectedBRMRow?.Bgive_Id__c || (this.brmData.length === 0 && this.isFromContact)) {
			this.isButtonDisabled = false;
			this.buttonLabel = 'Link';
		}
	}

	/*
	Description: handles the save operation on click of button
	Jira Story : IM-21
	*/
	handleSave(event) {
		var buttonName = event.target.dataset.name;
		if (buttonName === 'Create in BRM and Link') {
			this.link();
		} else if (buttonName === 'Save' || buttonName === 'Link') {
			if (this.isUnlinkChecked) {
				this.unlink();
			} else {
				this.link();
			}
		}
	}

	/*
	Description: perform the search operation based on the keyword
	Jira Story : IM-21
	*/
	async searchContacts(searchKeyFirstName, searchKeyLastName) {

		try {
			this.showSpinner = true;
			const result = await searchContacts({ firstName: searchKeyFirstName, lastName: searchKeyLastName });
			if (result && result != null) {
				this.showSpinner = false;
				let brmContactsArray = result['brmContacts'];
				let bgiveContactsArray = result['bgiveContacts'];
				let biveBaseURL = result['bgiveBaseURL'];
				if (Array.isArray(brmContactsArray) && brmContactsArray.length > 0) {
					this.showSaveButton = true;
					this.brmData = brmContactsArray.map((item) => {
						 const isRestricted = item.Restricted__c === true;
						let linkedColor = 'slds-text-color_default';
						let bgiveLinked = item.Bgive_Id__c != null ? 'Linked' : '';
						let bgiveRecordLink = item.Bgive_Id__c != null ? biveBaseURL + '/show/users/' + item.Bgive_Id__c : '';
						return {
							...item,
							 'FirstName': isRestricted ? item.RestrictedFirstName__c : item.FirstName,
                              'MiddleName': isRestricted ? item.RestrictedMiddleName__c : item.MiddleName,
                              'LastName': isRestricted ? item.RestrictedLastName__c : item.LastName,
							  'organization' : item.Account.Restricted__c == true ? item.Account.Restricted_Org_Name__c : item.Account.Name,
							'linkedColor': linkedColor,
							'bgiveLinked': bgiveLinked,
							'bgiveRecordLink': bgiveRecordLink,
						};
					});
					const matched = this.brmData.find((item) => item.Id === this.recordId);
					this.preSelectedRow = matched ? [matched.Id] : [];
					this.preSelectedContact = matched;
				} else {
					this.showSaveButton = false;
					this.preSelectedRow = [];
				}
				if (Array.isArray(bgiveContactsArray) && bgiveContactsArray.length > 0) {
					this.showSaveButton = true;
					this.bgiveData = bgiveContactsArray.map((item) => {
						let isBRMIdExist = item.brm_id != undefined && item.brm_id != null && item.brm_id != '';
						let linkedColor = 'slds-text-color_default';
						let brmIdLink = isBRMIdExist ? '/' + item.brm_id : '';
						let brmLinked = isBRMIdExist ? 'Linked' : '';
						return {
							...item,
							'linkedColor': linkedColor,
							'brmIdLink': brmIdLink,
							'brmLinked': brmLinked,
							'bgiveRecordLink': biveBaseURL + '/show/users/' + item.id,
						};
					});
				} else {
					this.showSaveButton = false;
				}
			} else {
				this.showSpinner = false;
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in searchContacts ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: handles the search of Bgive Contact
	Jira Story : IM-21
	*/
	async getBgiveContact(bgiveid) {
		try {
			const result = await getBgiveContact({ bgiveId: bgiveid });
			if (result) {
				if (result != null) {
					this.bgiveContact = result;
					this.isLinked = true;
					this.bgiveLinkedStatusValue = 'Linked';
					this.isButtonDisabled = !this.isFromContact || this.bgiveLinkedStatusValue == 'Linked';
				}
			} else {
				this.showToast('Error', 'Bgive Contact Search Failed', 'error');
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in getBgiveContact ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: perform the link process of Brm and bgive contact records
	Jira Story : IM-21
	NOTES      : Modify the confirm message if Master Contact Info is enabled as a future Enhancement.
	*/
	async link() {
		const result = await LightningConfirm.open({
			message: 'Are you sure you want to proceed with the link?',
			variant: 'header',
			label: 'Confirmation',
			theme: 'warning',
		});
		if (result) {
			this.showSpinner = true;
			//IM-404: Separate transactions for BRM and Bgive Update
			this.checkLinkScenario();
		} else {
			this.showSpinner = false;
		}
	}

	/*
	Description: perform the link process of Brm and bgive contact records
	Jira Story : IM-404
	*/
	async checkLinkScenario() {
		let brmContact = this.isFromContact ? this.brmContactDetails : this.selectedBRMRow || this.preSelectedContact;
		let bgiveContact = JSON.stringify(this.selectedBgiveRow);
		let solicitorStatus = this.solicitorStatus;
		try {
			if (brmContact != null && !bgiveContact) {
				this.updateBrmContact(brmContact, solicitorStatus);
			} else {
				/**
				 * 1. If the contact is not present in BRM, create then contact then link (The link is a future call)
				 * 2. If the contacts are present, the make separate calls.
				 */
				if (brmContact == null && bgiveContact) {
					this.createBrmContactAndLink(brmContact, bgiveContact, solicitorStatus);
				} else {
					this.brmLink(brmContact, bgiveContact, solicitorStatus);
				}
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in checkLinkScenario ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: Update BRM Contact - When Bgive Contact is not present
	Jira Story : IM-404
	*/
	async updateBrmContact(brmContact, enableSolicitorHistory) {
		try {
			brmContact.FirstName = this.firstName;
			brmContact.LastName = this.lastName;
			brmContact.Preferred_First_Name__c = this.preferredFirstName;
			brmContact.MiddleName = this.middleName;
			const updateResult = await updateBrmContact({
				brmContact: brmContact,
				bGiveId: brmContact.Bgive_Id__c,
				bGiveContigId: brmContact.Bgive_Contig_Id__c,
				enableSolicitorHistory: enableSolicitorHistory,
			});
			if (updateResult) {
				//Update is successful, navigate to the contact record page.
				if (this.isFromContact) {
					this.navigateToContactRecord(String(brmContact.Id));
				} else {
					this.handleSearch();
				}
				this.showToast('Success', 'Contact updated successfully.', 'success');
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in updateBrmContact ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: Creates the contact in BRM and links it via future call
	Jira Story : IM-404
	*/
	async createBrmContactAndLink(brmContact, bgiveContact, enableSolicitorHistory) {
		try {
			const createContactResult = await brmLink({
				brmContact: brmContact,
				bgiveContact: bgiveContact,
				enableSolicitorHistory: enableSolicitorHistory,
			});
			if (createContactResult) {
				//Search again to update results - Stay in the same tab
				this.handleSearch();
				this.showToastForCreate('Success', 'Contact {0} created successfully.!', 'success', createContactResult);
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in createBrmContactAndLink ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: Contact is present in both BRM and Bgive, link them
	Jira Story : IM-344
	*/
	async brmLink(brmContact, bgiveContact, solicitorStatus) {
		try {
			const brmLinkingResult = await brmLink({
				brmContact: brmContact,
				bgiveContact: bgiveContact,
				enableSolicitorHistory: solicitorStatus,
			});
			if (brmLinkingResult && brmLinkingResult.Bgive_Id__c != null) {
				//BRM Update is Successful, proceed with Bgive changes
				this.showSpinner = false;
				this.bgiveLink(brmContact, bgiveContact);
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in brmLink ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: Separate BRM and Bgive Transactions for linking
	Jira Story : IM-344
	*/
	async bgiveLink(brmContact, bgiveContact) {
		try {
			const bgiveLinkingResult = await bgiveLink({
				brmContact: brmContact,
				bgiveContact: bgiveContact,
			});
			if (bgiveLinkingResult && bgiveLinkingResult.length > 0) {
				//Link is successful, redirect to the contact record page
				if (this.isFromContact) {
					this.navigateToContactRecord(String(brmContact.Id));
				} else {
					this.handleSearch();
				}
				this.showToast('Success', 'Contact updated successfully.', 'success');
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in bgiveLink ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: performs the unlinking process of brm and bgive contact records
	Jira Story : IM-21
	*/
	async unlink() {
		const result = await LightningConfirm.open({
			message: 'Are you sure you want to unlink the record?',
			variant: 'header',
			label: 'Confirmation',
			theme: 'warning',
		});
		if (result) {
			this.showSpinner = true;
			//IM-404: Unlink the contacts from both systems.
			this.brmUnlink();
		} else {
			this.showSpinner = false;
		}
	}

	/*
	Description: performs the unlinking in BRM first, then calls Bgive unlink
	Jira Story : IM-404
	*/
	async brmUnlink() {
		try {
			const brmUnlinkResult = await brmUnlink({
				brmContact: this.brmContactDetails,
				enableSolicitorHistory: this.solicitorStatus,
			});
			if (!brmUnlinkResult) {
				this.bgiveUnlink();
			} else {
				this.showSpinner = false;
				this.showToast('Error', 'Contact unlinking failed.', 'error');
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in brmUnlink ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: performs the unlinking in bgive
	Jira Story : IM-404
	*/
	async bgiveUnlink() {
		try {
			const bgiveUnlinkResult = await bgiveUnlink({
				brmContact: this.brmContactDetails,
			});
			if (!bgiveUnlinkResult) {
				//Unlink is always done from contact page, hence redirecting back to contact record page
				this.navigateToContactRecord(String(this.brmContactDetails?.Id));
				this.showToast('Success', 'Contact unlinked successfully.', 'success');
			} else {
				this.showSpinner = false;
				this.showToast('Error', 'Contact unlinking failed.', 'error');
			}
		} catch (error) {
			console.error('Unhandled Exception occurred in bgiveUnlink ' + getErrorMessages(error));
			this.handleError(error);
		}
	}

	/*
	Description: Navigates to the record Page once the record is created
	Jira Story : IM-404
	*/
	navigateToContactRecord(value) {
		try {
			this.isButtonDisabled = true;
			this.showSpinner = false;
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: value,
					objectApiName: 'Contact',
					actionName: 'view',
				},
			});
			setTimeout(() => {
				window.location.reload();
			}, 600);
		} catch (error) {
			console.error('Unhandled Exception occurred in navigateToContactRecord ', getErrorMessages(error));
		}
	}

	/*
	Description: Toast functions
	Jira Story : IM-21
	*/
	showToast(title, message, variant) {
		const evt = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant,
		});
		this.dispatchEvent(evt);
	}

	/*
	Description: Toast Function with contactData
	Jira Story : IM-21
	*/
	showToastForCreate(title, message, variant, contactData) {
		const evt = new ShowToastEvent({
			title: title,
			message: message,
			messageData: [
				{
					url: '/' + contactData.Id,
					label: '"' + contactData.FirstName + ' ' + contactData.LastName + '"',
				},
			],
			variant: variant,
		});
		this.dispatchEvent(evt);
	}

	/*
	Description: handles the error parsing logic
	Jira Story : IM-404
	*/
	handleError(error) {
		this.showSpinner = false;
		this.error = error;
		let errorMessages = getErrorMessages(error);
		if (errorMessages.length > 0) {
			let errorMessage = errorMessages[0];
			this.showToast('Error', errorMessage, 'error');
		}
	}
}