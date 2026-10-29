import { LightningElement, api, track, wire } from 'lwc';
import createOrg from '@salesforce/apex/DITCmpController.createOrg';
import createContact from '@salesforce/apex/DITCmpController.createContact';
import getPickLists from "@salesforce/apex/DITLookupController.getPickLists";
//import PGONECODE from '@salesforce/schema/Contact.Assistant_Business_Phone_Country_Code__c';
const columns = [
	{ label: 'Name', fieldName: 'mainField' },
	{ label: 'AKA', fieldName: 'AKA' },
	{ label: 'Legal Name', fieldName: 'Legal_Name' },
	{ label: 'Website', fieldName: 'Website' }
];
export default class CreateNewLookup extends LightningElement {
	@track columns = columns;
	@api objectApiName = 'Account';
	@api fields = ['Name'];
	@api duplicaterec;
	@api loaderId;
	_duplicaterec=[]
	staffTitle = 'Staff'
	isduplicate = false;
	get title() {
		return this.duplidateDone ? 'Potential Duplicate Records' : (this.objectApiName == 'Account') ? 'Create Organization' : 'Create New Contact (Staff)';
	};
	@api name;
	@api dlRecordId;
	email
	disableCreateBtn = false;

	isExitingUse = true;
	selectedRows;
	isaccount;
	firstname;
	lastname;
	email;
	satffTitle;
	assistantPhoneCode;
	assistantPhone;
	phoneCodeValues = [];
	get disablebtn(){
		return this.disableCreateBtn;
	}

	@wire(getPickLists, { objectType: 'Contact', selectedField: 'Assistant_Business_Phone_Country_Code__c' })
	wiredCountryPickLists({ error, data }) {
		//console.log('#####getCountryPickLists: ' + JSON.stringify(data));
		if (data) {
			let phoneCodeValues = [];
			for (let key in data) {
				phoneCodeValues.push({ label: data[key], value: key });
			}
			this.phoneCodeValues = phoneCodeValues;
		} else if (error) {
			c//onsole.log('#####getCountryPickLists-error: ' + JSON.stringify(error));
			this.error = error;
			this.phoneCodeValues = [];
		}
	}



	get duplidateDone() {
		this.isduplicate = this._duplicaterec && this._duplicaterec.length > 0;
		return this.isduplicate;
	}
	connectedCallback() {
		this._duplicaterec = this.duplicaterec;
		if (this.objectApiName == 'Account') {
			this.isaccount = true;
			//this.firstname = this.name.substring(0, this.name.indexOf(" "));
			//	this.lastname = this.name.substring(this.name.indexOf(" "));
		}
		if (this.objectApiName == 'Contact' && this.Name) {
			this.isaccount = false;
			this.firstname = this.name.substring(0, this.name.indexOf(" "));
			this.lastname = this.name.substring(this.name.indexOf(" "));
		}
	}
	accountId;
	handleSuccess(event) {
		console.log(event.detail.id);
	}


	handleCancel(event) {
		this.dispatchEvent(new CustomEvent('cancelation'));
	}
	handleNameChange(event) {
		this.name = event.target.value;
	}
	handleInputChnage(event) {
		this[event.target.name] = event.target.value;
	}
	handleInsertRec(event) {
		this.disableCreateBtn = true;
		const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
			.reduce((validSoFar, inputField) => {
				inputField.reportValidity();
				return validSoFar && inputField.checkValidity();
			}, true);
		if (isInputsCorrect) {
			if (this.objectApiName == 'Account') {
				createOrg({
					orgName: this.name,
					dataLoaderId: this.loaderId
				}).then(result => {
					this.dispatchEvent(new CustomEvent('success', { detail: result.Id }));
				}).catch(error => {
					//this.errorMsg = error;
				})
			}
			if (this.objectApiName == 'Contact') {
				createContact({
					title: this.staffTitle, firstName: this.firstname, lastName: this.lastname, myEmail: this.email, assistantPhone: this.assistantPhone, assistantPhoneCode: this.assistantPhoneCode
				}).then(result => {
					this.dispatchEvent(new CustomEvent('success', { detail: result.Id }));
				}).catch(error => {
					//this.errorMsg = error;
				})
			}
		}
	}

	handleCreateNewRec(event) {
		this._duplicaterec =[];
		this.isduplicate = false;
	}
	handleAccountSuccess(event) {
		this.dispatchEvent(new CustomEvent('success', { detail: event.detail.id }));
	}
	handleExistingRecord(event) {
		this.dispatchEvent(new CustomEvent('success', { detail: this.selectedRows }));
	}
	onRowSelection(event) {
		this.selectedRows = this.template.querySelector("lightning-datatable").selectedRows[0];
		this.isExitingUse = false;
	}
}