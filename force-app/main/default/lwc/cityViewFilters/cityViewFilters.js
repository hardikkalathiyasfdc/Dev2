import { LightningElement, api, track, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CITY_VIEW_GLOBAL_FILTERS_CHANNEL from '@salesforce/messageChannel/CityViewGlobalFiltersMessageChannel__c';
import getGeoAreasByFilters from '@salesforce/apex/CityViewFiltersController.getGeoAreasByFilters';
import getOffices from '@salesforce/apex/CityViewFiltersController.getOffices';
import getCityViewFocusAreas from '@salesforce/apex/CityViewController.getCityViewFocusAreas';
import CityView_Include_Grants_Filter_Access from '@salesforce/customPermission/CityView_Include_Grants_Filter_Access';

export default class CityViewFilters extends LightningElement {
    @api focusAreas;
    @api mapMarkers;
    @api isShowingDetailPage = false;
    @track selectedFocusAreas = [];
    isLoading = true;
    activeSections = ['focusAreas'];
    showOffices = false;
    initiativesFocusAreaFilter = '';
    isApplying = false;
    showGrants = false;
    shallShowGrantsCheckbox = false;

    @track _baseFilters = {
        showGrants: false,
        showOffices: false
    };

    @api
    get filters() {
        return this._filters || {};
    }
    set filters(value) {
        this._filters = value || {};
        this.initiateFromFilters();
    }

    get focusAreasForUi() {
        const selected = new Set(this.selectedFocusAreas || []);
        return (this.focusAreas || []).map(a => ({
            ...a,
            checked: selected.has(a.focusAreaName) || selected.has('All')
        }));
    }

    get isAllChecked() {
        const names = (this.focusAreas || []).map(a => a.focusAreaName);
        const selected = new Set(this.selectedFocusAreas || []);
        return selected.has('All') || (names.length > 0 && names.every(n => selected.has(n)));
    }

    get isNotLoading() {
        return !this.isLoading;
    }

    get isNotShowingDetailPage() {
        return !this.isShowingDetailPage;
    }

    @wire(MessageContext) messageContext;

    connectedCallback() {
        this.isLoading = true;
        this.shallShowGrantsCheckbox = CityView_Include_Grants_Filter_Access;
        this.processFocusAreas().then(() => {
            this.initiateFromFilters();
            this.isLoading = false;
        });
    }

    _sorted(arr) {
        return (Array.isArray(arr) ? [...arr] : []).slice().sort();
    }

    _getBaseFilters() {
        return {
            showGrants: !!this.showGrants,
            showOffices: !!this.showOffices,
            selectedFocusAreas: this._sorted(this.selectedFocusAreas)
        };
    }

    _hasChanged(key) {
        const now = this._getBaseFilters();
        return JSON.stringify(now[key]) !== JSON.stringify(this._baseFilters[key]);
    }

    _anythingChanged(keys) {
        return keys.some(k => this._hasChanged(k));
    }

    handleIncludeGrants(e) {
        this.showGrants = e.target.checked;
    }

    initiateFromFilters() {
        const f = this._filters || {};
        if(!f || Object.keys(f).length === 0) return;
        if(Array.isArray(f.selectedFocusAreas) && f.selectedFocusAreas.length > 0) {
            this.selectedFocusAreas = [...f.selectedFocusAreas];
        }
        this.showOffices = !!f.showOffices;
        this.showGrants = !!f.showGrants;
        this._baseFilters = this._getBaseFilters();
    }

    processFocusAreas() {
        return getCityViewFocusAreas()
            .then((sortedListFromApex) => {
                if(this.focusAreas && this.focusAreas.length > 0 && sortedListFromApex) {
                    const sortOrderMap = new Map();
                    sortedListFromApex.forEach((item, index) => {
                        sortOrderMap.set(item.Name.trim(), index);
                    });
                    const sortedLocalFocusAreas = [...this.focusAreas].sort((a, b) => {
                        const orderA = sortOrderMap.has(a.focusAreaName) ? sortOrderMap.get(a.focusAreaName) : Number.MAX_VALUE;
                        const orderB = sortOrderMap.has(b.focusAreaName) ? sortOrderMap.get(b.focusAreaName) : Number.MAX_VALUE;
                        return orderA - orderB;
                    });
                    this.focusAreas = sortedLocalFocusAreas;
                    const focusAreaNames = sortedLocalFocusAreas.map(area => area.focusAreaName);
                    const incoming = this._filters?.selectedFocusAreas;
                    if(Array.isArray(incoming) && incoming.length) {
                        this.selectedFocusAreas = [...incoming];
                    } else {
                        this.selectedFocusAreas = ['All', ...focusAreaNames];
                    }
                }
            }).catch((error) => {
                console.error('Error fetching sort order:', JSON.stringify(error));
            });
    }

    handleCheckboxChange(event) {
        const focusAreaName = event.target.dataset.name;
        const checked = event.target.checked;
        if(focusAreaName === 'All') {
            if(checked) {
                this.selectedFocusAreas = ['All', ...this.focusAreas.map(area => area.focusAreaName)];
            } else {
                this.selectedFocusAreas = [];
            }
        } else {
            if(checked) {
                if(!this.selectedFocusAreas.includes(focusAreaName)) {
                    this.selectedFocusAreas = [...this.selectedFocusAreas, focusAreaName];
                }
                this.selectedFocusAreas = this.selectedFocusAreas.filter(area => area !== 'All');
                const allAreas = this.focusAreas.map(area => area.focusAreaName);
                if(allAreas.every(area => this.selectedFocusAreas.includes(area))) {
                    this.selectedFocusAreas = ['All', ...allAreas];
                }
            } else {
                this.selectedFocusAreas = this.selectedFocusAreas.filter(area => area !== focusAreaName);
                this.selectedFocusAreas = this.selectedFocusAreas.filter(area => area !== 'All');
            }
        }
        this.updateCheckboxUI();
    }

    updateCheckboxUI() {
        const focusAreaNames = this.focusAreas.map(area => area.focusAreaName);
        this.template.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
            const focusAreaName = checkbox.dataset.name;
            if(focusAreaNames.includes(focusAreaName) || focusAreaName === 'All') {
                checkbox.checked = this.selectedFocusAreas.includes(focusAreaName);
            }
        });
    }

    handleOfficeChange(event) {
        this.showOffices = event.target.checked;
    }

    publishEvent(geoAreaIds, officeGeoAreas = {}, selectedFocusAreas = []) {
        const state = {
            selectedFocusAreas: Array.isArray(selectedFocusAreas) ? selectedFocusAreas : [],
            showOffices: !!this.showOffices,
            showGrants: !!this.showGrants
        };
        const applyPayload = {
            ...state,
            geoAreaIds: Array.isArray(geoAreaIds) ? geoAreaIds : [],
            officeGeoAreas: officeGeoAreas || {}
        };
        this.dispatchEvent(new CustomEvent('filtersready', {
            detail: state,
            bubbles: true,
            composed: true
        }));
        this.dispatchEvent(new CustomEvent('applyfilters', {
            detail: applyPayload,
            bubbles: true,
            composed: true
        }));
    }

    @api
    async applyFilters() {
        if(this.isApplying) return;
        this.isApplying = true;
        try {
            const nonGrantKeys = [
                'selectedFocusAreas',
                'showOffices'
            ];
            const grantsChanged = this._hasChanged('showGrants');
            const nonGrantChanged = this._anythingChanged(nonGrantKeys);
            if(!grantsChanged && !nonGrantChanged) return;
            if(grantsChanged) {
                const payload = {
                    bubbles: true,
                    composed: true,
                    filters: { showGrants: this.showGrants }
                };
                this._baseFilters = this._getBaseFilters();
                publish(this.messageContext, CITY_VIEW_GLOBAL_FILTERS_CHANNEL, payload);
                this.publishEvent([], {}, this.selectedFocusAreas);
            }
            if(!nonGrantChanged) return;
            const hasFocusAreas = this.selectedFocusAreas.length > 0;
            if(!hasFocusAreas && !this.showOffices) {
                this.showToast('Error', 'Please select at least one Focus Area.', 'error');
                return;
            }
            let officeGeoAreas = {};
            if(this.showOffices) officeGeoAreas = await getOffices();
            const result = await getGeoAreasByFilters({
                focusAreaNames: this.selectedFocusAreas
            }).catch(error => {
                console.error('Error fetching geo areas by filters:', JSON.stringify(error));
                this.showToast('Error', 'An error occurred while fetching data. Please try again.', 'error');
                return [];
            });
            const geoAreaIds = Array.isArray(result) ? result : [];
            this.publishEvent(geoAreaIds, officeGeoAreas, this.selectedFocusAreas);
            this._baseFilters = this._getBaseFilters();
        } catch(error) {
            console.error('Error during applyFilters:', JSON.stringify(error));
            this.publishEvent([], {}, this.selectedFocusAreas);
        } finally {
            this.isApplying = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}