import { LightningElement, api } from 'lwc';

export default class LookupPills extends LightningElement {
    @api selectedRecords = [];
    @api displayField = 'Name';
    @api icon;
    @api disabled = false;

    handleRemove(event) {
        this.dispatchEvent(new CustomEvent('remove', {
            detail: { recordId: event.detail.recordId }
        }));
    }
}