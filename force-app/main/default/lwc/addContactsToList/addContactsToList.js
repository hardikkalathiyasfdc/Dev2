import { LightningElement, api } from 'lwc';
import addContactsToList from "@salesforce/apex/AddContactsToListController.addContactsToList";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class AddContactsToList extends NavigationMixin(LightningElement) {

    @api recordId;
    showListLookup = false;
    showListText = false;
    targetList =  '';
    isLoading = false;
    newList = false;

    listSearchConfig = JSON.stringify({
        primaryField: 'Name',
        primaryWeight: 100,
        convertedField: 'Converted_List_Name__c',
        convertedWeight: 80
    });
    listDisplayFields = ['Name', 'ListMemberCount__c','Event_Start_Date_Time__c'];
    listDisplayFieldPrefixes = ['', 'List Member Count', 'Event Start Date/Time'];
    filterClause = 'RecordType.DeveloperName != \'Organization\'';

    get listSelectionOptions() {
        return [
            { label: 'Existing List', value: 'existing' },
            { label: 'New List', value: 'new' },
        ];
    }

    connectedCallback () {
        console.log('record Id ::::: '+this.recordId);
    }

    radioChange(event) {
        let selectedValue = event.detail.value;
        console.log('selected ::::: '+selectedValue);
        if(selectedValue === 'existing') {
            this.showListLookup = true;
            this.showListText = false;
            this.newList = false;
        } else {
            this.showListLookup = false;
            this.showListText = true;
            this.newList = true;
        }
    }

    handleValueSelected(event) {
        const selectedIds = event.detail.selectedIds;
        this.targetList = selectedIds && selectedIds.length > 0 ? selectedIds[0] : '';
    }

    handleNewListNameChange(event) {
        let newListName = event.detail.value;
        this.targetList = newListName;
    }

    handleFinish() {
         this.isLoading = true;
        if (this.targetList === '' || this.targetList === undefined) {
            this.showToast('Please select an existing list or enter the name for a new list.');
            return;
        } 
       
        addContactsToList({
            "currentListId":this.recordId,
            "listValue": String(this.targetList),
            "newList": this.newList
        })
        .then((result) => {
            this.navigateToRecord();
        })
        .catch((error) => {
            this.isLoading = false;
            console.log(error);
        });
    }    

    showToast(message) {
        const event = new ShowToastEvent({
            title: 'Required Fields Missing!',
            variant: 'error',
            message: message,
        });
        this.dispatchEvent(event);
    }
    
    navigateToRecord() {
        console.log('asdasd ')
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Campaign',
                actionName: 'view'
            }
        });
    }
}