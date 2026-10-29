import {LightningElement, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getAllFoundationCodes from '@salesforce/apex/IMProgramOverviewController.getAllFoundationCodes';
import getFoundationCodeData from '@salesforce/apex/IMProgramOverviewController.getFoundationData';
import getAnnouncementRows from '@salesforce/apex/IMProgramOverviewController.buildAnnouncementRows';
import getProgramOverviewData from '@salesforce/apex/IMProgramOverviewController.getProgramOverviewData';
import getBaseUrl from '@salesforce/apex/IMProgramOverviewController.getBaseUrl';
import { CurrentPageReference } from 'lightning/navigation';
import { copyToClipboard } from 'c/utils';
const TOAST_HEADER = 'Exception Occured - Unexpected Failure';
export default class ImProgramOverview extends LightningElement {
	//Variables
	objectName = 'Foundation_Code__c';
	placeholderText = 'Enter Here...';
	labelText = 'Focus Area / Initiative';
	@track focusArea;
	@track selectedRecordId;
	@track treeGridData;
	@track fcToChildrenMap;
	@track budgetedInitiativeIds = [];
	announcementRows;
	showSpinner = false;
	isCommunicationsTabActive = false;
	showLinkCopiedIcon;
	baseUrl;

	//Filter Logic
	filter = {
		criteria: [
			{
				fieldPath: 'Type__c',
				operator: 'eq',
				value: 'Focus Area',
			},
			{
				fieldPath: 'Type__c',
				operator: 'eq',
				value: 'Parent Initiative',
			},
			{
				fieldPath: 'Status__c',
				operator: 'ne',
				value: 'Deleted',
			},
			{
				fieldPath: 'Initiative__c',
				operator: 'ne',
				value: null,
			},
		],
		filterLogic: '(1 AND 3) OR ( 2 AND 3 AND 4)',
	};

	//Display Infos
	displayInfo = {
		primaryField: 'Foundation_Code__c',
	};

	//Wire to get all the Foundation Codes
	@wire(getAllFoundationCodes)
	getAllFcodes(result) {
		const {data, error} = result;
		if (data) {
			this.fcToChildrenMap = data;
			if(this.selectedRecordId){
				this.loadTabsetData();
			}
		} else if (error) {
			console.error(error);
		}
	}

	@wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
		if(currentPageReference?.state?.c__recordId){
			this.selectedRecordId = currentPageReference.state?.c__recordId;
		}
    }

	@wire(getBaseUrl)
	wiredBaseUrl({ error, data }) {
		if (data) {
			this.baseUrl = data;
		} else if (error) {
			console.error('Error fetching base URL:', error);
		}
	}

	/*
	Description: handles the selection of lookup value
	Jira Story : IM-211
	*/
	async handleLookupSelection(event) {
		try {
			this.selectedRecordId = event.detail.recordId;
			if (this.selectedRecordId != null) {
				this.showSpinner = true;
				let foundationRecord = await getFoundationCodeData({recordId: this.selectedRecordId});
				//Update the Focus Area Value to show on the UI
				if (foundationRecord.Type__c == 'Focus Area') {
					this.focusArea = foundationRecord.Name;
				} else {
					this.focusArea = foundationRecord.Initiative__r?.Focus_Area__r?.Name;
					if (this.focusArea == '' || this.focusArea == null) {
						this.showErrorToast(' Focus Area is not set on Parent Initiative');
					}
				}
				if (this.focusArea) {
					//Fetch the data required for the tabset
					this.loadTabsetData();
				}
			} else {
				this.treeGridData = null;
				this.budgetedInitiativeIds = [];
				this.announcementRows = '';
				this.focusArea = '';
				this.showSpinner = false;
			}
		} catch (error) {
			this.showSpinner = false;
			this.showErrorToast(' handleLookupSelection' + error);
		}
	}

	/*
	Description: Handles fetching the data from Apex, once the lookup selection has been made
	Jira Story : IM-211
	*/
	async loadTabsetData() {
		if (this.selectedRecordId) {
			try {
				let programOverviewResponse = await getProgramOverviewData({
					recordId: this.selectedRecordId,
					fcToChildrenMap: this.fcToChildrenMap,
				});
				if (programOverviewResponse != null) {
					this.treeGridData = programOverviewResponse.treeGridData;
					this.budgetedInitiativeIds = programOverviewResponse.budgetedInitiativeIds;
					if (this.isCommunicationsTabActive) {
						this.handleAnnouncements();
					}
					this.showSpinner = false;
				} else {
					this.showSpinner = false;
					this.treeGridData = null;
					this.budgetedInitiativeIds = [];
				}
			} catch (error) {
				this.showSpinner = false;
				this.treeGridData = null;
				this.budgetedInitiativeIds = [];
				this.showErrorToast(' loadTabsetData' + JSON.stringify(error.body.message));
			}
		}
	}

	/*
	Description: 
	Jira Story : IM-211
	*/
	async handleOverview() {
		try {
			this.isCommunicationsTabActive = false;
		} catch (error) {
			this.showErrorToast(' handleOverview' + JSON.stringify(error.body.message));
		}
	}

	/*
	Description: call the announcementWrapper generation method when the tab becomes active, pass the budgeted initiative ids
	Jira Story : IM-211
	*/
	async handleAnnouncements() {
		try {
			this.isCommunicationsTabActive = true;
			if (!this.announcementRows) {
				this.showSpinner = true;
				let result = await getAnnouncementRows({budgetedIds: this.budgetedInitiativeIds});
				if (result) {
					this.showSpinner = false;
					this.announcementRows = result;
				}
			}
		} catch (error) {
			this.showSpinner = false;
			this.announcementRows = '';
			this.showErrorToast(' handleAnnouncements' + JSON.stringify(error.body.message));
		}
	}

	/*
	Description: Show Error Toast Message when error occurs
	Jira Story : IM-211
	*/
	showErrorToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: TOAST_HEADER,
			message: displayMessage,
			variant: 'error',
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}

	/*
	Description: Method to copy the link to clipboard
	Jira Story : IM-556
	*/
	copyLink(){
		let msg;
		if(!this.selectedRecordId){
			msg = this.baseUrl;
		}else{
			msg = this.baseUrl + '?c__recordId=' + this.selectedRecordId;
		}
		let self = this;
		this.showLinkCopiedIcon = true;
		setTimeout(function() {
			self.showLinkCopiedIcon = false;
		}, 3000);

		copyToClipboard(msg);		
	}
}