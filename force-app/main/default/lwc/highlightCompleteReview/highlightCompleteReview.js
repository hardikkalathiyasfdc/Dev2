import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { getErrorMessages } from 'c/utils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/Highlight_Interaction__c.Id';
import STATUS_FIELD from '@salesforce/schema/Highlight_Interaction__c.Status__c';

const REVIEWED = 'Reviewed';

export default class HighlightCompleteReview extends LightningElement {
	@api recordId;

	@api async invoke() {
		if (!this.recordId) {
			this.showToast('Error', 'Highlight record Id is missing.', 'error');
			return;
		}

		const fields = {};
		fields[ID_FIELD.fieldApiName] = this.recordId;
		fields[STATUS_FIELD.fieldApiName] = REVIEWED;

		try {
			await updateRecord({ fields });
			this.showToast('Success', 'Highlight has been successfully marked as Review Complete.', 'success');
		} catch (error) {
            let errorMessages = getErrorMessages(error);
            if (errorMessages.length > 0) {
                let errorMessage = errorMessages[0];
                this.showToast('Error', errorMessage, 'error');
            }
		}
	}

	showToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}
}