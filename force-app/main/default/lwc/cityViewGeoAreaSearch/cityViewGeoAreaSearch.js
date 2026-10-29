import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import fetchAllRecords from '@salesforce/apex/CityViewGeoAreaSearchController.fetchAllRecords';
import fetchLookUpAllValues from '@salesforce/apex/SObjectMultiSelectionController.fetchLookUpAllValues';
import getGeoAreaIds from '@salesforce/apex/CityViewFiltersController.getGeoAreaIds';
import CITY_VIEW_FILTERS_CHANNEL from '@salesforce/messageChannel/CityViewFiltersMessageChannel__c';
import FORM_FACTOR from '@salesforce/client/formFactor';

const MINIMAL_SEARCH_TERM_LENGTH = 2; // Min number of chars required to search
const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing to peform search
const HAS_FOCUS = 'slds-has-focus';
const DEFAULT_ICON = 'standard:default';
const KEYS = { ENTER: 13, ARROW_UP: 38, ARROW_DOWN: 40 };

export default class Lookup extends LightningElement {

    @api label; // Label for input field
    @api placeholder = 'Loading, please wait...'; // Placeholder for input field
    @api objectLabel; // Label for the object (used in the modal header)
    @api objectApiName; // API Name of the object from where to fetch the record (Required)
    @api fieldApiName; // Field API Name (Primary and Required)
    @api subFieldApiName; // Sub Field API Name (Secondary and Optional)
    @api iconName = DEFAULT_ICON; // Icon Name (e.g. standard:account)
    @api required = false;
    @api readOnly = false;
    @api isMultiSelect = false;
    showSpinner = true;
    @api selection = [];
    @api errors = [];
    _sortField;

    @track searchTerm = '';
    @track searchResults = [];
    @track hasFocus = false;
    @track isNewRecordForm = false;
    @track noRecordFound = false;
    cleanSearchTerm;
    blurTimeout;
    searchThrottlingTimeout;
    focusIndex = -1;

    formFactor = FORM_FACTOR;
    @api get selectedCity() {
        return this.value;
    }
    set selectedCity(data) {
        if (data && data.length > 0) {
            this.selection = JSON.parse(JSON.stringify(data));
        }
    }

    @api get sortField() {
        return this._sortField;
    }
    set sortField(data) {
        if (this._sortField != data) {
            this.searchTerm = "";
            this.searchResults = [];
        }
        this._sortField = data;
    }

    @api
    getSelection() {
        return this.selection;
    }

    get labelOfObject() {
        return (this.objectLabel ? this.objectLabel : (this.objectApiName ? this.objectApiName : 'Record'));
    }

    get isInputDisabled() {
        return this.hasSelection() || this.showSpinner;
    }
    closeModal() {
        this.isNewRecordForm = false;
    }

    _selectedFilter;
    @api get selectedFilter() {
        return this._selectedFilter;
    }

    set selectedFilter(value) {
        this.searchTerm = '';
        this._selectedFilter = value;
        this.handleClearSelection();
        const input = this.template.querySelector('input');
        if (input) {
            input.blur();
        }
        this.applyFilter();
    }

    @wire(MessageContext)
    messageContext;

    // This method is called every time selectedFilter is updated
    applyFilter() {
        this.searchResults = [];
        if (this._selectedFilter === 'City') {
            this.allResults = this.cityResults;
        } else if (this._selectedFilter === 'State') {
            this.allResults = this.stateResults;
        } else if (this._selectedFilter === 'Country') {
            this.allResults = this.countryResults;
        } else if (this._selectedFilter === 'BP Work') {
            this.allResults = this.initiativeResults;
        } else {
            this.allResults = [];
        }
    }

    filterInitiativesData = ` RecordType.DeveloperName IN ('Initiative', 'Standard') AND Active__c = true AND Publish_to_CityView__c = true AND Deleted__c = false `;
    allResults = [];
    cityResults = [];
    stateResults = [];
    countryResults = [];
    initiativeResults = [];
    @wire(fetchAllRecords, {
        sObjectName: 'Geo_Area__c',
        field: 'Name',
        subField: 'Geo_Name__c'
    }) wiredSearchResults({ error, data }) {
        if (data) {
            //  Filter based on RecordType.Name
            this.cityResults = data.filter(
                record => record.recordType && record.recordType === 'City'
            );
            this.stateResults = data.filter(
                record => record.recordType && record.recordType === 'State'
            );
            this.countryResults = data.filter(
                record => record.recordType && record.recordType === 'Country'
            );
            this.allResults = this.cityResults;
            const recordfetched = new CustomEvent('recordfetched', {});
            this.dispatchEvent(recordfetched);
            this.showSpinner = false;
        } else if (error) {
            this.allResults = [];
            this.cityResults = [];
            this.countryResults = [];
            this.showSpinner = false;
            console.error('Error fetching search results', error);
        }
    }

    connectedCallback() {
        this.fetchLookUpAllValues();
    }

    fetchLookUpAllValues() {
        fetchLookUpAllValues({
            'objectAPIName': 'Association__c',
            'recordTypeId': '',
            'filterData': this.filterInitiativesData
        }).then(result => {
            const mappedResults = result.map(item => ({
                id: item.Id,
                title: item.Name,
                focusArea: item.association.FC_Focus_Area__c,
                aka: item.association.AKA__c
            }));
            this.initiativeResults = mappedResults;
        }).catch(error => {
            this.error = error;
            this.initiativeResults = undefined;
        });
    }

    // INTERNAL FUNCTIONS
    updateSearchTerm(newSearchTerm) {
        this.clearFocus();
        this.searchTerm = newSearchTerm;

        // Compare clean new search term with current one and abort if identical
        const newCleanSearchTerm = newSearchTerm.trim().replace(/\*/g, '').toLowerCase();
        if (this.cleanSearchTerm === newCleanSearchTerm) {
            return;
        }

        // Save clean search term
        this.cleanSearchTerm = newCleanSearchTerm;

        // Ignore search terms that are too small
        if (newCleanSearchTerm.length < MINIMAL_SEARCH_TERM_LENGTH) {
            this.searchResults = [];
            return;
        }

        // Apply search throttling (prevents search if user is still typing)
        if (this.searchThrottlingTimeout) {
            clearTimeout(this.searchThrottlingTimeout);
        }

        this.searchThrottlingTimeout = setTimeout((self) => {
            // Send search event if search term is long enougth
            if (self.cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
                self.handleSearch(self.cleanSearchTerm, self.selection.map(element => element.id));
            }
            this.searchThrottlingTimeout = null;
        }, SEARCH_DELAY, this);
    }

    handleSearch(searchTerm, selectedIds) {
        try {
            const searchLower = searchTerm.toLowerCase();
            const regex = new RegExp(`(${searchTerm})`, 'ig');
            const sortByName = (a, b) => a.title.localeCompare(b.title);

            const source = this.allResults; // no deep clone needed since we don't mutate

            const filtetedAllResults1 = source
                .filter(r => r.subtitle && r.subtitle.toLowerCase().startsWith(searchLower))
                .sort(this._sortField === 'Name' ? sortByName : undefined);

            const filtetedAllResults2 = source
                .filter(r => r.subtitle && r.subtitle.toLowerCase().includes(searchLower))
                .sort(this._sortField === 'Name' ? sortByName : undefined);

            const filtetedAllResults3 = source
                .filter(r => r.title && r.title.toLowerCase().includes(searchLower))
                .sort(this.sortField === 'Name' ? sortByName : undefined);

            const filtetedAllResults4 = source
                .filter(r => r.aka && r.aka.toLowerCase().includes(searchLower))
                .sort(this.sortField === 'Name' ? sortByName : undefined);

            // Merge and keep unique by id
            let finalFilteredRecords = [
                ...filtetedAllResults4,
                ...filtetedAllResults1,
                ...filtetedAllResults2,
                ...filtetedAllResults3
            ].filter((value, index, self) =>
                index === self.findIndex(t => t.id === value.id)
            );

            // Remove subtitle property
            finalFilteredRecords = finalFilteredRecords.map(({ subtitle, ...rest }) => rest);

            // Highlight and filter aka
            finalFilteredRecords = finalFilteredRecords.map(item => {
                let titleDisplay = item.title;
                if (titleDisplay && this.searchTerm) {
                    titleDisplay = titleDisplay.replace(regex, `<strong class="extra-bold">$1</strong>`);
                }

                let akaDisplay = item.aka;
                if (akaDisplay && this.searchTerm) {
                    akaDisplay = akaDisplay
                        .split(',')
                        .map(str => str.trim())
                        .filter(val => val.toLowerCase().includes(searchLower))
                        .map(val => val.replace(regex, `<strong class="extra-bold">$1</strong>`))
                        .join(', ');
                }

                return {
                    ...item,
                    akaDisplay,
                    titleDisplay
                };
            });

            this.searchResults = finalFilteredRecords;
            this.showSpinner = false;
        }
        catch (err) {
            this.showSpinner = false;
        }
    }

    isSelectionAllowed() {
        if (this.isMultiSelect) {
            return true;
        }
        return !this.hasSelection();
    }

    hasResults() {
        return this.searchResults.length > 0;
    }

    hasSelection() {
        return this.selection.length > 0;
    }

    // EVENT HANDLING
    handleInput(event) {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }

        this.noRecordFound = false;
        this.updateSearchTerm(event.target.value);
    }

    saveLookupSelection(recordId) {
        if (recordId == 'create-new') {
            this.isNewRecordForm = this.isCreatable;
        } else {
            // Save selection
            let selectedItem = this.searchResults.filter(result => result.id === recordId);
            if (selectedItem.length === 0) {
                return;
            }
            selectedItem = selectedItem[0];
            const newSelection = [...this.selection];
            newSelection.push(selectedItem);
            this.selection = newSelection;
            // Reset search
            this.searchTerm = '';
            this.searchResults = [];
            // Notify parent components that selection has changed
            this.selectionValueEvt();
        }
    }

    handleResultEnter() {
        const dropdown = [...this.template.querySelectorAll('.dropdown')];
        if (dropdown && dropdown.length) {
            this.template.querySelector('input').blur();
            this.saveLookupSelection(dropdown[this.focusIndex].dataset.recordId);
        }
    }

    async fetchGeoAreaIds(selectedId) {
        var focusAreas = [];
        if (this._selectedFilter === 'BP Work') {
            let selectedGeoArea = this.initiativeResults.find(item => item.id === selectedId);
            focusAreas.push(selectedGeoArea.focusArea);
        }
        await getGeoAreaIds({
            selectedId: selectedId,
            searchBy: this._selectedFilter
        }).then(result => {
            let geoAreaIds = new Set();
            if (result && result.length > 0) {
                geoAreaIds = new Set(result);
            }
            if (this._selectedFilter != 'BP Work' && geoAreaIds.size === 0) {
                geoAreaIds.add(selectedId);
            }
            const payload = {
                geoAreaIds: Array.from(geoAreaIds),
                selectedFocusAreas: focusAreas,
                searchBy: this._selectedFilter,
                selectedId: selectedId
            };
            publish(this.messageContext, CITY_VIEW_FILTERS_CHANNEL, payload);
        }).catch(error => {
            console.error('Error fetching geo areas: ', JSON.stringify(error));
        });
    }

    handleResultClick(event) {
        if (this._selectedFilter === 'BP Work' || this._selectedFilter === 'Country' || this._selectedFilter === 'State') {
            let selectedId = event.currentTarget.dataset.recordid;
            this.fetchGeoAreaIds(selectedId);
        }
        this.saveLookupSelection(event.currentTarget.dataset.recordid);
    }

    handleComboboxClick() {
        // Hide combobox immediatly
        if (this.blurTimeout) {
            window.clearTimeout(this.blurTimeout);
        }
        this.hasFocus = false;
    }

    handleFocus() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        [...this.template.querySelectorAll('.dropdown')].map(li => li.firstChild.classList.remove(HAS_FOCUS));
        this.focusIndex = -1;
        this.hasFocus = true;
    }

    handleBlur() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        // Delay hiding combobox so that we can capture selected result
        this.blurTimeout = window.setTimeout((self) => {
            self.hasFocus = false;
            self.blurTimeout = null;
        }, 300, this);
    }

    handleRemoveSelectedItem(event) {
        const recordId = event.currentTarget.name;
        this.selection = this.selection.filter(item => item.id !== recordId);
        this.selectionValueEvt();
    }

    @api
    handleClearSelection() {
        this.selection = [];
        // Notify parent components that selection has changed
        this.selectionValueEvt();
        if (this._selectedFilter == 'BP Work') {
            const payload = {
                geoAreaIds: [],
                selectedFocusAreas: [],
                searchBy: this._selectedFilter
            };
            publish(this.messageContext, CITY_VIEW_FILTERS_CHANNEL, payload);
        }
    }

    selectionValueEvt() {
        const selected = new CustomEvent('select', {
            detail: JSON.parse(JSON.stringify(this.selection))
        });
        this.dispatchEvent(selected);
        this.errors = [];
    }

    arrowNavigationUp(event) {
        if (!this.isSelectionAllowed()) {
            return;
        }
        if (this.hasFocus && (this.hasResults() || this.noRecordFound) && event.which === KEYS.ARROW_UP) {
            const dropdown = [...this.template.querySelectorAll('.dropdown')];
            dropdown.map(li => li.firstChild.classList.remove(HAS_FOCUS));
            const itemCount = (dropdown.length - 1);
            if (this.focusIndex !== -1) {
                if (itemCount !== (this.focusIndex + itemCount)) {
                    if (this.focusIndex) {
                        --this.focusIndex;
                    } else {
                        this.focusIndex = itemCount;
                    }
                } else if (this.focusIndex === 1) {
                    this.focusIndex = 0;
                } else if (itemCount === (this.focusIndex + itemCount)) {
                    this.focusIndex = itemCount;
                }
            } else {
                this.focusIndex = itemCount;
            }
            dropdown[this.focusIndex].firstChild.classList.add(HAS_FOCUS);

        } else if (event.which === KEYS.ENTER && this.focusIndex !== -1) {
            this.handleResultEnter();
        }
    }

    arrowNavigationDown(event) {
        if (!this.isSelectionAllowed()) {
            return;
        }
        if (this.hasFocus && (this.hasResults() || this.noRecordFound) && event.which === KEYS.ARROW_DOWN) {
            const dropdown = [...this.template.querySelectorAll('.dropdown')];
            const itemCount = (dropdown.length - 1);
            if (itemCount !== this.focusIndex) {
                (this.focusIndex !== -1) ? dropdown[this.focusIndex].firstChild.classList.remove(HAS_FOCUS) : null;
                dropdown[++this.focusIndex].firstChild.classList.add(HAS_FOCUS);
            } else if (itemCount === this.focusIndex) {
                dropdown[this.focusIndex].firstChild.classList.remove(HAS_FOCUS);
                this.focusIndex = 0;
                dropdown[this.focusIndex].firstChild.classList.add(HAS_FOCUS);
            }
        }
    }

    clearFocus() {
        if (this.focusIndex === -1) return;
        this.focusIndex = -1;
        [...this.template.querySelectorAll('.dropdown')].map(li => li.firstChild.classList.remove(HAS_FOCUS));
    }

    notifyUser(title, message, variant) {
        const toastEvent = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(toastEvent);
    }

    // STYLE EXPRESSIONS
    get getContainerClass() {
        let css = 'slds-combobox_container slds-has-inline-listbox ';
        if (this.hasFocus && this.hasResults()) {
            css += 'slds-has-input-focus ';
        }
        if (this.errors.length > 0) {
            css += 'has-custom-error';
        }
        return css;
    }

    get getDropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
        if (this.hasFocus && (this.hasResults() || this.noRecordFound)) {
            css += 'slds-is-open';
        } else {
            css += 'slds-combobox-lookup';
        }
        return css;
    }

    get getInputClass() {
        let css = 'slds-input slds-combobox__input has-custom-height ' +
            (this.errors.length === 0 ? '' : 'has-custom-error ');
        if (!this.isMultiSelect) {
            css += (this.hasSelection() ? 'slds-combobox__input-value has-custom-border' : '');
        }
        return css;
    }

    get getComboboxClass() {
        let css = 'slds-combobox__form-element slds-input-has-icon ';
        if (this.isMultiSelect) {
            css += 'slds-input-has-icon_right';
        } else {
            css += (this.hasSelection() ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right');
        }
        return css;
    }

    get getSearchIconClass() {
        let css = 'slds-input__icon slds-input__icon_right ';
        if (!this.isMultiSelect) {
            css += (this.hasSelection() ? 'slds-hide' : '');
        }
        return css;
    }

    get getClearSelectionButtonClass() {
        return 'slds-button slds-button_icon slds-input__icon slds-input__icon_right ' +
            (this.hasSelection() ? '' : 'slds-hide');
    }

    get getSelectIconName() {
        return this.hasSelection() ? this.iconName : DEFAULT_ICON;
    }

    get getSelectIconClass() {
        return 'slds-combobox__input-entity-icon ' +
            (this.hasSelection() ? '' : 'slds-hide');
    }

    get getInputValue() {
        if (this.isMultiSelect) {
            return this.searchTerm;
        }
        return this.hasSelection() ? this.selection[0].title : this.searchTerm;
    }

    get getListboxClass() {
        return 'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid ';
    }

    get pillsContainer() {
        return (this.isMultiSelect && this.hasSelection()) ? 'slds-listbox_selection-group selectionGroup' : '';
    }

    get isInputReadonly() {
        if (this.isMultiSelect) {
            return false;
        }
        return this.hasSelection();
    }

    get isExpanded() {
        return this.hasResults();
    }
}