import { LightningElement, api, track } from 'lwc';
import getRecentlyViewed from '@salesforce/apex/GenericLookupController.getRecentlyViewed';

export default class LookupRecentlyViewed extends LightningElement {
    @api objectApiName;
    @api displayFields = [];
    @api displayFieldPrefixes = [];
    @api filterClause = '';
    @api maxResults = 5;
    @api icon = 'standard:default';
    @api accessMode = 'USER_MODE';
    @api withoutSharing = false;
    @api isMultiSelect = false;
    @api hideHeader = false;

    @track recentRecords = [];
    @track isLoading = false;
    
    _selectedIds = [];
    _isInitialized = false;

    @api
    get selectedIds() {
        return this._selectedIds;
    }

    set selectedIds(value) {
        this._selectedIds = value || [];
    }

    connectedCallback() {
        if (!this._isInitialized) {
            this.loadRecentlyViewed();
            this._isInitialized = true;
        }
    }

    get hasRecords() {
        return !this.isLoading && this.recentRecords && this.recentRecords.length > 0;
    }

    get showHeader() {
        return !this.hideHeader;
    }

    get processedRecords() {
        const selectedIdSet = new Set(this._selectedIds);
        return this.recentRecords.map(record => ({
            ...record,
            isSelected: selectedIdSet.has(record.Id)
        }));
    }

    async loadRecentlyViewed() {
        this.isLoading = true;
        
        try {
            const request = {
                objectApiName: this.objectApiName,
                displayFields: this.displayFields,
                filterClause: this.filterClause,
                maxResults: this.maxResults,
                accessMode: this.accessMode,
                withoutSharing: this.withoutSharing
            };
            
            const records = await getRecentlyViewed({ request: JSON.stringify(request) });
            this.recentRecords = records || [];
            
            this.dispatchEvent(new CustomEvent('load', {
                detail: { records: this.recentRecords }
            }));
        } catch (error) {
            this.recentRecords = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleRecordSelect(event) {
        this.dispatchEvent(new CustomEvent('select', {
            detail: { record: event.detail.record }
        }));
    }
}