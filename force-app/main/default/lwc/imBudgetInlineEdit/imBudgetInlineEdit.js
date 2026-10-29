import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import hasPeriodLabelsEdit from '@salesforce/customPermission/IM_Budget_Period_Edit_Access';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBudgetPeriods from '@salesforce/apex/IMBudgetPeriodController.getBudgetPeriods';
import updateBudgetPeriods from '@salesforce/apex/IMBudgetPeriodController.updateBudgetPeriods';


const COLUMNS = [
    { label: 'Period Label', fieldName: 'Period_Label__c', editable: hasPeriodLabelsEdit ?? false },
    { label: 'Period Total', fieldName: 'Period_Total_Amount__c', type: 'currency', 
        typeAttributes: { 
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        } 
    },
];

export default class ImBudgetInlineEdit extends LightningElement {
    
    columns = COLUMNS;
    @api recordId;
    records;
    budgetPeriods;
    numberOfPeriods;
    draftValues = [];
    fields = ['id'];

    @wire(getRecord, { recordId: '$recordId',  fields: '$fields' })
    wiredRecordResult({ data, error }) {
        if (data) {
            refreshApex(this.budgetPeriods);
        } else if (error) {
            this.showErrorToast('Error loading Budget Periods');
        }
    }

    @wire(getBudgetPeriods, { budgetId: '$recordId' })
    wiredBudgetPeriods(result) {
        this.budgetPeriods = result;
        const { data, error } = result;
        if (data) {
            this.records = data;
            this.numberOfPeriods = this.records.length;
        } else if (error) {
            this.showErrorToast('Unable to fetch budget periods');
        }
    }

    handleSave(event) {
        event.preventDefault();
        this.draftValues = event.detail.draftValues;
        updateBudgetPeriods({ periodsToUpdate: this.draftValues })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated successfully',
                        variant: 'success'
                    })
                );
                refreshApex(this.budgetPeriods);
                this.draftValues = [];
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Records cannot be updated',
                        variant: 'error'
                    })
                );
            });
    }
    
    showErrorToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: 'Error',
			message: displayMessage,
			variant: 'error',
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}
}