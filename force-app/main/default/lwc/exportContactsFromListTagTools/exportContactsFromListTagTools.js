import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import getAvailableColumns from '@salesforce/apex/ContactListWithTagsReportController.getAvailableColumns';
import getMemberList from '@salesforce/apex/ContactListWithTagsReportController.getMemberList';
import SIGNIFICANT_OTHER_FIELD from '@salesforce/schema/Contact.Annual_Report_Salutation__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';

const FIELDS = [
    'Campaign.Name', 'Campaign.RecordType.DeveloperName'
];

export default class ExportContactsFromListTagTools extends LightningElement {
    @api contactIds;
    @api additionalContactIds;
    @api listIds;
    @api tagIds;
    @api isRemoveDuplicates;
    @api restrictedContactCount;
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
    objectInfo;

    columnHeaders = ['First/Preferred First Name', 'Last/Preferred Last Name', 'Significant Other Name(Preferred)',
                     'Title', 'Organization', 'Priority Email', 'F&F Tags', 'Other Tags', 'Contact ID',
                     'List Member ID', 'Source - Generated Results'];
    selectedColumns = ['firstOrPreferredFirstName', 'Last_Preferred_Last_Name__c', 'SignificantOtherPreferredFirstName', 
                       'Title', 'organization', 'Priority_Email__c', 'ffTags', 'otherTags', 'Id', 
                       'listMemberId', 'tagSourceResult'];

    preSelectedColumns = [
        { label: 'Significant Other', value: 'significantOther' },
        { label: 'Significant Other Salutation', value: 'SignificantSalutation' },
        { label: 'Correspondence Significant Other Annual Report Salutation', value: 'SignificantARSalutation' },
        { label: 'First/Preferred First Name', value: 'firstOrPreferredFirstName' },
        { label: 'Last/Preferred Last Name', value: 'Last_Preferred_Last_Name__c' },
        { label: 'Last Name', value: 'LastName' },
        { label: 'Significant Other Name(Preferred)', value: 'SignificantOtherPreferredFirstName' },
        { label: 'Title', value: 'Title' },
        { label: 'Organization', value: 'organization' },
        { label: 'Priority Email', value: 'Priority_Email__c' },
        { label: 'F&F Tags', value: 'ffTags' },
        { label: 'Other Tags', value: 'otherTags' },  
        { label: 'Contact ID', value: 'Id' },
        { label: 'List Member ID', value: 'listMemberId' },
        { label: 'Source - Generated Results', value: 'tagSourceResult' }   
    ];

    get options() {
        return [
            { label: 'Standard', value: 'Standard' },
            { label: 'Executive', value: 'Executive' }
        ];
    }

    get shallDisableExportButton() {
        return this.typeOfExport == '' || this.typeOfExport == undefined;
    }

    connectedCallback() {
        if(this.contactIds == null) this.contactIds = [];
        if(this.tagIds == null) this.tagIds = [];
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    list;

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Error fetching object info', error);
        }
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

    handleChange(event) {
        this.typeOfExport = event.detail.value;
        this.typeSelection = false;
        this.columnSelection = true;
        this.setAvailableOptions();
    }

    handleColumnSelection(event) {
        this.selectedColumns = event.detail.value;
        let headers = [];
        for(let i=0; i<this.selectedColumns.length; i++) {
            let header = this.allColumns.find(o => o.value === this.selectedColumns[i]);
            if(header.value == 'Significant_Other_Title__c') {
                headers.push('"' + header.label + '"');
            } else {
                headers.push(header.label);
            }
        }
        this.columnHeaders = headers;
    }

    handleExport() {
        this.handleFinish();
    }

    closeExport(isExport) {
        const selectedEvent = new CustomEvent('closeexport', {
            detail: { isExport: isExport }
        });
        this.dispatchEvent(selectedEvent);
    }

    handleCancel() {
        this.closeExport(false);
    }

    handleFinish() {
        this.isLoading = true;
        if(this.typeOfExport !== '') this.getMembers();
    }

    showNotification(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
        });
        this.dispatchEvent(evt);
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

    setAvailableOptions() {
        getAvailableColumns({
        }).then((result) => {
            if(result.error) {
                console.log('Error while retrieveing available options.');
            } else {
                let options = [];
                let contactOptions = result.contactFields;
                let listMemberOptions = result.listMemberFields;
                contactOptions.forEach((element) => {
                    let label = element.fieldLabel;
                    if(element.fieldValue == 'AssistantName') label = 'Staff Name'
                    options.push({ label: label , value: element.fieldValue });
                    this.contactColumns.push(element.fieldValue);
                });
                options = options.concat(this.preSelectedColumns); 
                listMemberOptions.forEach((element) => {
                    options.push({ label: element.fieldLabel , value: element.fieldValue });
                    this.listMemberColumns.push(element.fieldValue);
                });

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

                //this.allColumns = options;
            }
        }).catch((error) => {
            console.log(error);
        });
    }

    async getMembers() {
        const batchedContactIds = this.chunkArray(this.contactIds, 5000);
        let allMembers = [];
        for(let batch of batchedContactIds) {
            try {
                await getMemberList({
                    campaignIds: this.listIds,
                    additionalContactIds: this.additionalContactIds,
                    tagIds: this.tagIds,
                    contactIds: batch,
                    typeOfExport: this.typeOfExport,
                    fieldAPINames: this.selectedColumns,
                    listMemberFieldAPINames: this.listMemberColumns,
                    contactFieldAPINames: this.contactColumns,
                    isRemoveDuplicates: this.isRemoveDuplicates
                }).then((result) => {
                    if(result.error) {
                        console.log('Error on getMembers');
                    } else {
                        if(result) allMembers = allMembers.concat(result);
                    }
                }).catch((error) => {
                    console.log(error);
                });
            } catch(error) {
                console.error(JSON,stringify(error));
            }
            await this.sleep(2000);
        }
        allMembers.sort((a, b) => {


            let lastNameA = a.contact?.Last_Preferred_Last_Name__c?.toLowerCase() || '';
            let lastNameB = b.contact?.Last_Preferred_Last_Name__c?.toLowerCase() || '';
            if (lastNameA < lastNameB) return -1;
            if (lastNameA > lastNameB) return 1;
            return 0;
        });
        this.members = allMembers;

        if (this.restrictedContactCount > 0) {
            let message;
            if (hasPrivateNameFieldsAccess) {
                message = 'Your results contain ' + this.restrictedContactCount + ' Private Contact(s).';
            } else {
                message = `\n\n You've encountered a problem with some of the records you selected ` + this.restrictedContactCount + ` records are not exporting). ` +
                `Please contact brmpartnerships@bloomberg.org for further assistance. \n\n`;
            }
            this.showNotification('Warning', message, 'warning', 'sticky');
        }
        this.exportToCSV1();
    }

    chunkArray(array, size) {
        let result = [];
        for(let i = 0; i < array.length; i += size) {
            result.push(array.slice(i, i + size));
        }
        return result;
    }

    sleep(DELAY) {
        return new Promise(resolve => setTimeout(resolve, DELAY));
    }

    exportToCSV1() {
        var jsonRecordsData = this.members;  
        let csvIterativeData = '';  
        let csvSeperator;
        let newLineCharacter;  
        csvSeperator = ",";  
        newLineCharacter = "\n";
        csvIterativeData += this.columnHeaders.join(csvSeperator);  
        csvIterativeData += newLineCharacter;
        for(let i = 0; i < jsonRecordsData.length; i++) {
            var tempListMember = JSON.stringify(jsonRecordsData[i].listMember);
            if(tempListMember == undefined) tempListMember = [];
            var listmember = JSON.parse(tempListMember);
            var contactData = JSON.parse(JSON.stringify(jsonRecordsData[i].contact));
            var otherData = JSON.parse(JSON.stringify(jsonRecordsData[i]));
            let counter = 0;
            for(let j = 0; j < this.selectedColumns.length; j++) {
                let dataKey = this.selectedColumns[j];
                if(dataKey === 'Via__c') dataKey = 'bpLpContact';
                if(counter > 0) { csvIterativeData += csvSeperator; }      
                if(dataKey in contactData && !dataKey.includes('Assistant')) {
                    if(contactData[dataKey]) {
                        if(typeof contactData[dataKey] == "string" && contactData[dataKey].includes('"')) {
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
                if(dataKey in listmember && !(dataKey in contactData)) {
                    if(listmember[dataKey] != null && listmember[dataKey] != undefined) {
                        if(dataKey == 'RSVPUpdateDate__c') {
                            const rsvpDt = new Date(listmember[dataKey]);
                            var hours = rsvpDt.getHours();
                            var mon = rsvpDt.getMonth() + 1;
                            var ampm = hours >= 12 ? 'PM' : 'AM';
                            hours = hours % 12;
                            hours = hours ? hours : 12;
                            var mins = rsvpDt.getMinutes().toString();                       
                            if(mins < 10) mins = '0' + mins;
                            const dt = mon + '/' + rsvpDt.getDate() + '/' + rsvpDt.getFullYear() + 
                                       ', ' + hours + ': ' + mins + ' ' + ampm;
                            csvIterativeData += '"' + dt + '"';
                        } else if(dataKey == 'CC_Assistant__c' || dataKey == 'Fundraising_Rendering_Sample_Needed__c') {
                            csvIterativeData += '"' + listmember[dataKey] + '"';
                        } else if(dataKey == 'Fundraising_Gift_Amount__c') {
                            csvIterativeData += '"' + formatter.format(listmember[dataKey]) + '"';
                        } else if(typeof listmember[dataKey] == "string") {
                            if( listmember[dataKey].includes('"')) {
                                csvIterativeData += '"' + listmember[dataKey].replace(/"/g, '""') + '"';
                            } else {
                                csvIterativeData += '"' + listmember[dataKey] + '"';
                            }       
                        } else if(typeof listmember[dataKey] == "number") {
                            csvIterativeData += listmember[dataKey];
                        } else csvIterativeData += '""';  
                    } else if(dataKey=='CC_Assistant__c' || dataKey=='Fundraising_Rendering_Sample_Needed__c') {
                        csvIterativeData += '"' + listmember[dataKey] + '"';
                    } else csvIterativeData += '""';  
                }
                if(dataKey in otherData) {
                    if(otherData[dataKey]) {
                        if(typeof otherData[dataKey] == "string" && otherData[dataKey].includes('"')) {
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
        this.hrefdata = 'data:text/csv;charset=utf-8,%EF%BB%BF' + encodeURIComponent(csvIterativeData);
        let downloadElement = document.createElement('a');
        downloadElement.href = this.hrefdata;
        downloadElement.target = '_blank';
        downloadElement.download = 'ListTagsData.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
        this.isLoading = false;
        this.closeExport(true);
    }
}