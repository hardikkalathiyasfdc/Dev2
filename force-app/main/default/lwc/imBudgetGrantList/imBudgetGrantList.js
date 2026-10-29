import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedRecords from '@salesforce/apex/IMBudgetGrantListController.getRelatedBudgetGrants';
const RELATED_LIST_HEADER = 'Participating Budgets';
const COLUMNS = [
    { label: 'Initiative',
        fieldName: 'nameUrl',
        type: 'url',
        typeAttributes: {label: { fieldName: 'InitiativeName' }, target: '_blank'},
        sortable: true
    },
    { label: 'Grant Name', fieldName: 'grantNameUrl', type: 'url', 
        typeAttributes: {label: { fieldName: 'grantName' }, target: '_blank'}, 
        sortable: true 
    },
    { label: 'Budget Amount (USD)', fieldName: 'Budget_Amount_USD__c', type: 'currency', sortable: true },
    { label: 'Budget Amount (Local)', fieldName: 'Budget_Amount_Local__c', type: 'currency',  
        typeAttributes: { currencyCode: {fieldName : 'Currency'} }, 
        sortable: true 
    }
];

export default class ImBudgetGrantList extends LightningElement {
    
    //Variables
    @api imGrant;
    columns = COLUMNS;
    relatedListHeader = RELATED_LIST_HEADER;
    data = [];
    error;
    sortBy;
    sortDirection;
    
    connectedCallback(){
        this.getRelatedBudgetGrants();
    }
    
    /*
    Description: get the related budget grant records based on the im grant id received
    Jira Story : IM-139
    */
    async getRelatedBudgetGrants(){
        try {
            const result = await getRelatedRecords({ imGrantId: this.imGrant.Id });
            if (result) {
                this.data = this.processGrants(result.budgetGrants, result.nonBudgetGrants);
                this.error = undefined;
            } else if(error){
                this.error = error;
                this.data = [];
                this.showErrorToast(JSON.stringify(this.error));
            }
        } catch (error) {
            this.error = error;
            this.data = [];
            this.showErrorToast(this.error);
        }
    }
    
    /*
    Description: Process Budget Grants & Non Budget Grants data to add additional fields for display
    Jira Story : IM-552
    */
    processGrants(budgetGrants, nonBudgetGrants){
        let data = [];
        budgetGrants?.map(record => {
            let grantName = record.Budget_Org__r.Organization__r.Name + (record.Unique_Identifier__c!=null ? '-'+record.Unique_Identifier__c : '');
            this.formData(data, record, grantName, record.Budget__r.Initiative__r);
        });
        nonBudgetGrants?.map(record => {
            let grantName = record.IM_Grant__r.Partner_Org__r.Name;
            this.formData(data, record, grantName, record.Initiative__r);
        });
        return data;
    }

    /*
    Description: Form a list of Budget & Non Budget Grants
    Jira Story : IM-552
    */
    formData(data, record, grantName, initiative) {
        if(record.IM_Grant__r.Currency__r.Name == 'USD'){
            this.columns = [...COLUMNS].filter(COLUMNS => COLUMNS.fieldName != 'Budget_Amount_Local__c');
        }
        data.push({
            ...record,
            grantName : grantName,
            nameUrl : `/${initiative.Id}`,
            grantNameUrl : `/${record.Id}`,
            InitiativeName : initiative.Name || null,
            Currency : record.IM_Grant__r.Currency__r.Name,
            Budget_Amount_Local__c : record.Budget_Amount_Local__c
        });
    }

    /*
    Description: Invoked when the user clicks on any column enabled for sorting
    Jira Story : IM-139
    */
    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }
    
    /*
    Description: Helper function to sort data
    Jira Story : IM-139
    */
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
    }
    
    
    /*
    Description: Show Error Toast Message when error occurs
    Jira Story : IM-139
    */
    showErrorToast(displayMessage) {
        const errorEvt = new ShowToastEvent({
            title: 'Failed to retrieve budget grants',
            message: displayMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(errorEvt);
    }
}