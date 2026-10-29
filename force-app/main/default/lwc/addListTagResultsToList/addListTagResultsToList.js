import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecentlyViewed from '@salesforce/apex/AddListTagResultsToListController.getRecentlyViewed';
import addToExistingListAsync from '@salesforce/apex/AddListTagResultsToListController.addToExistingListAsync';
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';

export default class AddListTagResultsToList extends LightningElement {
    @api contactListTagData = [];
    @api contactSources = [];
    @api restrictedContactCount;
    selectedListId;
    listDisplayFields = ['Name', 'ListMemberCount__c', 'Event_Start_Date_Time__c'];
    listDisplayFieldPrefixes = ['', 'List Member Count', 'Event Start Date/Time'];
    listSearchFields = ['Name', 'Converted_List_Name__c'];
    listSearchConfig = JSON.stringify({
        primaryField: 'Name',
        primaryWeight: 100,
        convertedField: 'Converted_List_Name__c',
        convertedWeight: 80
    });
    disableNewRecord = false;
    selectedMemberStatus;
    keepExistingStatus;
    isLoading = false;
    maximumMemberCount;

    get shallDisableSubmitButton() {
        return this.selectedListId == undefined || 
               this.selectedListId == '';
    }

    handleCloseModal() {
        this.dispatchEvent(new CustomEvent('closemodal', {}));
    }

    handleLookupChange(event) {
        const selectedIds = event.detail.selectedIds;
        this.selectedListId = selectedIds && selectedIds.length > 0 ? selectedIds[0] : undefined;
    }

    handleMemberStatusChange(event) {
        this.selectedMemberStatus = event.detail.value;
    }

    handleExistingMemberStatusChange(event) {
        this.keepExistingStatus = event.detail.value == 'keep';
    }

    handleAddToList() {
        this.isLoading = true;
        this.checkForErrors();
        setTimeout(() => {
            this.addToExistingListAsync();
        }, 100);
        setTimeout(() => {
            this.isLoading = false;
            this.showNotification('List Creation', 'You will receive an email once all contacts have been added to the list.', 'success', 'dismissable');
            this.handleCloseModal();
        }, 10000);
    }

    addToExistingListAsync() {
        const contactSourcesMap = {};
        this.contactSources.forEach(item => {
            contactSourcesMap[item.key] = item.value.replaceAll('\n', ';');
        });
        addToExistingListAsync({
            "campaignId" : this.selectedListId,
            "memberStatus" : this.selectedMemberStatus,
            "keepExistingStatus" : this.keepExistingStatus,
            "contactIds" : this.contactListTagData,
            "contactSourceMap" : contactSourcesMap
        }).then((result) => {
            if (this.restrictedContactCount > 0 && !hasPrivateNameFieldsAccess) {
                let message = `\n\n You've encountered a problem with some of the records you selected ` + this.restrictedContactCount + ` records are not exporting). ` +
                    `Please contact brmpartnerships@bloomberg.org for further assistance. \n\n`;
                this.showNotification('Warning', message, 'warning', 'sticky');
            }
        }).catch((error) => {
            console.log(error);




        });

    }

    showNotification(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
        });
        this.dispatchEvent(evt);
    }

    checkForErrors() {
        if (!this.selectedListId) {
            console.warn('No list selected');
        }
    }

    get options() {
        return [            
            { label: 'Sent', value: 'Sent' },
            { label: 'Responded', value: 'Responded' },
        ];
    }

    get existingCampaignStatusOptions() {
        return [
            { label: 'Keep member status', value: 'keep' },
            { label: 'Overwrite member status', value: 'overwrite' },
        ];
    }
}