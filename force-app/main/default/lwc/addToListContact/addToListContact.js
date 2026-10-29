import { LightningElement, wire, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkGuestInList from '@salesforce/apex/ContactAddToListAuraCtrl.checkGuestInList';
import createListMember from '@salesforce/apex/ContactAddToListAuraCtrl.createListMember';

export default class addToListContact extends LightningElement {
    @api recordId;
    selectedId;
    allResult;
    btnDisabled = true;
    errMsg;
    campaignDisplayFields = ['Name', 'ListMemberCount__c', 'Event_Start_Date_Time__c'];
    campaignDisplayFieldPrefixes = ['', 'List Member Count', 'Event Start Date/Time'];
    campaignSearchFields = ['Name', 'Converted_List_Name__c'];
    campaignSearchConfig = JSON.stringify({
        primaryField: 'Name',
        primaryWeight: 100,
        convertedField: 'Converted_List_Name__c',
        convertedWeight: 80
    });
    filterClause = 'RecordType.DeveloperName != \'Organization\'';

    @wire(checkGuestInList, {
        contactId: '$recordId',
        listId: '$selectedId'
    }) wireCheckGuestInList(result) {
        this.allResult = result;
        if (result && result.data === true) {
            this.btnDisabled = true;
            this.errMsg = 'The Contact is already in selected List. Please select another list.';
        } else {
            this.errMsg = '';
        }
    }

    handleListUpdate(event) {
        let selectedListIds = event.detail.selectedIds;
        if(!selectedListIds) {
            this.selectedId = null;
            this.btnDisabled = true;
        } else {
            this.selectedId = selectedListIds[0];
            this.btnDisabled = false;
        }
        refreshApex(this.allResult);
    }

    saveCampaignMember() {
        createListMember({
            contactId: this.recordId,
            listId: this.selectedId
        }).then(() => {
            this.showToast('Success', 'The Contact is added into list successfully.', 'success');
            this.closeAction();
        }).catch(error => {
            this.errMsg = error.body.message;
        });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}