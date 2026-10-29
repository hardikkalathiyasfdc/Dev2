import { LightningElement, wire, track, api } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from 'lightning/confirm';
import getListMembers from "@salesforce/apex/ListEditCmpController.getListMembers";
import getUserListView from "@salesforce/apex/ListEditCmpController.getUserListView"
import saveListMembers from "@salesforce/apex/ListEditCmpController.saveListMembers";
import updateRSVPStatus from "@salesforce/apex/ListEditCmpController.updateRSVPStatus";
import getMyDomain from "@salesforce/apex/ListEditCmpController.getMyDomain";
import addSignificantOther from "@salesforce/apex/ListEditCmpController.addSignificantOther";
import updateGuestInfo from "@salesforce/apex/ListEditCmpController.updateGuestInfo";
import getUserInfo from '@salesforce/apex/ListEditCmpController.getUserInfo';
import syncEvent from "@salesforce/apex/EventMangementAuraCtrl.syncEvent";
import syncFromZkipsterEvent from "@salesforce/apex/EventMangementAuraCtrl.startSyncFromZkipster";
import checkEventList from "@salesforce/apex/EventMangementAuraCtrl.checkEventList";
import deleteGuests from "@salesforce/apex/EventMangementAuraCtrl.deleteGuests";
import LIST_RECORDTYPE_ID from "@salesforce/schema/Campaign.RecordType.Id";
import LIST_RECORDTYPE_NAME from "@salesforce/schema/Campaign.RecordType.Name";
import LIST_RECORDTYPE_DEVELOPErNAME from "@salesforce/schema/Campaign.RecordType.DeveloperName";
import PROGRAMATIC from "@salesforce/schema/Campaign.Programmatic__c";
import getRestrictedContactCount from "@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedContactCount";
import getRestrictedContactForGenerateBio from "@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedContactForGenerateBio";
import Access_Short_Bio from '@salesforce/customPermission/Access_Short_Bio';
import Access_Generate_Bio_Report from '@salesforce/customPermission/Access_Generate_Bio_Report';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';
import FORM_FACTOR from '@salesforce/client/formFactor';
import Contacts_With_Missing_Email_Report from '@salesforce/label/c.Contacts_With_Missing_Email_Report';
import UpdateGuestInfo from 'c/updateGuestInfo';

const _FIELDS = [LIST_RECORDTYPE_ID, LIST_RECORDTYPE_NAME, LIST_RECORDTYPE_DEVELOPErNAME, PROGRAMATIC];

export default class ListEditCmp extends NavigationMixin(LightningElement) {
	@api recordId;
	@api now;
	@track myList = {};
	@track savedResults = {};
	@track recType;
	@track listReportId;
	@track guestCount = 0;
	@track expectedGuestCount = 0;
	@track eventSummary = [];
	@track attendenceSummary = [];
	@track showDonation = false;
	showCreateInteractions = false;
	interactionContactIds = [];
	interactionRestrictedCount = 0;
	@track showInviteBtn = false;
	isDesktop = false;
	isMobile = false;

	isListMemberSource = true;
	listValues = [];
	generateBio = false;

	searchTerm = "";
	BLANK = "";
	COL_CHAR_WIDTH = 7;
	MIN_COL_WIDTH = 150;
	MAX_COL_WIDTH = 300;
	emailField;
	emailTitle;
	emailSubjectField;
	emailStatus;
	emailSent;
	emailTemplateLastModified;
	emailShowCC;
	isEventList;
	selectedRowIds;
	selectedMembers;
	showRSVPSelection = false;
	showEventEmail = false;
	showInvitation = false;
	showAssistant = false;
	showEmailSummary = false;
	selectedEmailOptions = [];
	selectedEmailType = "";
	showNewGuestCreation = false;
	showNewListViewCreation = false;
	showDeleteConfirmation = false;
	syncDiable = false;
	syncFromDisable = false;
	timeoutId;
	emailId;
	eventStatus;
	showExport;
	exportFields;
	selectedExportFields;
	addSignificantOtherMessage;
	showAddSignificantOtherMessage;
	recordTypeName;
	listRec;
	hideExportForListRec = false;
	selectedMenuItemValue;
	restrictedContact = 0;
	showShortBio = false;
	listViewData;
	selectedViewId;
	listViewOptions;
	selectedOptions = [];
	isRestricted = false;
	selectedSource = '';
	contactsMissingEmailCount = 0;
	NOTES_FIELD = 'UB_Notes__c';
	MAX_SORT_COLUMNS = 5;
	SORT_MARKER_UP = "\u2B06\uFE0E";
	SORT_MARKER_DOWN = "\u2B07\uFE0E";
	showSortModal = false;
	reportId = Contacts_With_Missing_Email_Report;
	showSpinner = false;

	listSelected(event) {
		var selectedData = event.detail.arrItems;
		this.listValues = [];
		selectedData.forEach(selectedData => {
			this.listValues.push(selectedData.value);
		});
		this.selectedSource = this.listValues.join(';');
	}

	get myViewExists() {
		return this.selectedViewId;
	}

	get isProgramatic() {
		return getFieldValue(this.listRec, PROGRAMATIC);
	}

	get showInvitationBtn() {
		return this.showInviteBtn && this.eventStatus == 'Upcoming';
	}

	get showSave() {
		return (
			this.myList &&
			this.myList.draftValues &&
			Object.keys(this.myList.draftValues).length
		);
	}

	get isHideCheckbox() {
		return !this.isEventList;
	}

	get title() {
		return this.myList.title ? this.myList.title : '';
	}

	get memberCount() {
		return this.myList.size;
	}

	get isLoaded() {
		return this.myList.isLoaded;
	}

	get data() {
		return this.myList.data;
	}

	get columns() {
		return this.myList.columns;
	}

	get stickyColumns() {
		return this.myList.stickyColumns;
	}

	get stickyColumns2() {
		return this.myList.stickyColumns2;
	}

	get stickyColumns3() {
		return this.myList.columns;
	}

	get draftValues() {
		return this.myList.draftValues;
	}

	get sortableColumns() {
		let columns = (this.myList && this.myList.columns) || [];
		let options = [];
		for (let i = 0; i < columns.length; i++) {
			let col = columns[i];
			let label = col.baseLabel != null ? col.baseLabel : col.label;
			if(!col.fieldApi || label == null || !String(label).length) {
				continue;
			}
			if(col.type == "action" || col.type == "button-icon" || col.type == "customIcon") {
				continue;
			}
			options.push({
				label: label,
				field: col.fieldApi,
				type: this.getSortType(col)
			});
		}
		return options;
	}

	get rowOffset() {
		return this.myList.rowOffset;
	}

	get isPagination() {
		return this.myList.showPagination ? true : false;
	}

	get isPrev() {
		return this.myList.showPrev ? true : false;
	}

	get isNext() {
		return this.myList.showNext ? true : false;
	}

	get menuButtonSize() {
		return this.showInvitationBtn ? 2 : 3;
	}

	get hasGenerateBioAccess() {
		return Access_Generate_Bio_Report;
	}

	get hasGenerateShortBioAccess() {
		return Access_Short_Bio;
	}

	get isNotEventList() {
		return !this.isEventList;
	}

	get hasNotLoaded() {
		return !this.isLoaded;
	}

	get missingEmailExportUrl() {
		return `/lightning/r/Report/${this.reportId}/view?fv0="${this.recordId}"`;
	}

	get hasMissingEmailContacts() {
		return this.contactsMissingEmailCount > 0;
	}

	contactFieldMapping = {
		Additional_Email__c: 'Restricted_Additional_Email__c',
		ContactBusinessEmail__c: 'Restricted_Business_Email__c',
		Full_Name__c: 'Restricted_Name__c',
		UB_Company__c: 'Restricted_Org_Name__c',
		Contact_Priority_email__c: 'Restricted_Personal_Email__c',
		UB_FirstName__c: 'RestrictedFirstName__c',
		UB_LastName__c: 'RestrictedLastName__c',
		Middle_Name__c: 'RestrictedMiddleName__c',
		UB_Salutation__c: 'RestrictedSalutation__c',
		UB_Suffix__c: 'RestrictedSuffix__c'
	};

	@track fieldAccessMap = {};

	@wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
	campaignMemberMetadata({ data, error }) {
		if(data) {
			const mapResult = {};

			Object.values(this.contactFieldMapping).forEach(fieldName => {
				const fieldMeta = data.fields[fieldName];

				if(fieldMeta) {
					mapResult[fieldName] = {
						accessible: true,
						createable: fieldMeta.createable,
						updateable: fieldMeta.updateable
					};
				} else {
					mapResult[fieldName] = {
						accessible: false,
						createable: false,
						updateable: false
					};
				}
			});

			this.fieldAccessMap = mapResult;
		} else if(error) {
			console.error('Error fetching CampaignMember metadata:', error);
		}
	}

	// Helper method to check access later
	hasAccess(fieldApiName) {
		return this.fieldAccessMap[fieldApiName]?.accessible || false;
	}

	@wire(getUserListView, { view: 'Desktop' })
	listView({ error, data }) {
		if(data) {
			if(data && data.length > 0) {
				this.selectedViewId = data[0].Id;
				this.selectedOptions = data[0].Column__c.split(',');
			}
		} else {
			console.log(error);
		}
	}

	@wire(CurrentPageReference)
	setCurrentPageReference(currentPageReference) {
		this.currentPageReference = currentPageReference;
	}

	@wire(getUserInfo, {})
	userData({ error, data }) {
		if(data) {
			this.showShortBio = true;
		} else {
			this.showShortBio = false;
		}
	}

	@wire(getRecord, { recordId: '$recordId', fields: _FIELDS })
	wiredRecord({ data, error }) {
		if(data) {
			this.listRec = data;
			this.recordTypeName = this.listRec.fields.RecordType.value.fields.DeveloperName.value;
			if(this.recordTypeName === 'State_Campaign' ||
				this.recordTypeName === 'BP_Campaign' ||
				this.recordTypeName === 'GuestList') {
				this.hideExportForListRec = true;
			} else {
				this.hideExportForListRec = false;
			}
		}
	}

	@wire(checkEventList, { recordId: "$recordId" })
	wireCheckList(result) {
		if(result.data) {
			this.isEventList = result.data;
		}
	}

	// Set interval is to check if it's a new page and to load the table.
	// For some reason LWC gets cached and each time you navigate to here it is not a new
	// instance so it shows the old list edit and needs to be refreshed.
	// It checks if record has changed or time stamp so quick action going to same record id will refresh also.
	connectedCallback() {
		if (FORM_FACTOR === 'Large') {
			this.isDesktop = true;
		} else if (FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium') {
			this.isMobile = true;
		}
		this.isRestricted = hasPrivateNameFieldsAccess;
		this.init();
		this.loadTable();
		this.getMyDomain();
		let self = this;
		setInterval(function () {
			if(self.recordId != self.getRecordId() || self.now != self.getNow()) {
				self.init();
				self.loadTable();
			}
		}, 500);
	}

	init() {
		this.myList = {};
		this.myList.sortSpec = this.getDefaultSortSpec();
		this.myList.filter = {};
		this.savedresults = {};
		this.showSortModal = false;
		this.searchTerm = "";
		this.showRSVPSelection = false;
		this.showEventEmail = false;
		this.showInvitation = false;
		this.showInviteBtn = false;
		this.showNewGuestCreation = false;
		this.showDeleteConfirmation = false;
		this.showNewListViewCreation = false;
	}

	getRecordId() {
		let check =
			this.currentPageReference &&
			this.currentPageReference.state &&
			this.currentPageReference.state.c__id;
		return check != null && check.length ? check : this.recordId;
	}

	getNow() {
		let check =
			this.currentPageReference &&
			this.currentPageReference.state &&
			this.currentPageReference.state.c__now;
		return check != null && check.length ? check : this.now;
	}

	loadTable(isExport, isNewCols) {
		let self = this;
		this.myList.isLoaded = false;
		this.recordId = this.getRecordId();
		this.now = this.getNow();
		isExport = isExport ? true : false;
		let params = {
			campaignId: self.recordId,
			pageNum: self.myList.pageNum,
			sortField: isExport ? 'Contact.Last_Preferred_Last_Name__c' : null,
			sortDir: isExport ? 'ASC' : null,
			searchTerm: self.searchTerm,
			isExport: isExport
		};
		if(isExport) {
			params.fieldsList = self.selectedExportFields;
		}
		getListMembers(params)
			.then((result) => {
				self.myList.isLoaded = true;
				result = result ? result : {};
				result.list = result.list ? result.list : {};
				self.exportFields = result.exportFields ? result.exportFields : [];
				let selected = [];
				for (let i = 0; i < self.exportFields.length; i++) {
					let f = self.exportFields[i];
					selected.push(f.value);
				}
				self.selectedExportFields = [];
				if(isExport) {
					let myOldList = JSON.parse(JSON.stringify(self.myList));
					if(self.myList.filteredData && self.myList.filteredData.length > 0) {
						let exportData = self.myList;
						// exportData.data = result.data.filter((elem) => self.myList.filteredData.find(({ Id }) => elem.Id === Id));;
						let orderMap = {};
						for (let i = 0; i < self.myList.filteredData.length; i++) {
							orderMap[self.myList.filteredData[i].Id] = i;
						}
						exportData.data = result.data
							.filter((elem) => orderMap[elem.Id] !== undefined)
							.map((elem) => {
								let updatedElem = { ...elem };

								const restrictedName = elem.Contact?.Restricted_Name__c || '';

								if (updatedElem.EmailSubjectLine__c && updatedElem.EmailSubjectLine__c.includes('#') && hasPrivateNameFieldsAccess) {
									updatedElem.EmailSubjectLine__c = updatedElem.EmailSubjectLine__c.replace(/#/g, restrictedName);
								}

								if (updatedElem.Latest_Email_Subject__c && updatedElem.Latest_Email_Subject__c.includes('#') && hasPrivateNameFieldsAccess) {
									updatedElem.Latest_Email_Subject__c = updatedElem.Latest_Email_Subject__c.replace(/#/g, restrictedName);
								}

								return updatedElem;
							});
						exportData.columns = self.getColumns(result);
						self.exportExcel(exportData);
					} else {
						self.exportExcel(result);
					}
					self.myList.isLoaded = true;
					myOldList.isLoaded = true;
					self.myList = myOldList;
					return;
				}
				self.myList.title = result.list && result.list.Name;
				let guestCount =
					result.list.GuestsinEvent__c && !isNaN(result.list.GuestsinEvent__c)
						? result.list.GuestsinEvent__c
						: 0;
				let expectedCount =
					result.list.ExpectedAttendance__c &&
						!isNaN(result.list.ExpectedAttendance__c)
						? result.list.ExpectedAttendance__c
						: 0;
				let contactsMissingEmailCount = result.list.Contacts_Missing_Email_Count__c && !isNaN(result.list.Contacts_Missing_Email_Count__c)
												? result.list.Contacts_Missing_Email_Count__c
												: 0;
				self.guestCount = guestCount;
				self.expectedGuestCount = expectedCount;
				this.contactsMissingEmailCount = contactsMissingEmailCount;
				self.listReportId = result.listReportId;
				self.recType =
					result.list.RecordType &&
					result.list.RecordType.DeveloperName &&
					result.list.RecordType.DeveloperName;
				self.eventStatus = result.list.EventStatus__c;
				self.isEventList = self.recType == "Pre_Event";
				self.myList.nameMap = result.nameMap;
				self.myList.size = !isNaN(result.dataSize)
					? Number(result.dataSize)
					: 0;
				self.myList.allData = result.data.map(record => {
					if(record.Contact.Restricted__c && hasPrivateNameFieldsAccess) {
						// Replace actual values with restricted values
						record.Contact.FirstName = record.Contact.RestrictedFirstName__c;
						record.Contact.LastName = record.Contact.RestrictedLastName__c;
					}
					return record;
				});
				self.myList.pageSize = result.pageSize;
				if(!isNewCols) {

					self.myList.columns = self.getColumns(result);
					let cols = [];
					let cols2 = [];
					let pencil = {};
					for (let i = 0; i < self.myList.columns.length; i++) {
						if(i < 3) cols.push(self.myList.columns[i]);
						else {
							cols2.push(self.myList.columns[i]);
						}
						if(i < 3 && self.myList.columns[i].type == "button-icon") {
							pencil = self.myList.columns[i];
						}
					}
					self.myList.stickyColumns = cols;
					cols2.push(pencil);
					self.myList.stickyColumns2 = cols2;
				}
				self.applySortIndicators();
				self.refreshFilteredSortedData(false);
				self.setInitialColumnWidths();
				if(self.myList.draftValues) {
					for (let key in self.myList.draftValues) {
						let draft = self.myList.draftValues[key];
						self.updateDataValues(draft);
					}
				}
				if(!isNewCols) {
					self.savedResults = JSON.parse(JSON.stringify(self.myList));
				}
			})
			.catch((error) => {
				self.showErrorToast(error);
			});
	}

	handleEmail(event) {
		let recId = event.detail.data.recordId;
		let iconId = event.detail.data.iconId;
		let idx = this.myList && this.myList.dataMap && this.myList.dataMap[recId];
		if(!idx && idx != 0) {
			return;
		}
		this.emailId = recId;
		this.emailShowCC = this.myList.data[idx].CC_Assistant__c;
		this.emailField = 'EventEmailBody__c';
		this.emailSubjectField = 'Email_Subject__c';
		this.emailTitle = 'Email';
		this.emailStatus = 'Email_Status__c';
		this.emailSent = 'Email_Sent__c';
		if (iconId == 'savethedate') {
			this.emailField = 'Save_The_Date_Email_Body__c';
			this.emailSubjectField = 'Save_The_Date_Subject__c';
			this.emailTitle = 'Save The Date';
			this.emailStatus = 'Save_The_Date_Status__c';
			this.emailSent = 'Save_The_Date_Sent__c';
			this.emailTemplateLastModified = 'Save_the_Date_Last_Modified__c';
		} else if (iconId == 'invitation') {
			this.emailField = 'Invite_Email_Body__c';
			this.emailSubjectField = 'EmailSubjectLine__c';
			this.emailTitle = 'Invitation';
			this.emailStatus = 'Invitation_Status__c';
			this.emailSent = 'Invitation_Sent__c';
			this.emailTemplateLastModified = 'Invitation_Last_Modified__c';
		} else if (iconId == 'reminder') {
			this.emailField = 'Reminder_Email_Body__c';
			this.emailSubjectField = 'Reminder_Subject__c';
			this.emailTitle = 'Reminder';
			this.emailStatus = 'Reminder_Email_Status__c';
			this.emailSent = 'Reminder_Email_Sent__c';
			this.emailTemplateLastModified = 'Reminder_Last_Modified__c';
		} else if (iconId == 'email') {
			this.emailTitle = 'Email';
			this.emailTemplateLastModified = 'Email_Last_Modified__c';
		}
		this.showEventEmail = true;
	}

	handleEmailClose(event) {
		this.showEventEmail = false;
		let data = event && event.detail && event.detail.data;
		if(!data) {
			return;
		}
		let item = this.myList && this.myList.dataMap ? this.myList.dataMap[data.id] : null;
		if(item == null) {
			return;
		}
		item = this.myList.data[item];
		for (let key in data) {
			if(item[key] != null) item[key] = data[key];
		}
		this.myList.data = JSON.parse(JSON.stringify(this.myList.data));
	}

	handleInvitation(event) {
		let optionsMap = {};
		let selectedMembers = [];
		for (let i = 0; i < this.selectedRowIds.length; i++) {
			let rowId = this.selectedRowIds[i];
			let item =
				this.myList && this.myList.dataMap ? this.myList.dataMap[rowId] : null;
			item = item != null ? this.myList.data[item] : null;
			if(item == null) {
				continue;
			}
			selectedMembers.push(item);
			item.generalWarning = this.getEmailWarning(item);
			item.warning = item.generalWarning;
			if(item.Has_Save_The_Date__c) {
				optionsMap.savethedate = {
					label: 'Save The Date',
					value: 'savethedate'
				};
				if(item.Save_The_Date_Sent__c && item.Save_The_Date_Sent__c != "") {
					item.saveWarning =
						"Save the date has been sent on " +
						this.getFormattedDateTime(item.Save_The_Date_Sent__c) +
						"\n";
				}
			}
			if(item.Has_Invite_Email__c) {
				optionsMap.invite = { label: "Invitation", value: "invitation" };

				if(item.Invitation_Sent__c && item.Invitation_Sent__c != "") {
					item.inviteWarning =
						"Invitation has been sent on " +
						this.getFormattedDateTime(item.Invitation_Sent__c) +
						"\n";
				}
			}
			if(item.Has_Reminder_Email__c) {
				optionsMap.reminder = { label: "Reminder", value: "reminder" };
				if(item.Reminder_Email_Sent__c && item.Reminder_Email_Sent__c != "") {
					item.reminderWarning =
						"Reminder has been sent on " +
						this.getFormattedDateTime(item.Reminder_Email_Sent__c) +
						"\n";
				}
			}
			if(item.Has_Event_Email__c) {
				optionsMap.email = { label: "Email", value: "email" };
				if(item.Email_Sent__c && item.Email_Sent__c != "") {
					item.emailWarning =
						"Email has been sent on " +
						this.getFormattedDateTime(item.Email_Sent__c) +
						"\n";
				}
			}
		}
		let optList = [];
		optList.push({ label: "Please select an email type", value: "" });
		for (let key in optionsMap) {
			optList.push(optionsMap[key]);
		}
		optList.sort((a, b) => a - b);
		selectedMembers.sort((a, b) => {
			return a.warning && a.warning.length ? -1 : 1;
		});
		this.selectedMembers = selectedMembers;
		this.selectedEmailOptions = optList;
		this.selectedEmailType = "";
		this.showInvitation = true;
	}

	getFormattedDateTime(key) {
		if(!key || key == "") {
			return "";
		}
		try {
			const d = new Date(key);
			return d.toLocaleDateString() + " " + d.toLocaleTimeString();
		} catch (e) {
			return "";
		}
	}

	getEmailWarning(item) {
		let msg = "";
		if(!item.Event_From_Email__c || !item.Event_From_Email__c.length) {
			msg += "No Event from email found.\n";
		}
		return msg;
	}

	handleInvitationClose(event) {
		this.showInvitation = false;
		this.init();
		this.loadTable();
	}

	getSelectedItems(event) {
		let selectedRowIds = [];
		const selectedRows = event.detail.selectedRows;
		// Display that fieldName of the selected rows
		for (let i = 0; i < selectedRows.length; i++) {
			selectedRowIds.push(selectedRows[i].Id);
		}

		this.selectedRowIds = selectedRowIds;
	}

	handleReport() {
		let url =
			"/lightning/r/Report/" + this.listReportId + "/view?fv0=" + this.recordId;
		window.open(url, "_blank");
	}

	handleNewDonation() {
		this.showDonation = true;
	}

	handleDonoClose() {
		this.showDonation = false;
	}

	handleDonoSave() {
		this.showDonation = false;
		this.init();
		this.loadTable();
	}

	handleCreateInteractions() {
		const rows = this.getInteractionTargetRows();
		const contactIds = [...new Set(rows.map((row) => row.ContactId).filter(Boolean))];
		if (!contactIds.length) {
			this.showToast(
				"No contacts to use",
				"There are no contacts in the current view. Clear a filter or add members, then try again.",
				"warning"
			);
			return;
		}
		this.interactionContactIds = contactIds;
		this.interactionRestrictedCount = rows.filter(
			(row) => row.Contact && row.Contact.Restricted__c
		).length;
		this.showCreateInteractions = true;
	}

	getInteractionTargetRows() {
		const filtered = (this.myList && this.myList.filteredData) || [];
		if (!this.selectedRowIds || !this.selectedRowIds.length) {
			return filtered;
		}
		const idSet = new Set(this.selectedRowIds);
		return filtered.filter((row) => idSet.has(row.Id));
	}

	handleCreateInteractionsClose() {
		this.showCreateInteractions = false;
	}

	handleCreateInteractionsSuccess(event) {
		this.showCreateInteractions = false;
		this.showToast(
			"Interactions created",
			`${event.detail.count} Interaction record(s) created.`,
			"success"
		);
		this.loadTable();
	}

	handleGuestsDeletion(event) {
		let selectedRowIds = this.selectedRowIds;
		if(!selectedRowIds) {
			this.showToast(
				"Warning",
				"Please select at least one guest to update RSVP status.",
				"warning"
			);
		} else {
			this.showDeleteConfirmation = true;
		}
	}

	handleDeletionConfirm(event) {
		this.showDeleteConfirmation = false;
		let selectedRowIds = this.selectedRowIds;
		if(selectedRowIds && selectedRowIds.length > 0) {
			deleteGuests({
				guestIds: JSON.stringify(selectedRowIds)
			})
				.then((result) => {
					this.showToast(
						"Success",
						"The Guests are deleted successfully.",
						"success"
					);
					this.loadTable();
				})
				.catch((error) => {
					this.showToast("Error", error.body.message, "error");
				});
		}
	}

	handleRSVPUpdateYes(event) {
		let selectedRowIds = this.selectedRowIds;
		if(selectedRowIds && selectedRowIds.length > 0) {
			this.showRSVPSelection = true;
		} else {
			this.showToast(
				"Warning",
				"Please select at least one guest to update RSVP status.",
				"warning"
			);
		}
	}

	handlePopSelection(event) {
		let status = event.detail?.rsvpValue;
		let attendedStatus = event.detail?.attendanceValue;
		this.showRSVPSelection = false;
		let self = this;

		// prevent overwriting with blank values
		if(!status) status = undefined;
		if(!attendedStatus) attendedStatus = undefined;

		updateRSVPStatus({
			memberIds: JSON.stringify(this.selectedRowIds),
			status: status,
			attendedStatus: attendedStatus
		})
			.then((result) => {
				this.loadTable();
				this.showToast(
					"Success",
					"The RSVP/Attendance status of selected Guests are updated.",
					"success"
				);
			})
			.catch((error) => {
				let msg = self.getErrMsg(error);
				this.showToast("Error", msg, "error");
			});
	}

	handlePopClose(event) {
		this.showRSVPSelection = false;
		this.showNewGuestCreation = false;
		this.showDeleteConfirmation = false;
		this.showNewListViewCreation = false;
	}

	handleEmailSummaryClose(event) {
		this.showEmailSummary = false;
	}

	handleEmailSummary(event) {
		this.showEmailSummary = true;
	}

	handleNewGuestCreation() {
		this.showNewGuestCreation = true;
	}

	async handleListViewSave(event) {
		this.selectedViewId = event.detail.Id;
		this.selectedOptions = event.detail.selectedOptions;
		this.showNewListViewCreation = false;
		this.showToast(
			"Success",
			"New list view has been updated successfully.",
			"success"
		);
		this.loadTable();
	}

	handleNewGuestSave(event) {
		this.showNewGuestCreation = false;
		this.showToast(
			"Success",
			"The new Guest is added successfully.",
			"success"
		);
		this.loadTable();
	}

	handleSearch(evt) {
		const isEnterKey = evt.keyCode === 13;
		this.searchTerm = evt.target.value;
		if (isEnterKey) {
			this.init();
			this.searchTerm = evt.target.value;
			this.loadTable();
		}
	}

	handleTitleClick(event) {
		this.syncDiable = false;
		this.navigateToRecord(this.recordId);
	}

	handleRowAction(event) {
		const row = event.detail.row;
		this.navigateToRecord(row.Id);
	}

	handleNext() {
		this.myList.pageNum++;
		this.myList.data = this.getPaginatedData();
	}

	handlePrev() {
		this.myList.pageNum--;
		this.myList.data = this.getPaginatedData();
	}

	handleZkipsterSync(event) {
		this.syncDiable = true;
		let self = this;
		syncEvent({
			listId: this.recordId
		})
			.then((result) => {
				if(result === "success") {
					this.showToast(
						"Success!",
						"Guests are syncing to zkipster and will appear in zkipster shortly.",
						"success"
					);
					self.syncDiable = false;
				} else if(result === "Cancelled") {
					this.showToast("Error!", "Unable to sync Cancelled or Complete events to zkipster.", "error");
				} else if(result === "error") {
					this.showToast(
						"Error",
						"There is something wrong with sync process. Please ask Data team to check Error Log.",
						"error"
					);
				}
			})
			.catch((error) => {
				let msg = self.getErrMsg(error);
				this.showToast("Error", msg, "error");
				this.syncDiable = false;
			});
	}

	handleZkipsterFromSync(event) {
		this.syncFromDisable = true;
		let self = this;
		syncFromZkipsterEvent({
			eventId: this.recordId
		})
			.then((result) => {
				if(result === "Cancelled") {
					this.showToast("Error!", "Unable to sync guest information to BRM for Cancelled events.", "error");
				} else {
					this.showToast(
						"Success!",
						"Guest information is syncing to BRM from zkipster and will appear in BRM shortly.",
						"success"
					);
					this.syncFromDisable = false;
				}
			})
			.catch((error) => {
				let msg = this.getErrMsg(error);
				this.showToast("Error", msg, "error");
				this.syncFromDisable = false;
			});
	}

	doExpensiveThing() {
		this.syncDiable = false;
	}

	handleHeaderAction(event) {
		const actionName = event.detail.action.name;
		const colDef = event.detail.columnDefinition;
		let columns = JSON.parse(JSON.stringify(this.myList.columns));
		let targetField = colDef && (colDef.fieldName || colDef.fieldApi);
		let idx = -1;
		for (let i = 0; i < columns.length; i++) {
			let col = columns[i];
			let isMatch = targetField
				? col.fieldApi == targetField
				: col.label == colDef.label;
			if(isMatch) {
				idx = i;
				break;
			}
		}
		if(idx == -1) {
			return;
		}
		let col = columns[idx];
		let filter = { ...(this.myList.filter || {}) };
		let fieldFilter = this.getFilterVals(col, actionName);
		if(fieldFilter == null) {
			delete filter[col.fieldApi];
		} else {
			filter[col.fieldApi] = fieldFilter;
		}
		this.myList.filter = filter;
		this.myList.columns = columns;
		let colMap = {};
		let colActionMap = {};
		for (let i = 0; i < columns.length; i++) {
			let c = columns[i];
			if(c.fieldApi) {
				colMap[c.fieldApi] = c;
				if(c.actions) {
					colActionMap[c.fieldApi] = c.actions;
				}
			}
		}
		this.myList.colMap = colMap;
		this.myList.stickyColumns = this.cloneColActions(this.myList.stickyColumns, colActionMap);
		this.myList.stickyColumns2 = this.cloneColActions(this.myList.stickyColumns2, colActionMap);
		this.refreshFilteredSortedData(true);
	}

	cloneColActions(columns, colActionMap) {
		let updated = this.getUpdatedColActions(columns, colActionMap);
		return updated ? JSON.parse(JSON.stringify(updated)) : updated;
	}

	getUpdatedColActions(columns, colActionMap) {
		if(!columns) {
			return columns;
		}
		for (let i = 0; i < columns.length; i++) {
			let col = columns[i];
			if(col.fieldApi && col.actions && colActionMap[col.fieldApi]) {
				col.actions = colActionMap[col.fieldApi];
			}
		}
		return columns;
	}

	getFilterVals(col, actionName) {
		const isNotes = col.fieldApi === this.NOTES_FIELD;
		let fieldFilter = {};
		let anyChecked = false;
		for (let i = 0; i < col.actions.length; i++) {
			let action = col.actions[i];
			let key = isNotes ? action.name : action.label;
			let isAllRow = action.name == "All" || action.label == "All";
			if(actionName == "All") {
				action.checked = isAllRow;
			} else if(isAllRow) {
				action.checked = false;
			} else if(actionName == key) {
				action.checked = !action.checked;
			}
			if(!isAllRow && action.checked) {
				fieldFilter[key] = true;
				anyChecked = true;
			}
		}
		if(!anyChecked) {
			for (let i = 0; i < col.actions.length; i++) {
				let action = col.actions[i];
				action.checked = action.name == "All" || action.label == "All";
			}
			delete col.iconName;
			return null;
		}
		col.iconName = "utility:filterList";
		return fieldFilter;
	}

	handleCellChanged(event) {
		let newDrafts = event.detail.draftValues;
		this.myList.draftValues = this.myList.draftValues
			? this.myList.draftValues
			: [];
		let copyData = [...this.myList.draftValues];
		for (let i = 0; i < newDrafts.length; i++) {
			let check = newDrafts[i];
			for (let field in check) {
				check[field] = this.getVal(check[field], this.myList.colMap[field]);
			}
			let isFound = false;
			for (let j = 0; j < copyData.length; j++) {
				if(check.Id == copyData[j].Id) {
					copyData[j] = Object.assign(copyData[j], check);
					isFound = true;
					break;
				}
			}
			if(!isFound) {
				copyData.push(check);
			}
		}

		if(copyData.length >= 200) {
			this.showErrorToast(
				"You can only edit at most 200 members before saving."
			);
			this.myList.draftValues = JSON.parse(
				JSON.stringify(this.myList.draftValues)
			);
			return;
		}
		this.myList.draftValues = JSON.parse(JSON.stringify(copyData));
	}

	async showExportPopup() {
		await this.restrictedContactCountForCurrentList();

		if(this.restrictedContact && this.restrictedContact > 0) {
			let confirmMessage = hasPrivateNameFieldsAccess
				? `Your results contain ${this.restrictedContact} Private Contact(s).`
				: `You've encountered a problem with some of the records you selected (${this.restrictedContact} records are not exporting). Please contact brmpartnerships@bloomberg.org for further assistance.`;
			const confirmResult = await LightningConfirm.open({
				message: confirmMessage,
				variant: 'header',
				label: 'Please Confirm',
				theme: 'warning'
			});
			if(confirmResult) {
				this.showExport = true;
				this.selectedExportFields = [];
			}
		} else {
			this.showExport = true;
			this.selectedExportFields = [];
		}
	}
	handleExport(event) {
		let isExport = event && event.detail && event.detail.isExport;
		this.showExport = false;
		if(isExport) {
			this.selectedExportFields = event.detail.selected;
			this.loadTable(true);
		}
	}

	exportExcel(result) {
		let columns = result && result.columns;
		if(!columns) {
			return;
		}
		columns = [];
		for (let i = 0; i < result.columns.length; i++) {
			if(
				result.columns[i].label &&
				result.columns[i].label.length &&
				result.columns[i].fieldApi != "EventEmailBody__c"
			) {
				columns.push(result.columns[i]);
			}
		}
		let tempGuestCount = this.guestCount;
		let csv = "";

		if(this.isEventList && this.eventSummary.length) {
			csv += "Expected Attendance," + this.expectedGuestCount + "\n";
			csv += "PlaceHolderGuests," + "\n";
			/*----------------------------------------------------------*/
			csv += "RSVP Statuses\n";
			for (let i = 0; i < this.eventSummary.length; i++) {
				let label = this.eventSummary[i].label;
				csv += this.getCsvFormatted(label);
				if(i < this.eventSummary.length - 1) {
					csv += ",";
				} else {
					csv += "\n";
				}
			}
			for (let i = 0; i < this.eventSummary.length; i++) {
				let count = this.eventSummary[i].count;
				csv += count;
				if(i < this.eventSummary.length - 1) {
					csv += ",";
				} else {
					csv += "\n\n";
				}
			}

			/*----------------------------------------------------------*/
			csv += "Attendance Statuses\n";
			csv += ",";
			csv += ",";
			for (let i = 0; i < this.attendenceSummary.length; i++) {
				let label = this.attendenceSummary[i].label;
				csv += this.getCsvFormatted(label);
				if(i < this.attendenceSummary.length - 1) {
					csv += ",";
				} else {
					csv += "\n";
				}
			}
			csv += ",";
			csv += ",";
			for (let i = 0; i < this.attendenceSummary.length; i++) {
				let count = this.attendenceSummary[i].count;
				csv += count;
				if(i < this.attendenceSummary.length - 1) {
					csv += ",";
				} else {
					csv += "\n\n";
				}
			}
			/*----------------------------------------------------------*/
		}
		for (let i = 0; i < columns.length; i++) {
			csv += this.getCsvFormatted(columns[i].label);
			if(i < columns.length - 1) {
				csv += ",";
			} else {
				csv += "\n";
			}
		}
		if(csv == "") {
			return;
		}
		let data = result && result.data;
		if(!data) {
			return;
		}

		for (let i = 0; i < data.length; i++) {
			if(!data[i].Contact.DoNotCall && (this.isRestricted || (!this.isRestricted && !data[i].Contact.Restricted__c))) {
				if(this.isValidFiltered(data[i])) {
					for (let j = 0; j < columns.length; j++) {
						let col = columns[j];
						let h = col.fieldApi;
						let d = data[i][h];
						let val = data[i];

						if((val && val.Contact?.Restricted__c && this.contactFieldMapping[col.fieldApi] && this.hasAccess(this.contactFieldMapping[col.fieldApi]) && val.Contact[this.contactFieldMapping[col.fieldApi]])) {
							if((col.fieldApi == 'UB_Company__c' && val?.Contact?.Account?.Restricted__c) || val?.Contact?.Restricted__c) {
								val = val.Contact[this.contactFieldMapping[col.fieldApi]];
							} else {
								val = val.Contact[col.fieldApi];
							}
							d = val;
						}
						if(h == 'PartySize__c') {
							val = this.getVal(d, col, false, true, true);
						} else {
							val = this.getCsvFormatted(
								this.getVal(d, col, false, true, true)
							);
						}
						if(col.type == "checkbox") {
							val = val == '"true"' || val == true ? "Yes" : "";
						}
						csv += val;
						if(j < columns.length - 1) {
							csv += ",";
						} else {
							csv += "\n";
						}
					}
				}
			} else {
				tempGuestCount--;
			}
		}
		csv = csv.replace("PlaceHolderGuests,", "Guests, " + tempGuestCount);
		this.download(csv);
	}

	getVal(val, col, replaceBlank, isLookupName) {
		return getVal(val, col, replaceBlank, isLookupName, false);
	}

	getVal(val, col, replaceBlank, isLookupName, isExport) {
		if(!col) {
			return val;
		}
		if(col.type == "html") {
			val = this.getHtmlText(val, isExport);
		} else if(col.type == "lookup" && isLookupName) {
			val =
				this.myList.nameMap &&
				this.myList.nameMap[col.fieldApi] &&
				this.myList.nameMap[col.fieldApi][val];
		} else if(isExport && col.type && col.type == "date") {
			val = this.getDate(val);
		} else if(isExport && col.type && col.type == "datetime") {
			val = this.getDateTime(val);
		}
		if(val == null || !val.length) {
			return replaceBlank ? this.BLANK : val;
		}
		return val;
	}

	getDate(key) {
		if(!key || !key.length) {
			return "";
		}
		const d = new Date(key);
		return d.toLocaleDateString();
	}

	getDateTime(key) {
		if(!key || !key.length) {
			return "";
		}
		const d = new Date(key);
		var hours = d.getHours();
		var mon = d.getMonth() + 1;
		var ampm = hours >= 12 ? 'PM' : 'AM';
		hours = hours % 12;
		hours = hours ? hours : 12;
		var mins = d.getMinutes().toString();
		if(mins < 10) {
			mins = '0' + mins;
		}
		const dt = mon + '/' + d.getDate() + '/' + d.getFullYear() + ', ' + hours + ':' + mins + ' ' + ampm;
		return dt;
	}

	navigateToRecord(rowId) {
		if(!rowId || !rowId.length) {
			return;
		}
		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: rowId,
				actionName: "view"
			}
		});
	}

	getHtmlText(val, isExport) {
		if(!val || !val.length) {
			return val;
		}
		let retVal;
		let span = document.createElement("span");
		val = val.replace(/%/g, "%25");
		span.innerHTML = decodeURIComponent(val);
		if(isExport) {
			retVal = span.textContent || span.innerText;
		} else {
			retVal = span.innerHTML;
		}
		return retVal;
	}

	download(data) {
		data = !data ? "" : data;
		let hiddenElement = document.createElement("a");
		hiddenElement.href =
			"data:text/csv;charset=utf-8,%EF%BB%BF" + encodeURIComponent(data);
		hiddenElement.target = "_self";
		hiddenElement.download =
			"List View: " + this.title + " " + this.getFormattedTime() + ".csv";
		document.body.appendChild(hiddenElement);
		hiddenElement.click();
	}

	getFormattedTime() {
		var today = new Date();
		var y = today.getFullYear();
		var m = today.getMonth() + 1;
		var d = today.getDate();
		var h = today.getHours();
		var mi = today.getMinutes();
		var s = today.getSeconds();
		return y + "-" + m + "-" + d + "-" + h + "-" + mi + "-" + s;
	}

	getCsvFormatted(d) {
		if(typeof d == "number") {
			var formatter = new Intl.NumberFormat("en-US", {
				style: "currency",
				currency: "USD",
				maximumFractionDigits: 0 // (causes 2500.99 to be printed as $2,501)
			});
			return '"' + formatter.format(d) + '"';
		}
		if(typeof d == "boolean") {
			return '"' + d + '"';
		}

		d = d != null ? d : "";
		let regExp = new RegExp('"', "g");
		try {
			return '"' + d.replace(regExp, '""') + '"';
		} catch (e) {
			return "";
		}
	}

	handleCancel() {
		let filter = this.myList.filter;
		let sortSpec = this.myList.sortSpec;
		let columns = this.myList.columns;
		this.myList = JSON.parse(JSON.stringify(this.savedResults));
		this.myList.draftValues = [];
		this.myList.filter = filter || {};
		this.myList.sortSpec = sortSpec || this.getDefaultSortSpec();
		if(columns && columns.length) {
			this.myList.columns = columns;
			let colMap = {};
			for (let i = 0; i < columns.length; i++) {
				if(columns[i].fieldApi) {
					colMap[columns[i].fieldApi] = columns[i];
				}
			}
			this.myList.colMap = colMap;
		}
		this.refreshFilteredSortedData(false);
	}

	getFilteredData() {
		let data = this.myList.allData;
		if(!data || !data.length) {
			this.showInviteBtn = false;
			return [];
		}
		let filteredData = [];
		let showInv = false;
		for (let i = 0; i < data.length; i++) {
			let d = data[i];
			this.setDonorType(d);
			if(
				d.Has_Save_The_Date__c ||
				d.Has_Invite_Email__c ||
				d.Has_Reminder_Email__c ||
				d.Has_Event_Email__c
			) {
				showInv = true;
			}
			if(this.isValidFiltered(d)) {
				filteredData.push(d);
			}
		}
		this.showInviteBtn = showInv;
		return filteredData;
	}

	setInitialColumnWidths() {
		let columns = this.myList.columns;
		let colWidthMap = {};
		let colFieldMap = {};
		for (let i = 0; i < columns.length; i++) {
			let col = columns[i];
			let api = col.fieldApi;
			if(api) {
				colWidthMap[api] = this.MIN_COL_WIDTH;
				colFieldMap[api] = col;
			}
		}
		let data = this.myList.data;
		for (let i = 0; i < data.length; i++) {
			let d = data[i];
			for (let field in d) {
				let col = colFieldMap[field];
				if(field == "EventEmailBody__c") {
					colWidthMap[field] = 140;
				} else if(field == "RSVPStatus__c" || field == "AttendedStatus__c") {
					colWidthMap[field] = 100;
				} else if(col && col.type !== "lookup" && col.type !== "checkbox") {
					let val = this.getVal(d[field], col, true, true, true);
					val = val && val.length ? val : this.BLANK;
					let len = val.length * this.COL_CHAR_WIDTH;
					colWidthMap[field] = Math.min(
						Math.max(colWidthMap[field], len),
						this.MAX_COL_WIDTH
					);
				}
			}
		}

		for (let i = 0; i < columns.length; i++) {
			let col = columns[i];
			let api = col.fieldApi;
			if(api) {
				col.initialWidth = colWidthMap[api];
			}
		}
		this.myList.columns = columns;
	}

	applyRestrictedSubject(elem) {
		if(!elem || !hasPrivateNameFieldsAccess) {
			return elem;
		}
		let updatedElem = { ...elem };
		const restrictedName = elem.Contact?.Restricted_Name__c || '';
		if(updatedElem.EmailSubjectLine__c && updatedElem.EmailSubjectLine__c.includes('#')) {
			updatedElem.EmailSubjectLine__c = updatedElem.EmailSubjectLine__c.replace(/#/g, restrictedName);
		}
		if(updatedElem.Latest_Email_Subject__c && updatedElem.Latest_Email_Subject__c.includes('#')) {
			updatedElem.Latest_Email_Subject__c = updatedElem.Latest_Email_Subject__c.replace(/#/g, restrictedName);
		}
		return updatedElem;
	}

	getPaginatedData() {
		let filteredData = this.myList && this.myList.filteredData;
		if(!filteredData) {
			return [];
		}
		this.myList.pageSize = this.myList.pageSize ? this.myList.pageSize : 20;
		let pageSize = this.myList.pageSize;
		this.myList.pageNum = this.myList.pageNum ? this.myList.pageNum : 0;
		let pageNum = this.myList.pageNum;
		this.myList.pageNum = pageNum;
		let start = pageNum * pageSize;
		let max = Math.min(start + pageSize, filteredData.length);
		let pageData = [];
		let dataMap = {};
		for (let i = start; i < max; i++) {
			let d = this.applyRestrictedSubject(filteredData[i]);
			d.myEmailMap = this.getEmailMap(d);
			pageData.push(d);
			dataMap[d.Id] = pageData.length - 1;
		}

		this.myList.dataMap = dataMap;
		this.setPagination(filteredData.length);
		return pageData;
	}

	getEmailMap(d) {
		let email = {};
		if(!d) {
			return email;
		}
		email.savethedate = {
			hasVal: d.Has_Save_The_Date__c,
			status: d.Save_The_Date_Status__c,
			sent: d.Save_The_Date_Sent__c
		};
		email.invitation = {
			hasVal: d.Has_Invite_Email__c,
			status: d.Invitation_Status__c,
			sent: d.Invitation_Sent__c
		};
		email.reminder = {
			hasVal: d.Has_Reminder_Email__c,
			status: d.Reminder_Email_Status__c,
			sent: d.Reminder_Email_Sent__c
		};
		email.email = {
			hasVal: d.Has_Event_Email__c,
			status: d.Email_Status__c,
			sent: d.Email_Sent__c
		};
		return email;
	}

	setDonorType(d) {
		if(!d || !d.Fundraising_Donor_Type__c) {
			return;
		}
		let donorType = d.Fundraising_Donor_Type__c;
		if("Individual" == donorType) {
			d.c__isHide_Fundraising_Organization__c = true;
			d.c__isHide_ContactId = false;
			d.Fundraising_Organization__c = "";
		} else if("Organization" == donorType) {
			d.c__isHide_Fundraising_Organization__c = false;
			d.c__isHide_ContactId = false;
		}
	}

	isValidFiltered(data) {
		let filter = this.myList.filter;
		if(!filter || !data) {
			return true;
		}
		for (let field in filter) {
			let fieldFilter = filter[field];
			if(!fieldFilter || fieldFilter.all || !Object.keys(fieldFilter).length) {
				continue;
			}
			let col =
				(this.myList.colMap && this.myList.colMap[field]) ||
				this.getColumnByField(field);
			if(!col) {
				continue;
			}
			if(!this.matchesColumnFilter(data, col, fieldFilter)) {
				return false;
			}
		}
		return true;
	}

	matchesColumnFilter(data, col, fieldFilter) {
		let fieldApi = col.fieldApi;
		if(fieldApi === this.NOTES_FIELD) {
			let notesValue = this.getNotesValue(data, col);
			return fieldFilter[this.getNotesActionName(notesValue)] == true;
		}
		let val = this.getVal(data[fieldApi], col, true, true);
		if(col.fieldType == "MULTIPICKLIST" && val != this.BLANK) {
			let valList = String(val).split(";");
			for (let i = 0; i < valList.length; i++) {
				if(fieldFilter[valList[i]]) {
					return true;
				}
			}
			return false;
		}
		return fieldFilter[val] == true;
	}

	getColumns(result) {
		if(!result || !result.data || !result.data.length) {
			return result.columns;
		}
		let columns = result.columns;
		let dupeCheck = {};
		let data = result.data;
		let eventSummary = {};
		let attendenceSummary = {};
		for (let i = 0; i < data.length; i++) {
			for (let j = 0; j < columns.length; j++) {
				let col = columns[j];
				/*---------------------------------------------*/
				if(
					(!this.searchTerm || this.searchTerm == "") &&
					Object.keys(eventSummary).length == 0 &&
					col.fieldApi == "RSVPStatus__c"
				) {
					let options = col.typeAttributes.options;
					for (let i = 0; i < options.length; i++) {
						let label = options[i].label;
						eventSummary[label] = 0;
					}
				}
				/*---------------------------------------------*/
				if(
					(!this.searchTerm || this.searchTerm == "") &&
					Object.keys(attendenceSummary).length == 0 &&
					col.fieldApi == "AttendedStatus__c"
				) {
					let options = col.typeAttributes.options;
					for (let i = 0; i < options.length; i++) {
						let label = options[i].label;
						attendenceSummary[label] = 0;
					}
				}
				/*---------------------------------------------*/
				this.setDonorType(data[i]);
				if(col.label) {
					if(!col.actions) {
						col.actions = [];
					}
					let h = col.fieldApi;
					if(col.fieldApi === this.NOTES_FIELD) {
						col.sortable = true;
					}
					let val = col.fieldApi === this.NOTES_FIELD
						? this.getNotesValue(data[i], col)
						: this.getVal(data[i][h], col, true, true);
					/*---------------------------------*/
					if(
						(!this.searchTerm || this.searchTerm == "") &&
						col.fieldApi == "RSVPStatus__c" &&
						val &&
						val != ""
					) {
						let count = eventSummary[val] ? eventSummary[val] : 0;
						count++;
						eventSummary[val] = count;
					}
					/*---------------------------------*/
					if(
						(!this.searchTerm || this.searchTerm == "") &&
						col.fieldApi == "AttendedStatus__c" &&
						val &&
						val != ""
					) {
						let count = attendenceSummary[val] ? attendenceSummary[val] : 0;
						count++;
						attendenceSummary[val] = count;
					}
					/*------------------------------------------*/

					if(col.fieldType == "MULTIPICKLIST" && val != this.BLANK) {
						let valList = val.split(";");
						for (let z = 0; z < valList.length; z++) {
							let v = valList[z];
							if(v) {
								dupeCheck[h] = dupeCheck[h] != null ? dupeCheck[h] : {};
								if(!dupeCheck[h][v]) {
									col.actions.push({ label: v, name: v, checked: false });
								}
								dupeCheck[h][v] = true;
							}
						}
					} else {
						dupeCheck[h] = dupeCheck[h] != null ? dupeCheck[h] : {};
						if(col.fieldApi === this.NOTES_FIELD) {
							let actionName = this.getNotesActionName(val);
							let actionLabel = this.getNotesActionLabel(val);
							if(!dupeCheck[h][actionName]) {
								col.actions.push({
									label: String(actionLabel),
									name: String(actionName),
									checked: false
								});
							}
							dupeCheck[h][actionName] = true;
						} else {
							if(!dupeCheck[h][val]) {
								col.actions.push({ label: val, name: val, checked: false });
							}
							dupeCheck[h][val] = true;
						}
					}
				}
			}
		}

		if(!this.searchTerm || this.searchTerm == "") {
			this.eventSummary = Object.keys(eventSummary).length > 0 ? [] : this.eventSummary;
			for (let key in eventSummary) {
				this.eventSummary.push({ label: key, count: eventSummary[key] });
				}
			this.attendenceSummary = Object.keys(attendenceSummary).length > 0 ? [] : this.attendenceSummary;
			for (let key in attendenceSummary) {
				this.attendenceSummary.push({ label: key, count: attendenceSummary[key] });
				}
			}

		this.myList.colMap = {};
		this.myList.filter = this.myList.filter || {};
		for (let i = 0; i < columns.length; i++) {
			let col = columns[i];
			this.myList.colMap[col.fieldApi] = col;
			if(col.baseLabel == null && col.label != null) {
				col.baseLabel = col.label;
			}
			if(col.actions) {
				col.actions.sort((a, b) => {
					if(a.label == this.BLANK) {
						return -1;
					}
					return String(a.label).toLowerCase() > String(b.label).toLowerCase() ? 1 : -1;
				});
				col.actions.unshift({ label: "All", name: "All", checked: true });
			}
		}
		this.reconcileFilters(columns);
		return columns;
	}

	setPagination(dataSize) {
		let pageSize = this.myList.pageSize;
		this.myList.pageNum = this.myList.pageNum ? this.myList.pageNum : 0;
		if(!dataSize || dataSize <= pageSize) {
			this.myList.rowOffset = 0;
			this.myList.showNext = false;
			this.myList.showPrev = false;
			this.myList.showPagination = false;
			return;
		}
		this.myList.rowOffset = pageSize * this.myList.pageNum;
		this.myList.showPrev = this.myList.pageNum != 0;
		this.myList.showNext = (this.myList.pageNum + 1) * pageSize <= dataSize;
		this.myList.showPagination = this.myList.showPrev || this.myList.showNext;
	}

	picklistChanged(event) {
		event.stopPropagation();
		let dataRecieved = event.detail.data;
		let updatedItem = {
			Id: dataRecieved.context
		};
		let val = dataRecieved.value;
		updatedItem[dataRecieved.field] = val;
		this.updateDraftValues(updatedItem);
		this.updateDataValues(updatedItem);
	}

	updateDraftValues(updateItem) {
		let draftValueChanged = false;
		this.myList.draftValues = this.myList.draftValues
			? this.myList.draftValues
			: [];
		let copyDraftValues = this.myList.draftValues;
		copyDraftValues.forEach((item) => {
			if(item.Id === updateItem.Id) {
				Object.assign(item, updateItem);
				draftValueChanged = true;
			}
		});

		if(draftValueChanged) {
			this.myList.draftValues = JSON.parse(JSON.stringify(copyDraftValues));
		} else {
			copyDraftValues.push(updateItem);
			this.myList.draftValues = JSON.parse(JSON.stringify(copyDraftValues));
		}
	}

	updateDataValues(updateItem) {
		if(this.myList.dataMap[updateItem.Id] == null) {
			return;
		}
		let idx = this.myList.dataMap[updateItem.Id];
		let data = this.myList.data;
		let item = data[idx];
		for (let field in updateItem) {
			item[field] = updateItem[field];
		}
		this.setDonorType(item);
		this.myList.data = JSON.parse(JSON.stringify(data));
	}

	handleSort(event) {
		let field = event.detail.fieldName;
		if(!field) {
			return;
		}
		let spec = this.myList.sortSpec || [];
		let direction = "asc";
		if(spec.length === 1 && spec[0].field === field) {
			direction = spec[0].direction === "asc" ? "desc" : "asc";
		}
		let col =
			(this.myList.colMap && this.myList.colMap[field]) ||
			this.getColumnByField(field);
		this.myList.sortSpec = [
			{
				field: field,
				direction: direction,
				label: col ? (col.baseLabel != null ? col.baseLabel : col.label) : field,
				type: this.getSortType(col)
			}
		];
		this.applySortIndicators();
		this.refreshFilteredSortedData(true);
	}

	handleSaveBtn() {
		this.template.querySelector("lightning-datatable").save();
		this.template.querySelector("button[text=Save]").click();
	}

	handleAssistants() {
		if(!this.selectedRowIds || !this.selectedRowIds.length) {
			return this.showErrorToast("To CC Staff, select at least 1 guest.");
		}
		this.showAssistant = true;
	}

	handleAssistantClose() {
		this.showAssistant = false;
	}

	handleAssistantUpdate() {
		this.showAssistant = false;
		this.init();
		this.loadTable();
	}

	// BRME-6977: Method to handle guest info update
	handleUpdateGuestInfo() {
		if(!this.selectedRowIds || !this.selectedRowIds.length) {
			return this.showErrorToast("No guest(s) selected to update information.");
		}else{
			this.handleOpenUpdateGuestInfo();
		}
	}

	// BRME-6977: Method to open the modal to take the field and value inputs
	async handleOpenUpdateGuestInfo() {
		const result = await UpdateGuestInfo.open({
			size: "small",
			description: "Update Guest Details",
			object: "CampaignMember",
			recType: this.recType
		});
		if(result !== undefined && result !== 'close'){
			this.showSpinner = true;
			this.updateGuestInfo(result?.columnLabel, result?.fieldName, result?.value);
		}
	}

	// BRME-6977: Method to update the list members for the selected field with the selected value
	async updateGuestInfo(column, fieldName, value) {
		let self = this;
		try {
			await updateGuestInfo({ memberIds: JSON.stringify(this.selectedRowIds), fieldName: fieldName, value: value });
			this.showSpinner = false;
			this.loadTable();
			this.showToast(
				"Success",
				`The ${column} of selected Guests are updated.`,
				"success"
			);
		} catch (error) {
			let msg = self.getErrMsg(error);
			this.showToast("Error", msg, "error");
		}
	}

	handleSave(event) {
		let draftVals =
			event && event.details && event.details.draftValues
				? event.details.draftValues
				: this.template.querySelector("c-inline-data-table").draftValues;
		this.mergeDraftValues(draftVals);
		let self = this;
		self.myList.isLoaded = false;
		saveListMembers({ membersList: self.myList.draftValues })
			.then(() => {
				self.myList.draftValues = [];
				self.showSuccessToast("Save Successful!");
				self.myList.data = [];
				self.loadTable();
			})
			.catch((error) => {
				let msg = self.getErrMsg(error);
				msg = msg && msg.length ? msg : "unknown error";
				self.showErrorToast(msg);
			});
	}

	getErrMsg(error) {
		if(!error) {
			return null;
		}
		if(typeof error === "string") {
			return error;
		}

		let errMsg = null;
		if(Array.isArray(error)) {
			for (let i = 0; i < error.length; i++) {
				errMsg = this.getErrMsg(error[i]);
				if(errMsg && errMsg.length) {
					return errMsg;
				}
			}
		} else if(typeof error === "object") {
			for (let key in error) {
				if(key == "message") {
					return error[key];
				} else {
					errMsg = this.getErrMsg(error[key]);
					if(errMsg && errMsg.length) {
						return errMsg;
					}
				}
			}
		}

		return errMsg;
	}

	mergeDraftValues(draftList) {
		this.myList.draftValues = this.myList.draftValues
			? this.myList.draftValues
			: [];
		for (let i = 0; i < draftList.length; i++) {
			let isFound = false;
			let check = draftList[i];
			for (let j = 0; j < this.myList.draftValues.length; j++) {
				if(this.myList.draftValues[j].Id == check.Id) {
					isFound = true;
					this.updateDraftValues(check);
					break;
				}
			}
			if(!isFound) {
				this.myList.draftValues.push(check);
			}
			this.updateDataValues(check);
		}
	}

	showErrorToast(msg) {
		msg = this.getErrMsg(msg);
		const evt = new ShowToastEvent({
			title: "Error",
			message: msg,
			variant: "error"
		});
		this.dispatchEvent(evt);
		this.myList.isLoaded = true;
	}

	showToast(title, message, variant) {
		const evt = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(evt);
	}

	showSuccessToast(msg) {
		const evt = new ShowToastEvent({
			title: "Success",
			message: msg,
			variant: "success"
		});
		this.dispatchEvent(evt);
		this.myList.isLoaded = true;
	}
	shortBio = false;
	closeBioGeneration() {
		this.generateBio = false;
	}
	generateBioDoc() {
		if(this.selectedMenuItemValue == 'bio') {
			this.handleGenerateBio();
		} else if(this.selectedMenuItemValue == 'shortBio') {
			this.handleGenerateShortBio();
		}
		this.generateBio = false;
	}
	async handleGenerateBio(event) {
		await this.generateDocument(event, false, 'bio');
	}

	async handleGenerateShortBio(event) {
		await this.generateDocument(event, true, 'shortBio');
	}

	async generateDocument(event, isShort, actionName) {
		const ids = this.myList.data.map(rowData => {
			return rowData.ContactId;
		});
		const selectedIds = ids.join(";");
		// Wait for restrictedContactCountForCurrentList to complete before proceeding
		await this.restrictedContactCountForCurrentList(ids);
		const recordId = this.recordId;
		const selectedSource = this.selectedSource;
		this.url = `${this.myDomain}/apex/DocGeneration?selectedSource=${encodeURIComponent(selectedSource)}&docGenerateType=MultiBioDoc&short=${isShort}&bio=${isShort}&id=${selectedIds}&listId=${recordId}&includeListsEvents=yes&actionName=${actionName}&source=quickaction&retURL=lightning/cmp/c__ListViewInlineEditCmp?c__id=${this.recordId}`;

		if(this.restrictedContact && this.restrictedContact > 0) {

			let confirmMessage = hasPrivateNameFieldsAccess
				? `Your results contain ${this.restrictedContact} Private Contact(s).`
				: `You've encountered a problem with some of the records you selected (${this.restrictedContact} records are not exporting). Please contact brmpartnerships@bloomberg.org for further assistance.`;
			const confirmResult = await LightningConfirm.open({
				message: confirmMessage,
				variant: 'header',
				label: 'Please Confirm',
				theme: 'warning'
			});
			if(confirmResult) {
				this.generateBio = true;
				window.open(this.url);
			}
		} else {
			window.open(this.url, '_self');
		}
	}

	getMyDomain() {
		getMyDomain()
			.then((result) => {
				this.myDomain = result;
			})
			.catch((error) => {
				console.log('Error while retrieving Domain: ' + error);
			});
	}
	createListView(event) {
		this.showNewListViewCreation = true;
	}

	async handleAddSignificantOther(event) {
		if(this.selectedRowIds == undefined || this.selectedRowIds.length == 0) {
			this.showToast(
				"Error",
				"To Add Significant Other, select at least 1 guest.",
				"error"
			);
			return;
		}
		const result = await LightningConfirm.open({
			message: 'Are you sure you want to add Significant Other(s)?',
			variant: 'header',
			label: 'Please Confirm',
			theme: 'warning'
		});
		if(result) {
			this.addSignificantOther(event);
		}
	}

	addSignificantOther(event) {
		addSignificantOther({ listId: this.recordId, selectedIds: this.selectedRowIds })
			.then((result) => {
				this.addSignificantOtherMessage = result;
				this.showAddSignificantOtherMessage = true;
			})
			.catch((error) => {
				console.log('Error while retrieving handleAddSignificantOther: ' + JSON.stringify(error));
			});
	}

	handleShowAddSignificantOtherMessage(event) {
		this.showAddSignificantOtherMessage = false;
		this.loadTable();
	}

	handleOnMenuItem(event) {
		this.selectedMenuItemValue = event.detail.value;
		if(this.selectedMenuItemValue == 'addGuest') {
			this.handleNewGuestCreation();
		} else if(this.selectedMenuItemValue == 'addSignificantOthers') {
			this.handleAddSignificantOther();
		} else if(this.selectedMenuItemValue == 'deleteGuests') {
			this.handleGuestsDeletion();
		} else if(this.selectedMenuItemValue == 'updateRSVPAttendance') {
			this.handleRSVPUpdateYes();
		} else if(this.selectedMenuItemValue == 'updateCCAssistants') {
			this.handleAssistants();
		} else if(this.selectedMenuItemValue == 'updateGuestInfo') {
			this.handleUpdateGuestInfo();
		} else if(this.selectedMenuItemValue == 'syncGuestsToZkipster') {
			this.handleZkipsterSync();
		} else if(this.selectedMenuItemValue == 'syncGuestsFromZkipster') {
			this.handleZkipsterFromSync();
		} else if(this.selectedMenuItemValue == 'guestList') {
			this.showExportPopup();
		} else if(this.selectedMenuItemValue == 'guestSummaryEmail') {
			this.handleEmailSummary();
		} else if(this.selectedMenuItemValue == 'bio') {
			this.shortBio = false;
			this.generateBio = true;
		} else if(this.selectedMenuItemValue == 'shortBio') {
			this.shortBio = true;
			this.generateBio = true;
		} else if(this.selectedMenuItemValue == 'sendInvitations') {
			this.handleInvitation();
		} else if(this.selectedMenuItemValue == 'createColumnOrders') {
			this.createListView();
		}
	}

	get generateBioHeader() {
		return this.shortBio ? 'Generate Short Bio' : 'Generate Bio';
	}
	async restrictedContactCountForCurrentList(selectedIds) {
		try {
			// Await the result from getRestrictedContactCount
			if(selectedIds && selectedIds.length > 0){
				this.restrictedContact = await getRestrictedContactForGenerateBio({contactIds: selectedIds});
			}
			else{
			this.restrictedContact = await getRestrictedContactCount({ listId: this.recordId });
			}

		} catch (error) {
			console.log('restrictedContactCount error : ' + JSON.stringify(error));
		}
	}

	getColumnByField(fieldApi) {
		return (this.myList?.columns || []).find(col => col.fieldApi === fieldApi);
	}

	getCellDisplayValue(row, fieldApi) {
		const col = this.myList?.colMap?.[fieldApi] || this.getColumnByField(fieldApi);
		const rawValue = row ? row[fieldApi] : "";

		let value = this.getVal(rawValue, col, false, true, true);

		return value == null ? "" : String(value).trim();
	}

	getNotesValue(rowOrValue, col) {
		let rawValue;
		if(rowOrValue && typeof rowOrValue === "object" && rowOrValue[this.NOTES_FIELD] !== undefined) {
			rawValue = rowOrValue[this.NOTES_FIELD];
		} else {
			rawValue = rowOrValue;
		}
		if(rawValue == null) {
			return "";
		}
		if(typeof rawValue === "object") {
			if(rawValue.value != null) {
				rawValue = rawValue.value;
			} else if(rawValue.label != null) {
				rawValue = rawValue.label;
			} else if(rawValue.displayValue != null) {
				rawValue = rawValue.displayValue;
			} else {
				return "";
			}
		}
		let value = this.getVal(rawValue, col, false, true, true);
		if(value == null) {
			return "";
		}
		if(typeof value === "object") {
			if(value.value != null) {
				value = value.value;
			} else if(value.label != null) {
				value = value.label;
			} else if(value.displayValue != null) {
				value = value.displayValue;
			} else {
				return "";
			}
		}
		return String(value).trim();
	}

	getNotesActionName(noteValue) {
		let cleanValue = noteValue == null ? '' : String(noteValue).trim();
		return cleanValue.length ? cleanValue : '__BLANK_NOTES__';
	}

	getNotesActionLabel(noteValue) {
		let cleanValue = noteValue == null ? '' : String(noteValue).replace(/\s+/g, " ").trim();
		if(!cleanValue.length || cleanValue === "[object Object]") {
			return '';
		}
		return cleanValue.length > 120
			? cleanValue.substring(0, 120) + '...'
			: cleanValue;
	}

	refreshFilteredSortedData(resetPage = true) {
		if(resetPage) {
			this.myList.pageNum = 0;
		}
		this.myList.filteredData = this.applyMultiSort(this.getFilteredData());
		this.myList.data = this.getPaginatedData();
	}

	applySortIndicators() {
		let columns = this.myList && this.myList.columns;
		if(!columns || !columns.length) {
			return;
		}
		let spec = this.myList.sortSpec || [];
		let markerMap = {};
		for (let i = 0; i < spec.length; i++) {
			markerMap[spec[i].field] =
				spec[i].direction === "desc"
					? this.SORT_MARKER_DOWN
					: this.SORT_MARKER_UP;
		}
		for (let i = 0; i < columns.length; i++) {
			let col = columns[i];
			let base = col.baseLabel != null ? col.baseLabel : col.label;
			if(base == null) {
				continue;
			}
			col.baseLabel = base;
			let marker = markerMap[col.fieldApi];
			col.label = marker ? base + " " + marker : base;
		}
		this.myList.columns = [...columns];
	}

	getDefaultSortSpec() {
		return [{ field: "UB_LastName__c", direction: "asc", type: "string" }];
	}

	getSortType(col) {
		if(!col) {
			return "string";
		}
		if(col.fieldType == "MULTIPICKLIST") {
			return "string";
		}
		switch (col.type) {
			case "checkbox":
			case "boolean":
				return "boolean";
			case "date":
				return "date";
			case "datetime":
				return "datetime";
			case "number":
			case "currency":
			case "percent":
				return "number";
			default:
				return "string";
		}
	}

	applyMultiSort(rows) {
		let spec = this.myList.sortSpec;
		if(!rows || !rows.length || !spec || !spec.length) {
			return rows || [];
		}
		let specs = spec.slice(0, this.MAX_SORT_COLUMNS);
		let decorated = new Array(rows.length);
		for (let i = 0; i < rows.length; i++) {
			let keys = new Array(specs.length);
			for (let j = 0; j < specs.length; j++) {
				keys[j] = this.getSortKey(rows[i], specs[j]);
			}
			decorated[i] = { row: rows[i], keys: keys, idx: i };
		}
		decorated.sort((a, b) => {
			for (let j = 0; j < specs.length; j++) {
				let cmp = this.compareSortKeys(a.keys[j], b.keys[j], specs[j]);
				if(cmp !== 0) {
					return cmp;
				}
			}
			return a.idx - b.idx;
		});
		let sorted = new Array(decorated.length);
		for (let i = 0; i < decorated.length; i++) {
			sorted[i] = decorated[i].row;
		}
		return sorted;
	}

	getSortKey(row, spec) {
		let col =
			(this.myList.colMap && this.myList.colMap[spec.field]) ||
			this.getColumnByField(spec.field);
		let type = spec.type || this.getSortType(col);
		let raw = row ? row[spec.field] : null;
		if(spec.field === this.NOTES_FIELD) {
			let notes = this.getNotesValue(row, col);
			return notes && notes.length
				? notes.replace(/\s+/g, " ").toLowerCase()
				: null;
		}
		if(type == "boolean") {
			if(raw == null || raw === "") {
				return null;
			}
			return raw === true || raw === "true" ? 1 : 0;
		}
		if(type == "number") {
			if(raw == null || raw === "") {
				return null;
			}
			let num = Number(raw);
			return isNaN(num) ? null : num;
		}
		if(type == "date" || type == "datetime") {
			if(raw == null || raw === "") {
				return null;
			}
			let time = new Date(raw).getTime();
			return isNaN(time) ? null : time;
		}
		let display = this.getCellDisplayValue(row, spec.field);
		if(display == null || !display.length) {
			return null;
		}
		return display.replace(/\s+/g, " ").toLowerCase();
	}

	compareSortKeys(aKey, bKey, spec) {
		let dir = spec.direction === "desc" ? -1 : 1;
		let aBlank = aKey == null;
		let bBlank = bKey == null;
		if(aBlank && bBlank) {
			return 0;
		}
		if(aBlank) {
			return dir === 1 ? 1 : -1;
		}
		if(bBlank) {
			return dir === 1 ? -1 : 1;
		}
		if(typeof aKey === "number" && typeof bKey === "number") {
			return aKey === bKey ? 0 : dir * (aKey < bKey ? -1 : 1);
		}
		return dir * this.getCollator().compare(String(aKey), String(bKey));
	}

	getCollator() {
		if(!this._collator) {
			this._collator = new Intl.Collator(undefined, {
				numeric: true,
				sensitivity: "base"
			});
		}
		return this._collator;
	}

	reconcileFilters(columns) {
		let filter = this.myList.filter || {};
		for (let i = 0; i < columns.length; i++) {
			let col = columns[i];
			if(!col.fieldApi || !col.actions) {
				continue;
			}
			let fieldFilter = filter[col.fieldApi];
			if(!fieldFilter || fieldFilter.all) {
				delete filter[col.fieldApi];
				delete col.iconName;
				continue;
			}
			const isNotes = col.fieldApi === this.NOTES_FIELD;
			let kept = {};
			let anyKept = false;
			for (let j = 0; j < col.actions.length; j++) {
				let action = col.actions[j];
				if(action.name == "All" || action.label == "All") {
					continue;
				}
				let key = isNotes ? action.name : action.label;
				if(fieldFilter[key]) {
					action.checked = true;
					kept[key] = true;
					anyKept = true;
				}
			}
			if(anyKept) {
				filter[col.fieldApi] = kept;
				col.iconName = "utility:filterList";
				for (let j = 0; j < col.actions.length; j++) {
					if(col.actions[j].name == "All") {
						col.actions[j].checked = false;
					}
				}
			} else {
				delete filter[col.fieldApi];
				delete col.iconName;
			}
		}
		this.myList.filter = filter;
	}

	openSortModal() {
		this.showSortModal = true;
		requestAnimationFrame(() => {
			let modal = this.template.querySelector("c-multi-sort-modal");
			if(modal) {
				modal.setCriteria(this.myList.sortSpec || []);
			}
		});
	}

	closeSortModal() {
		this.showSortModal = false;
	}

	handleSortApply(event) {
		this.myList.sortSpec = event.detail || [];
		this.showSortModal = false;
		this.applySortIndicators();
		this.refreshFilteredSortedData(true);
	}

	handleSortClear() {
		this.myList.sortSpec = this.getDefaultSortSpec();
		this.showSortModal = false;
		this.applySortIndicators();
		this.refreshFilteredSortedData(true);
	}
}