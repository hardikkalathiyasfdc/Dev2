import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCityLevelWork from '@salesforce/apex/CityViewDetailPageController.getCityLevelWork';
import showStateLevelData from '@salesforce/apex/CityViewDetailPageController.showStateLevelData';
var lastShowGrants = false;
export default class CityViewCityLevelWork extends NavigationMixin(LightningElement) {
    @api isCountrySelected;
    @api isStateSelected;
    @api selectedGroupBy;
    @api formFactor;
    @track cityWork = [];
    @track stateWork = [];
    @track countryWork = [];
    @track rawCityWork = [];
    @track rawStateWork = [];
    @track rawCountryWork = [];
    @track groupedCityWork = [];
    @track error;
    isLoading = false;
    _selectedGeoAreaId;
    isGeoAreaIdAvailable = false;
    showStateFlag = false;
   _shallShowGrants = false;

    @api
    get shallShowGrants() {
        return this._shallShowGrants;
    }
    set shallShowGrants(value) {
        lastShowGrants = value;
        this._shallShowGrants = value;
       if(this.geoAreaId && this.rawCityWork  && this.rawCityWork.length>0)
        this.applyGrantFilter();
    } 

    @api
    get geoAreaId() {
        return this._selectedGeoAreaId;
    }
    set geoAreaId(value) {
        this.isGeoAreaIdAvailable = !!value;
        if (value !== this._selectedGeoAreaId) {
            this.getShowStateCondition(value);
            this.fetchCityWork(value);
        }
        this._selectedGeoAreaId = value;
    }

    get showStateWorkForStates() {
        return (this.isStateSelected ||
            (!this.isStateSelected && !this.isCountrySelected && this.showStateFlag));
    }

    get showStateWorkForCountries() {
        return this.isCountrySelected && this.showStateFlag;
    }

    @api
    getCityLevelData() {
        const cityData = {
            groupedCityWork: this.groupedCityWork,
            stateWork: this.stateWork,
            countryWork: this.countryWork,
            showStateFlag: this.showStateFlag,
            shallShowGrants: this.shallShowGrants
        }
        return cityData;
    }

    get tableStyle() {
        const normalizedFormFactor = this.formFactor ? this.formFactor.toLowerCase() : '';
        if (normalizedFormFactor === 'large') {
            return 'max-height: 300px; overflow: auto;';
        } else if (normalizedFormFactor === 'small' || normalizedFormFactor === 'medium') {
            return ''; // Empty style for small/medium form factor
        }
    }

    get showCityWorkTable() {
        return !this.isCountrySelected && !this.isStateSelected;
    }

    get showCityWork() {
        return this.cityWork.length > 0;
    }

    get showStateWork() {
        return this.stateWork.length > 0;
    }

    get showCountryWork() {
        return this.countryWork.length > 0;
    }

    connectedCallback() {
        this._shallShowGrants = lastShowGrants;
    }  


    applyGrantFilter() {
        this.isLoading = true;
        const recordsToKeep = r => this.shallShowGrants || r.recordType !== 'Grant';
        this.cityWork = (this.rawCityWork || []).filter(recordsToKeep);
        this.stateWork = (this.rawStateWork || []).filter(recordsToKeep);
        this.countryWork = (this.rawCountryWork || []).filter(recordsToKeep);
        this.groupedCityWork = this.groupByFocusArea(this.cityWork || []);
        setTimeout(() => {
            this.isLoading = false;
        }, 500);
    }

    getShowStateCondition(geoAreaId) {
        showStateLevelData({
            geoAreaId
        }).then(result => {
            this.showStateFlag = result;
        }).catch(error => {
            console.error('Error fetching city work:', error);
            this.error = error;
        })
    }

    fetchCityWork(geoAreaId) {
        this.isLoading = true;
        getCityLevelWork({
            geoAreaId
        }).then(result => {
            if (result && result.length > 0) {
                // Filter work by geoAreaLevel
                const city = result.filter(i => i.geoAreaLevel === 'city');
                const state = result.filter(i => i.geoAreaLevel === 'state');
                const country = result.filter(i => i.geoAreaLevel === 'country');
                const recordsToKeep = r => this.shallShowGrants || r.recordType !== 'Grant';
                this.rawCityWork = city;
                this.rawStateWork = state;
                this.rawCountryWork = country;
                this.cityWork = city.filter(recordsToKeep);
                this.stateWork = this.handleCustomSort(state.filter(recordsToKeep));
                this.countryWork = this.handleCustomSort(country.filter(recordsToKeep));
            } else {
                this.cityWork = [];
                this.stateWork = [];
                this.countryWork = [];
                this.groupedCityWork = [];
            }
            this.groupedCityWork = this.groupByFocusArea(this.cityWork);
        }).catch(error => {
            console.error('Error fetching city work:', error);
            this.error = error;
        }).finally(() => {
            this.isLoading = false;
        });
    }

    handleCustomSort(records) {
        records.sort((a, b) => {
            const focusA = (a.focusArea || '').toLowerCase();
            const focusB = (b.focusArea || '').toLowerCase();
            if (focusA === focusB) {
                // If 'a' has 'boldfontcss' and 'b' doesn't, 'a' should come before 'b'
                if (a.customCss === 'boldfontcss' && b.customCss !== 'boldfontcss') {
                    return -1; // 'a' comes first
                }
                // If 'b' has 'boldfontcss' and 'a' doesn't, 'b' should come before 'a'
                if (a.customCss !== 'boldfontcss' && b.customCss === 'boldfontcss') {
                    return 1; // 'b' comes first (so 'a' comes after 'b')
                }
                // If both have 'boldfontcss', or neither have it, sort by associationName
                return a.associationName.localeCompare(b.associationName);
            }
            return focusA.localeCompare(focusB);
        });
        return records;
    }

    // Group city work by focus area
    groupByFocusArea(cityWork) {
        const groupedData = cityWork.reduce((acc, item) => {
            if (!acc[item.focusArea]) {
                acc[item.focusArea] = {
                    focusArea: item.focusArea,
                    color: item.color,
                    records: []
                };
            }
            acc[item.focusArea].records.push(item);
            return acc;
        }, {});
        // Convert to array and sort records inside each group by Name
        return Object.values(groupedData).map(group => {
            group.records.sort((a, b) => {
                // If 'a' has 'boldfontcss' and 'b' doesn't, 'a' should come before 'b'
                if (a.customCss === 'boldfontcss' && b.customCss !== 'boldfontcss') {
                    return -1; // 'a' comes first
                }
                // If 'b' has 'boldfontcss' and 'a' doesn't, 'b' should come before 'a'
                if (a.customCss !== 'boldfontcss' && b.customCss === 'boldfontcss') {
                    return 1; // 'b' comes first (so 'a' comes after 'b')
                }
                // If both have 'boldfontcss', or neither have it, sort by associationName
                return a.associationName.localeCompare(b.associationName);
            });
            return group;
        });
    }

    // Toggle showBenefit on click
    handleCityClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this.groupedCityWork = this.groupedCityWork.map(group => {
            return {
                ...group,
                records: group.records.map(record => {
                    if (record.orgAssociationId === recordId) {
                        return {
                            ...record,
                            showDescription: !record.showDescription
                        };
                    }
                    return record;
                })
            };
        });
    }

    // Toggle showBenefit on click
    handleStateClick(event) {
        const recordId = event.currentTarget.dataset.id;
        let stateWork = JSON.parse(JSON.stringify(this.stateWork));
        stateWork.forEach((record) => {
            if (record.orgAssociationId === recordId) {
                record.showDescription = !record.showDescription;
            }
        });
        this.stateWork = stateWork;
    }

    // Toggle showBenefit on click
    handleCountryClick(event) {
        const recordId = event.currentTarget.dataset.id;
        let countryWork = JSON.parse(JSON.stringify(this.countryWork));
        countryWork.forEach((record) => {
            if (record.orgAssociationId === recordId) {
                record.showDescription = !record.showDescription;
            }
        });
        this.countryWork = countryWork;
    }
}