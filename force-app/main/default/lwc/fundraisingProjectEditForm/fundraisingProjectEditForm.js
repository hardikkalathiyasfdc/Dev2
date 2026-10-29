import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getchildRecords from '@salesforce/apex/FundraisingProjectController.getchildrecords';
import checkFundraisingCodingAccess from '@salesforce/apex/FundraisingProjectController.checkFundraisingCodingAccess';
import upsertRecipientOrganization from '@salesforce/apex/FundraisingProjectController.createchildrecords';
import duplicateFundris from '@salesforce/apex/FundraisingProjectController.duplicateFundd';
import PledgePageRefresh from '@salesforce/messageChannel/PledgePageRefresh__c';
import createAppealrecod from '@salesforce/apex/FundraisingProjectController.createAppealrecod';

const FIELDS = [
    'Fundraising_Project__c.Political__c',
    'Fundraising_Project__c.Advocacy__c',
    'Fundraising_Project__c.Foundation_Coding__c'
];

import { getRecord, getFieldValue, deleteRecord } from 'lightning/uiRecordApi';
import {
    publish,
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';
import recepientdata_channel from '@salesforce/messageChannel/recepientsaveddata__c';

export default class FundraisingProjectEditForm extends NavigationMixin(LightningElement) {

    rec = {
        'sobjectType': 'Fundraising_Activity__c'
    };

    @wire(MessageContext)
    messageContext;

    receivedMessage;
    header;

    @api recordId;
    @api objectApiName;

    fundraisingProjectRecordId;
    objectApiName = 'Fundraising_Project__c';
    activeSections = ['A', 'B', 'C', 'E', 'F'];
    isLoading = false;
    isduplicate = false;
    isEditState;
    tableView;
    isActivity;
    addorganizations = false;
    fundraisingrecId;
    recepientOrg = true;
    recepientOrgColumns;
    currentRecordId;
    foundationCoding;

    @track recepientOrgData = [];

    isPolitical;
    isAdvo;

    @track recepientOrgDatatoInsert = [];
    @track hasRendered = true;

    hasFundraisingCodingAccess;

    listDisplayFields = ['Name', 'ListMemberCount__c', 'Event_Start_Date_Time__c'];
    listDisplayFieldPrefixes = ['', 'List Member Count', 'Event Start Date/Time'];
    listSearchFields =  ['Name','Converted_List_Name__c'];
    campaignSearchConfig = JSON.stringify({
        primaryField: 'Name',
        primaryWeight: 100,
        convertedField: 'Converted_List_Name__c',
        convertedWeight: 80
    });
    listRequired = false;
    showRecentlyViewed = true;
    campaignDefaultIds = [];

    lookupReciRecord(event) {
        event.preventDefault();
        this.selectedListIds = event.detail.selectedIds || [];
        let listRecordId = event.detail.selectedIds ? event.detail.selectedIds[0] : null;
        this.rec['BP_Event_Id__c'] = listRecordId;
    }

    get bpEventFilterClause() {
        return ` Recordtype.DeveloperName = 'Pre_Event'`;
    }

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId || null;
            let attributes = currentPageReference.attributes;
            let states = currentPageReference.state;
            let type = currentPageReference.type;
        }
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                recepientdata_channel,
                (message) => this.handleMessage(message)
            );
        }
    }

    @wire(getRecord, { recordId: '$currentRecordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            console.log('record data error>>>', error);
        } else if (data) {
            console.log('data777>>>>>>>>', data);
            this.isPolitical = getFieldValue(data, 'Fundraising_Project__c.Political__c');
            this.isAdvo = getFieldValue(data, 'Fundraising_Project__c.Advocacy__c');
            this.foundationCoding = getFieldValue(data, 'Fundraising_Project__c.Foundation_Coding__c');
        }
    }

    populatevalue(event) {
        console.log(event.target.fieldName);
        console.log(event.target.value);
        this.rec[event.target.fieldName] = event.target.value;
    }

    updateRecordView() {
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire()");
        }, 1000);
    }

    handleMessage(message) {
        this.recepientOrgDatatoInsert = [];
        this.recepientOrgData = message.record;
        if (this.recepientOrgData.length > 0) {
            this.addorganizations = false;
            for (var i = 0; i < this.recepientOrgData.length; i++) {
                console.log('Inside loop...');
                const record = {
                    sobjectType: 'Recipient_Organization__c',
                    Fundraising_Project__c: this.recordId,
                    Organization__c: this.recepientOrgData[i].Organization__c,
                    Recipient_Soft_Credit__c: this.recepientOrgData[i].Recipient_Soft_Credit__c
                };
                if (this.recepientOrgData[i].Id != undefined) {
                    record.Id = this.recepientOrgData[i].Id;
                }
                this.recepientOrgDatatoInsert.push(record);
            }
            console.log(this.recepientOrgDatatoInsert);
        }
        console.log('handleMessage');
        console.log(message.record);
    }

    connectedCallback() {
        this.recepientOrg = false;
        console.log('Inside connectedCallbackCC' + this.recordId);
        this.recepientOrgData = [];
        this.subscribeToMessageChannel();
        this.fundraisingProjectRecordId = this.recordId;
        this.header = this.recordId ? 'Edit Fundraising Project' : 'New Fundraising Project';
        this.isEditState = this.recordId ? true : false;
        this.isActivity = this.recordId ? true : false;
        if (this.recordId) {
            this.currentRecordId = this.recordId;
        }
        if (this.recordId) {
            this.tableView = true;
        }
        this.addColumns();
        this.getrecepientOrgData(this.recordId);
        this.checkFundraisingCodingAccess();
    }

    getrecepientOrgData(recordId) {
        this.isLoading = true;
        getchildRecords({ recordId: recordId })
            .then((result) => {
                if (result) {
                    console.log(result);
                    this.recepientOrgData = result.recipients ? result.recipients : [];
                    this.recepientOrgDatatoInsert = result.recipients ? result.recipients : [];
                    this.isLoading = false;
                    this.recepientOrg = true;
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.log('get child records error >>>>>', error);
            });
    }

    addRow(event) {
        this.tableView = true;
    }

    addColumns() {
        this.recepientOrgColumns = [
            { label: 'Organization', fieldName: 'Organization__c', required: true },
            { label: 'Recipient - Soft Credit', fieldName: 'Recipient_Soft_Credit__c', required: true }
        ];
    }

    createAppealrecods(actrec) {
        console.log('Inside createAppealrecods');
        console.log(actrec);
        createAppealrecod({ rec: actrec })
            .then(result => {
                this.handleNavigate(this.fundraisingrecId);
            })
            .catch(error => {
                console.log('Inside error>>>' + error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Duplicate Recipient',
                        message: 'Duplicate Organization is not allowed.',
                        variant: 'error',
                    }),
                );
                this.isLoading = false;
                console.log(error);
                this.error = error;
            });
    }

    crateRecorg(savedId) {
        console.log('crateRecorg savedId>>>>' + savedId + '>>isActivity>>' + this.isActivity);
        upsertRecipientOrganization({ rec: this.recepientOrgDatatoInsert })
            .then(result => {
                this.isLoading = true;
                if (result != '') {
                    console.log('Inside .....');
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Duplicate Recipient',
                            message: 'Recipient Organization already existing.',
                            variant: 'error',
                        }),
                    );
                    this.isLoading = false;
                } else {
                    if (!this.isActivity) {
                        this.rec.Fundraising_Effort_Id__c = this.fundraisingrecId;
                        this.createAppealrecods(this.rec);
                    } else {
                        this.handleNavigate(savedId);
                    }
                }
                console.log('result>>>' + result);
            })
            .catch(error => {
                console.log('Inside error>>>' + error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Duplicate Recipient',
                        message: 'Duplicate Organization is not allowed.',
                        variant: 'error',
                    }),
                );
                this.isLoading = false;
                console.log(error);
                this.error = error;
            });
    }

    handleActivitySaveSuccess(event) {
        console.log('Inside handleActivitySaveSuccess' + this.fundraisingrecId);
        this.handleNavigate(this.fundraisingrecId);
    }

    handleSubmit(event) {
        event.preventDefault();
        var isValidAppeal = true;
        var isValidfocusType = true;
        var isValidpoVal = true;

        if (
            this.foundationCoding == undefined ||
            this.foundationCoding == '' ||
            this.foundationCoding == null
        ) {
            this.isValidfocusType = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Creating Record',
                    message: 'Required fields are missing: [Foundation Code].',
                    variant: 'error',
                }),
            );
            return;
        }

        if (!this.isActivity) {
            if (
                this.rec.Name == null ||
                this.rec.Type__c == null ||
                this.rec.Name == '' ||
                this.rec.Type__c == ''
            ) {
                isValidAppeal = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Appeal section',
                        message: 'Please complete Initial Appeal section..!',
                        variant: 'error',
                    }),
                );
                return;
            }
        }

        if (this.isPolitical == true && this.isAdvo == true) {
            isValidpoVal = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Please uncheck Political or Advocacy',
                    message: 'Please uncheck Political or Advocacy',
                    variant: 'error',
                }),
            );
        }

        if (this.isduplicate === true) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Duplicate Record Warning',
                    message: 'This record looks like an existing record. Make sure to check any potential duplicate records.',
                    variant: 'warning',
                    mode: 'dismissable'
                }),
            );
        }
        let fundraisingForm = this.template.querySelector('lightning-record-edit-form[data-id="fundraisingForm"]');
        if (this.recepientOrgData.length > 0 && isValidAppeal && isValidfocusType && isValidpoVal) {
            console.log('Inside if');
            let isOrgValid = true;
            this.addorganizations = false;

            //  Validate each row
            let updatedData = this.recepientOrgData.map(rec => {
                let updatedRec = { ...rec };

                // check orgIds OR Organization__c
                if (
                    (!updatedRec.Organization__c || updatedRec.Organization__c === '') &&
                    (!updatedRec.orgIds || updatedRec.orgIds.length === 0)
                ) {
                    updatedRec.orgError = 'Please select Organization or remove this row';
                    isOrgValid = false;
                } else {
                    updatedRec.orgError = '';
                }

                return updatedRec;
            });

            this.recepientOrgData = updatedData;
            //  Stop save if invalid
            if (!isOrgValid) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Some rows are missing Organization',
                        variant: 'error',
                    }),
                );
            } else {
                fundraisingForm.submit();
            }
        } else {
             this.isLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Recipient Organization',
                        message: 'Please Add Recipient Organization.',
                        variant: 'error',
                    }),
                );
                this.addorganizations = true;
        }
    }

    refreshPage() {
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 1000);
    }

    handleSuccess(event) {
        var savedId = event.detail.id;
        this.fundraisingrecId = savedId;
        console.log(JSON.stringify(this.recepientOrgDatatoInsert));
        if (this.recepientOrgDatatoInsert.length > 0) {
            var tempdata = [];
            for (var i = 0; i < this.recepientOrgDatatoInsert.length; i++) {
                let data = this.recepientOrgDatatoInsert[i];
                data.Fundraising_Project__c = savedId;
                tempdata.push(data);
                console.log('Inside id>>>>' + JSON.stringify(data));
            }
            console.log(JSON.stringify(tempdata));
            this.recepientOrgDatatoInsert = tempdata;
            this.crateRecorg(savedId);
        } else {
            this.handleNavigate(savedId);
        }
    }

    handleNavigate(recordId) {
        const message = { recordId: recordId };
        setTimeout(() => {
            publish(this.messageContext, PledgePageRefresh, message);
        }, 1);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            }
        });
    }

    handleError(event) {
        console.log('The error' + JSON.stringify(event.detail));
        this.isLoading = false;
        const fieldErrors = event.detail.output.fieldErrors;
        console.log('The error is' + JSON.stringify(fieldErrors));
        const separator = ' ';
        let message = Object.values(fieldErrors)
            .map(field => {
                return field.map(error => error.message).join(separator);
            })
            .join(separator);
        if (message.includes('Required fields are missing')) {
            message = 'Please complete the required fields.';
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error creating record',
                message: message,
                variant: 'error',
            }),
        );
    }

    handleCancel() {
        console.log('the cancel call----->');
        if (this.recordId) {
            this.handleNavigate(this.recordId);
        } else {
            this.handleListViewNavigation();
        }
    }

    handleListViewNavigation() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Fundraising_Project__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    checkhadnlPoliticaleerror(event) {
        this.isPolitical = event.target.value;
    }

    checkhadnlAdvoeerror(event) {
        this.isAdvo = event.target.value;
    }

    checkduplixtae(event) {
        var dupli = event.target.value;
        console.log('duplicate dupli' + dupli);
        duplicateFundris({ recChar: dupli })
            .then(result => {
                if (result === true) {
                    this.isduplicate = true;
                    const evt = new ShowToastEvent({
                        title: 'Duplicate Record Warning',
                        message: 'This record looks like an existing record. Make sure to check any potential duplicate records before saving.',
                        variant: 'warning',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                } else {
                    this.isduplicate = false;
                }
            })
            .catch(error => {
                console.log('Inside error>>>' + error);
            });
    }

    handleFoundationCodingChange(event) {
        this.foundationCoding = event.detail.value;
    }

    checkFundraisingCodingAccess() {
        checkFundraisingCodingAccess()
            .then((result) => {
                if (result) {
                    this.hasFundraisingCodingAccess = result;
                }
            })
            .catch(error => {
                console.log('checkFundraisingCodingAccess error', error);
            });
    }
}