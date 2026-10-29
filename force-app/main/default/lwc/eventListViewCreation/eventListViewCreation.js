import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import updateListView from "@salesforce/apex/ListEditCmpController.updateListView";
import Name from '@salesforce/schema/User.Name';
import hasRequiredPermission from '@salesforce/apex/UtilityClass.hasRequiredPermission';

export default class EventListViewCreation extends LightningElement {
    @api listrecordId;
    columnsField;
    setFalse;
    _selectedOptions = [];
    listViewName;
    hasPrivatePermission = false;
    privateField = { label: 'Private', value: 'Contact_Private__c' };

    allOptions = [
        { "label": "First Name", "value": "UB_FirstName__c" },
        { "label": "Last Name", "value": "UB_LastName__c" },
        { "label": "RSVP", "value": "RSVPStatus__c" },
        { "label": "RSVP/Event Notes", "value": "RSVPNotes__c" },
        { "label": "RSVP/Event Note Complete", "value": "RSVP_Event_Note_Complete__c" },
        { "label": "Party Size", "value": "PartySize__c" },
        { "label": "Dietary", "value": "Dietary__c" },
        { "label": "Attendance", "value": "AttendedStatus__c" },
        { "label": "Table", "value": "Table__c" },
        { "label": "Seat", "value": "Seat__c" },
        { "label": "Email Preview", "value": "EventEmailBody__c" },
        { "label": "Last Email Status", "value": "Last_Email_Status__c" },
        { "label": "Last Email Sent Errors", "value": "Last_Email_Sent_Errors__c" },
        { "label": "Invitation Sent", "value": "Invitation_Sent__c" },
        { "label": "Source", "value": "Source__c" },
        { "label": "Notes", "value": "UB_Notes__c" },
        { "label": "Guest Of", "value": "GuestOf__c" },
        { "label": "Event Tier", "value": "EventTier__c" },
        { "label": "Full Name", "value": "Full_Name__c" },
        { "label": "Title", "value": "Contact_Title__c" },
        { "label": "Organization / Company", "value": "Organization_Company__c" },
        { "label": "Guest Email", "value": "Guest_Email__c" },
        { "label": "Guest Email Type", "value": "Guest_Email_Type__c" },
        { "label": "Latest Email Subject", "value": "Latest_Email_Subject__c" },
        { "label": "Business Phone", "value": "Business_Phone__c" },
        { "label": "Mobile Phone", "value": "Mobile_Phone__c" },
        { "label": "CC Assistant", "value": "CC_Assistant__c" },
        { "label": "CC Addresses", "value": "CC_Addresses__c" },
        { "label": "BCC Addresses", "value": "BCC_Addresses__c" },
        { "label": "Assistant Name", "value": "AssistantName__c" },
        { "label": "Assistant Business Email", "value": "Assistant_Email__c" },
        { "label": "Assistant Business Phone", "value": "Assistant_Business_Phone__c" },
        { "label": "Significant Other", "value": "Spouse_Link__c" },
        { "label": "Significant Other Invited?", "value": "SpouseInvited__c" },
        { "label": "Title, Significant Other", "value": "Significant_Other_Title__c" },
        { "label": "RSVP Last Modified Date", "value": "RSVPUpdateDate__c" },
        { "label": "Last Modified Date", "value": "LastModifiedDate" },
        { "label": "Event From Email", "value": "Event_From_Email__c" },
        { "label": "Save the Date Last Modified", "value": "Save_the_Date_Last_Modified__c" },
        { "label": "Invitation Last Modified", "value": "Invitation_Last_Modified__c" },
        { "label": "Reminder Last Modified", "value": "Reminder_Last_Modified__c" },
        { "label": "Email Last Modified", "value": "Email_Last_Modified__c" }
    ];

    @api
    get selectedOptions() {
        return this._selectedOptions;
    }
    set selectedOptions(value) {
        this._selectedOptions = value;
    }

    @wire(getRecord, { recordId: Id, fields: [Name] })
    userDetails({ error, data }) {
        if(error) {
            this.error = error;
        } else if(data) {
            if(data.fields.Name.value != null) {
                this.listViewName = data.fields.Name.value + ' View';
            }
        }
    }

    @wire(hasRequiredPermission, {
        permissionSet: 'Private_Name_Fields'
    }) hasRequiredPermission({ error, data }) {
        if(error) {
            this.hasPrivatePermission = false;
            return;
        }
        this.hasPrivatePermission = !!data;
        if (this.hasPrivatePermission && !this.allOptions.some(o => o.value === this.privateField.value)) {
            const options = [...this.allOptions];
            const partySizeIndex = options.findIndex(o => o.value === 'PartySize__c');
            if(partySizeIndex !== -1) {
                options.splice(partySizeIndex + 1, 0, this.privateField);
            } else {
                options.push(this.privateField);
            }
            this.allOptions = options;
        }
        if(!this.hasPrivatePermission && this._selectedOptions?.includes(this.privateField.value)) {
            this._selectedOptions = this._selectedOptions.filter(v => v !== this.privateField.value);
            this.columnsField = this._selectedOptions.join(',');
        }
        if(!this.listrecordId) {
            const selected = this.allOptions.map(o => o.value);
            this._selectedOptions = selected;
            this.columnsField = selected.join(',');
        }
    }

    connectedCallback() {
        if(this.selectedOptions && this.selectedOptions.length > 0) {
            this.columnsField = this.selectedOptions.join(',');
        }
        if (!this.listrecordId) {
            let selectedOptions = [];
            for (let op of this.allOptions) {
                selectedOptions.push(op.value);
    }
            this._selectedOptions = selectedOptions;
            this.columnsField = selectedOptions.join(',');
        }
    }
    
    resetListView() {
        let selectedOptions = [];
        for(let op of this.allOptions) {
            selectedOptions.push(op.value);
        }
        this._selectedOptions = selectedOptions;
        this.columnsField = selectedOptions.join(',');
        updateListView({
            viewId: this.listrecordId,
            selectedOptions: selectedOptions.join(',')
        }).then(() => {
            const selectedEvent = new CustomEvent("save", {
                detail: {
                    Id: this.listrecordId,
                    selectedOptions: this._selectedOptions
                }
            });
            this.dispatchEvent(selectedEvent);
        }).catch((error) => {
            console.log(error.body.message);
        });
    }

    handleChangeDual(event) {
        this._selectedOptions = event.detail.value;
        this.columnsField = this._selectedOptions.join(',');
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent("cancel"));
    }

    handleSuccess(event) {
        const selectedEvent = new CustomEvent("save", {
            detail: {
                Id: event.detail.id,
                selectedOptions: this._selectedOptions
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    handleSubmit(event) {
        event.preventDefault();
        let fields = event.detail.fields;
        fields["Name"] = this.listViewName;
        fields["Column__c"] = this._selectedOptions.join(',');
        fields["View__c"] = 'Desktop';
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
}