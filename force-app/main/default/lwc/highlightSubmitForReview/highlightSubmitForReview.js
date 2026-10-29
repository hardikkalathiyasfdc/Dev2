import { LightningElement, api } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import validateHighlight from '@salesforce/apex/HighlightSubmitController.validateHighlight';
import submitForReview from '@salesforce/apex/HighlightSubmitController.submitForReview';

const CONFIRM_MESSAGE =
    'This highlight will be sent for review and you will not be able to edit it while it is pending. Do you want to submit it now?';

export default class HighlightSubmitForReview extends LightningElement {
    _recordId;
    hasValidated = false;

    isWorking = true;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value && !this.hasValidated) {
            this.hasValidated = true;
            this.runFlow();
        }
    }

    async runFlow() {
        if (!this._recordId) {
            return;
        }

        this.isWorking = true;

        try {
            const result = await validateHighlight({ highlightId: this._recordId });

            if (!result.isValid) {
                this.failAndClose(result.errors);
                return;
            }

            const confirmed = await LightningConfirm.open({
                label: 'Confirmation',
                message: CONFIRM_MESSAGE,
                theme: 'warning',
                variant: 'header'
            });

            if (!confirmed) {
                this.dispatchEvent(new CloseActionScreenEvent());
                return;
            }

            const submitResult = await submitForReview({ highlightId: this._recordId });

            if (!submitResult.isValid) {
                this.failAndClose(submitResult.errors);
                return;
            }

            notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Submitted for review',
                    message: 'This highlight has been sent to the review queue.',
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.failAndClose([this.reduceError(error)], 'Not submitted');
        }
    }

    failAndClose(errors, title) {
        const messages =
            errors && errors.length ? errors : ['This highlight cannot be submitted yet.'];

        messages.forEach((message, index) => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: title || this.errorTitle(index, messages.length),
                    message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        });

        this.dispatchEvent(new CloseActionScreenEvent());
    }

    errorTitle(index, total) {
        return total === 1
            ? 'One thing needs your attention'
            : `Needs your attention (${index + 1} of ${total})`;
    }

    reduceError(error) {
        if (error && error.body) {
            if (Array.isArray(error.body)) {
                return error.body.map((e) => e.message).join(', ');
            }
            if (error.body.message) {
                return error.body.message;
            }
        }
        return 'Something went wrong. Try again, or contact your administrator.';
    }
}