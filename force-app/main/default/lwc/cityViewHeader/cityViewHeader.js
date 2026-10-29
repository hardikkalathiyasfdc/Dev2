import { LightningElement, wire, api } from 'lwc';
import { publish, subscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import GEO_AREA_MESSAGE_CHANNEL from '@salesforce/messageChannel/geoAreaSelected__c';
import TOGGLE_FILTERS_CHANNEL from '@salesforce/messageChannel/ToggleFiltersMessageChannel__c';
import cityViewImage from '@salesforce/resourceUrl/CityViewLogo';
import NAME_FIELD from '@salesforce/schema/Geo_Area__c.Name';
import getOrgId from '@salesforce/apex/CityViewDetailPageController.getFirstOrgIdByGeoArea';
import hasCustomPermission from '@salesforce/customPermission/CityView_With_Clickthrus';
import bgVideo from '@salesforce/resourceUrl/CityViewDots';
import CityView_Include_Grants_Filter_Access from '@salesforce/customPermission/CityView_Include_Grants_Filter_Access';

export default class CityViewHeader extends NavigationMixin(LightningElement) {
    @api focusAreas = [];
    @api filters = {};
    @api selectedInitiative = '';
    @api hasActiveFilters = false;
    sortField = 'GAFA_weight__c';
    // Static resource for the city view image
    cityViewImageUrl = cityViewImage;
    selectedGeoArea;
    selectedRecordName;
    selectedCityId; // transfered value from City view page via url
    showDetailPage; // transfered value from Country view page via url\
    backgroundVideoUrl = bgVideo;
    hasClickThruPermission = false;
    shallShowGrantsFilter = false;
    disableSearchBy = true;
    searchBy = 'City';
    selectedCities = new Array();
    orgId;
    isFiltersPopupOpen = false;
    _isShowingDetailPage = false;

    @api
    get isShowingDetailPage() {
        return this._isShowingDetailPage;
    }
    set isShowingDetailPage(value) {
        this._isShowingDetailPage = value;
        if(value) this.isFiltersPopupOpen = false;
    }

    get filterIconButtonClass() {
        return `filter-icon-btn ${this.disableFilters ? 'filters-disabled' : ''}`;
    }

    get disableFilters() {
        return this.isShowingDetailPage && !this.shallShowGrantsFilter;
    }

    get filterTitle() {
        return this.disableFilters ? 'Filters are disabled on detail pages' : 'Filters';
    }

    get showGrants() {
        return this.filters.showGrants;
    }

    get isCitySelected() {
        return this.searchBy === 'City';
    }

    get isStateSelected() {
        return this.searchBy === 'State';
    }

    get isCountrySelected() {
        return this.searchBy === 'Country';
    }

    get isInitiativeSelected() {
        return this.searchBy === 'BP Work';
    }

    get searchPlaceholder() {
        if (this.disableSearchBy) {
            return 'Loading, please wait...';
        }
        switch (this.searchBy) {
            case 'City':
                return 'Search City…';
            case 'State':
                return 'Search State…';
            case 'Country':
                return 'Search Country…';
            case 'BP Work':
                return 'Search Initiatives, Associations…';
        }
    }

    get selectedGeoAreaFullName() {
        return this.selectedRecordName ? this.selectedRecordName : '';
    }

    @wire(MessageContext) messageContext;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state) {
            this.selectedCityId = currentPageReference.state.c__selectedCityId || null;
            this.showDetailPage = currentPageReference.state.c__showDetail || false;
            this.selectedGeoArea = this.selectedCityId;
            if(this.selectedGeoArea) {
                const payload = {
                    bubbles: true,
                    composed: true,
                    geoAreaId: this.selectedGeoArea
                };
                publish(this.messageContext, GEO_AREA_MESSAGE_CHANNEL, payload);

            }
        }
    }

    connectedCallback() {
        this.shallShowGrantsFilter = CityView_Include_Grants_Filter_Access;
        this.subscribeToMessageChannel();
        this.hasClickThruPermission = hasCustomPermission;
    }

    // Subscribes to relevant message channels
    subscribeToMessageChannel() {
        subscribe(
            this.messageContext,
            GEO_AREA_MESSAGE_CHANNEL,
            (message) => this.handleGeoAreaMessage(message),
            { scope: APPLICATION_SCOPE }
        );
        this.toggleFilterSubscription = subscribe(
            this.messageContext,
            TOGGLE_FILTERS_CHANNEL,
            () => this.clearSelectedMarker()
        );
    }

    toggleFiltersPopup() {
        if(this.disableFilters) return;
        this.isFiltersPopupOpen = !this.isFiltersPopupOpen;
    }

    closeFiltersPopup() {
        this.isFiltersPopupOpen = false;
    }

    handleApplyFiltersFromPopup(event) {
        this.dispatchEvent(new CustomEvent('applyfilters', { detail: event.detail }));
        this.clearSelectedMarker();
        this.closeFiltersPopup();
    }

    handleFiltersReadyFromPopup(event) {
        this.dispatchEvent(new CustomEvent('filtersready', { detail: event.detail }));
        this.closeFiltersPopup();
    }

    handleRecordfetched() {
        this.disableSearchBy = false;
    }

    handleGeoAreaMessage(message) {
        this.selectedGeoArea = message.geoAreaId;
        this.isFiltersPopupOpen = false;
    }

    handleSelected(event) {
        if (event.detail && event.detail.length > 0) {
            this.selectedCities = JSON.parse(JSON.stringify(event.detail));;
            this.selectedGeoArea = event.detail[0].id;
            if (this.selectedGeoArea && this.searchBy != 'BP Work') {
                const payload = {
                    bubbles: true,
                    composed: true,
                    geoAreaId: this.selectedGeoArea,
                    geoAreaRec: event.detail[0]
                };
                publish(this.messageContext, GEO_AREA_MESSAGE_CHANNEL, payload);
            }
        }
    }

    // Fetching record details for selected geo area
    @wire(getRecord, { recordId: '$selectedGeoArea', fields: [NAME_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.selectedRecordName = data.fields.Name.value;
        } else if (error) {
            this.selectedRecordName = '';//'Error fetching name';
        }
    }
    
    openOrgDetails() {
        if (!this.selectedGeoArea) {
            console.warn('Geo Area Id is not set');
            return;
        }
        getOrgId({ 
            geoAreaId: this.selectedGeoArea 
        }).then(result => {
            this.orgId = result;
            if (this.orgId) {
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.orgId,
                        objectApiName: 'Account',
                        actionName: 'view'
                    }
                }).then(url => {
                    window.open(url, '_blank');
                });
            } else {
                console.warn('No Account found for the provided Geo Area Id');
            }
        }).catch(error => {
            console.error('Error fetching Account Id:', error);
        });
    }

    clearSelectedMarker() {
        this.selectedCities = new Array();
        if (this.refs && this.refs.searchcmp) {
            this.refs.searchcmp.handleClearSelection();
        }
    }

    handleImageClick() {
        window.location.reload();
    }

    handleSortChange(event) {
        this.sortField = event.detail.value;
    }

    handleTabChange(event) {
        this.searchBy = event.detail.value;
        this.objectApiName = this.searchBy === 'BP Work' ? 'Association__c' : 'Geo_Area__c';
        this.selectedCities = new Array();
        // Clear selected record and reset state
        this.selectedGeoArea = null;
        this.clearSelectedMarker();
        const searchByFilter = new CustomEvent('searchby', {
            detail: this.searchBy
        });
        this.dispatchEvent(searchByFilter);
    }
}