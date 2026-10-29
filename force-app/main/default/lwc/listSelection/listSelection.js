import { LightningElement, track, api } from 'lwc';
import getRSVPCount from '@salesforce/apex/GenerateBioReportAuraCtrl.getRSVPCount';
import getContactWithPhotoCount from '@salesforce/apex/GenerateBioReportAuraCtrl.getContactWithPhotoCount';
import getRestrictedContactCount from '@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedContactCount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class listSelection extends LightningElement {

    error;
    includeListsEvents = true;
    includeRSVPMembers = true;
    showSpinner = false;
    listSearchConfig = JSON.stringify({
        primaryField: 'Name',
        primaryWeight: 100,
        convertedField: 'Converted_List_Name__c',
        convertedWeight: 80
    });
    listDisplayFields = ['Name', 'ListMemberCount__c','Event_Start_Date_Time__c'];
    listDisplayFieldPrefixes = ['', 'List Member Count', 'Event Start Date/Time'];
    filterClause = 'RecordType.DeveloperName != \'Organization\'';
    selectedId;
    showWarning = false;

    @api clearSelection() {
        const lookup = this.template.querySelector('c-generic-lookup');
        if (lookup) {
            lookup.clearSelection();
        }
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    handleLookupChange(event) {
        const selectedIds = event.detail.selectedIds;
        if (!selectedIds || !selectedIds.length) {
            return;
        }
        const selectedId = selectedIds[0];
        this.selectedId = selectedId;
        getRestrictedContactCount({ listId: selectedId })
            .then(result => {
                if (result > 0) {
                    this.showWarning = true;
                }
            });

            this.getPhotoWithContactCount(selectedId);

    }

    getPhotoWithContactCount(selectedId){
        getContactWithPhotoCount({ listId: selectedId })
            .then(result => {
                let photoCount = result;
                let res = {};
                res.count = photoCount;
                res.listId = selectedId;
                res.includeListsEvents = this.includeListsEvents;
                res.includeRSVPMembers = this.includeRSVPMembers;
                if (this.includeRSVPMembers) {
                    getRSVPCount({ listId: selectedId })
                        .then(result => {
                            if (result == 0) {
                                this.template.querySelector('c-generic-lookup').clearSelection();
                                this.showToast('Error', 'There are no guests who RSVP\'d Yes in this selected list. Please check your search criteria.', 'error');
                            } else {
                                if (this.showWarning) {
                                    this.showToast('Warning', 'Your results contain ' + result + ' Private Contact(s).', 'Warning');
                                }
                                this.dispatchEvent(new CustomEvent('selected', { detail: res }));
                            }

                        });
                } else {
                    if (this.showWarning) {
                        this.showToast('Warning', 'Your results contain ' + result + ' Private Contact(s).', 'Warning');
                    }
                    this.dispatchEvent(new CustomEvent('selected', { detail: res }));
                }
            })
            .catch(error => {
                this.error = error;
            });
    }

    handleCheckboxChange(event) {
        console.log('====== ' + event.detail.checked);
        this.includeListsEvents = event.detail.checked;
        this.dispatchEvent(new CustomEvent('checked', { detail: this.includeListsEvents }));
    }

    handleRSVPChange(event) {
        console.log('====== ' + event.detail.checked);
        this.includeRSVPMembers = event.detail.checked;
        if(this.includeRSVPMembers && this.selectedId){
           this.getPhotoWithContactCount(this.selectedId);
        }
        this.dispatchEvent(new CustomEvent('rsvpchecked', { detail: this.includeRSVPMembers }));
    }
}