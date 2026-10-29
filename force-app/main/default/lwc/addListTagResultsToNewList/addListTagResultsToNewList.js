import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CAMPAIGN_OBJECT from '@salesforce/schema/Campaign';
import NAME_FIELD from '@salesforce/schema/Campaign.Name';
import DESCRIPTION_FIELD from '@salesforce/schema/Campaign.Description';
import addToExistingListAsync from '@salesforce/apex/AddListTagResultsToListController.addToExistingListAsync';

export default class AddListTagResultsToNewList extends LightningElement {
    @api contactListTagData = [];
    @api contactSources = [];
    @api memberStatus = '';
    campaignObject = CAMPAIGN_OBJECT;
    nameField = NAME_FIELD;
    descriptionField = DESCRIPTION_FIELD;
    campaignId;
    isDisabled = false;
    isLoading = false;

    handleCloseModal() {
        let selectedEvent = new CustomEvent('closemodal', {});
        this.dispatchEvent(selectedEvent);
    }

    handleCampaignCreated(event) {
        this.isDisabled = true;
        this.isLoading = true;
        this.campaignId = event.detail.id;
        setTimeout(() => {
            this.addToExistingListAsync();
        }, 100);
        setTimeout(() => {
            this.isLoading = false;
            this.showToast();
            this.handleCloseModal();
        }, 10000);
    }

    addToExistingListAsync() {
        const contactSourcesMap = {};
        this.contactSources.forEach(item => {
            contactSourcesMap[item.key] = item.value.replaceAll('\n', ';');
        });
        addToExistingListAsync({
            "campaignId" : this.campaignId,
            "memberStatus" : this.memberStatus,
            "keepExistingStatus" : false,
            "contactIds" : this.contactListTagData,
            "contactSourceMap" : contactSourcesMap
        });
    }

    showToast() {
        const event = new ShowToastEvent({
            title: 'List Creation',
            message: 'You will receive an email once all contacts have been added to the list.',
            variant: 'success'
        });
        this.dispatchEvent(event);
    }
}