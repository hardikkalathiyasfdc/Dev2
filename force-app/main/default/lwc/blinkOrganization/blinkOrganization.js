import { LightningElement, wire, api } from 'lwc';
import { getErrorMessages } from 'c/utils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import LightningConfirm from 'lightning/confirm';
import searchOrganization from '@salesforce/apex/BlinkOrganizationController.searchOrganization';
import createInBrmAndLink from '@salesforce/apex/BlinkOrganizationController.createInBrmAndLink';
import createInBgiveAndLink from '@salesforce/apex/BlinkOrganizationController.createInBgiveAndLink';
import brmLink from '@salesforce/apex/BlinkOrganizationController.brmLink';
import bgiveLink from '@salesforce/apex/BLinkOrgService.bgiveLink';
import brmUnlink from '@salesforce/apex/BlinkOrganizationController.brmUnlink';
import bgiveUnlink from '@salesforce/apex/BLinkOrgService.bgiveUnlink';
import getOrganization from '@salesforce/apex/BlinkOrganizationController.getOrganization';
import getBgiveOrg from '@salesforce/apex/BlinkOrganizationController.getBgiveOrg';
import organizationDetailModal from 'c/organizationDetailModal';
import isBgiveOrgCreationEnabled from '@salesforce/apex/BlinkOrganizationController.isBgiveOrgCreationEnabled';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

const BGIVE_COLUMNS = [
	{ label: 'Name', fieldName: 'name', initialWidth: 240 },
	{
		label: 'Linked Status',
		fieldName: 'brmIdLink',
		initialWidth: 140,
		type: 'url',
		typeAttributes: { label: { fieldName: 'brmLinked' }, target: '_blank' },
	},
	{ label: 'Tax ID', fieldName: 'tax_id', initialWidth: 140 },
	{ label: 'Tax Status', fieldName: 'tax_class', initialWidth: 120 },
	{ label: 'Legal Name', fieldName: 'legal_name', initialWidth: 120 },
	{ label: 'Country', fieldName: 'country', initialWidth: 120 },
	{ label: 'AKA', fieldName: 'acronym', initialWidth: 120 },
	{ label: 'Address 1', fieldName: 'street_address', initialWidth: 120 },
	{ label: 'City', fieldName: 'city', initialWidth: 120 },
	{ label: 'State', fieldName: 'state', initialWidth: 120 },
	{ label: 'Website', fieldName: 'url', initialWidth: 120 },
	{
		label: 'Bgive Id',
		fieldName: 'bgiveRecordLink',
		initialWidth: 140,
		type: 'url',
		typeAttributes: { label: { fieldName: 'id' }, target: '_blank' },
	},
	{ label: 'Bgive Contig Id', fieldName: 'contig_id', initialWidth: 140 },
];

const BRM_COLUMNS = [
	{
		label: 'Name',
		fieldName: 'brmIdLink',
		initialWidth: 240,
		type: 'url',
		typeAttributes: { label: { fieldName: 'brmLinked' }, target: '_blank' },
	},
	{ label: 'Linked Status', fieldName: 'bGiveLink', initialWidth: 140 },
	{ label: 'Tax ID', fieldName: 'Tax_ID__c', initialWidth: 140 },
	{ label: 'Tax Status', fieldName: 'Tax_Status__c', initialWidth: 120 },
	{ label: 'Legal Name', fieldName: 'Legal_Name__c', initialWidth: 120 },
	{ label: 'Country', fieldName: 'BillingCountry', initialWidth: 120 },
	{ label: 'AKA', fieldName: 'AKA__c', initialWidth: 120 },
	{ label: 'Address 1', fieldName: 'BillingStreet', initialWidth: 120 },
	{ label: 'City', fieldName: 'BillingCity', initialWidth: 120 },
	{ label: 'State', fieldName: 'BillingState', initialWidth: 120 },
	{ label: 'Website', fieldName: 'Website', initialWidth: 120 },
	{
		label: 'Bgive Id',
		fieldName: 'bgiveRecordLink',
		initialWidth: 140,
		type: 'url',
		typeAttributes: { label: { fieldName: 'Bgive_Id__c' }, target: '_blank' },
	},
	{ label: 'Bgive Contig Id', fieldName: 'Bgive_Contig_Id__c', initialWidth: 140 },
];

export default class BlinkOrganization extends NavigationMixin(LightningElement) {
	//Variable
	@api isFromOrg = false;
	@api recordId;
	bgiveColumns = BGIVE_COLUMNS;
	brmData = [];
	bgiveData = [];
	searchKeyOrg;
	searchKeyContigId;
	orgName;
	orgLegalName;
	orgAKA;
	selectedBRMRow;
	selectedBgiveRow;
	//brmOrgDetails = {};
	brmOrgDetails;
	bgiveOrg;
	isLinked;
	bgiveLinkedStatusValue;
	showSpinner = false;
	isLoading = false;
	bgiveOrgCreationEnabled = false;
	showSearchResults = false;
	isUnlinkChecked = false;
	_preSelectedRow;
	lastRefreshToken;
	wiredResult;
	noBRMOrgMessage = 'There are no matching organizations in BRM.';
	noBgiveOrgMessage = 'There are no matching organizations in Bgive.';
	noBRMOrgExistsInBgive = 'No Matching org exist in Bgive.';
	bgiveLinkedStatusOptions = [
		{ label: 'Linked', value: 'Linked' },
		{ label: 'Unlinked', value: 'Unlinked' },
	];

	hasRestrictedAccess = false;
	isObjectInfoLoaded = false;

	get brmColumns() {
		let columns = [...BRM_COLUMNS];
		if (this.hasRestrictedAccess) {
			const privateColumn = {
				label: 'Private',
				fieldName: 'Restricted__c',
				initialWidth: 120,
				type: 'boolean'
			};

			// find index after "Legal Name"
			const insertIndex = columns.findIndex(
				col => col.fieldName === 'Legal_Name__c'
			);

			if (insertIndex !== -1) {
				columns.splice(insertIndex + 1, 0, privateColumn);
			}
		}
		return columns;
	}

	@wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
	objectInfoHandler({ data, error }) {
		if (data) {
			const field = data.fields.Restricted__c;
			this.hasRestrictedAccess = field;
			this.isObjectInfoLoaded = true;
		}
		if (error) {
			console.error(error);
		}
	}

	get isBRMData() {
		return this.brmData.length === 0 ? false : true;
	}

	get isBgiveData() {
		return this.bgiveData.length === 0 ? false : true;
	}

	get showNoBRMOrgMessage() {
		return this.brmData.length > 0 && this.bgiveData.length === 0 ? this.noBRMOrgExistsInBgive : this.noBgiveOrgMessage;
	}

	get showMasterOrgInfo() {
		return this.isFromOrg && this.isLinked ? true : false;
	}

	get buttonLabel() {
		let label = 'Link';
		if (this.isFromOrg && this.isLinked) {
			label = 'Save';
		} else {
			if (
				(this.brmData.length > 0 && this.bgiveData.length === 0) ||
				(this.selectedBRMRow && !this.selectedBRMRow.Bgive_Id__c && !this.selectedBgiveRow)
			) {
				label = 'Create in Bgive and Link';
			} else if (
				(this.bgiveData.length > 0 && this.brmData.length === 0) ||
				(this.selectedBgiveRow && !this.selectedBgiveRow.brm_id && !this.selectedBRMRow)
			) {
				label = 'Create in BRM and Link';
			}
		}
		return label;
	}

	get isButtonDisabled() {
		const hasBgiveId = this.selectedBRMRow?.Bgive_Id__c ? true : false;
		if (this.buttonLabel === 'Create in Bgive and Link') {
			return hasBgiveId || !this.bgiveOrgCreationEnabled;
		} else if (this.buttonLabel === 'Link') {
			return hasBgiveId;
		}
		return false;
	}

	get showSearchSection() {
		return this.isFromOrg && this.isLinked ? false : true;
	}

	get showBgiveOrgCard() {
		return this.isFromOrg && this.isLinked ? true : false;
	}

	get showLinkedStatus() {
		return this.isFromOrg && this.brmOrgDetails.Bgive_Id__c ? true : false;
	}

	get showBgiveOrgCard() {
		return this.isFromOrg && this.isLinked ? true : false;
	}

	get showButton() {
		if (this.isFromOrg && this.isLinked) {
			return true;
		} else {
			return this.selectedBRMRow == undefined && this.selectedBgiveRow == undefined ? false : true;
		}
	}

	get shallDisableSaveButton() {
		return !this.searchKeyOrg?.trim() && !this.searchKeyContigId?.trim();
	}

	get preSelectedRow() {
		return this._preSelectedRow;
	}

	set preSelectedRow(value) {
		this._preSelectedRow = value;
	}

	/*
	Description: ConnectedCallback, runs when DOM is loaded
	Jira Story : BRME-5165
	*/
	connectedCallback() {
		isBgiveOrgCreationEnabled()
			.then((result) => {
				this.bgiveOrgCreationEnabled = result;
			})
			.catch((error) => {
				console.error('Error retrieving metadata setting:', error);
				this.bgiveOrgCreationEnabled = false;
			});
	}

	@wire(CurrentPageReference)
	handlePageRef(pageRef) {
		if (!pageRef || !this.wiredResult) {
			return;
		}
		const token = pageRef.state?.c__refreshToken;
		if (token && token !== this.lastRefreshToken) {
			this.lastRefreshToken = token;
			this.isLinked = false;
			refreshApex(this.wiredResult);
		}
	}

	/*
	Description: retrieve the record info using id
	Jira Story : BRME-5165
	*/
	@wire(getOrganization, { ordId: '$recordId' })
	wiredAccount(result) {
		this.wiredResult = result;
		const { data, error } = result;
		if (data) {
			this.brmOrgDetails = data;
			this.showSearchResults = true;
			this.orgName = data.Name;
			this.searchKeyOrg = data.Restricted__c ?  data.Restricted_Org_Name__c: data.Name;
			let bgiveId = data.Bgive_Id__c;
			if (bgiveId) {
				this.getBgiveOrg(bgiveId);
			} else {
				this.searchOrganization(this.orgName);
			}
		} else if (error) {
			console.error('Error while retrieving Org details: ' + JSON.stringify(error));
		}
	}

	/*
	Description: handles they keyword change on UI for search
	Jira Story : BRME-5165
	*/
	handleSearchOrgInputChange(event) {
		this.searchKeyOrg = event.detail.value;
	}

	/*
	Description: handles the contig id change on UI for search
	Jira Story : BRME-5165
	*/
	handleSearchContigIdInputChange(event) {
		this.searchKeyContigId = event.detail.value;
	}

	/*
	Description: handles the search operation, triggered from UI
	Jira Story : BRME-5165
	*/
	handleSearch() {
		this.showSearchResults = true;
		this.orgName = '';
		this.orgLegalName = '';
		this.orgAKA = '';
		this.selectedBRMRow = null;
		this.selectedBgiveRow = null;
		this.brmData = [];
		this.bgiveData = [];
		this.searchOrganization();
	}

	/*
	Description: handles the selection of BRM record from the given results
	Jira Story : BRME-5165
	*/
	handleBRMRowSelection(event) {
		this.preSelectedRow = [];
		this.selectedBRMRow = event.detail.selectedRows[0];
		this.orgName = this.selectedBRMRow.Name;
		this.orgLegalName = this.selectedBRMRow.Legal_Name__c;
		this.orgAKA = this.selectedBRMRow.AKA__c;
	}

	/*
	Description: handles the selection of Bgive record from the given results
	Jira Story : BRME-5165
	*/
	handleBgiveRowSelection(event) {
		this.selectedBgiveRow = event.detail.selectedRows[0];
		this.orgName = this.selectedBgiveRow.name;
	}

	/*
	Description: performs the search based on keyword entered or id given on UI
	Jira Story : BRME-5165
	*/
	async searchOrganization() {
		if (!this.isObjectInfoLoaded) {
			await this.waitForObjectInfo();
		}
		try {
			this.isLoading = true;
			this.showSpinner = true;
			const result = await searchOrganization({
				orgName: String(this.searchKeyOrg).trimEnd().trimStart(),
				contigId: this.searchKeyContigId ? String(this.searchKeyContigId).trimEnd().trimStart() : '',
			});
			if (result && result != null) {
				let brmOrgsArray = result['brmOrgs'];
				let bgiveOrgsArray = result['bgiveOrgs'];
				let biveBaseURL = result['bgiveBaseURL'];
				if (Array.isArray(brmOrgsArray) && brmOrgsArray.length > 0) {
					this.brmData = brmOrgsArray.map((item) => {
						let isBGiveExist = item.Bgive_Id__c != null && item.brm_id != '';
						let brmIdLink = '/' + item.Id;
						let bGiveLink = isBGiveExist ? 'Linked' : '';
						let bgiveRecordLink = item.Bgive_Id__c != null ? biveBaseURL + '/show/organizations/' + item.Bgive_Id__c : '';
						return {
							...item,
							'brmIdLink': brmIdLink,
							'brmLinked': (item.Name == '#' && this.hasRestrictedAccess) ? item.Restricted_Org_Name__c : item.Name,
							'bGiveLink': bGiveLink,
							'bgiveRecordLink': bgiveRecordLink,
						};
					});
					const matched = this.brmData.find((item) => item.Id === this.recordId);
					if (matched) {
						this.selectedBRMRow = matched;
						this.orgName = matched.Name;
						this.orgLegalName = matched.Legal_Name__c;
						this.orgAKA = matched.AKA__c;
						this.preSelectedRow = matched ? [matched.Id] : [];
					}
				} else {
					this.preSelectedRow = [];
				}
				if (Array.isArray(bgiveOrgsArray) && bgiveOrgsArray.length > 0) {
					this.bgiveData = bgiveOrgsArray
						.filter((item) => item.tax_class != 'Political/527')
						.map((item) => {
							let isBRMIdExist = item.brm_id != undefined && item.brm_id != null && item.brm_id != '';
							let brmIdLink = isBRMIdExist ? '/' + item.brm_id : '';
							let brmLinked = isBRMIdExist ? 'Linked' : '';
							let isCountryExists = item.geo_country_id != undefined && item.geo_country_id != null && item.geo_country_id.length > 0;
							let isStateExists = item.geo_state_id != undefined && item.geo_state_id != null && item.geo_state_id.length > 0;
							let bgiveState = isStateExists ? item.geo_state_id[0].name : '';
							let bgiveCountry = isCountryExists ? item.geo_country_id[0].name : '';
							return {
								...item,
								'brmIdLink': brmIdLink,
								'brmLinked': brmLinked,
								'country': bgiveCountry,
								'state': bgiveState,
								'bgiveRecordLink': biveBaseURL + '/show/organizations/' + item.id,
							};
						});
				}
				this.showSpinner = false;
				this.isLoading = false;
			}
		} catch (error) {
			console.error('Unhandled Exception occured in searchOrganization ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: handles the save operation.
	Jira Story : BRME-5165
	*/
	handleSave(event) {
		var buttonName = event.target.dataset.name;
		var isCreate = false;
		if (buttonName === 'Create Org in Bgive') {
			isCreate = true;
			this.showOrgModal();
			return;
		}
		if (buttonName === 'Create Org in BRM') {
			isCreate = true;
		}
		if (this.isUnlinkChecked) {
			this.unlink();
		} else {
			this.link(isCreate);
		}
	}

	/*
	Description: handles the name change
	Jira Story : BRME-5165
	*/
	handleNameChange(event) {
		this.orgName = event.detail.value;
		this.selectedBRMRow.Name = this.orgName;
	}

	/*
	Description: handles the link change
	Jira Story : BRME-5165
	*/
	handleBgiveLinkedChange(event) {
		this.isUnlinkChecked = event.detail.value === 'Unlinked';
	}

	/*
	Description: Search for Bgive Org using apex method
	Jira Story : BRME-5165
	*/
	async getBgiveOrg(bgiveid) {
		try {
			const result = await getBgiveOrg({ orgBGiveId: bgiveid });
			if (result) {
				if (result != null) {
					this.bgiveOrg = result;
					this.isLinked = true;
					this.bgiveLinkedStatusValue = 'Linked';
				}
			} else {
				this.showToast('Error', 'Bgive Org Search Failed', 'error');
			}
		} catch (error) {
			console.error('Unhandled Exception occured in getBgiveOrg ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: Modal screen for BRM Org
	Jira Story : BRME-5165
	*/
	async showOrgModal() {
		const result = await organizationDetailModal.open({
			size: 'small',
			description: 'BRM Orgnaization Details',
			orgDetails: this.selectedBRMRow,
		});
		if (result === 'ok') {
			this.linkOrg('Organization created successfully.', true);
		}
	}

	/*
	Description: triggered from the click of link button on UI
	Jira Story : BRME-5165
	*/
	async link(isCreate) {
		var orgMessage = 'Organization updated successfully.';
		if (isCreate) {
			orgMessage = 'Organization created successfully.';
		}
		const result = await LightningConfirm.open({
			message: 'Are you sure you want to proceed?',
			variant: 'header',
			label: 'Confirmation',
			theme: 'warning',
		});
		if (result) {
			this.showSpinner = true;
			this.checkLinkScenario(orgMessage, true);
		} else {
			this.showSpinner = false;
		}
	}

	/*
	Description: Check the link scenario and perform relevant steps
	Jira Story : IM-404
	*/
	async checkLinkScenario(message, refresh) {
		if (this.selectedBRMRow == undefined && this.brmOrgDetails != undefined) {
			this.selectedBRMRow = this.brmOrgDetails;
		}
		try {
			let bgiveOrg = JSON.stringify(this.selectedBgiveRow);
			let brmOrg = this.selectedBRMRow;
			/**
			 * 1 - Bgive org is present, Brm org is not present  - Create in BRM and Link
			 * 2 - Bgive Org is not present, Brm org is present - Create in Bgive and Link
			 * 3 - Both orgs are present - Link
			 */
			if (bgiveOrg != null && brmOrg === null) {
				this.createInBrmAndLink(bgiveOrg, message, refresh);
			} else if ((bgiveOrg === null || bgiveOrg === undefined) && brmOrg) {
				this.createInBgiveAndLink(brmOrg, message, refresh);
			} else {
				this.brmLink(brmOrg, bgiveOrg, message, refresh);
			}
		} catch (error) {
			console.error('Unhandled Exception occured in checkLinkScenario ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: creates the org in BRM and links to bgive via future call
	Jira Story : IM-404
	*/
	async createInBrmAndLink(bgiveOrg, message, refresh) {
		try {
			const result = await createInBrmAndLink({ bgiveOrg: bgiveOrg });
			if (result) {
				this.processLinkResult(String(result.Bgive_Id__c), message, refresh);
			} else {
				this.showSpinner = false;
			}
		} catch (error) {
			console.error('Unhandled Exception occured in createInBrmAndLink ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: creates the org in bgive and links to brm
	Jira Story : IM-404
	*/
	async createInBgiveAndLink(brmOrg, message, refresh) {
		try {
			const result = await createInBgiveAndLink({ brmOrg: brmOrg });
			if (result) {
				this.processLinkResult(String(result.Bgive_Id__c), message, refresh);
			} else {
				this.showSpinner = false;
			}
		} catch (error) {
			console.error('Unhandled Exception occured in createInBgiveAndLink ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: links the org in BRM first and calls bgive link
	Jira Story : IM-404
	*/
	async brmLink(brmOrg, bgiveOrg, message, refresh) {
		try {
			const result = await brmLink({ brmOrg: brmOrg, bgiveOrg: bgiveOrg });
			if (result && result.Bgive_Id__c != null) {
				this.bgiveLink(brmOrg, bgiveOrg, message, refresh);
			} else {
				this.showSpinner = false;
			}
		} catch (error) {
			console.error('Unhandled Exception occured in brmLink ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: links the org in bgive
	Jira Story : IM-404
	*/
	async bgiveLink(brmOrg, bgiveOrg, message, refresh) {
		try {
			const result = await bgiveLink({ brmOrg: brmOrg, bgiveOrg: bgiveOrg });
			if (result) {
				this.processLinkResult(result, message, refresh);
			} else {
				this.showSpinner = false;
			}
		} catch (error) {
			console.error('Unhandled Exception occured in bgiveLink ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: process the link result, perform the next steps
	Jira Story : IM-404
	*/
	processLinkResult(result, message, refresh) {
		if (result != null) {
			this.showToast('Success', message, 'success');
			this.showSpinner = false;
			if (refresh) {
				if (this.isFromOrg) {
					setTimeout(() => {
						this.navigateToOrgRecord();
					}, 300);
				} else {
					this.searchKeyOrg = this.orgName;
					this.handleSearch();
				}
			}
		} else {
			this.showSpinner = false;
		}
	}

	/*
	Description: Unlink function, triggered on click of Save button from UIs
	Jira Story : BRME-5165
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
			this.brmUnlink();
		} else {
			this.showSpinner = false;
		}
	}

	/*
	Description: performs the unlinking in BRM of org first, then calls Bgive unlink
	Jira Story : IM-404
	*/
	async brmUnlink() {
		try {
			const result = await brmUnlink({ brmOrg: this.brmOrgDetails });
			if (!result) {
				this.bgiveUnlink();
			} else {
				this.showSpinner = false;
			}
		} catch (error) {
			console.error('Unhandled Exception occured in brmUnlink ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: performs the unlinking of org in Bgive.
	Jira Story : IM-404
	*/
	async bgiveUnlink() {
		try {
			const result = await bgiveUnlink({ brmOrg: this.brmOrgDetails });
			if (!result) {
				this.showToast('Success', 'Organization Unlinked successfully.', 'success');
				setTimeout(() => {
					this.navigateToOrgRecord();
				}, 300);
			} else {
				this.showSpinner = false;
			}
		} catch (error) {
			console.error('Unhandled Exception occured in brmUnlink ' + error);
			this.handleError(error);
		}
	}

	/*
	Description: Toast Function
	Jira Story : BRME-5165
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
	Description: Navigates to the record Page once the record is created
	Jira Story : BRME-5165
	*/
	navigateToOrgRecord() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.recordId,
				objectApiName: 'Account',
				actionName: 'view',
			},
		});
		setTimeout(() => {
			window.location.reload();
		}, 100);
	}

	/*
	Description: handles the error parsing logic
	Jira Story : IM-404
	*/
	handleError(error) {
		this.showSpinner = false;
		this.isLoading = false;
		this.error = error;
		let errorMessages = getErrorMessages(error);
		if (errorMessages.length > 0) {
			let errorMessage = errorMessages[0];
			let duplicateIndex = errorMessages[0].indexOf('DUPLICATES_DETECTED');
			if (duplicateIndex != -1) {
				errorMessage = errorMessage.substring(duplicateIndex);
			}
			this.showToast('Error', errorMessage, 'error');
		}
	}
}