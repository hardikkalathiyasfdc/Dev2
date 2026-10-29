import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';

const IN_DEVELOPMENT = 'In Development';
const REVISIONS_NEEDED_YES = 'Yes';

export default class ImRequestRevision extends LightningElement {
    @api recordId;
    isSaving = false;

    // Values pushed into the hidden form fields so the LDS submit performs the send-back.
    get inDevelopmentStatus() {
        return IN_DEVELOPMENT;
    }

    get revisionsNeededYes() {
        return REVISIONS_NEEDED_YES;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleConfirm() {
        const form = this.template.querySelector('lightning-record-edit-form');
        const reasonField = this.template.querySelector('lightning-input-field[field-name="Revisions_Reason__c"]');
        if (!reasonField.reportValidity()) {
            return;
        }
        this.isSaving = true;
        form.submit();
    }

    handleSuccess() {
        this.isSaving = false;
        this.showToast('Success', 'Initiative sent back for revisions.', 'success');
        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(event) {
        this.isSaving = false;
        this.showToast('Error', this.getErrorMessage(event?.detail), 'error');
    }

    showToast(title, message, variant, mode = 'dismissible') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (error?.message) {
            return error.message;
        }
        if (error?.detail) {
            return error.detail;
        }
        return 'An unexpected error occurred.';
    }
}