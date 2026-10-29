import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import EVENT_STATUS_FIELD from '@salesforce/schema/Campaign.EventStatus__c';
import EVENT_TYPE_FIELD from '@salesforce/schema/Campaign.EventType__c';
import TIMEZONE_FIELD from '@salesforce/schema/Campaign.TimeZone__c';
import hasEventPermission from '@salesforce/customPermission/Events_Access_Custom_Permission';
import hasProgrammaticEventPermission from '@salesforce/customPermission/Programmatic_Events_List_Custom_Permission';
import hasGalaPermission from '@salesforce/customPermission/Events_Events_Managed_Gala_Details';
import getEvents from '@salesforce/apex/EventMangementController.getEvents';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class eventsManagement extends NavigationMixin(LightningElement) {
	pastEvents;
	upcomingEvents;
	allEvents;
	eventStatus = 'Upcoming';
	isChecked = false;
	programmaticJS = false;
	isGalaChecked = false;
	includeGalasJS = false;
	isCheckboxChecked;
	eventFilter;
	showEventDetail = false;
	showEventCreation = false;
	showDocGeneration = false;
	showEmailUpdate = false;
	selectedEventId;
	allUpcommingEvents;
	allPastEvents;
	options;
	fieldOptions = [
		//{ label: '', value: 'None' },
		{ label: 'Event Name', value: 'Name' },
		{ label: 'Event Type', value: 'EventType__c' },
		{ label: 'Event Start Date', value: 'Event_Start_Date_Time__c' },
		{ label: 'Time Zone', value: 'TimeZone__c' },
		{ label: 'Guests', value: 'TotalGuests__c' },
		{ label: 'Event Coordinator', value: 'EventCoordinator__c' },
		{ label: 'Program-Managed', value: 'Programmatic__c' },
	];
	filterOptions = [];
	containsFilter = [{ label: 'Contains', value: 'Contains' }];
	equalsFilter = [{ label: 'Equals', value: 'Equals' }];
	greaterFilter = [
		{ label: 'Greater Than', value: '>' },
		{ label: 'Less Than', value: '<' },
		{ label: 'Equals', value: '=' }
	];
	programmaticFilterOptions = [
		{ label: 'Yes', value: 'Yes' },
		{ label: 'No', value: 'No' }
	];
	isTextField = false;
	isNumberField = false;
	isPicklist = false;
	isStartDate = false;
	isLookup = false;
	ischeckbox = false;
	dataOptions = [];
	eventStatusOptions = [];
	eventTypeOptions = [];
	timezoneOptions = [];
	selectedFieldName;
	selectedFilter;
	selectedKeyValue;
	isMobileDevice = false;
	selectedProgramic = 'Event Name';
	disableToggle = false;
	disableGalaToggle = false;
	shallShowEventError = false;

	get isShowToggle() {
		return hasEventPermission || hasProgrammaticEventPermission;
	}

	get isShowGalaToggle() {
		return hasGalaPermission;
	}

	get hideEventDetail() {
		return !this.showEventDetail;
	}

	getDateTimeVal(dt) {
		if(!dt) return 0;
		try {
			return new Date(dt).getTime();
		} catch (e) {
			return 0;
		}
	}

	connectedCallback() {
		if(FORM_FACTOR === 'Small') {
			this.isMobileDevice = true;
		}
		this.filterOptions = this.containsFilter;
		this.sectionLabel = 'Upcoming Events';
		this.isTextField = true;
		this.getEvents();

	}

	handleChange(event) {
		this.eventStatus = event.target.value;
		this.sectionLabel = (this.eventStatus === '' ? 'All' : this.eventStatus) + ' Events';
		if(this.isChecked) this.programmaticJS = this.isChecked;
		this.getEvents();
	}

	handleEventSelected(event) {
		this.navigateToRecordPage(event.detail);
	}

	navigateToRecordPage(recordId) {
		// Opens the Account record modal
		// to view a particular record.
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__recordPage',
			attributes: {
				recordId: recordId,
				actionName: 'view'
			}
		}).then(url => {
			window.open(url, '_blank');
		});
	}

	handleEventGeneration() {
		this.showDocGeneration = true;
	}

	handleUpdateEmails() {
		this.showEmailUpdate = true;
	}

	handleEmailUpdateFinish() {
		this.showEmailUpdate = false;
	}

	handleDocGenerationFinish() {
		this.showDocGeneration = false;
	}

	handleNewZkipsterEvent() {
		this.showEventCreation = true;
	}

	handleCreationFinished() {
		this.showEventCreation = false;
		refreshApex(this.allEvents);
	}

	handleBack() {
		this.showEventDetail = false;
		refreshApex(this.allEvents);
	}

	handleFieldChange(event) {
		let fieldName = event.target.value;
		this.selectedFieldName = fieldName;
		this.isTextField = false;
		this.isNumberField = false;
		this.isPicklist = false;
		this.isLookup = false;
		this.ischeckbox = false;
		this.isStartDate = false;
		if(fieldName == 'Name') {
			this.filterOptions = this.containsFilter;
			this.isTextField = true;
			this.selectedFilter = 'Contains';
		} else if(fieldName == 'EventStatus__c') {
			this.filterOptions = this.equalsFilter;
			this.isPicklist = true;
			this.dataOptions = this.eventStatusOptions;
			this.selectedFilter = 'Equals';
			this.selectedKeyValue = 'Upcoming';
		} else if(fieldName == 'EventType__c') {
			this.filterOptions = this.equalsFilter;
			this.isPicklist = true;
			this.dataOptions = this.eventTypeOptions;
			this.selectedFilter = 'Equals';
		} else if(fieldName == 'Event_Start_Date_Time__c') {
			this.filterOptions = this.greaterFilter;
			this.isStartDate = true;
		} else if(fieldName == 'TimeZone__c') {
			this.filterOptions = this.equalsFilter;
			this.isPicklist = true;
			this.dataOptions = this.timezoneOptions;
			this.selectedFilter = 'Equals';
		} else if(fieldName == 'TotalGuests__c') {
			this.filterOptions = this.greaterFilter;
			this.isNumberField = true;
		} else if(fieldName == 'EventCoordinator__c') {
			this.filterOptions = this.equalsFilter;
			this.isLookup = true;
			this.selectedFilter = 'Equals';
		} else if(fieldName == 'Programmatic__c') {
			this.filterOptions = this.equalsFilter;
			this.ischeckbox = true;
			this.selectedFilter = 'Equals';
			this.dataOptions = this.programmaticFilterOptions;
		}
	}

	handleFilterChange(event) {
		let filter = event.target.value;
		this.selectedFilter = filter;
	}

	@wire(getPicklistValues, {
		recordTypeId: '012000000000000AAA',
		fieldApiName: EVENT_STATUS_FIELD
	}) wireEventStatusOptions(result) {
		if(result.data) {
			let options = [{ label: '', value: '' }];
			result.data.values.forEach((x) => {
				options.push({ label: x.label, value: x.value });
			});
			this.eventStatusOptions = options;
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '012000000000000AAA',
		fieldApiName: EVENT_TYPE_FIELD
	}) wireEventTypeOptions(result) {
		if(result.data) {
			let options = [{ label: '', value: '' }];
			result.data.values.forEach((x) => {
				options.push({ label: x.label, value: x.value });
			});
			this.eventTypeOptions = options;
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '012000000000000AAA',
		fieldApiName: TIMEZONE_FIELD
	}) wireTimezoneOptions(result) {
		if(result.data) {
			let options = [{ label: '', value: '' }];
			result.data.values.forEach((x) => {
				options.push({ label: x.label, value: x.value });
			});
			this.timezoneOptions = options;
		}
	}

	handleSearch() {
		if(this.isChecked) {
			this.programmaticJS = this.isChecked;
		}
		this.getEvents();
	}

	handleClear() {
		// Reset the state of the component to initial values
		this.eventFilter = null;
		this.selectedFieldName = null;
		this.selectedFilter = null;
		this.selectedKeyValue = null;
		this.eventStatus = 'Upcoming'; // Initial status
		this.isTextField = true;
		this.isNumberField = false;
		this.isPicklist = false;
		this.isStartDate = false;
		this.isLookup = false;
		this.ischeckbox = false;

		this.isChecked = false; // Reset the checkbox to unchecked state
		this.programmaticJS = this.isChecked;
		this.isGalaChecked = false;
		this.includeGalasJS = this.isGalaChecked;

		// Reset specific input fields based on their data-id attributes
		const fieldNameCombobox = this.template.querySelector('lightning-combobox[data-id="fieldName"]');

		// Reset the values of the specified comboboxes
		if(fieldNameCombobox) {
			fieldNameCombobox.value = '';
		}

		// Reset the specific fields in your 'lightning-layout-item'
		const textInput = this.template.querySelector('lightning-input[type="text"]');
		const numberInput = this.template.querySelector('lightning-input[type="number"]');
		const dateInput = this.template.querySelector('lightning-input[type="date"]');
		const recordPicker = this.template.querySelector('lightning-record-picker');

		// Reset their values to empty strings
		if(textInput) {
			textInput.value = '';
		}
		if(numberInput) {
			numberInput.value = '';
		}
		if(dateInput) {
			dateInput.value = '';
		}
		if(recordPicker) {
			recordPicker.value = '';
		}
		this.getEvents();
	}

	handleSearchFromMobile(event) {
		const e = event.detail;
		this.selectedFieldName = e.selectedFieldName;
		this.selectedFilter = e.selectedFilter;
		this.selectedKeyValue = e.selectedKeyValue;
		this.eventStatus = e.eventStatus;
		this.programmaticJS = e.isProgramManagedChecked;
		this.includeGalasJS = e.isGalaChecked;
		this.getEvents();
	}

	getEvents() {
		if(!hasEventPermission && hasProgrammaticEventPermission) {
			this.programmaticJS = true;
			this.isChecked = true;
			this.disableToggle = true;
		}
		if(!hasEventPermission && hasGalaPermission) {
			this.includeGalasJS = true;
			this.isGalaChecked = true;
			this.disableGalaToggle = true;
		}
		getEvents({
			fieldName: this.selectedFieldName,
			filter: this.selectedFilter,
			keyValue: this.selectedKeyValue,
			eventStatus: this.eventStatus,
			programmatic: this.programmaticJS,
			includeGalas: this.includeGalasJS
		}).then(result => {
			this.shallShowEventError = false;
			this.allEvents = result;
			if(this.allEvents) {
				let events = JSON.parse(this.allEvents);
				let dir = !this.eventStatus || this.eventStatus == 'Upcoming' || !this.eventStatus.length ? 1 : -1;
				if(this.eventStatus) {
					events = events.sort((a, b) => {
						a = this.getDateTimeVal(a.event.Start_Date_Time__c);
						b = this.getDateTimeVal(b.event.Start_Date_Time__c);
						if(!a) return 1;
						if(!b) return -1;
						return a > b ? dir : a < b ? dir * -1 : 0;
					});
				}
				events.forEach((x) => {
					if(x.event) {
						x.event.EventCoordinator = undefined;
						if(x.event.EventCoordinator__r) {
							x.event.EventCoordinator = x.event.EventCoordinator__r.Name;
						}
					}
				});
				this.events = events;
				this.allUpcommingEvents = events;
				this.upcomingEvents = events;
				if(events.length > 400) {
					this.upcomingEvents = events.slice(0, 400);
				}
			}
		}).catch(error => {
			this.shallShowEventError = true;
			console.log('### error message', JSON.stringify(error));
			this.allEvents = undefined;
		})
	}

	handleKeyValueChange(event) {
		this.selectedKeyValue = event.detail.value;
	}

	handleCheckboxChange(event) {
		this.isCheckboxChecked = event.detail.value;
		this.selectedKeyValue = this.isCheckboxChecked;
	}

	handleDataChange(event) {
		this.selectedKeyValue = event.detail.value;
	}

	handleUserSelected(event) {
		this.selectedKeyValue = event.detail.recordId;
	}

	handleToggleChange(event) {
		this.isChecked = event.target.checked;
		if(this.isChecked) {
			this.programmaticJS = this.isChecked;
			this.getEvents();
		} else {
			this.programmaticJS = this.isChecked;
			this.handleClear();
		}
	}

	handleGalaToggleChange(event) {
		this.isGalaChecked = event.target.checked;
		this.includeGalasJS = this.isGalaChecked;
		this.getEvents();
	}
}