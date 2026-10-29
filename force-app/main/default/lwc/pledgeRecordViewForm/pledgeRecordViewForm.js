import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe ,createMessageContext ,APPLICATION_SCOPE } from 'lightning/messageService';
import getchildRecords from '@salesforce/apex/PledgeRecordViewFormController.getPledgeChilds';
import hasRecordEditAccess from '@salesforce/apex/PledgeRecordViewFormController.hasRecordEditAccess';
import SAMPLEMC from '@salesforce/messageChannel/PledgePageRefresh__c';

const FIELDS = ['Pledge__c.Target_Amount__c', 'Pledge__c.Total_Paid_Amount__c', 'Pledge__c.Pledge_Amount__c', 'Pledge__c.Payments_NOT_Tracked__c', 'Pledge__c.Total_Benefit_Value__c', 'Pledge__c.Organization__c'];
const ORG_FIELDS = ['Account.Search_Display_Name__c'];

export default class PledgeRecordViewForm extends  NavigationMixin(LightningElement) {
    @api recordId;
    @track benefitsData;
    @track wiredResultList = [];
    @track donorsData;
    @track orgId;
    donorsStyle;
    objectApiName = 'Pledge__c';
    activeSections = ['A', 'B', 'C', 'D', 'E','F'];
    openEditPage = false;
    benefitsStyle;
    delayTimeout;
    editAccess = false;
    DELAY = 20000;
    publisherMessage = '';
    subscription = null;
    context = createMessageContext();
    unTracked;
    benifitValue;

    benefitsColumns = [
        {
            label: 'Benefit',
            fieldName: 'benefitUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'benefitName'
                },
                target: '_blank'
            }
        },
        {
            label: 'Quantity',
            fieldName: 'Quantity__c',
            type: 'number',
            sortable: true
        },
        {
            label: 'Listing Location',
            fieldName: 'Listing_Location__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Listing Text',
            fieldName: 'Listing_Text__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Start Date',
            fieldName: 'Start_Date__c',
            type: 'date-local',
            sortable: true,
            typeAttributes: {
                day: "numeric",
                month: "numeric",
                year: "numeric"
            }
        },
        {
            label: 'End Date',
            fieldName: 'End_Date__c',
            type: 'date-local',
            sortable: true,
            typeAttributes: {
                day: "numeric",
                month: "numeric",
                year: "numeric"
            }
        }
    ];

    donorsColumns = [
        {
            label: 'Donor Type',
            fieldName: 'Donor_Type__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Donor',
            fieldName: 'donorUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'donorName'
                },
                target: '_blank'
            }
        },
        {
            label: 'Credit Type',
            fieldName: 'Credit_Type__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Donor Amount',
            fieldName: 'Amount__c',
            type: 'number',
            wrapText: true,
            sortable: true,
        }
    ];

    get orgRecordUrl() {
        return this.orgId ? `/lightning/r/Account/${this.orgId}/view` : '#';
    }

    get targetAmount() {
        const tAmount = getFieldValue(this.pledge.data, 'Pledge__c.Target_Amount__c');
        const cType = getFieldValue(this.pledge.data, '');
        const ct = (cType === null || cType === "" || cType === undefined) ? '' : cType;
        const ta = (tAmount === null || tAmount === "" || tAmount === undefined) ? '' : tAmount;
        return ct + ' ' + ta;
    }

    get paymentAmount() {
        const pAmount = getFieldValue(this.pledge.data, 'Pledge__c.Total_Paid_Amount__c');
        const cType = getFieldValue(this.pledge.data, '');
        const ct = (cType === null || cType === "" || cType === undefined) ? '' : cType;
        const ta = (pAmount === null || pAmount === "" || pAmount === undefined) ? '' : pAmount;
        return ct + ' ' + ta;
    }

    get pledgeAmount() {
        const pAmount = getFieldValue(this.pledge.data, 'Pledge__c.Pledge_Amount__c');
        const cType = getFieldValue(this.pledge.data, '');
        const ct = (cType === null || cType === "" || cType === undefined) ? '' : cType;
        const ta = (pAmount === null || pAmount === "" || pAmount === undefined) ? '' : pAmount;
        return ct + ' ' + ta;
    }

    get orgSearchDisplayName() {
        return getFieldValue(this.orgRecord.data, 'Account.Search_Display_Name__c');
    }

    @wire(getRecord, { recordId: '$orgId', fields: ORG_FIELDS })
    orgRecord;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    pledge({ error, data }) {
        if (error) {
            console.log('record data error>>>', error);
        } else if (data) {
            this.unTracked = getFieldValue(data, 'Pledge__c.Payments_NOT_Tracked__c');
            this.benifitValue = getFieldValue(data, 'Pledge__c.Total_Benefit_Value__c');
            this.orgId = getFieldValue(data, 'Pledge__c.Organization__c');
        }
    }

    connectedCallback() {
        this.getDonorsBenefits(this.recordId);
        this.hasRecordEditAccess(this.recordId);
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.context,
            SAMPLEMC,
            (RecData) => this.displayMessage(RecData),
            { scope: APPLICATION_SCOPE }
        );
    }

    displayMessage() {
        this.getDonorsBenefits(this.recordId);
        return refreshApex(this.recordId);
    }

    hasRecordEditAccess(recordId) {
        hasRecordEditAccess({
            recordId: recordId
        }).then((result) => {
            this.editAccess = result;
        }).catch(error => {
            console.log('get child records error >>>>>', error);
        })
     }

    getDonorsBenefits(recordId) {
        getchildRecords({
            recordId: recordId
        }).then((result) => {
            if (result) {
                this.donorsData = [];
                this.wiredResultList = result;
                this.donorsData = result.donors ? this.donorsRowData(result.donors) : [];
                this.benefitsData = (result.pBenefits) ? this.benefitsRowData(result.pBenefits) : [];
                this.benefitsStyle = this.benefitsData && this.benefitsData.length > 4 ? 'height: 250px;width: auto;' : '';
                this.donorsStyle = this.donorsData && this.donorsData.length > 4 ? 'height: 250px;width: auto;' : '';
            }
        }).catch(error => {
            console.log('get child records error >>>>>', error);
        })
    }

    benefitsRowData(data) {
        var benefits = [];
        data.forEach(rec => {
            let objRec = Object.assign({}, rec);
            objRec['benefitName'] = rec.Benefits__r.Name;
            objRec['benefitUrl'] = '/' + rec.Benefits__c;
            benefits.push(objRec);
        });
        return benefits;
    }

    donorsRowData(data) {
        var donors = [];
        data.forEach(rec => {
            let objRec = Object.assign({}, rec);
            objRec['donorName'] = '';
            objRec['donorUrl'] = '';
            if (rec.Donor_Type__c == 'Contact') {
                objRec['donorName'] =  rec.Contact__r.Search_Display_Name__c;
                objRec['donorUrl'] = '/' + rec.Contact__c;
            } else if (rec.Donor_Type__c == 'Organization') {
                objRec['donorName'] =  rec.Organization__r.Search_Display_Name__c;
                objRec['donorUrl'] = '/' + rec.Organization__c;
            }
            donors.push(objRec);
        });
        return donors;
    }

    handlepledgeEdit() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Pledge__c',
                actionName: 'edit'
            }
        });
    }
}