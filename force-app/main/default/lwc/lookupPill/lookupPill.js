import { LightningElement, api } from 'lwc';

export default class LookupPill extends LightningElement {
    @api record;
    @api displayField = 'Name';
    @api icon;
    @api disabled = false;

    get pillLabel() {
        if (!this.record) return '';
        if (this.record.fields && this.record.fields[this.displayField]) {
            return this.record.fields[this.displayField];
        }
        return '';
    }

    get recordId() {
        if (!this.record) return '';
        return this.record.Id || '';
    }

    handleRemove() {
        if (this.disabled) return;
        
        this.dispatchEvent(new CustomEvent('remove', {
            detail: { recordId: this.recordId }
        }));
    }
}