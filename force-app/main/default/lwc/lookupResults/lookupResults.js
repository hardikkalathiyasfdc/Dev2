import { LightningElement, api } from 'lwc';

export default class LookupResults extends LightningElement {
    @api displayFields = [];
    @api displayFieldPrefixes = [];
    @api icon;
    @api isMultiSelect = false;
    @api isLoading = false;
    @api allowNewRecord = false;
    @api objectLabel = '';
    
    _results = [];
    _selectedIds = [];
    
    @api
    get results() {
        return this._results;
    }
    
    set results(value) {
        this._results = value || [];
    }

    @api
    get selectedIds() {
        return this._selectedIds;
    }

    set selectedIds(value) {
        this._selectedIds = value || [];
    }

    get processedResults() {
        const selectedIdSet = new Set(this._selectedIds);
        return this._results.map(record => ({
            ...record,
            isSelected: selectedIdSet.has(record.Id)
        }));
    }

    get resultCount() {
        return this._results ? this._results.length : 0;
    }

    handleRecordSelect(event) {
        this.dispatchEvent(new CustomEvent('select', {
            detail: { record: event.detail.record }
        }));
    }

    handleNewRecord() {
        this.dispatchEvent(new CustomEvent('newrecord'));
    }
}