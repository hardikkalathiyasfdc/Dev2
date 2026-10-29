import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCityAssociationCounts from '@salesforce/apex/CityViewDetailPageController.getCityAssociationCounts';

var lastShowGrants = false;

export default class CityViewCountryLevelWork extends NavigationMixin(LightningElement) {
    @api isCountrySelected = false;
    @api isStateSelected = false;
    @api showDetailPage;
    @api selectedGroupBy;
    @api formFactor;
    @track cityWork = [];
    @track error;
    associationWiseData = [];
    isLoading = false;
    isGeoAreaIdAvailable = false;
    hasPermission = false;
    selectedSort = 'association';
    selectedCityId;
    _shallShowGrants = false;
    _selectedGeoAreaId;

    @api
    get shallShowGrants() {
        return this._shallShowGrants;
    }
    set shallShowGrants(value) {
        lastShowGrants = value;
        this._shallShowGrants = value;
        if (this.geoAreaId && this._rawCityWork && this._rawCityWork.length > 0)
            this.applyGrantFilter();
    }

    @api
    get geoAreaId() {
        return this._selectedGeoAreaId;
    }
    set geoAreaId(value) {
        this.isGeoAreaIdAvailable = !!value;
        if (value !== this._selectedGeoAreaId) {
            this.fetchCityWork(value, 'Country');
        }
        this._selectedGeoAreaId = value;
    }

    get isMobile() {
        const normalizedFormFactor = this.formFactor ? this.formFactor.toLowerCase() : '';
        return (normalizedFormFactor === 'small' || normalizedFormFactor === 'medium') ? true : false;
    }

    get sortOptions() {
        return [
            { label: 'City', value: 'city' },
            { label: 'BP Work', value: 'association' }
        ];
    }

    get cityWorkData() {
        return this.cityWork;
    }

    get sortByCity() {
        return this.selectedGroupBy == 'city';
    }

    get sortByAssociation() {
        return this.selectedGroupBy == 'association';
    }

    get associationData() {
        return this.associationWiseData;
    }

    get tableStyle() {
        const normalizedFormFactor = this.formFactor ? this.formFactor.toLowerCase() : '';
        if (normalizedFormFactor === 'large') {
            return 'max-height: 300px !important; overflow: auto !important;';
        } else if (normalizedFormFactor === 'small' || normalizedFormFactor === 'medium') {
            return ''; // Empty style for small/medium form factor
        }
    }

    get showCityWork() {
        return this.cityWork.length > 0;
    }

    @api
    getCityLevelData() {
        if(this.selectedGroupBy == 'association') {
            return { data: this.associationData, shallShowGrants: this.shallShowGrants };
        } else {
            return { data: this.cityWorkData, shallShowGrants: this.shallShowGrants };
        }
    }

    connectedCallback() {
        this._shallShowGrants = lastShowGrants;
    }

    applyGrantFilter() {
        this.cityWork = this._getProcessedCities(this._rawCityWork);
        if(this.cityWork) this.getAssociationData();
        else this.fetchCityWork(this.geoAreaId, 'Country');
    }

    handleSortChange(event) {
        this.selectedSort = event.detail.value;
        this.getAssociationData();
        this.dispatchEvent(new CustomEvent('sortingvaluechangeonstatework', {
            detail: this.selectedSort,
            bubbles: true,
            composed: true
        }));
    }

    getAssociationData() {
        this.isLoading = true;
        const structuredData = this.restructureAssociationsByCity(this.cityWork);
        // Compute focus area totals (sum of active cities across associations in that focus area)
        const focusAreaTotals = new Map();
        structuredData.forEach(assoc => {
            const focusArea = assoc.associationData.focusArea || '';
            const activeCount = (assoc.cities || []).filter(c => c.isOngoingCity).length;
            assoc.activeCityCount = activeCount;
            focusAreaTotals.set(focusArea, (focusAreaTotals.get(focusArea) || 0) + activeCount);
        });
        // Sort: focus area total desc - association active count desc - name asc
        structuredData.sort((a, b) => {
            const focusA = a.associationData.focusArea || '';
            const focusB = b.associationData.focusArea || '';
            const totalA = focusAreaTotals.get(focusA) || 0;
            const totalB = focusAreaTotals.get(focusB) || 0;
            if(totalB !== totalA) return totalB - totalA;
            if(focusA !== focusB) return focusA.localeCompare(focusB); // tie-break for equal totals
            if(b.activeCityCount !== a.activeCityCount) return b.activeCityCount - a.activeCityCount;
            return a.displayName.localeCompare(b.displayName);
        });
        this.associationWiseData = structuredData;
        setTimeout(() => {
            this.isLoading = false;
        }, 500);
    }

    handleAssociationClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this.associationWiseData = this.associationWiseData.map(assoc => {
            if (assoc.orgId === recordId) {
                return {
                    ...assoc,
                    showCities: !assoc.showCities  //  Toggling the value
                };
            }
            return assoc;
        });
    }

    fetchCityWork(geoAreaId, selectedvalue) {
        this.isLoading = true;
        getCityAssociationCounts({
            geoAreaId: geoAreaId,
            selectedValue: selectedvalue
        }).then(result => {
            if (Array.isArray(result) && result.length > 0) {
                const citiesWithSortedOrgs = result.map(city => {
                    const sortedOrgs = [...(city.orgAssociations || [])].sort((a, b) => {
                        const focusA = (a.focusArea || '').toLowerCase();
                        const focusB = (b.focusArea || '').toLowerCase();
                        if (focusA === focusB) {
                            if (a.customcss === 'boldfontcss' && b.customcss !== 'boldfontcss') return -1;
                            if (a.customcss !== 'boldfontcss' && b.customcss === 'boldfontcss') return 1;
                            return a.associationName.localeCompare(b.associationName);
                        }
                        return focusA.localeCompare(focusB);
                    });
                    return {
                        ...city,
                        orgAssociations: sortedOrgs,
                        showAssociations: false
                    };
                });
                this._rawCityWork = JSON.parse(JSON.stringify(citiesWithSortedOrgs));
                this.cityWork = this._getProcessedCities(citiesWithSortedOrgs);
            } else {
                this.cityWork = [];
            }
            if (this.selectedGroupBy) this.selectedSort = this.selectedGroupBy;
            this.getAssociationData();
        }).catch(error => {
            console.error('Error fetching city work:', error);
            this.cityWork = [];
            this.error = error;
        }).finally(() => {
            this.isLoading = false;
        });
    }

    _getProcessedCities(citiesWithSortedOrgs) {
        const recordsToKeep = (org) => this.shallShowGrants || org.recordType !== 'Grant';
        if (!citiesWithSortedOrgs || citiesWithSortedOrgs.length == 0) { return citiesWithSortedOrgs; }
        const processed = citiesWithSortedOrgs.map(city => {
            let filteredOrgs = (city.orgAssociations || []).filter(recordsToKeep);
            const newCount = filteredOrgs.length;
            const baseName = (city.displayName || city.cityName || '').replace(/\s\(\d+\)$/, '');
            return {
                ...city,
                orgAssociations: filteredOrgs,
                associationCount: newCount,
                displayName: `${baseName} (${newCount})`
            };
        });
        const sortedCities = processed.filter(city => city.associationCount > 0)
            .sort((a, b) => {
                if (b.associationCount === a.associationCount) {
                    return a.displayName.localeCompare(b.displayName);
                }
                return b.associationCount - a.associationCount;
            });
        return sortedCities;
    }

    restructureAssociationsByCity(cityData) {
        const associationMap = new Map();
        cityData.forEach(city => {
            const {
                cityId,
                cityName,
                displayName: cityDisplayName,
                associationCount,
                orgAssociations = [],
                showAssociations,
                iconName
            } = city;

            orgAssociations.forEach(association => {
                const { associationName, startDate, endDate, showInitial } = association;
                let key = associationName; //+ association.nonConsecutive;
                if (!associationMap.has(key)) {
                    // Initialize the association entry
                    associationMap.set(key, {
                        associationName: associationName,
                        displayName: '', // set later
                        count: 0,
                        showCities: false,
                        orgId: association.orgAssociationId,
                        associationData: { ...association }, // full original
                        cities: [],
                        customCss: '',
                        showInitial: showInitial,
                        nonConsecutive: association.nonConsecutive
                    });
                }

                const assocEntry = associationMap.get(key);
                // Prevent duplicate city entry (edge case)
                const alreadyAdded = assocEntry.cities.some(c => c.cityId === cityId);
                if (!alreadyAdded) {
                    // Format the years only
                    let yearRange = '';
                    const startYear = startDate ? new Date(startDate).getUTCFullYear() : null;
                    const endYear = endDate && endDate != 'Present' ? new Date(endDate).getUTCFullYear() : endDate;

                    if (startYear && endYear) {
                        yearRange = ` (${startYear} - ${endYear})`;
                    } else if (startYear) {
                        yearRange = ` (${startYear} - Present)`;
                    }
                    const currentYear = new Date().getUTCFullYear();
                    const isOngoing = (typeof endYear === 'string' && endYear.toLowerCase() === 'present') ||
                        (typeof endYear === 'number' && endYear >= currentYear);
                    const isOngoingCity = yearRange && yearRange.toLowerCase().includes('present') ||
                        (typeof endYear === 'number' && endYear >= currentYear);

                    if (isOngoing) {
                        assocEntry.customCss = 'boldfontcss';
                    }

                    const cleanCityName = cityDisplayName.replace(/\s\(\d+\)$/, '');

                    assocEntry.cities.push({
                        cityId,
                        cityName,
                        displayName: `${cleanCityName}${yearRange}`,
                        associationCount,
                        showAssociations,
                        iconName,
                        isOngoingCity: isOngoingCity,
                        customCss: assocEntry.customCss,
                        nonConsecutive: association.nonConsecutive,
                        orgAssociation: { ...association } // include full original orgAssociation for this city
                    });
                    assocEntry.cities.sort((a, b) => {
                        if (a.isOngoingCity !== b.isOngoingCity) {
                            return a.isOngoingCity ? -1 : 1; // false comes first, true goes last
                        }
                        return a.cityName.localeCompare(b.cityName); // secondary sort
                    });
                    associationMap.set(key, assocEntry);
                    assocEntry.count++;
                }
            });
        });

        // Now finalize display names like "C40 (2)"
        associationMap.forEach((value, key) => {
            value.displayName = `${value.associationName} (${value.count})`;
        });

        return Array.from(associationMap.values());
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
            group.records.sort((a, b) => a.associationName.localeCompare(b.associationName)); // Sort records alphabetically
            return group;
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

    handleCityClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this.selectedCityId = recordId;
        // Create a new array by mapping over the original one
        this.cityWork = this.cityWork.map(city => {
            if (city.cityId === recordId) {
                let sortedAssociations = this.handleCustomSort(city.orgAssociations);
                const newShowAssociations = !city.showAssociations;
                  // ----- remove duplicate associations -----
                const associationNames = new Set();

                const uniqueAssociations = sortedAssociations.filter(association => {
                    const key = association.associationName; // adjust if needed
                    if (associationNames.has(key)) return false;
                    associationNames.add(key);
                    return true;
                });
                return {
                    ...city,
                    orgAssociations:uniqueAssociations,
                    showAssociations: newShowAssociations,
                    iconName: newShowAssociations ? 'utility:chevrondown' : 'utility:chevronright' // Toggle icon for clicked city
                };
            }
            return city; // Unchanged cities stay untouched
        });
    }


    handleOrgClick(event) {
        const orgId = event.currentTarget.dataset.id;
        const selectedCityId = this.selectedCityId;

        // Update cityWork immutably
        this.cityWork = this.cityWork.map(city => {
            if (city.cityId === selectedCityId) {
                city.orgAssociations = this.handleCustomSort(city.orgAssociations);
                // Update orgs
                const updatedOrgs = city.orgAssociations.map(org => {
                    if (org.orgAssociationId === orgId) {
                        return {
                            ...org,
                            showDescription: !org.showDescription // or toggle: !org.showDescription
                        };
                    }
                    return org;
                });

                return {
                    ...city,
                    orgAssociations: updatedOrgs
                };
            }
            return city;
        });
    }

    openSelectedCityDetails(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'CityView' // Name of your Lightning Tab
            },
            state: {
                c__selectedCityId: recordId,
                c__showDetail: 'true'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }
}