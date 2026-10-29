import { LightningElement, api, track  } from 'lwc';

import { createRecord } from 'lightning/uiRecordApi';

export default class CloneRecord extends LightningElement {
    @api recordId;
    @track recordFields = [];  // Holds field data with names and values
    @track clonedRecordId;
    objectApiName = 'Campaign';

    async connectedCallback() {
        
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.field;
        const newValue = event.target.value;
        this.recordFields = this.recordFields.map(field =>
            field.fieldName === fieldName ? { ...field, value: newValue } : field
        );
    }

    handleSave() {
        const fields = {};
        this.recordFields.forEach(field => {
            fields[field.fieldName] = field.value;
        });

        createRecord({
            apiName: this.objectApiName,
            fields
        })
            .then(record => {
                this.clonedRecordId = record.id;
            })
            .catch(error => {
                console.error('Error creating cloned record:', error);
            });
    }
}