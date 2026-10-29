import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import FIRST_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/Contact.LastName';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Contact.AccountId';
import TITLE_FIELD from '@salesforce/schema/Contact.Title';
import PERSONAL_EMAIL from '@salesforce/schema/Contact.Alternate_Email__c'; 
import PREFRRRED_FIRSTNAME from '@salesforce/schema/Contact.Preferred_First_Name__c';  
import SALUTATION_FIELD from '@salesforce/schema/Contact.Salutation'; 
import MIDDLENAME_FIELD from '@salesforce/schema/Contact.MiddleName';
import SUFFIX_FIELD from '@salesforce/schema/Contact.Suffix';   
import MAILING_CITY_FIELD from '@salesforce/schema/Contact.MailingCity';
import MAILING_COUNTRY_CODE_FIELD from '@salesforce/schema/Contact.MailingCountryCode';
import MAILING_STATE_CODE_FIELD from '@salesforce/schema/Contact.MailingStateCode';
//import CITY_STATE_NA_FIELD from '@salesforce/schema/Contact.City_State_NA__c';
import getContactInfo from "@salesforce/apex/EventMangementAuraCtrl.getSearchContactInfo";
import getCountryStateCodes from "@salesforce/apex/EventMangementAuraCtrl.getCountryStateCodes";
import getCountryPickLists from "@salesforce/apex/EventMangementAuraCtrl.getCountryPickLists";
import getStatePickLists from "@salesforce/apex/EventMangementAuraCtrl.getStatePickLists";
import saveContact from "@salesforce/apex/EventMangementAuraCtrl.saveContact";
import findDuplicates from "@salesforce/apex/EventMangementAuraCtrl.findDuplicates";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import LightningConfirm from 'lightning/confirm';

export default class contactCreation extends LightningElement {
	@api firstName;
	@api lastName;
	@api email;
	duplicateRecordFound = false;
	duplicateRecords;
	duplicateRecordIds;
	duplicateContactId;
	duplicateContactName;
	showDuplicates = false;
	showPopover = false;
	firstForm = false;
		showConfirm = false;
	accountId;
	showCreation = false;
	countryOptions = [];
	stateOptions;
	mapOfListValues = new Map();
	selectedCountryValue;
	selectedStateValue;
	organizationId;
	error;
	contactRecord = {
		Salutation : SALUTATION_FIELD,
        FirstName : FIRST_NAME_FIELD,
        LastName : LAST_NAME_FIELD,
		Preferred_First_Name__c : PREFRRRED_FIRSTNAME,
        Email : EMAIL_FIELD,
		Alternate_Email__c : PERSONAL_EMAIL,
		Suffix : SUFFIX_FIELD,
		MiddleName : MIDDLENAME_FIELD,
        AccountId : ACCOUNT_ID_FIELD,
		Title : TITLE_FIELD,
        MailingCity : MAILING_CITY_FIELD,
        MailingCountryCode : MAILING_COUNTRY_CODE_FIELD,
		MailingStateCode : MAILING_STATE_CODE_FIELD,
        //City_State_NA__c : CITY_STATE_NA_FIELD
    };

	connectedCallback() {
		this.contactRecord = {};
		this.contactRecord.FirstName =  this.firstName;
		this.contactRecord.LastName =  this.lastName;
		
	}
	 @track salutationOptions = [];
    selectedSalutation = '';

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$contactObjectInfo.data.defaultRecordTypeId', fieldApiName: SALUTATION_FIELD })
    wiredSalutationValues({ error, data }) {
        if (data) {
            this.salutationOptions = data.values;
        } else if (error) {
            console.error('Error retrieving salutation picklist values', error);
        }
    }

	@wire(getCountryPickLists, { objectType: 'Contact', selectedField: 'MailingCountryCode' })
    wiredCountryPickLists({ error, data }) {
		//console.log('#####getCountryPickLists: ' + JSON.stringify(data));
        if (data) {
			for(let key in data) {
				this.countryOptions = [...this.countryOptions, {label: data[key], value: key}];
			}
		} else if (error) {
				c//onsole.log('#####getCountryPickLists-error: ' + JSON.stringify(error));
				this.error = error;
				this.countryOptions = undefined;
		}
	}
	
	@wire(getStatePickLists, { objectName: 'Contact', controllingField: 'MailingCountryCode', dependentField: 'MailingStateCode' })
    wiredStatePickLists({ error, data }) {
		//console.log('#####getCountryPickLists: ' + JSON.stringify(data));
        if (data) {
			for(let key in data) {
				//console.log('#####key: ' + key);
				//this.countryOptions.push({label: key, value: key});
				this.countryOptions = [...this.countryOptions, {label: key, value: key}];
				if (data.hasOwnProperty(key)) {
					//console.log('#####data[key]: ' + data[key]);
					//this.mapOfListValues.push({key: key, value: data[key]});
					let states = data[key];
					const stateValues = [];
					if(states != null && states != '') {
						//console.log('#####states: ' + states);
						for ( let i in states) {
							//console.log('#####ii: ' + states[i]);
							stateValues.push({label: states[i], value: i});
						}
						this.mapOfListValues.set(key, stateValues);
					}
                }
			}	
		} else if (error) {
				console.log('#####getCountryPickLists-error: ' + JSON.stringify(error));
				this.error = error;
				this.countryOptions = undefined;
		}
	}

	handleCancel(event) {
		this.dispatchEvent(new CustomEvent('cancelation'));
	}
			
	 togglePopover() {
        this.showPopover = !this.showPopover; // Toggle the popover visibility.
    }

	handleCreate() {
		let lastNameInput = this.template.querySelector('.lastNameValidation');
		if (!lastNameInput.checkValidity()) {
			lastNameInput.reportValidity();
			return;
		} 
		saveContact({contactRecord: this.contactRecord, allowDuplicate: this.duplicateRecordFound})
		.then(result => {	
			console.log('#########result ===> ' + JSON.stringify(result));
			if(result.isDuplicateFound){
              this.duplicateRecordFound = result.isDuplicateFound;
			  this.showPopover = result.isDuplicateFound; //We use this variable to  display the duplicate popover, when there is a duplicate record found
			this.duplicateRecordIds = result.duplicateRecordIds; //this list contain the list of duplicate record id
			} else if (result.contactId != null) {
				// Clear the user enter values
				let conRec= this.contactRecord;
				conRec.Id=result.contactId;
				this.contactRecord = {};
				const selectedEvent = new CustomEvent('create', { detail: conRec });
				this.dispatchEvent(selectedEvent);
				this.dispatchEvent(new CustomEvent('cancelation'));
			} else {
				let message = result.errorMessage;
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error Creating Contact',
						message,
						variant: 'error'
					}),
				);
			}
		})
		.catch(error => {
			console.log('#######create contact error: ' + JSON.stringify(error));
			this.error = error.message;
		});
	}

	handleSuccess(event) {
		const selectedEvent = new CustomEvent('create', { detail: event.detail.id });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
	}

	handleCreation(event) {
		this.showCreation = true;
	}

	handleCreationCancel(event) {
		this.showCreation = false;
	}

	handleCreationSuccess(event) {
		this.showCreation = false;
		this.accountId = event.detail;
	}

	handleError(event) {
	    var errorCode = JSON.stringify(event.detail.output.errors[0].errorCode);
		console.log('#########contactCreation-errorCode:' + errorCode);
		if (JSON.stringify(event.detail.output.errors[0].errorCode) === '"DUPLICATES_DETECTED"') {
			console.log('#########inside duplicate errpr');
			this.duplicateRecordFound = true;
			this.firstForm = true;
		}
		getContactInfo({conId: event.detail.output.errors[0].duplicateRecordError.matchResults[0].matchRecordIds[0]}).then(data=>{
			this.duplicateContactId = data.Id;
			this.duplicateContactName = data.Name;
		  }).catch(err=>{console.log('########eventGuestCreation-handleCreationSuccess: ' + err);});
	}

	handleViewDuplicates() {
		this.showDuplicates = true;
	}

	handleShowDuplicatesCancel() {
		this.showDuplicates = false;
	}

	handleContactSelection(event) {
		const contactId = event.detail;
		console.log('###########handleContactSelection-contactId: ' + JSON.stringify(contactId));
		this.showDuplicates = false;
		const selectedEvent = new CustomEvent('create', { detail: contactId });
        this.dispatchEvent(selectedEvent);
	}

	handleCountryChange(event) {
		this.contactRecord.MailingCountryCode = event.detail.value;
		this.stateOptions = this.mapOfListValues.get(event.detail.value);
	}

	handleStatesChange(event) {
		//this.selectedStateValue =  event.detail.value;
		this.contactRecord.MailingStateCode =  event.detail.value;
	}

	handleValueSelected(event) {
        //this.contactRecord.AccountId = event.detail;
		if (event.detail instanceof Array) {
			this.contactRecord.AccountId = event.detail[0];
		}
        console.log('######Selected Organization id: ' + this.contactRecord.AccountId);
    }
     handleInputChange(event){
		this.duplicateRecordFound = false;  //we are resetting duplicate record found flag when user edit any fields on the contact creation form
        const fieldName = event.target.name;
        const value = event.target.value;
        let recordData = JSON.parse(JSON.stringify(this.contactRecord));
        recordData[fieldName] = value;
        this.contactRecord = recordData;
	 }
	handleSalutationChange(event){
		this.contactRecord.Salutation = event.target.value;
		this.selectedSalutation = event.target.value;
	}

	handleMailingCityChange(event) {
		this.contactRecord.MailingCity = event.target.value;
	}	

	get isStatesDisabled() {
		if (this.stateOptions != null && this.stateOptions.length > 0) {
			return false;
		}
		return true;
	}
}