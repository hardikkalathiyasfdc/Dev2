import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSortPreferences from '@salesforce/apex/EventTablePreferencesController.getSortPreferences';
import saveSortPreferences from '@salesforce/apex/EventTablePreferencesController.saveSortPreferences';

export default class events extends LightningElement {
    @api displayEvents;
    @api title;
    @track sortCriteria = [];
    @track originalEvents = [];
    currentPage = 0;
    disablePrev = true;
    disableNext = true;
    defaultSize = 400;
    showDeleteConfirmation = false;
    selectedEventId;
    showSortModal = false;
    _totalEvents = [];

    sortableColumns = [
        { key: 'name', label: 'Event Name', field: 'event.Name', type: 'string' },
        { key: 'etype', label: 'Event Type', field: 'event.EventType__c', type: 'string' },
        { key: 'startDate', label: 'Event Start Date', field: 'event.Event_Start_Date_Time__c', type: 'date' },
        { key: 'endDate', label: 'Event End Date', field: 'event.Event_End_Date_Time__c', type: 'date' },
        { key: 'timeZone', label: 'Time Zone', field: 'event.TimeZone__c', type: 'string' },
        { key: 'guest', label: 'Guests', field: 'event.TotalGuests__c', type: 'number' },
        { key: 'pend', label: 'Pend', field: 'event.TotalPend__c', type: 'number' },
        { key: 'yes', label: 'Yes', field: 'event.TotalYes__c', type: 'number' },
        { key: 'no', label: 'No', field: 'event.TotalNo__c', type: 'number' },
        { key: 'attended', label: 'Attended', field: 'event.TotalAttend__c', type: 'number' },
        { key: 'notAttended', label: 'Not Attended', field: 'event.TotalNotAttend__c', type: 'number' },
        { key: 'coordinator', label: 'Event Coordinator', field: 'event.EventCoordinator', type: 'string' },
        { key: 'programatic', label: 'Program-Managed', field: 'event.Programmatic__c', type: 'boolean' }
    ];

    @api
    get totalEvents() {
        return this._totalEvents;
    }
    set totalEvents(value) {
        this._totalEvents = value ? [...value] : [];
        if(!this.originalEvents.length) {
            this.originalEvents = value ? [...value] : [];
        }
        if(this.sortCriteria.length) this.applyMultiSort();
        this.currentPage = 0;
        this.disablePrev = true;
        this.disableNext = this._totalEvents.length <= this.defaultSize;
        this.displayEvents = this._totalEvents.slice(0, this.defaultSize);
    }

    get sortDisplay() {
        const result = {};
        this.sortCriteria.forEach((item) => {
            const col = this.sortableColumns.find(c => c.field === item.field);
            if(col) {
                result[col.key] = item.direction === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
            }
        });
        return result;
    }

    async connectedCallback() {
        const saved = await getSortPreferences();
        this.sortCriteria = JSON.parse(saved || '[]');
        if(this.sortCriteria.length && this._totalEvents.length) {
            this.applyMultiSort();
        }
    }

    renderedCallback() {
        if(this._totalEvents && this._totalEvents.length > this.defaultSize && this.currentPage === 0) {
            this.disableNext = false;
        }
    }

    handleEventSelection(event) {
        const eventId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('selected', { detail: eventId }));
    }

    openMultiSort() {
        this.showSortModal = true;
        requestAnimationFrame(() => {
            const modal = this.template.querySelector('c-multi-sort-modal');
            if(modal) modal.setCriteria(this.sortCriteria);
        });
    }

    closeMultiSort() {
        this.showSortModal = false;
    }

    handleSortClear() {
        this.sortCriteria = [];
        this._totalEvents = [...this.originalEvents];
        this.currentPage = 0;
        this.disablePrev = true;
        this.disableNext = this._totalEvents.length <= this.defaultSize;
        this.displayEvents = this._totalEvents.slice(0, this.defaultSize);
        this.showSortModal = false;
        this.saveSortPreferences();
    }

    async saveSortPreferences() {
        await saveSortPreferences({
            sortJson: JSON.stringify(this.sortCriteria)
        });
    }

    handleMultiSortApply(event) {
        this.sortCriteria = event.detail || [];
        this.applyMultiSort();
        this.showSortModal = false;
        this.saveSortPreferences();
    }

    applyMultiSort() {
        const rows = [...this._totalEvents];
        rows.sort((a, b) => {
            for(const selectedCriteria of this.sortCriteria) {
                const aVal = this.normalizeValue(this.getFieldValue(a, selectedCriteria.field), selectedCriteria.type);
                const bVal = this.normalizeValue(this.getFieldValue(b, selectedCriteria.field), selectedCriteria.type);
                if(aVal === bVal) continue;
                if(aVal === null || aVal === undefined || aVal === '') return 1;
                if(bVal === null || bVal === undefined || bVal === '') return -1;
                const comparison = aVal > bVal ? 1 : -1;
                return selectedCriteria.direction === 'asc' ? comparison : comparison * -1;
            }
            return 0;
        });
        this._totalEvents = rows;
        this.currentPage = 0;
        this.disablePrev = true;
        this.disableNext = rows.length <= this.defaultSize;
        this.displayEvents = rows.slice(0, this.defaultSize);
    }

    getFieldValue(record, path) {
        return path.split('.').reduce((acc, key) => (acc ? acc[key] : undefined), record);
    }

    normalizeValue(value, type) {
        if(value === null || value === undefined) return null;
        switch(type) {
            case 'number':
                return Number(value) || 0;
            case 'date':
                return this.getDateTimeVal(value);
            case 'boolean':
                return value === true || value === 'true' ? 1 : 0;
            default:
                return String(value).toLowerCase();
        }
    }

    handleSort(event) {
        const sortKey = event.currentTarget.dataset.id;
        const clickedColumn = this.sortableColumns.find(col => col.key === sortKey);
        if(!clickedColumn) return;
        let direction = 'asc';
        if(this.sortCriteria.length === 1 && this.sortCriteria[0].field === clickedColumn.field) {
            direction = this.sortCriteria[0].direction === 'asc' ? 'desc' : 'asc';
        }
        this.sortCriteria = [ {
            field: clickedColumn.field,
            direction,
            label: clickedColumn.label,
            type: clickedColumn.type
        }];
        this.applyMultiSort();
        this.saveSortPreferences();
    }

    getDateTimeVal(dt) {
        if(!dt) return 0;
        try {
            return new Date(dt).getTime();
        } catch (e) {
            return 0;
        }
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handlePrevious() {
        let newPage = parseInt(this.currentPage, 10) - 1;
        if(newPage === 0) {
            this.disablePrev = true;
            this.displayEvents = this._totalEvents.slice(0, this.defaultSize);
        } else {
            this.displayEvents = this._totalEvents.slice(newPage * this.defaultSize, (newPage + 1) * this.defaultSize);
        }
        this.disableNext = false;
        this.currentPage = newPage;
    }

    handleNext() {
        let newPage = parseInt(this.currentPage, 10) + 1;
        this.disablePrev = false;
        if((newPage + 1) * this.defaultSize >= this._totalEvents.length) {
            this.displayEvents = this._totalEvents.slice(newPage * this.defaultSize, this._totalEvents.length);
            this.disableNext = true;
        } else {
            this.displayEvents = this._totalEvents.slice(newPage * this.defaultSize, (newPage + 1) * this.defaultSize);
        }
        this.currentPage = newPage;
    }
}