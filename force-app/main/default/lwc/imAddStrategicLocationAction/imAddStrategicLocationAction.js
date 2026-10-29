import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ImAddStrategicLocationAction extends LightningElement {
    @api recordId;
    _missingContextChecked = false;

    renderedCallback() {
        // Guard against invalid launches from a non-record context.
        // This is a quick action for IM_Initiative__c and must receive a valid record Id.
        if (this._missingContextChecked || this.recordId) {
            return;
        }

        this._missingContextChecked = true;

        setTimeout(() => {
            if (!this.recordId) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Missing record context',
                        message: 'This action must be launched from an Initiative record page.',
                        variant: 'error'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }, 300);
    }

    get hasRecordId() {
        return Boolean(this.recordId);
    }

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleStatusChange(event) {
        const status = event.detail.status;

        // Close the action after the flow completes and show a toast only when the create step succeeded.
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            const outputVariables = event.detail.outputVariables || [];
            const successOutput = outputVariables.find(
                (output) => output.name === 'Was_Create_Successful'
            );

            if (successOutput && successOutput.value === true) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Strategic Location request saved successfully.',
                        variant: 'success'
                    })
                );
            }

            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
}