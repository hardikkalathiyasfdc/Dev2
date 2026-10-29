import { LightningElement, api } from 'lwc';

export default class CustomLookup extends LightningElement {
    @api childObjectApiName = 'CampaignMember'; //Contact is the default value
    @api targetFieldApiName = 'CampaignId'; //AccountId is the default value
    @api fieldLabel = 'Select Existing List';
    @api disabled = false;
    @api value;
    @api required = false;

    handleChange(event) {
        // Creates the event
        const selectedEvent = new CustomEvent('valueselected', {
            detail: event.detail.value
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }

    @api isValid() {
        if (this.required) {
            this.template.querySelector('lightning-input-field').reportValidity();
        }
    }
}