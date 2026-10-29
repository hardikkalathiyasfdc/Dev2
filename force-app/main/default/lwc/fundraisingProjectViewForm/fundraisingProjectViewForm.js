import { LightningElement, api, wire, track} from 'lwc';
import getOrganizationChildRecords from '@salesforce/apex/FundraisingProjectController.getchildrecords';
import checkFundraisingCodingAccess from '@salesforce/apex/FundraisingProjectController.checkFundraisingCodingAccess';
import PledgePageRefresh from '@salesforce/messageChannel/PledgePageRefresh__c';

import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import { refreshApex } from '@salesforce/apex';
export default class FundraisingProjectViewForm extends LightningElement {
     @api recordId;
     objectApiName = 'Fundraising_Project__c';
     activeSections = ['A', 'B','C','D','E'];
     @track organizationsData;
    @track sortBy;
    @track sortDirection;
    hasFundraisingCodingAccess;
      
 publisherMessage = '';
    subscription = null;
    @wire(MessageContext)
    messageContext;

     organizationColumns = [
        
        {
            label: 'Organization Name',
            fieldName: 'organizationUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'organizationName'
                },
                target: '_blank'
            }
        },
        {
            label: 'Recipient - Soft Credit',
            fieldName: 'RecipientSoftCreditUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'RecipientSoftCreditName'
                },
                target: '_blank'
            }
        },
        {
            label: 'Number of pledges',
            fieldName: 'Number_of_pledges__c',
            type: 'number',
            sortable: true
        },
        {
            label: 'Total pledge amount (USD)',
            fieldName: 'Total_pledge_amounts__c',
            type: 'number',
            sortable: true
        }
    ];
    connectedCallback() {
        this.getOrganizations(this.recordId);
        this.subscribeToMessageChannel( this.recordId);
        this.checkFundraisingCodingAccess();
    }
     // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel(recordId) {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                PledgePageRefresh,
                (message) => this.handleMessage(recordId),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        console.log('TestVeeeeeff',message);
           this.getOrganizations(this.recordId);
        return refreshApex(this.recordId); 
        
    }
    
    getOrganizations(recordId) {
          getOrganizationChildRecords({ recordId: recordId })
               .then((result) => {
               if (result) {
                    this.organizationsData = [];
                    console.log(result.recipients);
                    this.organizationsData = result.recipients ? this.organizationsRowData(result.recipients) : [];
                    this.donorsStyle = this.organizationsData && this.organizationsData.length > 4 ? 'height: 250px;' : '';
               }
               })
               .catch(error => {
               console.log('get child records error >>>>>', error);
               })
    }

    organizationsRowData(data) {
        var organizations = [];
        data.forEach(rec => {
           
            let objRec = Object.assign({}, rec);
            objRec['organizationName'] = '';
            objRec['organizationUrl'] = '';
            objRec['RecipientSoftCreditUrl'] = '';
            objRec['RecipientSoftCreditName'] = '';
            objRec['organizationName'] = rec.Organization__r.Name;
            objRec['organizationUrl'] = '/' + rec.Organization__c;
            if(rec.Recipient_Soft_Credit__c!=null) { 
                objRec['RecipientSoftCreditName'] = rec.Recipient_Soft_Credit__r.Name ;
                objRec['RecipientSoftCreditUrl'] = '/' + rec.Recipient_Soft_Credit__c ;
            }
            organizations.push(objRec);
        });
        
        return organizations;
    }

    doSorting(event) {
        console.log('1 :::::::: ');
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        let sortedBy;

        if(this.sortBy === 'organizationUrl') {
            console.log('1.1 :::::::: ');
            sortedBy = 'organizationName';
        } else {
            console.log('1.2 :::::::: ');
            sortedBy = this.sortBy;
        }
        console.log('2 :::::::: ');
        this.sortData(sortedBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        console.log('3.1 :::::::: '+fieldname);
        let parseData = JSON.parse(JSON.stringify(this.organizationsData));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        if(fieldname === 'Number_of_pledges__c' || fieldname === 'Total_pledge_amounts__c') {
            parseData.sort((x, y) => {
                x = keyValue(x) ? keyValue(x) : ''; // handling null values
                y = keyValue(y) ? keyValue(y) : '';
                return isReverse * ((x > y) - (y > x));
            });
        } else {
            parseData.sort((x, y) => {
                x = keyValue(x) ? keyValue(x).toLowerCase() : ''; // handling null values
                y = keyValue(y) ? keyValue(y).toLowerCase() : '';
                return isReverse * ((x > y) - (y > x));
            });
        }
        
        this.organizationsData = parseData;
        this.organizationsData = [...this.organizationsData];
    }

    checkFundraisingCodingAccess() {
        checkFundraisingCodingAccess()
            .then((result) => {
                if (result) {
                    this.hasFundraisingCodingAccess = result;
                }
            }).catch(error => {
                console.log('checkFundraisingCodingAccess error', error);
            })
    }
}