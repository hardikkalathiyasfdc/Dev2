import { LightningElement, track, api, wire } from 'lwc';
import getFieldSetFields from '@salesforce/apex/ContactExportController.getFieldSetFields';
import getContactsWithSelectedFields from '@salesforce/apex/ContactExportController.getContactsWithSelectedFields';
import getAllFieldAccess from '@salesforce/apex/ContactExportController.getAllFieldAccess';
import getRestrictedContact from '@salesforce/apex/ContactExportController.getRestrictedContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import SIGNIFICANT_OTHER_FIELD from '@salesforce/schema/Contact.Annual_Report_Salutation__c';
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';

export default class ContactExport extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isLeaderShip;
    @api mode;
    @track fields = [];
    @track selectedFields = ["First_Preferred_First_Name__c", "Last_Preferred_Last_Name__c", "Significant_Other_Name_Preferred__c", "Title", "Contact_Org_Name__c", "Priority_Email__c", "ffTags", "otherTags", "Id"];
    contactObject = CONTACT_OBJECT;
    significantOtherField = SIGNIFICANT_OTHER_FIELD;
    isLoading = false;
    isFirstLoad = false;
    objectApiName = 'Contact';
    preSelectedColumns = [
        { label: 'First/Preferred First Name', value: 'First_Preferred_First_Name__c' },
        { label: 'Last/Preferred Last Name', value: 'Last_Preferred_Last_Name__c' },
        { label: 'Significant Other Name (Preferred)', value: 'Significant_Other_Name_Preferred__c' },
        { label: 'Title', value: 'Title' },
        { label: 'Organization', value: 'Contact_Org_Name__c' },
        { label: 'Priority Email', value: 'Priority_Email__c' },
        { label: 'F&F Tags', value: 'ffTags' },
        { label: 'Other Tags', value: 'otherTags' },
        { label: 'Contact ID', value: 'Id' },
    ];

    customColumns = [
        { label: 'Significant Other', value: 'Significant_Name__c' },
        { label: 'Private', value: 'Restricted__c' },
        { label: 'Significant Other Salutation', value: 'Significant_Other__r.Salutation' },
        { label: 'Correspondence Significant Other Annual Report Salutation', value: 'Significant_Other__r.Annual_Report_Salutation__c' },
        { label: 'Title, Significant  Other', value: 'Significant_Other__r.Title' },
        { label: 'Significant Other Email', value: 'Significant_Other__r.Email' },
        { label: 'Significant Other Staff', value: 'significantOtherAssistantName' }
    ];

    fieldSetName = 'Export_List'; // Replace with the name of your field set

    fieldAccessMap = {};

    get isRestricted() {
        return hasPrivateNameFieldsAccess;
    }

    @wire(getAllFieldAccess)
    fieldAccessHandler({ data, error }) {
        if (data) {
            this.fieldAccessMap = data;
            console.log('All Field Access:', data);
        } else if (error) {
            console.error('Error fetching all field access', error);
        }
    }


    isFieldReadable(fieldApiName) {
        return this.fieldAccessMap[fieldApiName.toLowerCase()]?.isAccessible === true;
    }

    isFieldUpdatable(fieldApiName) {
        return this.fieldAccessMap[fieldApiName.toLowerCase()]?.isUpdateable === true;
    }

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        this.mode = urlParams.get('c__mode');
        if (!this.recordId) {
            this.recordId = urlParams.get('c__accountId');
        }
        this.isLoading = true;
        this.loadFieldSetFields();
        this.isFirstLoad = true;
        this.fetchRecords();
    }

    loadFieldSetFields() {
        this.isLoading = true;
        getFieldSetFields({ fieldSetName: this.fieldSetName })
            .then((data) => {
                let finalCustomCols = data || [];

                // --- Add pre-selected columns
                finalCustomCols = finalCustomCols.concat(this.customColumns || []);
                finalCustomCols = finalCustomCols.concat(this.preSelectedColumns || []);

                // --- Apply generic field access filter
                const fieldAccessMap = {
                    "Significant_Other__r.Annual_Report_Salutation__c": SIGNIFICANT_OTHER_FIELD.fieldApiName,
                    "SignificantARSalutation": SIGNIFICANT_OTHER_FIELD.fieldApiName,
                    "AssistantName": "Significant_Other__c",
                    "Restricted__c": "Restricted__c",
                    "Restricted_Name__c": "Restricted_Name__c",
                    "Restricted_Org_Name__c": "Restricted_Org_Name__c"
                    // add more mappings as needed
                };

                this.fields = finalCustomCols.filter(col => {
                    const fieldApi = fieldAccessMap[col.value] || col.value;
                    return !fieldAccessMap[col.value] || this.isFieldReadable(fieldApi);
                });
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleFieldChange(event) {
        this.selectedFields = event.detail.value;
    }

    exportToExcel() {
        this.isFirstLoad = false;
        this.fetchRecords();
    }

    fetchRecords() {
        if (!this.selectedFields.length) {
            this.showToast('No Fields Selected', 'Please select at least one field to export.', 'warning');
            return;
        }
        this.isLoading = true;
        let restrictedContactCount = 0;
        getRestrictedContact({accountId: this.recordId})
        .then((data)=> {
          if(data){
              restrictedContactCount = data;
          }
        }).catch((error) => {
            this.showToast('Error', error.body.message, 'error');
        })

        getContactsWithSelectedFields({
            selectedFields: this.selectedFields,
            accountId: this.recordId,
            mode: this.mode
        }).then((data) => {
            if (!data.length) {
                this.showToast('No Records to Export', 'No contacts available to export.', 'error');
                this.isLoading = false;
                this.navigateToRecord();
                return;
            }
            if (!this.isFirstLoad) {
                if (restrictedContactCount > 0 && !this.isRestricted) {
                    data =  data.filter(member => member.Restricted__c == 'false');
                    this.showToast('Warning!', 'You\'ve encountered a problem with some of the records you selected (' + restrictedContactCount + ' records are not exporting), please contact brmpartnerships@bloomberg.org for further assistance.', 'warning');
                } else
                if (restrictedContactCount > 0) {
                    this.showToast('Warning!', 'This List you selected has ' + restrictedContactCount + ' Private Contact(s).', 'warning');
                }
                let headers = [];
                for (let i = 0; i < this.selectedFields.length; i++) {
                    let header = this.fields.find(o => o.value === this.selectedFields[i]);
                    headers.push(header.label.replace(/,/g, ""));
                }
                // Generate CSV content
                let csvContent = headers.join(',') + '\n';
                data.forEach((row) => {
                    let rowData = this.selectedFields.map((field) => {
                        let value = row[field];
                        if (value) {
                            if (typeof value === "string" && value.includes('"')) {
                                return `"${value.replace(/"/g, '""')}"`;  // escape quotes
                            } else {
                                return `"${value}"`;
                            }
                        } else {
                            return '""';  // force empty fields to be ""
                        }
                    });
                    csvContent += rowData.join(',') + '\n';
                });
                const link = document.createElement('a');
                link.href = "data:text/csv;charset=utf-8,%EF%BB%BF" + encodeURIComponent(csvContent);
                link.download = 'Contacts.csv';
                link.target = '_self';
                document.body.appendChild(link);
                link.click();
                this.navigateToRecord();
                this.showToast('Success', 'Contacts exported successfully.', 'success');
            }
        }).catch((error) => {
            this.showToast('Error', error.body.message, 'error');
        }).finally(() => {
            this.isLoading = false;
        });
    }

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}