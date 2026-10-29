import { LightningElement, api, track, wire } from 'lwc';
import fetchHistoryRecords from '@salesforce/apex/FieldHistoryController.fetchHistoryRecords';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class CustomFieldHistoryTable extends LightningElement {
    @api recordId;
    @track historyRecords = [];
    @track columns = [
        { label: 'Date', fieldName: 'createdDate', type: 'date', initialWidth: 150, typeAttributes: { year: 'numeric', month: 'numeric', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: true } },
        { label: 'Field', fieldName: 'fieldLabel', type: 'text', initialWidth: 140 },
        { 
            label: 'User', 
            fieldName: 'userUrl', 
            type: 'url', 
            initialWidth: 150,
            typeAttributes: { 
                label: { fieldName: 'userName' }, target: '_blank' 
            } 
        },
        { label: 'Original Value', fieldName: 'originalValue', type: 'richText', wrapText: true, typeAttributes: { isRichText: { fieldName: 'isRichText' } } },
        { label: 'New Value', fieldName: 'newValue', type: 'richText', wrapText: true, typeAttributes: { isRichText: { fieldName: 'isRichText' } } }
    ];
    error;
    isLoading = false;
    offset = 0;
    limitRows = 50;
    noMoreData = false; 
    tableEndMessage = 'No more data to load';
    MAX_ROWS = 2000;
    objectApiName;
    objectLabel;
    objectIcon;

    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    wiredRecord({ error, data }) {
        if (data) {
            this.objectApiName = data.apiName;
            if (!this.objectApiName.includes('__c')) {
                this.objectIcon = `standard:${this.objectApiName.toLowerCase()}`;
            } else {
                this.objectIcon = `standard:related_list`;
            }
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectLabel = data.label;
        } else if (error) {
            console.error(error);
        }
    }

    connectedCallback() {
        this.loadRecords();
    }

    loadRecords() {
        this.isLoading = true;
        fetchHistoryRecords({ parentId: this.recordId, offset: this.offset, limitRows: this.limitRows })
            .then(data => {
                if (
                    data.length < this.limitRows ||
                    this.offset >= this.MAX_ROWS
                ) {
                    this.noMoreData = true;
                }
                
                let dataMap = data.map(record => {
                    return {
                        ...record,
                        userUrl: `/${record.userId}`
                    };
                });
                let updatedRecords = [...this.historyRecords, ...dataMap];
                this.historyRecords = updatedRecords;
                this.offset += this.limitRows;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
            });
    }

    handleLoadMore(event) {
        if (this.isLoading || this.noMoreData) return;
        this.loadRecords();
    }
}