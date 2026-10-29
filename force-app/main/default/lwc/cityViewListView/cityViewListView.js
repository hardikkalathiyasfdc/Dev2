import { LightningElement, api, track } from 'lwc';
import getOrgAssociations from '@salesforce/apex/CityViewDetailPageController.getOrgAssociations';

var lastGlobalTitle;

export default class CityViewListView extends LightningElement {
    @api isCountrySelected;
    @api isStateSelected;
    @api isCitySelected;
    @api isSearchByInitiative;
    @api selectedInitiative;
    @api searchByInitiative;
    @track processedCities = [];
    @track processedCountries = [];
    @track processedStates = [];
    _listViewGlobalTitle;
    _isCountrySelected;
    _isStateSelected;
    _isCitySelected
    _isSearchByInitiative;
    _searchByInitiative;
    shallShowSpinner = true;
    selectedGeoId = '';
    _cityRawData;
    _stateRawData;
    _countryRawData;
    _cityReady = false;
    _stateReady = false;
    _countryReady = false;
    _shallShowGrants = false;

    @api
    get shallShowGrants() {
        return this._shallShowGrants;
    }
    set shallShowGrants(value) {
        this._shallShowGrants = value;
        this._checkIfReadyForProcessing();
    }

    @api
    get listViewGlobalTitle() {
        return this._listViewGlobalTitle;
    }
    set listViewGlobalTitle(value) {
        // Check if the value is null, undefined, or blank string
        if(value === null || value === undefined || value === '') {
            // Use the old value stored in lastGlobalTitle
            this._listViewGlobalTitle = lastGlobalTitle;
        } else if(value == 'hidefilter') {
            this._listViewGlobalTitle = null;
        } else {
            // Set new value normally
            this._listViewGlobalTitle = value;
            lastGlobalTitle = value;
        }
    }

    get selectedLevel() {
        if(this._isCountrySelected) {
            return 'Country';
        } else if(this._isStateSelected) {
            return 'State';
        } else if(this._isCitySelected) {
            return 'City';
        } else if(this._searchByInitiative) {
            return 'BP Work';
        }
        return null;
    }

    @api
    get cityRawData() {
        return this._cityRawData;
    }
    set cityRawData(value) {
        this._cityRawData = value ? [...value] : [];
        this._cityReady = true;
        this._checkIfReadyForProcessing();
    }
    
    @api
    get stateRawData() {
        return this._stateRawData;
    }
    set stateRawData(value) {
        this._stateRawData = value ? [...value] : [];
        this._stateReady = true;
        this._checkIfReadyForProcessing();
    }

    @api
    get countryRawData() {
        return this._countryRawData;
    }
    set countryRawData(value) {
        this._countryRawData = value ? [...value] : [];
        this._countryReady = true;
        this._checkIfReadyForProcessing();
    }
    
    _checkIfReadyForProcessing() {
        if(this._cityReady && this._stateReady && this._countryReady) {
            this._processAllData();
            // Reset flags for future updatesshowCountryTableForCountries
            this._cityReady = this._stateReady = this._countryReady = false;
        }
    }

    get showCountryTable() {
        return this._isStateSelected || this._isCitySelected || this._isSearchByInitiative || 
               (!this._isCitySelected && !this._isCountrySelected && !this._isStateSelected && !this._isSearchByInitiative);
    }

    get showForStatesAndCountry() {
        return (this._isCountrySelected || this._isStateSelected) && this.processedStates.length;
    }

    get showCityTable() {
        return this._isCountrySelected || this._isSearchByInitiative || this._isCitySelected || 
               (!this._isCitySelected && !this._isCountrySelected && !this._isStateSelected && !this._isSearchByInitiative);
    }

    get showCityTableForStates() {
        return this._isStateSelected;
    }

    get showStatesForCity() {
        return (this._isCitySelected || this._isSearchByInitiative || 
                (!this._isCitySelected && !this._isCountrySelected && !this._isStateSelected && !this._isSearchByInitiative)) 
               && this.processedStates.length;
    }

    get showCountryTableForCountries() {
        return this._isCountrySelected;
    }

    get showGrant() {
        return this.shallShowGrants;
    }

    async connectedCallback() {
        this._isCountrySelected = this.isCountrySelected;
        this._isStateSelected = this.isStateSelected;
        this._isCitySelected = this.isCitySelected;
        this._isSearchByInitiative = this.isSearchByInitiative;
        this._searchByInitiative = this.searchByInitiative;
        if(this._isSearchByInitiative) {
            this._isCountrySelected = false;
            this._isStateSelected = false;
            this._isCitySelected = false;
        }
    }

    async _processAllData() {
        const cityData = this.cityRawData?.length ? JSON.parse(JSON.stringify(this.cityRawData)) : [];
        const countryData = this.countryRawData?.length ? JSON.parse(JSON.stringify(this.countryRawData)) : [];
        const stateData = this.stateRawData?.length ? JSON.parse(JSON.stringify(this.stateRawData)) : [];
        const combined = [...cityData, ...stateData, ...countryData];
        const globalMax = Math.max(...combined.map(c => Number(c.bpCount) || 0));
        const showGeoIds = new Set();
        const activeGeoIds = new Set();
        const geoActiveCountMap = new Map();
        const geoAssociationRanges = new Map();

        const todayYear = new Date().getUTCFullYear();

        try {
            const associations = await getOrgAssociations({
                geoAreaIds: combined.map(c => c.geoAreaId)
            });
            associations.forEach(org => {
                const geoId = org?.Organization__r?.Government_Geo_Area__c;
                if(!geoId) return;
                const rt = org?.RecordType?.DeveloperName;
                if((rt === 'Grant' && !this.shallShowGrants || org.Association__c !=this.selectedInitiative) && this.searchByInitiative){
                    return;
                }
                const assocName =
                    org.Association__r?.CityView_Name_Override__c ||
                    org.Association__r?.Name;

                const fromYear = org.From__c ? new Date(org.From__c).getUTCFullYear() : null;
                const toYear = org.To__c ? new Date(org.To__c).getUTCFullYear() : todayYear;

                // active logic (unchanged)
                const isActive = (!org.To__c || new Date(org.To__c).getUTCFullYear() >= todayYear) && ((rt === 'Grant' && this.shallShowGrants) || rt != 'Grant');
                if(isActive) {
                    activeGeoIds.add(geoId);
                    geoActiveCountMap.set(geoId, (geoActiveCountMap.get(geoId) || 0) + 1);
                }
                // show geo logic (unchanged)
                showGeoIds.add(geoId);
                // ---------- RANGE TRACKING (FIX) ----------
                if(!geoAssociationRanges.has(geoId)) {
                    geoAssociationRanges.set(geoId, new Map());
                }
                const assocMap = geoAssociationRanges.get(geoId);
                if(!assocMap.has(assocName)) {
                    assocMap.set(assocName, {
                        grant: { min: null, max: null, defaultEndYear : null },
                        initiative: { min: null, max: null, defaultEndYear : null },
                        isNonConsecutive : false
                    });
                }
                const range = assocMap.get(assocName);
                if(rt === 'Grant') {
                    if(fromYear !== null && (range.grant.min === null || fromYear < range.grant.min)) {
                        range.grant.min = fromYear;
                    }
                    if(toYear !== null && (range.grant.max === null || toYear > range.grant.max)) {
                        range.grant.max = toYear;
                    }
                    if(range.grant.defaultEndYear != 'Present' ){
                       range.grant.defaultEndYear = org.To__c ? new Date(org.To__c).getUTCFullYear() : 'Present';
                    }
                } else {
                    if(fromYear > (range.initiative.max + 1) &&  range.isNonConsecutive == false && range.initiative.max != null){
                        range.isNonConsecutive = true;
                    }
                    if(fromYear !== null && (range.initiative.min === null || fromYear < range.initiative.min)) {
                        range.initiative.min = fromYear;
                    }
                    if(toYear !== null && (range.initiative.max === null || toYear > range.initiative.max)) {
                        range.initiative.max = toYear;
                    }
                     if(range.initiative.defaultEndYear != 'Present' ){
                       range.initiative.defaultEndYear = org.To__c ? new Date(org.To__c).getUTCFullYear() : 'Present';
                    }
                }
            });
        } catch (e) {
            console.error('Association fetch failed', e);
        }

        const geoIcons = new Map();
        geoAssociationRanges.forEach((assocMap, geoId) => {
            let hasOnlyGrant = false;
            let hasOutsideGrant = false;
            assocMap.forEach(range => {
                const hasGrant = range.grant.min !== null;
                const hasInitiative = range.initiative.min !== null;
                if(!hasGrant) return;
                // Only grant
                if(hasGrant && !hasInitiative) {
                    hasOnlyGrant = true;
                }
                // Grant outside initiative
                if(
                    hasGrant &&
                    hasInitiative &&
                    (range.grant.min < range.initiative.min ||
                        range.grant.max > range.initiative.max)
                ) {
                    hasOutsideGrant = true;
                }
            });
            if(hasOutsideGrant) {
                geoIcons.set(geoId, ['utility:favorite', 'utility:favorite_alt']);
            } else if(hasOnlyGrant) {
                geoIcons.set(geoId, ['utility:favorite_alt']); // ☆
            }
        });

        // ---------- UI BUILD ----------
        // Icons Related requirements are listed in BRME-6366 on Point 3
        const ICON_ORDER = {
            'utility:favorite': 1,
            'utility:favorite_alt': 2
        };

        const buildIcons = (geoId, name) =>
            (geoIcons.get(geoId) || []).map((icon, i) => ({
                key: `${name}-${icon}-${i}`,
                name: icon,
                title: icon === 'utility:favorite'
                    ? 'Strategic Location'
                    : 'Grants Geo Area Served',
                showIcon: true
            })).sort((a, b) => ICON_ORDER[a.name] - ICON_ORDER[b.name]);

        const toYear = value => {
            if (value === 'Present' || !value || value === 'N/A') return new Date().getUTCFullYear();
            const y = Number(value);
            return Number.isNaN(y) ? null : y;
        };

        const attachRanges = row => {
            const assocMap = geoAssociationRanges.get(row.geoAreaId);
            if(!assocMap || assocMap.size === 0) return;

            let grantMin = null;
            let grantMax = null;
            let initMin = null;
            let initMax = null;
           let isNonConsecutive = false;
            //  IMPORTANT: iterate Map VALUES
            let initiativeEndYear;
            let grantEndYear;
            for (const r of assocMap.values()) {
                const gMin = r?.grant?.min;
                const gMax = toYear(r?.grant?.max);
                const iMin = r?.initiative?.min;
                const iMax = toYear(r?.initiative?.max);
                if(r?.initiative?.defaultEndYear == 'Present' ){
                    initiativeEndYear = 'Present';  
                }
                 if(r?.grant?.defaultEndYear == 'Present' ){
                    grantEndYear = 'Present';  
                }

                if(!isNonConsecutive) isNonConsecutive = r.isNonConsecutive;
                if(gMin !== null) grantMin = grantMin === null ? gMin : Math.min(grantMin, gMin);
                if (gMax !== null) grantMax = grantMax === null ? r?.grant?.max  : r?.grant?.max == 'Present' ? gMax > (grantMax == 'Present' ? toYear(grantMax) : grantMax) ? 'Present' : grantMax : Math.min((grantMax == 'Present' ? toYear(grantMax) : grantMax), gMax);

                if(iMin !== null) initMin = initMin === null ? iMin : Math.min(initMin, iMin);
                if (iMax !== null) initMax =  initMax === null ? r?.initiative?.max  : r?.initiative?.max == 'Present' ? (iMax > (initMax == 'Present' ? toYear(initMax) : initMax) ? 'Present' : initMax ): Math.min((initMax == 'Present' ? toYear(initMax) : initMax), iMax);//initMax === null ? r?.initiative?.max == 'Present' ? 'Present' : iMax  : Math.max(initMax, iMax);
                                                        
            }
            //  Final geoArea-level values
            row.grantMinYear = grantMin;
            row.grantMaxYear = grantMax !== null ?  (grantEndYear == 'Present' ? (grantMax > toYear(grantEndYear) ? grantMax : grantEndYear ) : grantMax)  : grantMin !== null ? 'Present' : '';
            row.initiativeMinYear = initMin;
            row.initiativeMaxYear = initMax !== null ? (initiativeEndYear == 'Present' ? (initMax > toYear(initiativeEndYear) ? initMax : initiativeEndYear ) : initMax) : initMin !== null ? 'Present' : '';
            row.isNonConsecutive = isNonConsecutive;
        };

        const process = list =>
            list
                .filter(r => showGeoIds.has(r.geoAreaId))
                .map(r => {
                    r.hasActiveInitiative = activeGeoIds.has(r.geoAreaId);
                    r.activeCount = geoActiveCountMap.get(r.geoAreaId) || 0;
                    r.iconTypeList = buildIcons(r.geoAreaId, r.name);
                    attachRanges(r);
                    return this._processRow(r, globalMax);
                });
        this.processedCities =[...process(cityData)];
        this.processedStates = [...process(stateData)];
        this.processedCountries = [...process(countryData)];
        this.shallShowSpinner = false;
    }

    _processRow(c, maxCount) {
        const totalCount = Number(c.bpCount) || 0;
        const normalizedWidth = maxCount ? (totalCount / maxCount) * 100 : 0;
        const segments = (c.bpSegments || [])
            .map(s => {
                const width = totalCount > 0 ? (s.count / totalCount * 100).toFixed(1) : 0;
                return {
                    ...s,
                    style: `width: ${width}%; background-color: ${s.color};`
                };
            });
        return {
            ...c,
            normalizedWidth: normalizedWidth.toFixed(1),
            barStyle: `width: ${normalizedWidth.toFixed(1)}%;`,
            bpSegments: segments,
            hasActiveInitiative: c.hasActiveInitiative || false,
            rowClass: ''
        };
    }

    handleNameClick(event) {
        this.selectedGeoId = event.detail;
        this.processedCities = this.processedCities.map(city => ({
            ...city,
            rowClass: city.geoAreaId === this.selectedGeoId ? 'selected-row' : ''
        }));
        this.processedCountries = this.processedCountries.map(country => ({
            ...country,
            rowClass: country.geoAreaId === this.selectedGeoId ? 'selected-row' : ''
        }));
        this.dispatchEvent(new CustomEvent('geoareaselected', { detail: this.selectedGeoId }));
    }
}