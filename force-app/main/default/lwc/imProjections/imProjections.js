import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { refreshApex } from "@salesforce/apex";
import { updateRecord } from "lightning/uiRecordApi";
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getErrorMessages } from 'c/utils';

const columns = [
    { label: 'Year', fieldName: 'Year__c', hideDefaultActions:true, editable: true },
    { label: 'Amount', fieldName: 'Amount__c', hideDefaultActions:true, editable: true, type: 'currency', 
        typeAttributes: {minimumFractionDigits: '0'}, 
        cellAttributes: {alignment: 'left'}
    }
];

const INITIATIVE_FIELDS = ['IM_Initiative__c.Proposed_Amount__c'];

export default class ImProjections extends LightningElement {
    @api recordId;
    columns = columns;
    error;
    errors;
    data = [];
    draftValues = [];
    cardIcon = 'custom:custom11';
    cardTitle = 'Projections';
    isLoading = true;
    proposedAmount = 0;

    @wire(getRecord, {recordId: '$recordId', fields: INITIATIVE_FIELDS})
    initiativeInfo({ data }) {
        this.proposedAmount = data?.fields?.Proposed_Amount__c?.value ?? 0;
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Projections__r',
        fields: ['IM_Projections__c.Id', 'IM_Projections__c.Year__c', 'IM_Projections__c.Amount__c'],
      })
      listInfo({ error, data }) {
        this.isLoading = false;
        if (data) {
          this.records = data.records;
          this.error = undefined;
          let tempRecs = [];
          data.records.forEach(item => {
            let tempRec = Object.assign( {}, item.fields );
            tempRec.Id = item.fields.Id.value;
            tempRec.Year__c = item.fields.Year__c.value;
            tempRec.Amount__c = item.fields.Amount__c.value;
            tempRecs.push( tempRec );
            });
        this.data = tempRecs;
        this.cardTitle = 'Projections (' + this.data.length + ')';
        } else if (error) {
          this.error = error;
          this.records = undefined;
          this.data = [];
        }
    }

    handleCellChange(event) {
        this.errors = {};
        let changedValue = event.detail.draftValues[0];
        
        //validation for Year
        if(changedValue.hasOwnProperty('Year__c')) {
            const regex = /^\d{4}$/; // Matches exactly 4 digits
            if(!regex.test(changedValue.Year__c)) {
                let tempRow = {};
                tempRow[changedValue.Id] = {
                    messages: ['Please enter valid year.'],
                    fieldNames: ['Year__c'],
                    title: 'Error'
                };
                this.errors = {
                    rows: tempRow
                }
            }
        }
    }

    async handleSave(event) {
        event.preventDefault();
        this.draftValues = event.detail.draftValues;

        this.errors = {};
        let isError = false;
        //validation for Year
        const updatedFields = event.detail.draftValues;
        let tempRow = {};
        for (let changedValue of updatedFields) {
            let errorMessages = [];
            let fieldNames = [];

            if(changedValue.hasOwnProperty('Year__c')) {
                const regex = /^\d{4}$/; // Matches exactly 4 digits
                if(!regex.test(changedValue.Year__c)) {
                    errorMessages.push('Please enter valid year.');
                    fieldNames.push('Year__c');
                }
            }

            if ( errorMessages.length > 0 ) {
                isError = true;
                tempRow[changedValue.Id] = {
                    messages: errorMessages,
                    fieldNames: fieldNames,
                    title: 'Error'
                };
            }
        }

        if(isError) {
            this.errors = {rows: tempRow}
            return;
        }

        const updatedTotal = this.calculateTotalWithDrafts(updatedFields);
        const chkProposedAmount = Number(this.proposedAmount || 0);
        if(updatedTotal > chkProposedAmount) {
            this.showToast('Error', 
                    'Total of all projections ( $' + updatedTotal + ' ) cannot exceed initiative proposed amount ( $' + chkProposedAmount + ' ).', 
                    'error');
            return;
        }

        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);
            return { fields };
        });
        this.draftValues = [];

        try {
            // Update all records in parallel
            const recordUpdatePromises = records.map((record) => updateRecord(record));
            await Promise.all(recordUpdatePromises);

            this.showToast('Success', 'Projections updated successfully.', 'success');

                // Display fresh data in the datatable
            await refreshApex(this.data);
        } catch (error) {
            console.log('ERROR while saving the record: ' + JSON.stringify(error));
            let errorMessages = getErrorMessages(error);
            if (errorMessages.length > 0) {
                let errorMessage = errorMessages[0];
                this.showToast('Error', errorMessage, 'error');
            }
        }
    }

    handleCancel(event) {
        event.preventDefault();
        this.draftValues = [];
    }

    calculateTotalWithDrafts(updatedFields) {
        const amountsById = {};
        this.data.forEach((row) => {
            amountsById[row.Id] = Number(row.Amount__c || 0);
        });
        updatedFields.forEach((draft) => {
            if(draft.hasOwnProperty('Amount__c')) {
                amountsById[draft.Id] = Number(draft.Amount__c || 0);
            }
        });
        // Round to two decimal places for currency-style amounts.
        const sum = Number(Object.values(amountsById).reduce((total, amount) => total + amount, 0));
        if(!Number.isFinite(sum)) {
            return 0;
        }
        return Math.round(sum * 100) / 100;
    }

    get showDataTable() {
        return !this.isLoading && this.data && this.data.length > 0;
    }

	showToast(title, message, variant) {
		const evt = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant,
		});
		this.dispatchEvent(evt);
	}
}