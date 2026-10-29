import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import getAvailableColumns from "@salesforce/apex/ExportContactsController.getAvailableColumns";
import getContacts from "@salesforce/apex/ExportContactsController.getContactsFromList";
import getMemeberList from "@salesforce/apex/ExportContactsController.getMemeberList";
import getRestrictedContactCount from "@salesforce/apex/ExportContactsController.getRestrictedContactCount";
import LightningConfirm from 'lightning/confirm';
import SIGNIFICANT_OTHER_FIELD from '@salesforce/schema/Contact.Annual_Report_Salutation__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import hasRestrictedAccess from '@salesforce/customPermission/Private_Name_Fields';
const FIELDS = [
    'Campaign.Name', 'Campaign.RecordType.DeveloperName'
];

export default class ExportContactsFromList extends NavigationMixin(LightningElement) {
    @api contacts;
    @api recordId;
    typeSelection = true;
    listAddScreen = false;
    showListLookup = false;
    showListText = false;
    targetList = '';
    typeOfExport = '';
    isLoading = false;
    newList = false;
    columnSelection = false;
    allColumns = [];
    contactColumns = [];
    listMemberColumns = [];
    members;

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Error fetching object info', error);
        }
    }

    get isRestricted() {
        return hasRestrictedAccess;
    }

    checkFieldAccess(fieldApiName) {
        if (!this.objectInfo || !this.objectInfo.fields) {
            return false;
        }

        const fieldMeta = this.objectInfo.fields[fieldApiName];
        if (!fieldMeta) {
            return false;
        }
        return fieldMeta?.updateable === true;
    }


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    list;

    columnHeaders = ['First/Preferred First Name', 'Last/Preferred Last Name', 'Significant Other Name (Preferred)', 'Title', 'Organization', 'Priority Email', 'F&F Tags', 'Other Tags', 'Contact ID', 'List Member ID'];
    selectedColumns = ["firstOrPreferredFirstName", "lastOrPreferredLastName", "SignificantOtherPreferredFirstName", "Title", "organization", "Priority_Email__c", "ffTags", "otherTags", "Id", "listMemberId"];

    preSelectedColumns = [
        { label: 'Significant Other', value: 'significantOther' },
        { label: 'Significant Other Salutation', value: 'SignificantSalutation' },
        { label: 'Correspondence Significant Other Annual Report Salutation', value: 'SignificantARSalutation' },
        { label: 'First/Preferred First Name', value: 'firstOrPreferredFirstName' },
        { label: 'Last/Preferred Last Name', value: 'lastOrPreferredLastName' },
        { label: 'Significant Other Name (Preferred)', value: 'SignificantOtherPreferredFirstName' },
        { label: 'Title', value: 'Title' },
        { label: 'Organization', value: 'organization' },
        { label: 'Priority Email', value: 'Priority_Email__c' },
        { label: 'F&F Tags', value: 'ffTags' },
        { label: 'Other Tags', value: 'otherTags' },
        { label: 'Contact ID', value: 'Id' },
        { label: 'List Member ID', value: 'listMemberId' }
    ];

    get options() {
        return [
            { label: 'Standard', value: 'Standard' },
            { label: 'Executive', value: 'Executive' }
        ];
    }

    handleChange(event) {
        this.typeOfExport = event.detail.value;
        this.typeSelection = false;
        this.columnSelection = true;
        this.setAvailableOptions(this.list.data.fields.RecordType.value.fields.DeveloperName.value);
    }

    handleColumnSelection(event) {
        this.selectedColumns = event.detail.value;
        let headers = [];
        for (let i = 0; i < this.selectedColumns.length; i++) {
            let header = this.allColumns.find(o => o.value === this.selectedColumns[i]);
            if (header.value == 'Significant_Other_Title__c') {
                headers.push('' + header.label + '');
            } else {
                headers.push(header.label);
            }
        }
        this.columnHeaders = headers;
    }

    handleFinish() {
        if (this.typeOfExport !== '') this.getMembers();
    }

    getContacts() {
        getContacts({
            "listId": this.recordId,
            "typeOfExport": this.typeOfExport
        }).then((result) => {
            if (result.error) {
                console.log('error ::::: ' + JSON.stringify(result.error));
            } else {
                this.contacts = result;
                this.selectedTags = this.contacts[0].selectedTags;
                this.exportToCSV();
            }
        }).catch((error) => {
            console.log(JSON.stringify(error.body));
        });
    }

    exportToCSV() {
        var jsonRecordsData = this.contacts;
        let csvIterativeData;
        let csvSeperator
        let newLineCharacter;
        csvSeperator = ", ";
        newLineCharacter = "\n";
        csvIterativeData = '"' + this.list.data.fields.Name.value + '"';
        csvIterativeData += newLineCharacter;
        csvIterativeData += newLineCharacter;
        csvIterativeData += this.columnHeaders.map(h => '"' + h.replace(/"/g, '""') + '"').join(csvSeperator);
        csvIterativeData += newLineCharacter;
        for (let i = 0; i < jsonRecordsData.length; i++) {
            let counter = 0;
            for (let iteratorObj in this.selectedColumns) {
                let dataKey = this.selectedColumns[iteratorObj];
                if (counter > 0) { csvIterativeData += csvSeperator; }
                if (jsonRecordsData[i][dataKey] !== null && jsonRecordsData[i][dataKey] !== undefined) {
                    if (jsonRecordsData[i][dataKey].includes('"')) {
                        csvIterativeData += '"' + jsonRecordsData[i][dataKey].replace(/"/g, '""') + '"';
                    } else {
                        csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';
                    }
                } else {
                    csvIterativeData += '""';
                }
                counter++;
            }
            csvIterativeData += newLineCharacter;
        }
        this.hrefdata = "data:text/csv;charset=utf-8,%EF%BB%BF" + encodeURIComponent(csvIterativeData);
        let downloadElement = document.createElement('a');
        downloadElement.href = this.hrefdata;
        downloadElement.target = '_blank';
        downloadElement.download = 'Custom Export.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
        this.navigateToRecord();
        this.isLoading = false;
    }

    showToast(message) {
        const event = new ShowToastEvent({
            title: 'Get Help',
            variant: 'error',
            message: message,
        });
        this.dispatchEvent(event);
    }

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Campaign',
                actionName: 'view'
            }
        });
    }

    setAvailableOptions(fieldSetName) {
        getAvailableColumns({
            "recordTypeName": fieldSetName
        }).then((result) => {
            if (result.error) {
                console.log('Error while retrieveing available options.');
            } else {
                let options = [];

                // --- Contact options ---
                const contactOptions = result.contactFields.map(el => {
                    let label = el.fieldLabel;
                    if (el.fieldValue === 'AssistantName') label = 'Staff Name';
                    this.contactColumns.push(el.fieldValue);

                    return { label, value: el.fieldValue };
                });

                // --- List member options ---
                const listMemberOptions = result.listMemberFields.map(el => {
                    this.listMemberColumns.push(el.fieldValue);
                    return { label: el.fieldLabel, value: el.fieldValue };
                });

                // --- Combine everything ---
                options = [
                    ...contactOptions,
                    ...this.preSelectedColumns,
                    ...listMemberOptions
                ];

                // --- Map UI values to real field API names for access check ---
                const fieldAccessMap = {
                    "SignificantARSalutation": SIGNIFICANT_OTHER_FIELD.fieldApiName,
                    "AssistantName": "Significant_Other__c",
                    "Significant_Other__c": SIGNIFICANT_OTHER_FIELD.fieldApiName
                    // extend as needed
                };

                // --- Final filter based on access ---
                this.allColumns = options.filter(opt => {
                    const fieldApi = fieldAccessMap[opt.value] || opt.value;
                    return !fieldAccessMap[opt.value] || this.checkFieldAccess(fieldApi);
                });

            }
        }).catch((error) => {
            console.log(JSON.stringify(error.body));
        });
    }
    async getMembers() {
        // Count restricted contacts via a sharing-agnostic Apex call so the warning fires
        // even for users who cannot see the restricted contact records.
        let restrictedContactCount = 0;
        try {
            restrictedContactCount = await getRestrictedContactCount({ campaignId: this.recordId });
        } catch (e) {
            restrictedContactCount = 0;
        }
        getMemeberList({
            "campaignId": this.recordId,
            "typeOfExport": this.typeOfExport,
            "fieldAPINames": this.selectedColumns,
            "listMemberFieldAPINames": this.listMemberColumns,
            "contactFieldAPINames": this.contactColumns
        }).then((result) => {
            if (result.error) {
                console.log('Error on getMembers');
            } else {
                // this.members = result.filter(member => member.contact && (this.isRestricted || (!this.isRestricted && !member.contact.Restricted__c)));
                this.members = result
                    .filter(member =>
                        member.contact &&
                        (this.isRestricted || (!this.isRestricted && !member.contact.Restricted__c))
                    )
                    .map(member => {
                        let updatedMember = { ...member };

                        const restrictedName = member.contact?.Restricted_Name__c || '';
                            if (updatedMember.listMember.EmailSubjectLine__c && updatedMember.listMember.EmailSubjectLine__c.includes('#') && hasRestrictedAccess) {
                                updatedMember.listMember.EmailSubjectLine__c = updatedMember.listMember.EmailSubjectLine__c.replace(/#/g, restrictedName);
                            }

                            if (updatedMember.listMember.Latest_Email_Subject__c && updatedMember.listMember.Latest_Email_Subject__c.includes('#') && hasRestrictedAccess) {
                                updatedMember.listMember.Latest_Email_Subject__c = updatedMember.listMember.Latest_Email_Subject__c.replace(/#/g, restrictedName);
                            }


                        return updatedMember;
                    });
                if (restrictedContactCount > 0) {
                    this.confirmCSVExport(restrictedContactCount);
                } else {
                    this.exportToCSV1();
                }
            }
        }).catch((error) => {
            console.log(JSON.stringify(error.body));
        });
    }

    async confirmCSVExport(restrictedCount) {

        // Exclusive message per persona.
        let confirmMessage = hasRestrictedAccess
            ? 'Your results contain ' + restrictedCount + ' Private Contact(s).'
            : `You've encountered a problem with some of the records you selected ` +
              `(${restrictedCount} records are not exporting). ` +
              `Please contact brmpartnerships@bloomberg.org for further assistance.`;
        const confirmed = await LightningConfirm.open({
            message: confirmMessage,
            label: 'Warning!',
            variant: 'warning',
            theme: 'warning'
        });
        if (confirmed) this.exportToCSV1();
    }

    exportToCSV1() {
        var jsonRecordsData = this.members;
        let csvIterativeData;
        let csvSeperator = ",";
        let newLineCharacter;
        newLineCharacter = "\n";
        csvIterativeData = '"' + this.list.data.fields.Name.value + '"';
        csvIterativeData += newLineCharacter;
        csvIterativeData += newLineCharacter;
        csvIterativeData += this.columnHeaders.map(h => '"' + h.replace(/"/g, '""') + '"').join(csvSeperator);
        csvIterativeData += newLineCharacter;
        for (let i = 0; i < jsonRecordsData.length; i++) {
            var listmember = JSON.parse(JSON.stringify(jsonRecordsData[i].listMember));
            var contactData = JSON.parse(JSON.stringify(jsonRecordsData[i].contact));
            var otherData = JSON.parse(JSON.stringify(jsonRecordsData[i]));
            let counter = 0;
            for (let j = 0; j < this.selectedColumns.length; j++) {
                let dataKey = this.selectedColumns[j];
                if (dataKey === 'Via__c') dataKey = 'bpLpContact';
                if (counter > 0) csvIterativeData += csvSeperator;
                if (dataKey in contactData && !dataKey.includes('Assistant')) {
                    if (contactData[dataKey]) {
                        if (typeof contactData[dataKey] == "string" && contactData[dataKey].includes('"')) {
                            csvIterativeData += '"' + contactData[dataKey].replace(/"/g, '""') + '"';
                        } else {
                            csvIterativeData += '"' + contactData[dataKey] + '"';
                        }
                    } else {
                        csvIterativeData += '""';
                    }
                }
                const formatter = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD',
                });
                if (dataKey in listmember && !(dataKey in contactData)) {
                    if (listmember[dataKey] != null && listmember[dataKey] != undefined) {
                        if (dataKey == 'RSVPUpdateDate__c' || dataKey == 'LastModifiedDate' || dataKey == 'Invitation_Sent__c' ||
                            dataKey == 'Save_the_Date_Last_Modified__c' || dataKey == 'Reminder_Last_Modified__c' || dataKey == 'Email_Last_Modified__c' ||
                            dataKey == 'Invitation_Last_Modified__c') {

                            const rsvpDt = new Date(listmember[dataKey]);
                            var hours = rsvpDt.getHours();
                            var mon = rsvpDt.getMonth() + 1;
                            var ampm = hours >= 12 ? 'PM' : 'AM';
                            hours = hours % 12;
                            hours = hours ? hours : 12;
                            var mins = rsvpDt.getMinutes().toString();
                            if (mins < 10) mins = '0' + mins;
                            const dt = mon + '/' + rsvpDt.getDate() + '/' + rsvpDt.getFullYear() +
                                ', ' + hours + ': ' + mins + ' ' + ampm;
                            csvIterativeData += '"' + dt + '"';
                        } else if (dataKey == 'CC_Assistant__c' || dataKey == 'Fundraising_Rendering_Sample_Needed__c') {
                            csvIterativeData += '"' + listmember[dataKey] + '"';
                        } else if (dataKey == 'Fundraising_Gift_Amount__c') {
                            csvIterativeData += '"' + formatter.format(listmember[dataKey]) + '"';
                        } else if (typeof listmember[dataKey] == "string") {
                            if (listmember[dataKey].includes('"')) {
                                csvIterativeData += '"' + listmember[dataKey].replace(/"/g, '""') + '"';
                            } else {
                                csvIterativeData += '"' + listmember[dataKey] + '"';
                            }
                        } else if (typeof listmember[dataKey] == "number") {
                            csvIterativeData += listmember[dataKey];
                        } else csvIterativeData += '""';
                    } else if (dataKey == 'CC_Assistant__c' || dataKey == 'Fundraising_Rendering_Sample_Needed__c') {
                        csvIterativeData += '"' + listmember[dataKey] + '"';
                    } else csvIterativeData += '""';
                }
                if (dataKey in otherData) {
                    if (otherData[dataKey]) {
                        if (typeof otherData[dataKey] == "string" && otherData[dataKey].includes('"')) {
                            csvIterativeData += '"' + otherData[dataKey].replace(/"/g, '""') + '"';
                        } else {
                            csvIterativeData += '"' + otherData[dataKey] + '"';
                        }
                    } else csvIterativeData += '""';
                }
                counter++;
            }
            csvIterativeData += newLineCharacter;
        }
        this.hrefdata = "data:text/csv;charset=utf-8,%EF%BB%BF" + encodeURIComponent(csvIterativeData);
        let downloadElement = document.createElement('a');
        downloadElement.href = this.hrefdata;
        downloadElement.target = '_blank';
        downloadElement.download = 'Custom Export.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
        this.navigateToRecord();
        this.isLoading = false;
    }
}