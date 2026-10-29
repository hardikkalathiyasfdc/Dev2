import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import searchRecords from '@salesforce/apex/GenericLookupController.searchRecords';
import getRecordsByIds from '@salesforce/apex/GenericLookupController.getRecordsByIds';
import getObjectInfo from '@salesforce/apex/GenericLookupController.getObjectInfo';

const DEFAULT_NEW_RECORD_SETTINGS = {
    'Contact': {
        fieldSetName: 'New_Contact',
        fieldOverrides: {
            'AccountId': {
                componentType: 'genericLookup',
                objectApiName: 'Account',
                label: 'Organization',
                displayFields: ['Search_Display_Name__c', 'Computed_AKA__c', 'Legal_Name__c', 'Website'],
                searchFields: ['Search_Display_Name__c'],
                icon: 'standard:account',
                customSearchClass: 'OrganizationLookupSearch',
                allowNewRecord: false,
                newRecordSettings: { fieldSetName: 'New_Organization' }
            }
        }
    },
    'Account': {
        fieldSetName: 'New_Organization'
    }
};

const DEFAULT_ICON = 'standard:default';
const DEFAULT_MAX_RESULTS = 1000;
const SEARCH_DELAY = 1000;
const DISPLAY_INCREMENT = 10;
const SCROLL_THRESHOLD = 50;

export default class GenericLookup extends NavigationMixin(LightningElement) {
    @api objectApiName;
    @api label;
    @api placeholder = 'Search...';
    @api required = false;
    @api disabled = false;
    @api icon = DEFAULT_ICON;
    @api searchFields = [];
    @api filterClause = '';
    @api orderByClause = '';
    @api maxResults = DEFAULT_MAX_RESULTS;
    @api displayFields = [];
    @api displayFieldPrefixes = [];
    @api isMultiSelect = false;
    _allowNewRecord = true;
    @api
    get allowNewRecord() { return this._allowNewRecord; }
    set allowNewRecord(value) { this._allowNewRecord = value !== false && value !== 'false'; }
    @api newRecordSettings;
    _showRecentlyViewed = true;
    @api
    get showRecentlyViewed() { return this._showRecentlyViewed; }
    set showRecentlyViewed(value) { this._showRecentlyViewed = value !== false && value !== 'false'; }
    @api defaultResultsFilterClause;
    @api withoutSharing = false;
    @api accessMode = 'USER_MODE';
    @api searchKey ='';
    @api customSearchClass;
    @api searchConfig;
    
    _defaultSelectedIds = [];
    @api
    get defaultSelectedIds() {
        return this._defaultSelectedIds;
    }
    set defaultSelectedIds(value) {
        this._defaultSelectedIds = value || [];
        if (this._defaultSelectedIds.length > 0) {
            this.loadDefaultSelectedRecords();
        }
    }

    @track selectedRecords = [];
    @track searchResults = [];
    @track recentRecords = [];
    @track isSearching = false;
    @track showDropdown = false;
    @track errorMessage = '';
    @track objectLabel = '';
    @track showNewRecordModal = false;
    @track _effectiveNewRecordSettings = null;
    @track defaultResults = [];
    
    _searchTerm = '';
    _searchTimeout;
    _isInitialized = false;
    _hasFocus = false;
    _suppressClose = false;
    _displayLimit = DISPLAY_INCREMENT;

    connectedCallback() {
        this.loadObjectInfo();
        if (this._defaultSelectedIds.length > 0) {
            this.loadDefaultSelectedRecords();
        }
        this._isInitialized = true;
    }

    renderedCallback() {
                    }
                    
    disconnectedCallback() {
        if (this._searchTimeout) {
            clearTimeout(this._searchTimeout);
        }
    }

    get containerClass() {
        return 'slds-form-element' + (this.errorMessage ? ' slds-has-error' : '');
    }

    get comboboxClass() {
        let classes = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        if (this.showDropdown) {
            classes += ' slds-is-open';
        }
        return classes;
    }

    get dropdownOpen() {
        return this.showDropdown ? 'true' : 'false';
    }

    get isSingleSelectWithSelection() {
        return !this.isMultiSelect && this.selectedRecords.length > 0;
    }

    get showInputArea() {
        return this.isMultiSelect || this.selectedRecords.length === 0;
    }

    get selectedRecordName() {
        if (this.selectedRecords.length > 0 && this.selectedRecords[0].fields) {
            const primaryField = this.displayFields && this.displayFields.length > 0 
                ? this.displayFields[0] 
                : 'Name';
            return this.selectedRecords[0].fields[primaryField] || '';
        }
        return '';
    }

    get primaryDisplayField() {
        return this.displayFields && this.displayFields.length > 0 
            ? this.displayFields[0] 
            : 'Name';
    }

    get selectedIcon() {
        return this.icon || DEFAULT_ICON;
    }

    get showClearButton() {
        return !this.disabled && this.selectedRecords.length > 0;
    }

    get showDefaultResults() {
        return this.defaultResultsFilterClause &&
               !this._searchTerm &&
               this._hasFocus &&
               !this.isSearching &&
               this.defaultResults.length > 0;
    }

    get showRecentlyViewedSection() {
        return this.showRecentlyViewed &&
               !this.defaultResultsFilterClause &&
               !this._searchTerm && 
               this._hasFocus && 
               !this.isSearching;
    }

    get showSearchResults() {
        return this._searchTerm && 
               this.searchResults.length > 0;
    }

    get showSearchSpinner() {
        return this.isSearching;
    }

    get showNoResults() {
        return this._searchTerm && 
               this.searchResults.length === 0 && 
               !this.isSearching;
    }

    get showPills() {
        return this.isMultiSelect && this.selectedRecords.length > 0;
    }

    get showDoneButton() {
        return this.isMultiSelect && this.selectedRecords.length > 0;
    }

    get showFooter() {
        return this.allowNewRecord || this.showDoneButton;
    }

    get newButtonLabel() {
        return `New ${this.objectLabel}`;
    }

    get showRecentlyViewedHeader() {
        return this.isMultiSelect &&
               this.showRecentlyViewedSection &&
               this.recentRecords.length > 0;
    }

    get recentUnselectedCount() {
        const selectedIdSet = new Set(this.selectedIdsSet);
        return this.recentRecords.filter(record => !selectedIdSet.has(record.Id)).length;
    }

    get selectedCount() {
        return this.selectedRecords.length;
    }

    get searchUnselectedCount() {
        const selectedIdSet = new Set(this.selectedIdsSet);
        return this.searchResults.filter(record => !selectedIdSet.has(record.Id)).length;
    }

    get showSearchResultsHeader() {
        return this.isMultiSelect && this.showSearchResults;
    }

    get disallowNewInResults() {
        return false;
    }

    get showFieldSetModal() {
        return this.allowNewRecord && this.showNewRecordModal && this._effectiveNewRecordSettings != null;
    }

    get displayResults() {
        return this.searchResults.slice(0, this._displayLimit);
    }

    get displayDefaultResults() {
        return this.defaultResults.slice(0, this._displayLimit);
    }

    get hasMoreResults() {
        return this._searchTerm
            ? this.searchResults.length > this._displayLimit
            : this.defaultResults.length > this._displayLimit;
    }

    get selectedIdsSet() {
        return this.selectedRecords.map(record => record.Id);
    }

    @api
    get selectedIds() {
        return this.selectedIdsSet;
    }

    @api
    get value() {
        return this.isMultiSelect ? this.selectedRecords : this.selectedRecords[0];
    }

    @api
    clearSelection() {
        this.selectedRecords = [];
        this._searchTerm = '';
        this.searchResults = [];
        this.dispatchChangeEvent();
    }

    @api
    setSelection(records) {
        if (Array.isArray(records)) {
            this.selectedRecords = this.isMultiSelect ? records : [records[0]];
        } else if (records) {
            this.selectedRecords = [records];
        }
        this.dispatchChangeEvent();
    }

    @api
    reportValidity() {
        if (this.required && this.selectedRecords.length === 0) {
            this.errorMessage = 'Please select a value';
            return false;
        }
        this.errorMessage = '';
        return true;
    }

    @api
    setCustomValidity(message) {
        this.errorMessage = message;
    }

    handleFocusOut(event) {
        if (this._suppressClose) {
            return;
        }
        this._hasFocus = false;
        setTimeout(() => {
            if (!this._hasFocus) {
                this.closeDropdown();
            }
        }, 200);
    }

    handleDropdownMouseDown() {
        this._suppressClose = true;
    }

    handleDropdownMouseUp() {
        this._suppressClose = false;
    }

    handleInputFocus(event) {
        this._hasFocus = true;
        this.showDropdown = true;
        if (event.detail && event.detail.searchTerm) {
            this._searchTerm = event.detail.searchTerm;
            if (this.searchResults.length === 0) {
                this.performSearch(this._searchTerm);
            }
        } else if (this.defaultResultsFilterClause && this.defaultResults.length === 0) {
            this.loadDefaultResults();
        }
    }

    handleSearch(event) {
        const searchTerm = event.detail.searchTerm;
        this._searchTerm = searchTerm;
        this._displayLimit = DISPLAY_INCREMENT;
        
        if (this._searchTimeout) {
            clearTimeout(this._searchTimeout);
        }

        if (!searchTerm) {
            this.searchResults = [];
            return;
        }

        this._searchTimeout = setTimeout(() => {
            this.performSearch(searchTerm);
        }, SEARCH_DELAY);
    }

    handleInputClear() {
        this._searchTerm = '';
        this.searchResults = [];
        this.searchKey ='';
        this._displayLimit = DISPLAY_INCREMENT;
    }

    handleRecordSelect(event) {
        this.errorMessage = null;
        const selectedRecord = this.cleanRecord(event.detail.record);
        
        if (this.isMultiSelect) {
            const isAlreadySelected = this.selectedRecords.some(
                record => record.Id === selectedRecord.Id
            );
            
            if (isAlreadySelected) {
                this.selectedRecords = this.selectedRecords.filter(
                    record => record.Id !== selectedRecord.Id
                );
            } else {
                this.selectedRecords = [...this.selectedRecords, selectedRecord];
            }
        } else {
            this.selectedRecords = [selectedRecord];
            this.showDropdown = false;
            this._searchTerm = '';
            this.searchResults = [];
        }
        
        this.dispatchChangeEvent();
    }

    handleRecentLoad(event) {
        this.recentRecords = event.detail.records || [];
    }

    cleanRecord(record) {
        return {
            Id: record.Id,
            fields: record.fields || {}
        };
    }

    handlePillRemove(event) {
        const recordId = event.detail.recordId;
        this.selectedRecords = this.selectedRecords.filter(
            record => record.Id !== recordId
        );
        this.dispatchChangeEvent();
    }

    handleClearSelection() {
        this.selectedRecords = [];
        this._searchTerm = '';
        this.dispatchChangeEvent();
    }

    handleNewRecord() {
        const effectiveSettings = this.newRecordSettings || DEFAULT_NEW_RECORD_SETTINGS[this.objectApiName];
        if (effectiveSettings) {
            this._effectiveNewRecordSettings = effectiveSettings;
            this.showNewRecordModal = true;
            this.closeDropdown();
            return;
        }
        const pageRef = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'new'
            }
        };

        this[NavigationMixin.GenerateUrl](pageRef).then(url => {
            window.open(url, '_blank');
        });

        this.closeDropdown();
    }

    handleDone() {
        this.closeDropdown();
    }

    closeDropdown() {
        this.showDropdown = false;
        this._hasFocus = false;
        this._searchTerm = '';
        this.searchResults = [];
    }

    handleDropdownScroll(event) {
        const el = event.target;
        if (el.scrollHeight - el.scrollTop - el.clientHeight <= SCROLL_THRESHOLD) {
            if (this.hasMoreResults) {
                this._displayLimit += DISPLAY_INCREMENT;
            }
        }
    }

    async loadObjectInfo() {
        try {
            const result = await getObjectInfo({ 
                objectApiName: this.objectApiName 
            });
            this.objectLabel = result.label;
        } catch (error) {
            this.objectLabel = this.objectApiName;
        }
    }

    async loadDefaultSelectedRecords() {
        if (!this._defaultSelectedIds || this._defaultSelectedIds.length === 0) {
            return;
        }

        try {
            const request = {
                objectApiName: this.objectApiName,
                recordIds: this._defaultSelectedIds,
                displayFields: this.displayFields,
                accessMode: this.accessMode,
                withoutSharing: this.withoutSharing
            };
            
            const records = await getRecordsByIds({ request: JSON.stringify(request) });
            this.selectedRecords = records;
        } catch (error) {
            this.errorMessage = 'Error loading default values';
        }
    }

    async performSearch(searchTerm) {
        this.isSearching = true;

        try {
            const request = {
                objectApiName: this.objectApiName,
                searchTerm: searchTerm,
                searchFields: this.searchFields,
                displayFields: this.displayFields,
                filterClause: this.filterClause,
                orderByClause: this.orderByClause,
                maxResults: this.maxResults,
                accessMode: this.accessMode,
                withoutSharing: this.withoutSharing,
                customSearchClass: this.customSearchClass,
                searchConfig: this.searchConfig
            };

            const response = await searchRecords({ request: JSON.stringify(request) });
            this.searchResults = response.records || [];
        } catch (error) {
            this.errorMessage = 'Error performing search';
            this.searchResults = [];
        } finally {
            this.isSearching = false;
        }
    }

    async fetchAndSelectRecord(recordId) {
        try {
            const request = {
                objectApiName: this.objectApiName,
                recordIds: [recordId],
                displayFields: this.displayFields,
                accessMode: this.accessMode,
                withoutSharing: this.withoutSharing
            };
            
            const records = await getRecordsByIds({ request: JSON.stringify(request) });
            
            if (records && records.length > 0) {
                if (this.isMultiSelect) {
                    this.selectedRecords = [...this.selectedRecords, records[0]];
                } else {
                    this.selectedRecords = [records[0]];
                }
                this.closeDropdown();
                this.dispatchChangeEvent();
            }
        } catch (error) {
            this.errorMessage = 'Error fetching record';
        }
    }

    handleModalClose() {
        this.showNewRecordModal = false;
        this._effectiveNewRecordSettings = null;
    }

    handleModalSuccess(event) {
        const newRecordId = event.detail.id;
        this.showNewRecordModal = false;
        this.fetchAndSelectRecord(newRecordId);
    }

    async loadDefaultResults() {
        this.isSearching = true;
        try {
            const request = {
                objectApiName: this.objectApiName,
                searchTerm: '',
                searchFields: this.searchFields,
                displayFields: this.displayFields,
                filterClause: this.defaultResultsFilterClause,
                orderByClause: this.orderByClause,
                maxResults: this.maxResults,
                accessMode: this.accessMode,
                withoutSharing: this.withoutSharing
            };
            const response = await searchRecords({ request: JSON.stringify(request) });
            this.defaultResults = response.records || [];
        } catch (error) {
            this.defaultResults = [];
        } finally {
            this.isSearching = false;
        }
    }

    dispatchChangeEvent() {
        const detail = {
            selectedIds: this.selectedIdsSet,
            selectedRecords: this.selectedRecords
        };
        
        this.dispatchEvent(new CustomEvent('change', { detail }));
    }
}