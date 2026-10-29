import { LightningElement, track, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import EMAIL_FIELD from "@salesforce/schema/Contact.Email";
import PERSONAL_EMAIL_FIELD from "@salesforce/schema/Contact.Alternate_Email__c";
import getAssistantByContact from "@salesforce/apex/EventMangementAuraCtrl.getAssistantByContact";
import getContactInfo from "@salesforce/apex/EventMangementAuraCtrl.getSearchContactInfo";

export default class eventGuestCreation extends LightningElement {
	@api recordId;
	showCreation = false;
	contactId;
	guestOfId;
	contactEmail;
	contactName;
	contact;
	selectedContacts;

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
		return !this.contactId;
	}

	@wire(getRecord, {
		recordId: "$contactId",
		fields: [EMAIL_FIELD, PERSONAL_EMAIL_FIELD]
	}) wireContactInfo(result) {
		if(result.data) {
			let email = result.data.fields.Email.value;
			let personalEmail = result.data.fields.Alternate_Email__c.value;
			if(email) {
				this.contactEmail = email;
			} else if(personalEmail) {
				this.contactEmail = personalEmail;
			}
		}
	}

	createNewContact() {
		this.showCreation = true;
	}

	handleContactChange(event) {
		if(!event || !event.detail || !event.detail.length) {
			this.contactId = null;
			this.contactEmail = null;
		} else {
			this.contactId = event.detail[0].Id;
		}
	}

	handleGuestOfChange(event){
		if(!event || !event.detail || !event.detail.length) {
			this.guestOfId = null;
		} else {
			this.guestOfId = event.detail[0].Id;
		}
	}

	handleCreationSuccess(event) {
		this.showCreation = false;
		this.contactId = event.detail.Id ? event.detail.Id : event.detail;
		let self = this;
		getContactInfo({
			conId: this.contactId
		}).then(c => {
			let temp = [];
			temp.push(c);
			self.selectedContacts = JSON.parse(JSON.stringify(temp));
		}).catch(err => {
			console.log('Error - ' + JSON.stringify(err));
		});
	}

	handleCreationCancel() {
		this.showCreation = false;
	}

	handleSelectionChange(event) {
		this.rsvpValue = event.detail?.RSVP;
		this.attendanceValue = event.detail?.Attendance;
	}

	handleSubmit(event) {
		event.preventDefault();
		let fields = event.detail.fields;
		fields.ContactId = this.contactId;
		fields.GuestOf__c = this.guestOfId;
		fields.RSVPStatus__c = this.rsvpValue;
		fields.AttendedStatus__c = this.attendanceValue;
		if(!this.contactId || !this.contactId.length) {
			return this.template
				   .querySelector("lightning-record-edit-form")
				   .submit(fields);
		}
		let conList = [];
		conList.push(this.contactId);
		getAssistantByContact({ 
			contactIds: conList 
		}).then((result) => {
			console.log(result);
			let assistantId =
			result &&
			result[this.contactId] &&
			result[this.contactId].Related_Contact__c;
			if(assistantId) {
				fields.Assistant__c = assistantId;
			}
			let assistantEmail =
			result &&
			result[this.contactId] &&
			result[this.contactId].Related_Contact__r &&
			result[this.contactId].Related_Contact__r.Email;
			if(assistantEmail) {
				fields.AssistantEmail__c = assistantEmail;
			}
			this.template.querySelector("lightning-record-edit-form").submit(fields);
		}).catch((error) => {
			console.log("Error - " + JSON.stringify(error));
		});
	}

	handleRecommendedBy(event) {
		this.contactName = event.detail[0].Name;
	}

	handleCancel() {
		this.dispatchEvent(new CustomEvent("cancel"));
	}

	handleSuccess(event) {
		const selectedEvent = new CustomEvent("save", { detail: event.detail.id });
		this.dispatchEvent(selectedEvent);
	}
}