import { LightningElement, api } from 'lwc';
import getOrgAssociations from '@salesforce/apex/CityViewDetailPageController.getOrgAssociations';

export default class CityViewListViewForMobile extends LightningElement {
    @api selectedInitiativeId;
    selectedGeoId;
    processedCities = [];
    processedStates = [];
    processedCountries = [];
    shallShowSpinner = true;
    _cityRawData = [];
    _countryRawData = [];
    _stateRawData = [];
    _cityReady = false;
    _stateReady = false;
    _countryReady = false;
    _listViewGlobalTitle;
    _shallShowGrants = false;

    @api
    get shallShowGrants() {
        return this._shallShowGrants;
    }
    set shallShowGrants(value) {
        this._shallShowGrants = value;
        this.processData();
    }

    @api
    get listViewGlobalTitle() {
        return this._listViewGlobalTitle;
    }
    set listViewGlobalTitle(value) {
        this._listViewGlobalTitle = value;
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

    get selectedLevel() {
        if(this.listViewGlobalTitle) {
            return 'BP Work';
        }
        return null;
    }

    get cityRowCount() {
        return this.processedCities?.length || 0;
    }

    get stateRowCount() {
        return this.processedStates?.length || 0;
    }

    get countryRowCount() {
        return this.processedCountries?.length || 0;
    }

    get activeCityRowCount() {
        return this.processedCities.filter(r => r.hasActiveInitiative === true).length;
    }

    get activeStateRowCount() {
        return this.processedStates.filter(r => r.hasActiveInitiative === true).length;
    }

    get activeCountryRowCount() {
        return this.processedCountries.filter(r => r.hasActiveInitiative === true).length;
    }

    _checkIfReadyForProcessing() {
        if(this._cityReady && this._stateReady && this._countryReady) {
            this.processData();
            // Reset flags for future updatesshowCountryTableForCountries
            this._cityReady = this._stateReady = this._countryReady = false;
        }
    }

    async processData() {
        const cityData = this.cityRawData?.length ? JSON.parse(JSON.stringify(this.cityRawData)) : [];
        const countryData = this.countryRawData?.length ? JSON.parse(JSON.stringify(this.countryRawData)) : [];
        const stateRawData = this.stateRawData?.length ? JSON.parse(JSON.stringify(this.stateRawData)) : [];
        const combined = [...cityData, ...countryData, ...stateRawData];
        var activeGeoIds = new Set();
        let geoAreaToRecordTypes = new Map();
        let geoActiveCountMap = new Map();
           const geoAssociationRanges = new Map();
        var showGeoIds = new Set();
        await getOrgAssociations({
            geoAreaIds: combined.map(c => c.Id)
        }).then(orgAssociationList => {
            const today = new Date();
            const currentYear = today.getUTCFullYear();
            orgAssociationList.forEach(org => {
                const geoId = org?.Organization__r?.Government_Geo_Area__c;
                const rt = org?.RecordType?.DeveloperName;
                const assocName = org.Association__r?.CityView_Name_Override__c || org.Association__r?.Name;
                if(rt === 'Grant' && !this.shallShowGrants || org.Association__c !=this.selectedInitiativeId){
                    return;
                }
        const todayYear = new Date().getUTCFullYear();
                          const fromYear = org.From__c ? new Date(org.From__c).getUTCFullYear() : null;
                const toYear = org.To__c ? new Date(org.To__c).getUTCFullYear() : todayYear;
        
                if(!geoActiveCountMap.has(geoId)) {
                    geoActiveCountMap.set(geoId, 0);
                }
                  // active logic (unchanged)
                const isActive = (!org.To__c || new Date(org.To__c).getUTCFullYear() >= todayYear) && ((rt === 'Grant' && this.shallShowGrants) || rt != 'Grant');
                if(isActive) {
                    activeGeoIds.add(geoId);
                    geoActiveCountMap.set(geoId, (geoActiveCountMap.get(geoId) || 0) + 1);
                }
                if(((rt == 'Grant' && this.shallShowGrants) || rt != 'Grant') && org.Association__c == this.selectedInitiativeId) {
                    showGeoIds.add(geoId);
                }
                if(!geoAssociationRanges.has(geoId)) {
                    geoAssociationRanges.set(geoId, new Map());
                }
                 const assocMap = geoAssociationRanges.get(geoId);
                if(!assocMap.has(assocName)) {
                    assocMap.set(assocName, {
                        grant: { min: null, max: null },
                        initiative: { min: null, max: null },
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
                }
            });
            this.shallShowSpinner = false;
        }).catch(error => {
            console.error('Error fetching org associations:' + JSON.stringify(error.body));
            this.shallShowSpinner = false;
        });
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
                if(hasGrant && hasInitiative && (range.grant.min < range.initiative.min || range.grant.max > range.initiative.max)) {
                    hasOutsideGrant = true;
                }
            });
            // PRIORITY RULES
            if(hasOutsideGrant) {
                geoAreaToRecordTypes.set(geoId, ['utility:favorite', 'utility:favorite_alt']);
            } else if(hasOnlyGrant) {
                geoAreaToRecordTypes.set(geoId, ['utility:favorite_alt']); // ☆
            }
        });
        let iconTitleMap = new Map();
        iconTitleMap.set('utility:check', 'BRM Association');
        iconTitleMap.set('utility:favorite_alt', 'Grants Geo Area Served');
        iconTitleMap.set('utility:favorite', 'Strategic Location');
        const ICON_ORDER = {
            'utility:favorite': 1,
            'utility:favorite_alt': 2,
            'utility:check': 3
        };
        if(cityData.length) {
            this.processedCities = cityData.filter(c => showGeoIds.has(c.Id)).map(c => {
                const rtSet = geoAreaToRecordTypes.get(c.Id) || new Set();
                const iconTypeList = [...rtSet].sort((a, b) => {
                    const orderA = ICON_ORDER[a] ?? 999;
                    const orderB = ICON_ORDER[b] ?? 999;
                    return orderA - orderB;
                }).map((iconName, index) => {
                    let showIcon = true;
                    if(iconName === 'utility:favorite_alt') {
                        showIcon = this.shallShowGrants === true;
                    }
                    return {
                        key: `${c.Id}-${iconName}-${index}`,
                        name: iconName,
                        title: iconTitleMap.get(iconName),
                        showIcon: showIcon
                    };
                });
                return {
                    ...c,
                    hasActiveInitiative: activeGeoIds?.has(c.Id),
                    activeCount: geoActiveCountMap?.get(c.Id),
                    iconTypeList: iconTypeList
                };
            });
            this.processedCities = this.applySort(this.processedCities, 'hasActiveInitiative', 'ASC');
        }
        if(stateRawData.length) {
            this.processedStates = stateRawData.filter(c => showGeoIds.has(c.Id)).map(c => {
                const rtSet = geoAreaToRecordTypes.get(c.Id) || new Set();
                const iconTypeList = [...rtSet].sort((a, b) => {
                    const orderA = ICON_ORDER[a] ?? 999;
                    const orderB = ICON_ORDER[b] ?? 999;
                    return orderA - orderB;
                }).map((iconName, index) => {
                    let showIcon = true;
                    if(iconName === 'utility:favorite_alt') {
                        showIcon = this.shallShowGrants === true;
                    }
                    return {
                        key: `${c.Id}-${iconName}-${index}`,
                        name: iconName,
                        title: iconTitleMap.get(iconName),
                        showIcon: showIcon
                    };
                });
                return {
                    ...c,
                    hasActiveInitiative: activeGeoIds?.has(c.Id),
                    activeCount: geoActiveCountMap?.get(c.Id),
                    iconTypeList: iconTypeList
                };
            });
            this.processedStates = this.applySort(this.processedStates, 'hasActiveInitiative', 'ASC');
        }
        if(countryData.length) {
            this.processedCountries = countryData.filter(c => showGeoIds.has(c.Id)).map(c => {
                const rtSet = geoAreaToRecordTypes.get(c.Id) || new Set();
                const iconTypeList = [...rtSet].sort((a, b) => {
                    const orderA = ICON_ORDER[a] ?? 999;
                    const orderB = ICON_ORDER[b] ?? 999;
                    return orderA - orderB;
                }).map((iconName, index) => {
                    let showIcon = true;
                    if(iconName === 'utility:favorite_alt') {
                        showIcon = this.shallShowGrants === true;
                    }
                    return {
                        key: `${c.Id}-${iconName}-${index}`,
                        name: iconName,
                        title: iconTitleMap.get(iconName),
                        showIcon: showIcon
                    };
                });
                return {
                    ...c,
                    hasActiveInitiative: activeGeoIds?.has(c.Id),
                    activeCount: geoActiveCountMap?.get(c.Id),
                    iconTypeList: iconTypeList
                };
            });
            this.processedCountries = this.applySort(this.processedCountries, 'hasActiveInitiative', 'ASC');
        }
        setTimeout(() => {
            this.shallShowSpinner = false;
        }, 500);
    }

    applySort(list, sortBy, sortDirection) {
        let sortedData = [...list].sort((a, b) => {
            if(sortBy === 'hasActiveInitiative') {
                const aRank = a.hasActiveInitiative ? 0 : 1;
                const bRank = b.hasActiveInitiative ? 0 : 1;
                // Always force active first, inactive later — no ASC/DESC flipping
                if(aRank !== bRank) {
                    return aRank - bRank;
                }
                // Tie-breaker: sort by Name normally with ASC/DESC
                const nameA = (a.Name ?? '').toString().toLowerCase();
                const nameB = (b.Name ?? '').toString().toLowerCase();
                if(nameA < nameB) return sortDirection === 'ASC' ? -1 : 1;
                if(nameA > nameB) return sortDirection === 'ASC' ? 1 : -1;
                return 0;
            }
        });
        return sortedData;
    }

    sortData(list, sortBy, sortDirection) {
        const sorted = [...list].sort((a, b) => {
            const aActive = !!a.isActive;
            const bActive = !!b.isActive;
            if(aActive !== bActive) return aActive ? -1 : 1;
            let valA = a[sortBy] ?? '';
            let valB = b[sortBy] ?? '';
            if(typeof valA === 'string') valA = valA.toLowerCase();
            if(typeof valB === 'string') valB = valB.toLowerCase();
            if(valA < valB) return sortDirection === 'ASC' ? -1 : 1;
            if(valA > valB) return sortDirection === 'ASC' ? 1 : -1;
            return 0;
        });
        return sorted;
    }

    handleNameClick(event) {
        this.selectedGeoId = event.currentTarget.dataset.id;
        const dataType = event.currentTarget.dataset.type;
        let record;
        if(dataType == 'City') {
            record = this.processedCities.find(item => item.Id === this.selectedGeoId);
        } else if(dataType == 'State') {
            record = this.processedStates.find(item => item.Id === this.selectedGeoId);
        } else {
            record = this.processedCountries.find(item => item.Id === this.selectedGeoId);
        }
        this.dispatchEvent(new CustomEvent('geoareaselected', {
            detail: {
                geoId: this.selectedGeoId,
                selectedRecordName: record.Name
            }
        }));
    }
}