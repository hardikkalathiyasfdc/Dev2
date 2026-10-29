import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDNCContacts from '@salesforce/apex/ExportContactsController.getDNCContacts';
import hasRestrictedAccess from '@salesforce/customPermission/Private_Name_Fields';
import getMissingEmailContacts from '@salesforce/apex/ExportContactsController.getMissingEmailContacts';
import NUMBER_OF_DO_NOT_CONTACT_FIELD from '@salesforce/schema/Campaign.Do_Not_Contact__c';

const EXPORT_TYPES = {
    DNC: 'DNC',
    MISSING_EMAIL: 'MISSING_EMAIL'
};

const EXPORT_CONFIG = {
    DNC: {
        title: 'Do Not Contact Report',
        fileName: 'Do Not Contact Report.csv',
        reportLabel: 'Do Not Contact Report',
        selectedColumns: [
            'firstOrPreferredFirstName',
            'lastName',
            'significantOther',
            'title',
            'organization',
            'ContactAlertReason',
            'id',
            'listMemberId'
        ],
        columnHeaders: [
            'First/Preferred First Name',
            'Last Name',
            'Significant Other',
            'Title',
            'Organization',
            'Contact Alert Reason',
            'Contact ID',
            'List Member ID'
        ]
    },
    MISSING_EMAIL: {
        title: 'Contacts Missing Priority Email',
        fileName: 'Contacts Missing Priority Email.csv',
        reportLabel: 'Contacts Missing Priority Email Report',
        selectedColumns: [
            'firstOrPreferredFirstName',
            'lastName',
            'title',
            'organization',
            'businessEmail',
            'personalEmail',
            'additionalEmail',
            'priorityEmail',
            'id',
            'listMemberId'
        ],
        columnHeaders: [
            'First/Preferred First Name',
            'Last Name',
            'Title',
            'Organization',
            'Business Email',
            'Personal Email',
            'Additional Email',
            'Priority Email',
            'Contact ID',
            'List Member ID'
        ]
    }
};

export default class ExportCSVFromLWC extends LightningElement {
    @api recordId;
    @api exportType = EXPORT_TYPES.DNC;
    contacts = [];
    isLoading = false;
    errorMessage;
    hasLoaded = false;
    doNotContactCount;
    doNotContactCountLoaded = false;

    @wire(CurrentPageReference)
    handlePageReference(pageRef) {
        if(!pageRef || !pageRef.state) return;
        if(pageRef.state.c__recordId) {
            this.recordId = pageRef.state.c__recordId;
        }
        if(pageRef.state.c__exportType) {
            this.exportType = pageRef.state.c__exportType;
        }
        this.loadContacts();
    }

    @wire(getRecord, {recordId: '$recordId', fields: [NUMBER_OF_DO_NOT_CONTACT_FIELD]})
    wiredList({data, error}) {
        if(data){
            console.log('###########wiredList-data: ' + JSON.stringify(data));
            this.doNotContactCount = data.fields?.Do_Not_Contact__c?.value;
            console.log('###########wiredList-doNotContactCount: ' + this.doNotContactCount);
            this.doNotContactCountLoaded = true;
        } else if(error){
            console.error('Error fetching member count', error);
        }
    }

    connectedCallback() {
        this.loadContacts();
    }

    disconnectedCallback() {
        this.resetLoadState();
    }

    get normalizedExportType() {
        const value = this.exportType ? this.exportType.toUpperCase() : EXPORT_TYPES.DNC;
        if(value === EXPORT_TYPES.MISSING_EMAIL) return EXPORT_TYPES.MISSING_EMAIL;
        return EXPORT_TYPES.DNC;
    }

    get config() {
        return EXPORT_CONFIG[this.normalizedExportType];
    }

    get title() {
        return this.config.title;
    }

    get hasContacts() {
        return this.contacts && this.contacts.length > 0;
    }

    async loadContacts() {
        if(!this.recordId || this.hasLoaded) return;
        this.hasLoaded = true;
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            const apexMethod =
                this.normalizedExportType === EXPORT_TYPES.MISSING_EMAIL
                    ? getMissingEmailContacts
                    : getDNCContacts;
            const result = await apexMethod({
                recordId: this.recordId
            });
            console.log('Contacts fetched:', result);
            this.contacts = result || [];
            /*if(this.contacts.length === 0) {
                this.showToast(
                    'No Contacts Found',
                    'No Contacts were found for this Campaign.',
                    'info'
                );
                this.goBack();
                return;
            }
            this.exportToCSV();*/
            if(this.doNotContactCountLoaded) {
                let restrictedContactCount =
                    this.contacts.length > 0
                        ? this.contacts.filter(contact => contact.contact && contact.contact.Restricted__c === true).length
                        : 0;
                console.log('###########hasRestrictedAccess: ' + hasRestrictedAccess);
                if(!hasRestrictedAccess) {
                    restrictedContactCount = Math.max(this.doNotContactCount - (this.contacts ? this.contacts.length : 0), 0);
                }
                console.log('###########restrictedContactCount: ' + restrictedContactCount);
                if (restrictedContactCount > 0) {
                    this.confirmCSVExport(restrictedContactCount);
                } else {
                    this.exportToCSV();
                }
            }
        } catch (error) {
            this.errorMessage = this.normalizeError(error);
            this.showToast('Export Failed', this.errorMessage, 'error');
            this.isLoading = false;
        }
    }

    exportToCSV() {
        const jsonRecordsData = this.contacts || [];
        const csvSeparator = ',';
        const newLineCharacter = '\n';
        let csvIterativeData = '';
        csvIterativeData += this.config.reportLabel || this.title;
        csvIterativeData += newLineCharacter;
        csvIterativeData += newLineCharacter;
        csvIterativeData += this.config.columnHeaders.map((header) => this.csvEscape(header)).join(csvSeparator);
        csvIterativeData += newLineCharacter;
        for (let i = 0; i < jsonRecordsData.length; i++) {
            const row = jsonRecordsData[i];
            const rowValues = this.config.selectedColumns.map((dataKey) => {
                return this.csvEscape(row[dataKey]);
            });
            csvIterativeData += rowValues.join(csvSeparator);
            csvIterativeData += newLineCharacter;
        }
        const csvContent = '\uFEFF' + csvIterativeData;
        const blob = new Blob([csvContent], {
            type: 'application/octet-stream'
        });
        const downloadElement = document.createElement('a');
        const url = URL.createObjectURL(blob);
        downloadElement.href = url;
        downloadElement.download = this.config.fileName || 'Custom Export.csv';
        downloadElement.style.display = 'none';
        document.body.appendChild(downloadElement);
        downloadElement.click();
        document.body.removeChild(downloadElement);
        URL.revokeObjectURL(url);
        this.isLoading = false;
        window.setTimeout(() => {
            this.resetLoadState();
            this.goBack();
        }, 500);
    }

    csvEscape(value) {
        if(value === null || value === undefined) return '""';
        const stringValue = String(value);
        const escapedValue = stringValue.replace(/"/g, '""');
        return `"${escapedValue}"`;
    }

    goBack() {
        window.history.back();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    normalizeError(error) {
        if(Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if(typeof error?.body?.message === 'string') {
            return error.body.message;
        }
        if(typeof error?.message === 'string') {
            return error.message;
        }
        return 'Unknown error while exporting Contacts.';
    }

    async confirmCSVExport(restrictedCount) {
        let warningMessage = 'Your results contain ' + restrictedCount + ' Private Contact(s).';
        if (!hasRestrictedAccess && restrictedCount > 0) {
				warningMessage = 'You\'ve encountered a problem with some of the records you selected (' +
					restrictedCount + ' record(s) are not exporting). ' +
					'Please contact brmpartnerships@bloomberg.org for further assistance.';
		}
        const confirmed = await LightningConfirm.open({
            message: warningMessage,
            label: 'Warning!',
            variant: 'warning',
            theme: 'warning'
        });
        if (confirmed) {
            this.exportToCSV();
        } else {
            this.resetLoadState();
            this.goBack();
        }
    }

    resetLoadState() {
        this.isLoading = false;
        this.hasLoaded = false;
        this.doNotContactCountLoaded = false;
    }
}