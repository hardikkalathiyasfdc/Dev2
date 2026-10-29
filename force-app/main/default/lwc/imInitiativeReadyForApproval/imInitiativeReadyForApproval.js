import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';
import markReadyForApproval from '@salesforce/apex/IMInitiativeReadyForApprovalController.markReadyForApproval';

export default class InitiativeReadyForApproval extends LightningElement {
    @api recordId;
    isExecuting = false;

    @api
    async invoke() {
        if (this.isExecuting) {
            return;
        }
        this.isExecuting = true;

        try {
            const invalidFields = await markReadyForApproval({ recordId: this.recordId });

            if (invalidFields && invalidFields.length > 0) {
                this.showToast(
                    'Cannot mark Ready for Approval',
                    'Please complete the following: ' + invalidFields.join(', '),
                    'error',
                    'sticky'
                );
                return;
            }

            this.showToast('Success', 'Initiative status updated to Ready for Approval.', 'success');
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.dispatchEvent(new RefreshEvent());
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error', 'sticky');
        } finally {
            this.isExecuting = false;
        }
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
        return error?.message || 'An unexpected error occurred.';
    }
}