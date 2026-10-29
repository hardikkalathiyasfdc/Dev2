import { LightningElement, api, track } from 'lwc';
import saveSearch from "@salesforce/apex/ListTagSavedSearchController.saveSearch";

export default class ListTagSavedSearchPopup extends LightningElement {
    @track searchName = '';
    showSaveAsNewCheckbox = true;

    _selectedSavedSearch;

    @api
    get selectedSavedSearch() {
        return this._selectedSavedSearch;
    }
    set selectedSavedSearch(value) {
        this._selectedSavedSearch = value;
        if (value && value.Name) {
            this.searchName = value.Name;
            this.showSaveAsNewCheckbox = true;
        } else {
            this.searchName = '';
            this.showSaveAsNewCheckbox = false;
        }
    }

    @api availableLists;          
    @api listIds;                 
    @api selectedAdditionalContacts; 
    @api selectedLists;           
    @api selectedTags;            
    @api showModal = false;     

    @track saveAsNew = false;
    @track isLoading = false;
    @track errorMessage;


    handleNameChange(event) {
        this.searchName = event.target.value;
    }

    handleCheckboxChange(event) {
        this.saveAsNew = event.target.checked;
        if (this.saveAsNew) {
            this.searchName = '';
        } else if (this._selectedSavedSearch && this._selectedSavedSearch.Name) {
            this.searchName = this._selectedSavedSearch.Name;
        }
    }

    handleSave() {        
        if (!this.searchName) {
            this.errorMessage = 'Please enter a search name.';
            return;
        }
        this.errorMessage = '';
        this.isLoading = true;
        saveSearch({
            searchName: this.searchName,
            availableLists: this.availableLists,
            listIds: this.listIds,
            selectedAdditionalContacts: this.selectedAdditionalContacts,
            selectedLists: this.selectedLists,
            selectedTags: this.selectedTags,
            isInsert: this.saveAsNew,
            searchId: this.saveAsNew ? null : (this._selectedSavedSearch ? this._selectedSavedSearch.Id : null)
        })
            .then(result => {
                console.log('1.3 ::::::::::::: ');
                this.dispatchEvent(new CustomEvent('saved', { detail: { savedSearchId: result } }));
                this.saveAsNew = false;
                this.showModal = false;
            })
            .catch(error => {
                console.error('Error saving search:', error);
                this.errorMessage = 'Error saving search. Please try again.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.showModal = false;
        this.saveAsNew = false;
    }    
}