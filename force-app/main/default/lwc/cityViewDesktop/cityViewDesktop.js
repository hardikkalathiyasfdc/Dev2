import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { publish, subscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import GEO_AREA_MESSAGE_CHANNEL from '@salesforce/messageChannel/geoAreaSelected__c';
import CITY_VIEW_FILTERS_CHANNEL from '@salesforce/messageChannel/CityViewFiltersMessageChannel__c';
import TOGGLE_FILTERS_CHANNEL from '@salesforce/messageChannel/ToggleFiltersMessageChannel__c';
import CITY_VIEW_GLOBAL_FILTERS_CHANNEL from '@salesforce/messageChannel/CityViewGlobalFiltersMessageChannel__c';
import getGeoArea from '@salesforce/apex/CityViewController.getGeoArea';
import NAME_FIELD from '@salesforce/schema/Association__c.Name'

export default class CityViewDesktop extends LightningElement {
    @api rawData = [];
    @track selectedMapMarker;
    @track mapMarkers = [];
    @track filters = {};
    @track filteredMapMarkers = [];
    @track tempFilteredMapMarkers = [];
    @track countryGeoAreaIdList = [];
    @track stateGeoAreaIdlist = [];
    @track cityGeoAreaIdList = [];
    @track tempFilteredListViewData = [];
    @track selectedFocusAreas = ['All'];
    @track focusAreas = [];
    @track focusAreaMap;
    showMainPage = true;
    showDetail = false;
    showSideBar = true;
    isSearchByCountry = false;
    isSearchByState = false;
    listViewGlobalTitle = '';
    currentView = 'Map View';
    geoAreaId;
    shallShowGrants = false;
    zoomLevel = 3;
    isLoading = true;
    isInitiativeSelected = false;
    selectedInitiative = '';
    filterSubscription = null;
    toggleFilterSubscription = null;
    isContentBlurred = false;
    isSpinnerVisible = false;
    selectedHighlightSort = 'allTime';
    selectedGroupByForCityOnCountryLevel = 'association';
    selectedGroupByForStateOnCountryLevel = 'association';
    recordTypeName;
    searchBy = 'City';
    isCitySidebarOpen = false;
    wiredGeoAreaResult;
    showFilter = false;
    isMapSpinnerVisible = false;
    isNotLoadingMap = true;

    markerIcon = {
        path: "M 50, 50 m -25, 0 a 25,25 0 1,0 50,0a 25,25 0 1,0 -50,0",
        fillOpacity: 1,
        strokeOpacity: 0,
        strokeWeight: 1,
        anchor: { x: 50, y: 50 },
        scale: 0.2
    }

    triangleIcon = {
        path: "M 12 4 L 20 20 L 4 20 Z",
        fillColor: "black",
        fillOpacity: 1,
        scale: 1,
        strokeColor: "black",
        strokeWeight: 0
    };

    squareIcon = {
        path: "M 4 4 L 20 4 L 20 20 L 4 20 Z",
        fillColor: "black",
        fillOpacity: 1,
        scale: 0.8,
        strokeColor: "black",
        strokeWeight: 0
    };

    markerOfficeIcon = {
        path: "M948.1,1129.1c0,14.7-12,26.7-26.7,26.7H307.4c-14.7,0-26.7-12-26.7-26.7v-480.6c0-14.7,12-26.7,26.7-26.7h614c14.7,0,26.7,12,26.7,26.7v480.6 " +
            "M1682,1129c0,14.7-12,26.7-26.7,26.7h-614c-14.7,0-26.7-12-26.7-26.7v-480.6c0-14.7,12-26.7,26.7-26.7h614c14.7,0,26.7,12,26.7,26.7v480.6 " +
            "M910.5,1300.9v45c0,16.7,29.9,30.3,66.8,30.3s66.8-13.6,66.8-30.3v-45l3.1.3c104.1,11.5,176.7,49.3,176.7,95.4s-109.7,100-245.1,100-245.1-44.8-245.1-100,73.9-83.6,175.3-95.8l1.5.2",
        fillColor: "white",
        fillOpacity: 1,
        scale: 0.017,
        strokeColor: "black",
        strokeWeight: 1.5
    };

    mapOptions = {
        disableDefaultUI: true,
        zoomControl: true,
        scrollwheel: true
    };

    center = {
        location: { Latitude: '0', Longitude: '0' },
    };

    get cityRawData() {
        return this.cityGeoAreaIdList;
    }

    get stateRawData() {
        return this.stateGeoAreaIdlist;
    }

    get countryRawData() {
        return this.countryGeoAreaIdList;
    }

    get isCountrySelected() {
        return this.recordTypeName == 'Country';
    }

    get isStateSelected() {
        return this.recordTypeName == 'State';
    }

    get isCitySelected() {
        return this.recordTypeName == 'City';
    }

    get searchByCountry() {
        return this.searchBy == 'Country';
    }

    get searchByCity() {
        return this.searchBy == 'City';
    }

    get searchByState() {
        return this.searchBy == 'State';
    }

    get searchByInitiative() {
        return this.searchBy == 'BP Work';
    }

    get shallShowMapView() {
        return this.currentView === 'Map View';
    }

    get disableFilterCss() {
        return this.isInitiativeSelected ? 'unclickable' : '';
    }

    get isNotLoading() {
        return !this.isLoading;
    }

    get selectedCityName() {
        return this.selectedMapMarker?.title;
    }

    get hasActiveFilters() {
        const f = this.filters || {};
        const selected = Array.isArray(f.selectedFocusAreas) ? f.selectedFocusAreas : [];
        const totalFocusAreas = Array.isArray(this.focusAreas) ? this.focusAreas.length : 0;
        const focusIsDefault = selected.length === totalFocusAreas + 1 && selected.includes('All');
        const focusIsActive = selected.length > 0 && !focusIsDefault;
        const otherActive = !!f.showOffices || !!f.showGrants;
        return focusIsActive || otherActive;
    }

    get citySidebarClass() {
        return `city-sidebar ${this.isCitySidebarOpen ? 'open' : ''}`;
    }

    get isCitySidebarHidden() {
        return !this.isCitySidebarOpen;
    }

    get mainPageStyles() {
        return this.showMainPage ? 'display: block;' : 'display: none;';
    }

    get splitViewClass() {
        return `split-view ${this.isCitySidebarOpen ? 'sidebar-open' : ''}`;
    }

    get isLoadingMap() {
        return !this.isNotLoadingMap;
    }

    openCitySidebarAnimated() {
        this.isFiltersPopupOpen = false;
        this.isCitySidebarOpen = true;
    }

    closeCitySidebar() {
        this.isCitySidebarOpen = false;
    }

    handleApplyFiltersFromPopup(event) {
        const applyPayload = event.detail;
        const {
            geoAreaIds, officeGeoAreas,
            ...state
        } = applyPayload;
        this.filters = JSON.parse(JSON.stringify({
            ...this.filters,
            ...state
        }));
        publish(this.messageContext, CITY_VIEW_FILTERS_CHANNEL, applyPayload);
    }

    handleFiltersReadyFromPopup(event) {
        this.filters = JSON.parse(JSON.stringify({
            ...this.filters,
            ...event.detail
        }));
    }

    handleSearchFilter(event) {
        this.isInitiativeSelected = event.detail == 'BP Work';
        this.searchBy = event.detail;
    }

    handleSortingValueChangeOnCityWork(event) {
        this.selectedGroupByForCityOnCountryLevel = event.detail;
    }

    handleSortingValueChangeOnStateWork(event) {
        this.selectedGroupByForStateOnCountryLevel = event.detail;
    }
    
    handleHighlightSorting(event) {
        this.selectedHighlightSort = event.detail;
    }

    @wire(MessageContext) messageContext;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if(currentPageReference && currentPageReference.state) {
            this.showDetail = currentPageReference.state.c__showDetail || false;
            const showDetail = currentPageReference.state.c__showDetail === 'true';
            this.showSideBar = !showDetail;
            this.showMainPage = !showDetail;
            this.showDetail = showDetail;
        }
    }

    @wire(getGeoArea, { 
        geoAreaId: '$geoAreaId' 
    }) wiredRecord(result) {
        this.wiredGeoAreaResult = result;
        const { data, error } = result;
        if(data) {
            this.recordTypeName = data.RecordType?.Name || '';
            this.showSideBar = false;
            this.handleShowSideBar();
        } else if(error) {
            console.log('Error fetching record type:', error);
        }
    }

    @wire(getRecord, {
        recordId: '$selectedInitiative',
        fields: [NAME_FIELD]
    }) wiredAssociation({ data, error }) {
        if(data) {
            this.listViewGlobalTitle = data.fields.Name.value;
        }
    }

    subscribeToMessageChannel() {
        subscribe(
            this.messageContext,
            GEO_AREA_MESSAGE_CHANNEL,
            (message) => this.handleMessage(message),
            { scope: APPLICATION_SCOPE }
        );
        subscribe(
            this.messageContext,
            CITY_VIEW_GLOBAL_FILTERS_CHANNEL,
            (message) => {
                this.shallShowGrants = !!message.filters.showGrants;
                let processingdata = this.tempFilteredListViewData.length > 0 ? this.tempFilteredListViewData : this.rawData;
                this.processDataForListView(processingdata);
            }, { scope: APPLICATION_SCOPE }
        );
        if(!this.filterSubscription) {
            this.filterSubscription = subscribe(
                this.messageContext,
                CITY_VIEW_FILTERS_CHANNEL,
                (message) => this.filterMarkersData(message)
            );
        }
        if(!this.toggleFilterSubscription) {
            this.toggleFilterSubscription = subscribe(
                this.messageContext,
                TOGGLE_FILTERS_CHANNEL,
                (message) => this.clearSelectedMarker()
            );
        }
    }

    clearSelectedMarker() {
        this.listViewGlobalTitle = 'hidefilter';
        this.geoAreaId = null;
        this.selectedMapMarker = '';
        this.filteredMapMarkers = this.tempFilteredMapMarkers;
        this.processDataForListView(this.tempFilteredListViewData);
        this.handleDetailClose();
    }

    async filterMarkersData(message) {
        this.isInitiativeSelected = false;
        if(message.isLoading !== undefined) {
            this.isNotLoadingMap = !message.isLoading;
            return;
        }
        this.isNotLoadingMap = false;
        try {
            if(message && message.geoAreaIds && Array.isArray(message.geoAreaIds) && message.geoAreaIds.length > 0) {
                this.isSearchByCountry = false;
                this.isSearchByState = false;
                if(message.searchBy === 'BP Work') {
                    this.isInitiativeSelected = true;
                    this.selectedInitiative = message.selectedId;
                    this.filters.selectedFocusAreas = ['All', ...this.focusAreas.map(area => area.focusAreaName)];
                    this.handleDetailClose();
                } else if(message.searchBy === 'Country') {
                    this.isSearchByCountry = true;
                } else if(message.searchBy === 'State') {
                    this.isSearchByState = true;
                }
                const geoAreaIds = message.geoAreaIds;
                const geoIds = Array.isArray(message.geoAreaIds) ? message.geoAreaIds : [];
                const geoSet = new Set(geoIds);
                const geoMatchFn = (rec) => geoSet.has(rec.Geo_Area__c);
                const cityGeoMatchFn = (rec) => geoSet.has(rec.Geo_Area__r?.Parent__c);
                const focusMatchFn = (rec) =>
                    !message.selectedFocusAreas.length ||
                    message.selectedFocusAreas.includes(rec.Focus_Area_Name__c);
                // 2️ Filter main data
                let filteredData = this.rawData.filter(rec => geoMatchFn(rec) && focusMatchFn(rec));
                // 3️ Base list-view data = all records matching direct Geo Area
                let filteredDataForListView = this.rawData.filter(geoMatchFn);
                // 4 If state selected → include state + its parent country
                if(this.isStateSelected && filteredDataForListView.length > 0) {
                    const parentId = filteredDataForListView[0].Geo_Area__r.Parent__c;
                    const grandParentId = filteredDataForListView[0].Geo_Area__r.Parent__r.Parent__c;
                    filteredDataForListView = this.rawData.filter(rec =>
                        geoMatchFn(rec) || rec.Geo_Area__c == parentId || rec.Geo_Area__c == grandParentId || cityGeoMatchFn(rec)
                    );
                }
                // 5 If still empty → include grandparents (country > state > city)
                if(filteredDataForListView.length === 0) {
                    filteredDataForListView = this.rawData.filter(rec =>
                        geoMatchFn(rec) ||
                        geoAreaIds.includes(rec.Geo_Area__r.Parent__c) ||
                        geoAreaIds.includes(rec.Geo_Area__r.Parent__r?.Parent__c)
                    );
                }
                this.tempFilteredListViewData = filteredDataForListView;
                this.processDataForListView(filteredDataForListView);
                this.tempFilteredListViewData = filteredDataForListView;
                const groupedData = await this.groupByGeoAreaAndFocusArea(filteredData);
                this.filteredMapMarkers = await this.formatMapMarkers(groupedData);
                this.tempFilteredMapMarkers = this.filteredMapMarkers;
                if(message.gcomGeoAreas) {
                    this.addGcomMarkers(message.gcomGeoAreas);
                }
                if(message.officeGeoAreas) {
                    this.addOfficeMarkers(message.officeGeoAreas);
                }
                if(!this.isSearchByCountry && !this.isSearchByState) this.closeCitySidebar();
            }
        } catch(error) {
            console.error('Error while applying filters: ' + JSON.stringify(error.body));
        } finally {
            setTimeout(() => {
                this.isNotLoadingMap = true;
            }, 2000);
        }
    }

    addGcomMarkers(gcomGeoAreas, isForDetailPage) {
        if(!Array.isArray(gcomGeoAreas) || gcomGeoAreas.length === 0) {
            return;
        }
        const govInnovationColor = this.focusAreas.find(f => f.focusAreaName === 'Environment')?.colorCode || '#00000';
        const newMarkersMap = new Map();
        const cityMap = new Map();
        this.cityGeoAreaIdList.forEach(city => {
            cityMap.set(city.geoAreaId, { ...city });
        });
        gcomGeoAreas.forEach(area => {
            const latitude = area.Coordinates__c?.latitude;
            const longitude = area.Coordinates__c?.longitude;
            const geoId = area.Id;
            const name = area.Name;
            if(latitude && longitude) {
                const marker = {
                    geoAreaId: geoId,
                    value: geoId,
                    location: {
                        Latitude: latitude,
                        Longitude: longitude
                    },
                    focusArea: 'Government Innovation',
                    focusAreaColor: govInnovationColor,
                    title: name,
                    description: name,
                    mapIcon: {
                        ...this.markerIcon,
                        fillColor: govInnovationColor,
                        strokeColor: govInnovationColor
                    }
                };
                newMarkersMap.set(geoId, marker);

                const newSegment = {
                    focusArea: 'Environment',
                    count: 1,
                    color: govInnovationColor
                };
                if(!cityMap.has(geoId)) {
                    cityMap.set(geoId, {
                        geoAreaId: geoId,
                        name: name,
                        highlightCount: area?.Interaction_Count__c || '',
                        officeCount: area?.Office_Count__c || '',
                        bpCount: area?.Association_Count__c + 1,
                        hasCulturalAccess: (area?.Cultural_Access_Count__c > 0),
                        bpSegments: [{ ...newSegment }]
                    });
                }
            }
        });
        const updatedMarkers = this.filteredMapMarkers.filter(marker => !newMarkersMap.has(marker.geoAreaId));
        if(isForDetailPage) {
            return [...updatedMarkers, ...Array.from(newMarkersMap.values())];
        } else {
            this.filteredMapMarkers = [...updatedMarkers, ...Array.from(newMarkersMap.values())];
            this.tempFilteredMapMarkers = this.filteredMapMarkers;
            this.cityGeoAreaIdList = Array.from(cityMap.values());
        }
    }

    addOfficeMarkers(officeGeoAreas) {
        if(!Array.isArray(officeGeoAreas) || officeGeoAreas.length === 0) {
            return;
        }
        const geoAreaMap = new Map();
        const cityMap = new Map();
        this.cityGeoAreaIdList.forEach(city => {
            cityMap.set(city.geoAreaId, { ...city });
        });
        officeGeoAreas.forEach(office => {
            const geoAreaId = office.Geo_Area__c;
            const latitude = office?.Geo_Area__r?.Coordinates__c?.latitude;
            const longitude = office?.Geo_Area__r?.Coordinates__c?.longitude;
            if(!geoAreaMap.has(geoAreaId)) {
                geoAreaMap.set(geoAreaId, {
                    geoAreaId: geoAreaId,
                    latitude: latitude,
                    longitude: longitude,
                    addresses: [],
                    title: office.Geo_Area__r.Name,
                    name: office.Name
                });
            }
            geoAreaMap.get(geoAreaId).addresses.push(
                [office.Address__c.street, office.Address__c.city, office.Address__c.state, office.Address__c.postalCode, office.Address__c.country]
                    .filter(value => value && value.trim())
                    .join(', ')
            );

            if(!cityMap.has(geoAreaId)) {
                cityMap.set(geoAreaId, {
                    geoAreaId: geoAreaId,
                    name: office?.Geo_Area__r?.Name,
                    highlightCount: office?.Geo_Area__r?.Interaction_Count__c || '',
                    officeCount: office?.Geo_Area__r?.Office_Count__c || '',
                    bpCount: office?.Geo_Area__r?.Association_Count__c + 1,
                    hasCulturalAccess: (office?.Geo_Area__r?.Cultural_Access_Count__c > 0),
                    bpSegments: []
                });
            }
        });
        const officeMarkers = Array.from(geoAreaMap.values()).map(geoArea => ({
            location: {
                Latitude: geoArea.latitude,
                Longitude: geoArea.longitude
            },
            geoAreaId: geoArea.geoAreaId,
            value: geoArea.geoAreaId,
            title: geoArea.title,
            description: `Bloomberg Office(s):<br/>${geoArea.addresses.join('<br/>')}`,
            addresses: geoArea.addresses,
            mapIcon: this.markerOfficeIcon,
            isOfficeMarker: true
        }));
        this.filteredMapMarkers = [...this.filteredMapMarkers, ...officeMarkers];
        this.tempFilteredMapMarkers = this.filteredMapMarkers;
        this.cityGeoAreaIdList = Array.from(cityMap.values());
    }

    filteredDataMapped() {
        // Build cached maps for O(1) lookups
        if(!this.mapMarkerMap) {
            this.mapMarkerMap = new Map(this.mapMarkers.map(m => [m.geoAreaId, m]));
        }
        if(!this.rawDataMap) {
            this.rawDataMap = new Map(this.rawData.map(r => [r.Geo_Area__c, r]));
        }

        const foundMarker = this.mapMarkerMap.get(this.geoAreaId);
        const matchingRecord = this.rawDataMap.get(this.geoAreaId);
        let relatedGeoAreaIds = new Set([this.geoAreaId]); // always include self

        if(matchingRecord?.Geo_Area__r) {
            const geoArea = matchingRecord.Geo_Area__r;
            const recordTypeName = geoArea?.RecordType?.Name;

            // CITY → include parent (state) and grandparent (country)
            if(recordTypeName === 'City') {
                if(geoArea?.Parent__c) relatedGeoAreaIds.add(geoArea.Parent__c);
                if(geoArea?.Parent__r?.Parent__c) relatedGeoAreaIds.add(geoArea.Parent__r.Parent__c);
            }

            // STATE → include parent (country) + cities under this state
            if(recordTypeName === 'State') {
                if(geoArea?.Parent__c) relatedGeoAreaIds.add(geoArea.Parent__c); // parent country
            }
        }

        // Filter records based on relationship
        const filteredData = this.rawData.filter(record => {
            const geoArea = record.Geo_Area__r;
            if(!geoArea) return false;

            // CITY selection
            if(matchingRecord?.Geo_Area__r?.RecordType?.Name === 'City') {
                return (
                    relatedGeoAreaIds.has(record.Geo_Area__c)                         // self (city)
                );
            }

            // STATE selection
            if(matchingRecord?.Geo_Area__r?.RecordType?.Name === 'State') {
                return (
                    record.Geo_Area__c === this.geoAreaId ||                          // the selected state
                    geoArea?.Parent__c === this.geoAreaId ||                          // cities under this state
                    record.Geo_Area__c === matchingRecord.Geo_Area__r.Parent__c       // parent country
                );
            }

            // COUNTRY or other types — include just itself
            return record.Geo_Area__c === this.geoAreaId;
        });

        return { data: filteredData, foundMarker };
    }

    async handleMessage(message) {
        if(!message.selectedFromListView) {
            this.listViewGlobalTitle = message?.geoAreaRec?.title;
        }
        this.isInitiativeSelected = false;  // Reset flag to ensure the list view renders correctly when switching from initial BP Work selection to a list record.
        this.geoAreaId = message.geoAreaId;
        try {
            await refreshApex(this.wiredGeoAreaResult);
        } catch (error) {
            console.log('Refresh failed', error);
        }
        const environmentColor = this.focusAreas.find(f => f.focusAreaName === 'Environment')?.colorCode || '#00000';
        const otherMarkerColor = message?.geoAreaRec?.hasGcomData ? environmentColor : '#A9A9A9';
        if(message.geoAreaId) {
            if(!message.mapMarkerSelected && !message.viewDetailFromSummary) {
                let filteredData = this.filteredDataMapped();
                this.tempFilteredListViewData = filteredData.data;
                if(this.searchBy == 'City') {
                    this.processDataForListView(filteredData.data);
                }
                if(filteredData.foundMarker) {
                    this.selectedMapMarker = filteredData.foundMarker;
                } else {
                    let markerIcon = this.isStateSelected ? this.squareIcon : this.markerIcon
                    this.selectedMapMarker = {
                        geoAreaId: this.geoAreaId,
                        title: message?.geoAreaRec?.title,
                        name: message?.geoAreaRec?.name,
                        value: this.geoAreaId,
                        description: message?.geoAreaRec?.title,
                        location: {
                            Latitude: message?.geoAreaRec?.latitude,
                            Longitude: message?.geoAreaRec?.longitude
                        },
                        mapIcon: {
                            ...markerIcon,
                            fillColor: otherMarkerColor,
                            strokeColor: otherMarkerColor
                        }
                    };
                    const cityMap = new Map();
                    const newSegment = {
                        focusArea: 'Environment',
                        count: 1,
                        color: otherMarkerColor
                    };
                    cityMap.set(this.geoAreaId, {
                        geoAreaId: this.geoAreaId,
                        name: message?.geoAreaRec?.title,
                        highlightCount: message?.geoAreaRec?.interactionCount || '',
                        officeCount: message?.geoAreaRec?.officeCount || '',
                        bpCount: message?.geoAreaRec?.associationCount + 1,
                        hasCulturalAccess: (message?.geoAreaRec?.culturalAccessCount > 0),
                        bpSegments: [{ ...newSegment }]
                    });
                    this.cityGeoAreaIdList = Array.from(cityMap.values());
                    this.countryGeoAreaIdList = [];
                    this.stateGeoAreaIdlist = [];
                }
                this.isSpinnerVisible = true;
                this.filters.selectedFocusAreas = ['All', ...this.focusAreas.map(area => area.focusAreaName)];
                this.filteredMapMarkers = [this.selectedMapMarker];
                this.filteredMapMarkers = this.formatMapMarkers(filteredData.data);
                setTimeout(() => {
                    this.isSpinnerVisible = false;
                }, 1000);
            }
            if(message.showDetailPage || message.viewDetailFromSummary) {
                this.showDetailPage();
            }
            if(!this.isInitiativeSelected) this.openCitySidebarAnimated();
            else this.closeCitySidebar();
        } else {
            this.handleDetailClose();
            this.closeCitySidebar();
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.tempFilteredListViewData = [...this.rawData];
        this.processDataForListView(this.rawData);
        this.processGeoAreaData(this.rawData)
            .then(() => this.generateFocusAreas())
            .then(() => {
                this.isLoading = false;
                this.handleShowSideBar();
            })
            .catch(err => {
                this.isLoading = false;
            });
    }

    handleShowSideBar() {
        if(this.recordTypeName && this.isLoading == false) {
            this.showSideBar = true;
        }
    }
    
    handleAssociationSelection() {
        this.showDetail = false;
        this.currentView = 'List View';
        this.showSideBar = true;
        this.showFilter = true;
    }

    processGeoAreaData(data) {
        return new Promise((resolve, reject) => {
            try {
                const groupedData = this.groupByGeoAreaAndFocusArea(data);
                this.mapMarkers = this.formatMapMarkers(groupedData);
                this.filteredMapMarkers = [];
                setTimeout(() => {
                    this.filteredMapMarkers = this.mapMarkers;
                }, 0);
                this.tempFilteredMapMarkers = this.filteredMapMarkers;
                resolve();
            } catch (error) {
                reject(error);
            }
        });
    }

    processDataForListView(data) {
        return new Promise((resolve, reject) => {
            try {
                const geoMap = new Map();
                const gcomGeoIds = new Set();
                // this.rawdata is replaced by data to fix BP Work issue
                data.forEach(record => {
                    const geoId = record.Geo_Area__c;
                    const focusArea = record.Focus_Area_Name__c;
                    let associationCount = 0;
                    if(this.shallShowGrants) {
                        associationCount = (record.Association_Count__c || 0) + (record.Grant_Association_Count__c || 0);
                    } else {
                        associationCount = record.Association_Count__c || 0;
                    }
                    if(!geoMap.has(geoId)) {
                        geoMap.set(geoId, {
                            geoAreaId: geoId,
                            name: record?.Geo_Area__r?.Name,
                            highlightCount: record?.Geo_Area__r?.Interaction_Count__c || '',
                            officeCount: record?.Geo_Area__r?.Office_Count__c || '',
                            hasCulturalAccess: (record?.Geo_Area__r?.Cultural_Access_Count__c > 0),
                            bpSegments: new Map(),
                            recordType: record?.Geo_Area__r?.RecordType?.Name,
                            parent: record?.Geo_Area__r?.Parent__c,
                            grandParent: record?.Geo_Area__r?.Parent__r?.Parent__c
                        });
                    }
                    const geoEntry = geoMap.get(geoId);
                    if(!geoEntry.bpSegments.has(focusArea) && (associationCount !== 0 || record.Grant_Association_Count__c)) {
                        geoEntry.bpSegments.set(focusArea, {
                            focusArea: focusArea,
                            count: associationCount,
                            color: record.Color_Code__c
                        });
                    }
                    if(record?.Geo_Area__r?.Has_GCOM_Association__c === true) {
                        gcomGeoIds.add(geoId);
                    }
                });
                gcomGeoIds.forEach(geoId => {
                    const geoEntry = geoMap.get(geoId);
                    if(!geoEntry) return;
                    const envSegment = geoEntry.bpSegments.get('Environment');
                    if(envSegment) {
                        envSegment.count += 1;
                    } else {
                        geoEntry.bpSegments.set('Environment', {
                            focusArea: 'Environment',
                            count: 1,
                            color: '#3F843E'
                        });
                    }
                    geoMap.set(geoId,geoEntry);
                });
                const cityList = [];
                const countryList = [];
                const stateList = [];
                geoMap.forEach(entry => {
                    const wrapper = {
                        geoAreaId: entry.geoAreaId,
                        name: entry.name,
                        initial: entry.initial,
                        showInitial: entry.showInitial,
                        highlightCount: entry.highlightCount === 0 ? '' : entry.highlightCount,
                        officeCount: entry.officeCount === 0 ? '' : entry.officeCount,
                        bpCount: Array.from(entry.bpSegments.values()).reduce((sum, seg) => sum + seg.count, 0),
                        hasCulturalAccess: entry.hasCulturalAccess,
                        bpSegments: Array.from(entry.bpSegments.values()),
                        parent: entry.parent,
                        grandParent: entry.grandParent
                    };
                    if(entry.recordType === 'City') {
                        cityList.push(wrapper);
                    } else if(entry.recordType === 'State') {
                        stateList.push(wrapper);
                    } else if(entry.recordType === 'Country') {
                        countryList.push(wrapper);
                    }
                });
                this.cityGeoAreaIdList = cityList;
                this.stateGeoAreaIdlist = stateList;
                this.countryGeoAreaIdList = countryList;
                resolve();
            } catch (error) {
                reject(error);
            }
        });
    }

    handleViewChange(event) {
        this.currentView = event.detail;
    }

    groupByGeoAreaAndFocusArea(data) {
        const geoAreaMap = new Map();
        data.forEach(record => {
            const geoAreaId = record.Geo_Area__c;
            if(!geoAreaMap.has(geoAreaId) || record.Weight__c > geoAreaMap.get(geoAreaId).Weight__c) {
                geoAreaMap.set(geoAreaId, record);
            }
        });
        return Array.from(geoAreaMap.values());
    }

    formatMapMarkers(groupedData) {
        return groupedData.map(record => {
            const color = record.Color_Code__c ? record.Color_Code__c : '#808080';
            let markerIcon;
            if(record.Geo_Area__r.RecordType.Name == 'Country') {
                markerIcon = {
                    ...this.triangleIcon,
                    fillColor: color,
                    strokeColor: color
                };
            } else if(record.Geo_Area__r.RecordType.Name == 'State') {
                markerIcon = {
                    ...this.squareIcon,
                    fillColor: color,
                    strokeColor: color
                };
            } else {
                markerIcon = this.markerIcon
                markerIcon = {
                    ...markerIcon,
                    fillColor: color,
                    strokeColor: color
                };
            }
            const latitude = record?.Geo_Area__r?.Coordinates__c?.latitude;
            const longitude = record?.Geo_Area__r?.Coordinates__c?.longitude;
            return {
                geoAreaId: record.Geo_Area__c,
                value: record.Geo_Area__c,
                location: {
                    Latitude: latitude,
                    Longitude: longitude
                },
                focusArea: record.Focus_Area_Name__c,
                focusAreaColor: color,
                title: record.Geo_Area__r.Name,
                description: record.Geo_Area__r.Name,
                mapIcon: markerIcon
            };
        });
    }

    generateFocusAreas() {
        return new Promise((resolve) => {
            this.focusAreas = [];
            (this.rawData || []).forEach(row => {
                const name = row?.Focus_Area_Name__c?.trim() || 'Other';
                const color = row?.Color_Code__c || '#ccc';
                if(!this.focusAreas.some(fa => fa.focusAreaName === name)) {
                    this.focusAreas.push({
                        focusAreaName: name,
                        colorCode: color,
                        style: `background-color: ${color};`
                    });
                }
            });
            resolve();
        });
    }

    async handleMarkerSelect(event) {
        this.isMapSpinnerVisible = true;
        this.isInitiativeSelected = false;
        this.geoAreaId = event.target.selectedMarkerValue;
        await refreshApex(this.wiredGeoAreaResult);
        this.selectedMapMarker = this.filteredMapMarkers.find(marker => marker.geoAreaId === this.geoAreaId);
        setTimeout(() => {
            if(this.geoAreaId) {
                const payload = {
                    bubbles: true,
                    composed: true,
                    geoAreaId: this.geoAreaId,
                    showDetailPage: false,
                    mapMarkerSelected: true
                };
                publish(this.messageContext, GEO_AREA_MESSAGE_CHANNEL, payload);
            }
        }, 2000);
        setTimeout(() => {
            this.isMapSpinnerVisible = false;
        }, 1000);
    }

    async handleSelectFromListView(event) {
        this.isMapSpinnerVisible = true;
        this.geoAreaId = event.detail;
        await refreshApex(this.wiredGeoAreaResult);
        if(this.filteredMapMarkers.find(marker => marker.geoAreaId === this.geoAreaId)) {
            this.selectedMapMarker = this.filteredMapMarkers.find(marker => marker.geoAreaId === this.geoAreaId)
        } else {
            this.selectedMapMarker = { geoAreaId: this.geoAreaId }; //added this as we are not able to find geoarea in filteredMapMarkers for grant
        }
        setTimeout(() => {
            if(this.geoAreaId) {
                const payload = {
                    bubbles: true,
                    composed: true,
                    geoAreaId: this.geoAreaId,
                    showDetailPage: false,
                    mapMarkerSelected: true,
                    selectedFromListView: true
                };
                publish(this.messageContext, GEO_AREA_MESSAGE_CHANNEL, payload);
            }
        }, 2000);
        setTimeout(() => {
            this.isMapSpinnerVisible = false;
        }, 1000);
    }

    showDetailPage() {
        this.showMainPage = false;
        this.showDetail = true;
    }

    handleDetailClose() {
        this.isSpinnerVisible = true;
        this.showMainPage = true;
        this.showDetail = false;
        setTimeout(() => {
            this.isSpinnerVisible = false;
        }, 1000);
    }
}