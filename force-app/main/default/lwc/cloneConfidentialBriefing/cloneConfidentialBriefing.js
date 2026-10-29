import { LightningElement, api, track, wire } from 'lwc';
import getFilteredRecords from '@salesforce/apex/CloneConfidentialBriefingController.getFilteredRecords';
import getOrgDetails from '@salesforce/apex/CloneConfidentialBriefingController.getOrgDetails';
import getInteractions from '@salesforce/apex/CloneConfidentialBriefingController.getInteractions';
import cloneConfidentialBriefing from '@salesforce/apex/CloneConfidentialBriefingController.cloneConfidentialBriefing';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';

// Define fields to retrieve
const FIELDS = ['Account.Name'];

export default class CloneConfidentialBriefing extends LightningElement {
    @api recordId;
    @track selectedType = '';
    @track recordOptions = [];
    @track objectApiName = '';
    selectedContactIds = [];
    @track isDataLoaded = false; // Controls component visibility
    contactId;
    accountName;
    accountId;
    defaultRecordId = null;
    selectedRecordName;
    showSaveButton = false;
    @track showSpinner = true;
    get disabledSaveButton() {
        return !this.showSaveButton
    }

    get isContactSelected() {
        return this.objectApiName == 'Contact';
    }

    // Define options for main combobox
    typeOptions = [
        { label: 'Contact', value: 'Contact' },
        { label: 'Organization', value: 'Organization' },
        { label: 'Interaction', value: 'Interaction' },
        { label: 'List/Event', value: 'ListEvent' }
    ];

    // Flags to control rendering
    get isRecordPicker() {
        return this.selectedType === 'Organization' || this.selectedType === 'Contact';
    }

    get isComboBox() {
        return this.selectedType === 'ListEvent' || this.selectedType === 'Interaction';
    }


    // Wire the Apex method to fetch Organization details based on the Contact ID
    @wire(getOrgDetails, { recordId: '$recordId' })
    orgDetails({ data, error }) {
        if (data) {
            // Assign the fetched data to component properties
            this.contactId = data.contactId;
            this.accountName = data.accountName;
            this.accountId = data.accountId;
            this.showSpinner = false;
            // Check if contactId is valid
            if (this.contactId !== null && this.contactId !== undefined) {
                this.isDataLoaded = true;  // Show component if valid
            } else {
                this.isDataLoaded = false; // Hide component if invalid
                this.showToast('Error', 'Unable to clone Briefings from this location.', 'error');
                this.closeAction();
            }
        } else if (error) {
            console.error('Error fetching Organization details:', error);
        }
    }
    // Filter to exclude accounts with Name equal to '-'
    recordFilters = [
        {
            fieldName: 'Name',
            operator: '!=',
            value: '-'
        }
    ];

    // Handle type change
    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.showSaveButton = false;
        this.defaultRecordId = null;
        this.selectedContactIds = [];
        if (this.template.querySelector('lightning-record-picker'))
            this.template.querySelector('lightning-record-picker').clearSelection();
        // Set the object API name dynamically for record picker
        if (this.selectedType === 'Organization') {
            this.objectApiName = 'Account'; // Replace with actual object
            this.defaultRecordId = (this.accountId && this.accountName !== '-') ? this.accountId : '';
            this.selectedRecordId = this.defaultRecordId;
            this.showSaveButton = true;

        } else if (this.selectedType === 'Contact') {
            this.template.querySelector('c-contact-search')?.clearSelection();
            this.objectApiName = 'Contact';
        }
        else if (this.selectedType === 'Interaction') {
            this.objectApiName = 'Interaction__c'; // Replace with actual custom object
            this.fetchInteractionRecords();

        } else if (this.selectedType === 'ListEvent') {
            this.objectApiName = 'Campaign';
            this.fetchFilteredRecords(); // Fetch records for combobox
        }
    }

    // Fetch records for the combobox
    fetchFilteredRecords() {
        getFilteredRecords({ contactId: this.contactId }) // Change to your object API name
            .then((data) => {
                this.recordOptions = [];
                this.recordOptions = data.map(record => ({
                    label: this.formatDateToDDMMYYYY(record.Campaign.Start_Date_Time__c?.substring(0, 10).trim()) + ' - ' + record.Campaign.Name,
                    value: record.CampaignId
                }));
            })
            .catch((error) => {
                console.error('Error fetching records:', error);
            });
    }

    //fetch Records FOr Interaction
    fetchInteractionRecords() {
        getInteractions({ contactId: this.contactId })
            .then((result) => {
                this.recordOptions = [];
                this.recordOptions = result.map(record => ({
                    label: this.formatDateToDDMMYYYY(record.Interaction_Date__c ?? '') + ' - ' + (record.Background__c ? record.Background__c : record.Name),
                    value: record.Id
                }))
            })
            .catch((error) => {
                console.error('Error fetching Interaction records:', error);
            })
    }
    // Helper function to format date from "yyyy-mm-dd" to "dd-mm-yyyy"
    formatDateToDDMMYYYY(dateString) {
        if (!dateString) return '';  // Handle cases where date might be null/undefined
        let [year, month, day] = dateString.split('-');
        return `${month}-${day}-${year}`;
    }

    handleContactUpdate(event) {
        let selectedContacts = JSON.parse(JSON.stringify(event.detail));
        if (selectedContacts && selectedContacts.length > 0) {
            this.selectedContactIds = selectedContacts.map(record => record.Id);
            this.showSaveButton = true;
        } else {
            this.showSaveButton = false;
        }

    }

    // Handle record selection
    handleRecordSelect(event) {

        // Check if the event is from lightning-record-picker or lightning-combobox
        if (event.detail.recordId) {
            // lightning-record-picker case
            this.selectedRecordId = event.detail.recordId;
            this.showSaveButton = true;
        } else if (event.detail.value) {
            // lightning-combobox case
            this.selectedRecordId = event.detail.value;
            this.showSaveButton = true;
        } else {
            this.showSaveButton = false;
        }

        console.log('Selected Record ID:', this.selectedRecordId);
        // Additional logic here
    }

    // Watch for changes in selectedRecordId
    @wire(getRecord, { recordId: '$selectedRecordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.selectedRecordName = data.fields.Name.value;
            // Validate the record name
            if (this.selectedRecordName === '-') {
                this.showToast('Invalid Selection', 'This record cannot be selected.', 'error');
                this.showSaveButton = false;
            }
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    // Method to close the LWC action modal
    closeAction() {
        // Dispatch the CloseActionScreenEvent to close the action screen
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    // Utility method to show toast messages
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
    handleClone() {
        this.showSpinner = true;
        let selectedIds = [];
        if (this.objectApiName == "Contact") {
            selectedIds = this.selectedContactIds;
        }
        else {
            selectedIds = [this.selectedRecordId];
        }
        cloneConfidentialBriefing({ objectApiName: this.objectApiName, recordId: this.recordId, selectedIds: selectedIds })
            .then(result => {
                this.showSpinner = false;
                this.showToast('Success!', 'Record cloned successfully!', 'success');
                // Close the action screen after the update
                this.closeAction();
            })
            .catch(error => {
                this.showSpinner = false;
                this.showToast('Error', error.body.message, 'error');
            })


    }
}