import { LightningElement, api } from 'lwc';

export default class LookupResultItem extends LightningElement {
    @api record;
    @api displayFields = [];
    @api displayFieldPrefixes = [];
    @api icon = 'standard:default';
    @api isSelected = false;

    get optionClass() {
        let classes = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta';
        if (this.isSelected) {
            classes += ' slds-is-selected';
        }
        return classes;
    }

    get primaryField() {
        if (!this.record || !this.record.fields) return '';
        
        if (this.displayFields && this.displayFields.length > 0) {
            const value = this.record.fields[this.displayFields[0]] || '';
            const prefix = this.displayFieldPrefixes && this.displayFieldPrefixes.length > 0 
                ? this.displayFieldPrefixes[0] 
                : '';
            return prefix ? `${prefix}: ${value}` : value;
        }
        
        return '';
    }

    get hasSecondaryFields() {
        return this.secondaryFieldValues && this.secondaryFieldValues.length > 0;
    }

    get secondaryFieldValues() {
        if (!this.record || !this.record.fields || !this.displayFields || this.displayFields.length <= 1) {
            return [];
        }
        
        return this.displayFields.slice(1).map((field, index) => {
            const value = this.record.fields[field];
            const prefix = this.displayFieldPrefixes && this.displayFieldPrefixes.length > index + 1 
                ? this.displayFieldPrefixes[index + 1] 
                : '';
            if (value === null || value === undefined || value === '') return null;
            const displayValue = prefix ? `${prefix}: ${value}` : value;
            return {
                key: field + '-' + index,
                value: displayValue
            };
        }).filter(item => item !== null);
    }

    handleSelect() {
        this.dispatchEvent(new CustomEvent('select', {
            detail: { record: this.record }
        }));
    }
}