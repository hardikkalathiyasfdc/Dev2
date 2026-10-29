import { LightningElement, api } from 'lwc';
import fetchLookUpValues from '@salesforce/apex/SObjectMultiSelectionController.fetchLookUpValues';
import fetchLookUpAllValues from '@salesforce/apex/SObjectMultiSelectionController.fetchLookUpAllValues';

export default class SObjectMultiSelection extends LightningElement {
    @api title;
    @api objectApiName;
    @api iconName = 'standard:contact';
    @api recordTypeId;
    _filterData;
    @api
    get filterData() {
        return this._filterData;
    }
    set filterData(value) {
        if (value !== this._filterData) {
            this._filterData = value;
            this.fetchLookUpAllValues();
            this.displayRecords = false;
        }
    }
    @api placeholder = 'Search...';
    @api selectedContacts = [];
    displayRecords = false;
    originalList;
    availableContacts;
    allRecords;
    error;
    searchString;

    connectedCallback() {
        this.fetchLookUpAllValues();
        this.displayRecords = false;
    }

    fetchLookUpAllValues() {
        fetchLookUpAllValues({
            'objectAPIName': this.objectApiName,
            'recordTypeId': this.recordTypeId,
            'filterData': this.filterData
        }).then(result => {
            this.allRecords = result;
            this.availableContacts = result;
            this.error = undefined;

            const validIds = new Set(result.map(rec => rec.Id));
            const filteredSelected = this.selectedContacts.filter(rec => validIds.has(rec.Id));

            if (filteredSelected.length !== this.selectedContacts.length) {
                this.selectedContacts = [...filteredSelected];
                this.dispatchEvent(new CustomEvent('selected', { detail: this.selectedContacts }));
            }
        }).catch(error => {
            this.error = error;
            this.allRecords = undefined;
        });
    }

    changeContactSearch(event) {
        let searchString = event.target.value;
        if (searchString.length < 2) {
            this.onblur();
            return;
        }
        this.searchString = searchString;
        this.searchContacts();
    }

    @api clearSelection() {
        this.selectedContacts = [];
    }

    searchContacts() {
        fetchLookUpValues({
            'searchKeyWord': this.searchString,
            'excludeIds': this.selectedContacts,
            'objectAPIName': this.objectApiName,
            'recordTypeId': this.recordTypeId,
            'filterData': this.filterData
        }).then(result => {
            this.availableContacts = result;
            this.error = undefined;
            this.onfocus();
        }).catch(error => {
            this.error = error;
            this.availableContacts = undefined;
        });
    }

    removeSelection(event) {
        let selectedRowId = event.currentTarget.id.split('-')[0];
        this.selectedContacts =
            this.selectedContacts.filter(element => element.Id !== selectedRowId);
        this.dispatchEvent(new CustomEvent('removed', { detail: this.selectedContacts }));
    }

    getSelectedRows(event) {
        let selectedRowId = event?.target?.id?.split('-')[0];
        if (selectedRowId) {
            let selected = {};
            this.availableContacts.forEach(item => {
                if (item.Id === selectedRowId) selected = item;
            });
            if (this.selectedContacts === undefined) {
                this.selectedContacts = [];
            }
            let found = this.selectedContacts.find(element => element.Id === selected.Id);
            if (found === undefined) {
                this.selectedContacts = [...this.selectedContacts, selected];
            }

            this.dispatchEvent(new CustomEvent('selected', { detail: this.selectedContacts }));
        }
        this.searchString = '';
        this.template.querySelector('[data-id="lookup-pill"]').classList.add('slds-is-close');
        this.template.querySelector('[data-id="lookup-pill"]').classList.remove('slds-is-open');
        this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-close');
        this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-open');
        this.availableContacts = undefined;
        this.displayRecords = false;
    }

    onfocus() {
        this.displayRecords = true;
        if (!this.availableContacts && this.allRecords) {
            this.availableContacts = this.allRecords;
        }
        if (this.displayRecords) {
            this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-open');
            this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-close');
        }
    }

    onblur() {
        this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-close');
        this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-open');
    }

    handleFocus() {
        if (!this.displayRecords) {
            this.displayRecords = true;
        }
        if (!this.availableContacts && this.allRecords) {
            this.availableContacts = this.allRecords;
        }
        setTimeout(() => {
            this.onfocus();
            document.addEventListener('click', this.handleOutsideClick.bind(this));
        }, 0);
    }

    handleOutsideClick(event) {
        if (!(event.target instanceof Node && this.template.contains(event.target))) {
            this.displayRecords = false;
            this.template.querySelector('[data-id="searchRes"]').classList.add('slds-is-close');
            this.template.querySelector('[data-id="searchRes"]').classList.remove('slds-is-open');
            document.removeEventListener('click', this.handleOutsideClick.bind(this));
        }
    }
}