import { LightningElement, api, track } from 'lwc';
import getCityViewHighlights from '@salesforce/apex/CityViewDetailPageController.getCityViewHighlights';

export default class CityViewHighlights extends LightningElement {
    @api isCountrySelected;
    @api isStateSelected;
    @api selectedHighlightSort;
    @api formFactor;
    @track rawData = [];
    _geoAreaId;
    isLoading = false;

    get title() {
        return this.isCountrySelected
            ? `Country Level Highlights (${this.sortby})`
            : this.isStateSelected
                ? `State Level Highlights (${this.sortby})`
                : `City Level Highlights (${this.sortby})`;
    }

    get sortby() {
        return this.selectedSort == 'MostRecent' ? 'Most Recent' : 'All Time';
    }

    @api
    get geoAreaId() {
        return this._geoAreaId;
    }
    set geoAreaId(value) {
        this._geoAreaId = value;
        if (value) {
            this.fetchCityViewHighlights();
        }
        this._geoAreaId = value;
    }

    @api
    getHighlightsData() {
        return { highlightTitle: this.sortby, rawData: this.rawData };
    }

    // Getter to check if data is available to display
    get showData() {
        return this.rawData && this.rawData.length > 0;
    }

    get tableStyle() {
        const normalizedFormFactor = this.formFactor ? this.formFactor.toLowerCase() : '';
        if (normalizedFormFactor === 'large') {
            return 'max-height: 600px; overflow: auto;';
        } else if (normalizedFormFactor === 'small' || normalizedFormFactor === 'medium') {
            return ''; // Empty style for small/medium form factor
        }
    }

    selectedSort = 'allTime';
    get sortByMostRecent() {
        return this.selectedSort == 'MostRecent';
    }

    get sortByAllTime() {
        return this.selectedSort == 'allTime';
    }

    handleSortChange(event) {
        this.selectedSort = event.detail.value;
        this.fetchCityViewHighlights();
        this.dispatchEvent(new CustomEvent('highlightsortingchange', {
            detail: this.selectedSort,
            bubbles: true,
            composed: true
        }));
    }

    connectedCallback() {
        this.selectedSort = this.selectedHighlightSort;
        if (this._geoAreaId) {
            this.fetchCityViewHighlights();
        }
    }

    fetchCityViewHighlights() {
        this.isLoading = true;
        getCityViewHighlights({
            geoAreaId: this._geoAreaId,
            duration: this.selectedSort
        }).then((data) => {
            if (data && data.length > 0) {
                var records = data.map(record => {
                    const options = { year: 'numeric', month: 'long', timeZone: 'UTC' };
                    const formatter = new Intl.DateTimeFormat('en-US', options);
                    const monthName = formatter.format(new Date(record.Interaction_Date__c));
                    return { ...record, monthName };
                });
                this.rawData = records;
            } else {
                this.rawData = [];
            }
        }).catch((error) => {
            console.error('Error fetching data:', error);
        }).finally(() => {
            this.isLoading = false;
        });
    }
}