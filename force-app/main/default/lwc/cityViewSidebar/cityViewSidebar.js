import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import TOGGLE_FILTERS_CHANNEL from '@salesforce/messageChannel/ToggleFiltersMessageChannel__c';
import CITYVIEW_STYLES from '@salesforce/resourceUrl/cityViewCustomCSS';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class CityViewSidebar extends LightningElement {
    showSummary = false;
    showFilters = true;
    @api officeIconPath;
    @api isCountrySelected;
    @api isStateSelected;
    @api focusAreas = [];
    @api showDetailPage;
    @api isInitiativeSelected;
    @api selectedGroupByForStateOnCountryLevel;
    @api selectedGroupByForCityOnCountryLevel;
    _geoAreaId;
    _selectedMapMarker;
    subscription = null;
    _disableFilterCss;
    _shallShowGrants = false;

    @api
    get shallShowGrants() {
        return this._shallShowGrants;
    }

    set shallShowGrants(value) {
        this._shallShowGrants = value;
    }

    @api
    set disableFilterCss(value) {
        this._disableFilterCss = value;
    }

    get disableFilterCss() {
        return this._disableFilterCss;
    }

    @api
    get geoAreaId() {
        return this._geoAreaId;
    }

    @api
    get selectedMapMarker() {
        return this._selectedMapMarker;
    }

    set selectedMapMarker(value) {
        this.showSummary = false;
        if (value !== this._selectedMapMarker) {
            this._selectedMapMarker = value;
            this._geoAreaId = value?.geoAreaId;
            this.showSummary = true;
            this.showFilters = false;
        }
    }

    @api
    handleShowFilter() {
        this.showSummary = false;
        this.showFilters = true;
    }

    @wire(MessageContext)
    messageContext;

    isLoading = true;

    get isNotLoading() {
        return !this.isLoading;
    }

    connectedCallback() {
        this.subscription = subscribe(
            this.messageContext,
            TOGGLE_FILTERS_CHANNEL,
            (message) => this.handleMessage(message),
            { scope: APPLICATION_SCOPE }
        );

        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
        loadStyle(this, CITYVIEW_STYLES)
            .then(() => {
                console.log('Styles loaded successfully');
            })
            .catch(error => {
                console.error('Error loading styles', error);
            });
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        if (message.toggle) {
            setTimeout(() => {
                this.showFilters = true;
                this.showSummary = false;

            }, 100);
            this.resetMapMarker();
        }
    }

    @api
    resetMapMarker() {
        setTimeout(() => {
            if (this.refs && this.refs.cityvirefiltercmp) {
                this.refs.cityvirefiltercmp.applyFilters();
            }
        }, 500);
    }

    get filterStyles() {
        return this.showFilters ? 'display: block;' : 'display: none;';
    }

    get summaryStyles() {
        return this.showSummary ? 'display: block;' : 'display: none;';
    }
}