import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getContactReceivingDetails from '@salesforce/apex/Fundraising_Summary.getContactReceivingDetails';

const MAX_TILES = 3;

export default class ContactFundReceivingDetails extends NavigationMixin(LightningElement) {
    @api recordId;
    allRows = [];
    loaded = false;
    error;

    connectedCallback() {
        getContactReceivingDetails({ contactId: this.recordId })
            .then((records) => {
                this.allRows = (records || []).map((record) => ({
                    ...record,
                    recordUrl: `/${record.Id}`,
                    tileTitle: record.Pledge_Name_Amount__c || record.Name,
                    projectName: record.Fundraising_Effort__r?.Name,
                    projectUrl: record.Fundraising_Effort__c ? `/${record.Fundraising_Effort__c}` : null,
                    focusAreaInitiative: record.Fundraising_Effort__r?.Focus_Area_Initiative__c
                }));
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.allRows = [];
            })
            .finally(() => {
                this.loaded = true;
            });
    }

    get rows() {
        return this.allRows.slice(0, MAX_TILES);
    }

    get hasRecords() {
        return this.allRows.length > 0;
    }

    get displayCount() {
        return this.allRows.length > MAX_TILES ? `${MAX_TILES}+` : `${this.allRows.length}`;
    }

    get showViewAll() {
        return this.loaded && this.hasRecords;
    }

    handleRowAction(event) {
        if (event.detail.value === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.target.dataset.recordId,
                    objectApiName: 'Pledge__c',
                    actionName: 'view'
                }
            });
        }
    }

    handleViewAll(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Contact',
                relationshipApiName: 'Pledge_Recipient_Soft_Credits__r',
                actionName: 'view'
            }
        });
    }
}