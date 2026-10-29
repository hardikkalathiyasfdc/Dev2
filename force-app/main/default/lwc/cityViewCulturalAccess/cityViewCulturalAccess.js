import { LightningElement, track, api } from 'lwc';
import getCulturalAccessGroups from '@salesforce/apex/CityViewDetailPageController.getCulturalAccessGroups';

export default class CityViewCulturalAccess extends LightningElement {
    @track cities = [];
    @track culturalData = [];
    _selectedGeoAreaId;
    _isCountry;
    _isStateSelected;
    isLoading = false;
    isGeoAreaIdAvailable = false;

    get showCulturalData() {
        return (this.culturalData || []).length > 0;
    }

    get showCulturalDataForCountryState() {
        return (this._isCountry || this._isStateSelected) && !this.isLoading;
    }

    get innedBoxClass() {
        let baseClass = 'overflow: auto; padding-left: 11px; padding-right: 14px;';
        if(this.isCountry || this.isStateSelected) {
            baseClass += ' height: 417px;';
        } else {
            baseClass += ' height: 460px;';
        }
        return baseClass;
    }   

    @api
    get isCountry() {
        return this._isCountry;
    }
    set isCountry(value) {
        this._isCountry = value;
        this.loadData();
    }

    @api
    get isStateSelected() {
        return this._isStateSelected;
    }
    set isStateSelected(value) {
        this._isStateSelected = value;
        this.loadData();
    }

    @api
    get geoAreaId() {
        return this._selectedGeoAreaId;
    }
    set geoAreaId(value) {
        this._selectedGeoAreaId = value;
        this.loadData();
    }

    connectedCallback() {
        if (this._selectedGeoAreaId) {
            this.loadData();
        }
    }

    @api
    getCulturalAccessData() {
        return (this._isCountry || this._isStateSelected) ? this.cities : this.culturalData;
    }

    async loadData() {
        this.cities = [];
        this.culturalData = [];
        this.isGeoAreaIdAvailable = false;
        if (!this._selectedGeoAreaId) return;
        this.isLoading = true;
        try {
            let geoAreaId = this._selectedGeoAreaId;
            const groups = await getCulturalAccessGroups({ geoAreaId });
            const normalized = (groups || []).map(g => ({
                id: g.cityId,
                name: g.cityName,
                count: g.accessCount || 0,
                isExpanded: false,
                rows: (g.rows || []).map(r => ({ ...r, showBenefit: !!r.showBenefit }))
            }))
                .filter(g => g.rows.length > 0)
                .sort((a, b) => (b.count ?? 0) - (a.count ?? 0));
            if (this._isCountry || this._isStateSelected) {
                this.cities = normalized;
            } else if (normalized.length > 0) {
                this.isGeoAreaIdAvailable = true;
                this.culturalData = normalized[0].rows;
            }
            else {
                this.isGeoAreaIdAvailable = true;
            }
        } catch (e) {
            console.error('Error loading cultural access groups:', e);
            this.culturalData = [];
        } finally {
            this.isLoading = false;
        }
    }

    toggleCity(event) {
        const cityId = event.currentTarget.dataset.id;
        if (!cityId) return;
        const idx = this.cities.findIndex(c => c.id === cityId);
        if (idx === -1) return;
        const city = { ...this.cities[idx], isExpanded: !this.cities[idx].isExpanded };
        this.cities = [...this.cities.slice(0, idx), city, ...this.cities.slice(idx + 1)];
    }

    handleOrgClick(event) {
        const recId = event.currentTarget.dataset.id;
        const cityId = event.currentTarget.dataset.city;
        if ((this._isCountry || this._isStateSelected) && cityId) {
            const cIdx = this.cities.findIndex(c => c.id === cityId);
            if (cIdx === -1) return;
            const city = { ...this.cities[cIdx] };
            city.rows = city.rows.map(r => (r.id === recId ? { ...r, showBenefit: !r.showBenefit } : r));
            this.cities = [...this.cities.slice(0, cIdx), city, ...this.cities.slice(cIdx + 1)];
            return;
        }
        this.culturalData = (this.culturalData || []).map(r =>
            r.id === recId ? { ...r, showBenefit: !r.showBenefit } : r
        );
    }
}