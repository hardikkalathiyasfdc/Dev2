import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import CITYVIEW_STYLES from '@salesforce/resourceUrl/cityViewCustomCSS';
import cityViewImage from '@salesforce/resourceUrl/CityViewLogo';
import hasEmployeeTravelPermission from '@salesforce/customPermission/CityView_Employee_Travel_Custom_Permission';
import getOrgId from '@salesforce/apex/CityViewDetailPageController.getFirstOrgIdByGeoArea';
import getListViewData from '@salesforce/apex/CityViewDetailPageController.getListViewData';
import hasCustomPermission from '@salesforce/customPermission/CityView_With_Clickthrus';
import getGeoArea from '@salesforce/apex/CityViewController.getGeoArea';
import getOrgAssociations from '@salesforce/apex/CityViewDetailPageController.getOrgAssociations';
import CityView_Include_Grants_Filter_Access from '@salesforce/customPermission/CityView_Include_Grants_Filter_Access';
import CITY_VIEW_GLOBAL_FILTERS_CHANNEL from '@salesforce/messageChannel/CityViewGlobalFiltersMessageChannel__c';
import { publish, subscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import NAME_FIELD from '@salesforce/schema/Association__c.Name'
import { getRecord } from 'lightning/uiRecordApi';

export default class CityViewMobile extends NavigationMixin(LightningElement) {
    @api rawData;
    @track countryGeoAreaIdList = [];
    @track cityGeoAreaIdList = [];
    selectedGeoArea;
    isChecked = false;
    isInitiativeSearch = false;
    shallShowSpinner = false;
    showGeoAreaDetails = false;
    showGeoAreaDetailsOldValue = false;
    disableSearchBy = true;
    selectedInitiatives;
    selectedInitiativeId;
    selectedInitiativesIds = [];
    cityViewImageUrl = cityViewImage;
    selectedRecordName;
    listViewGlobalTitle;
    recordTypeName;
    formFactor = 'Small';
    displayEmployeeTravel = false;
    sortField = 'GAFA_weight__c';
    selectedCities = [];
    latitude = '';
    longitude = '';
    searchBy = 'City';
    selectedFocusAreaNames = new Set();
    hasPermission = false;
    shouldShowGrantFilter = false;
    orgId;
    cities;
    states;
    countries;
    activeGeoIds = new Set();
    selectedHighlightSort = 'allTime';

    markerOfficeIcon = {
        path: "M948.1,1129.1c0,14.7-12,26.7-26.7,26.7H307.4c-14.7,0-26.7-12-26.7-26.7v-480.6c0-14.7,12-26.7,26.7-26.7h614c14.7,0,26.7,12,26.7,26.7v480.6 " +
            "M1682,1129c0,14.7-12,26.7-26.7,26.7h-614c-14.7,0-26.7-12-26.7-26.7v-480.6c0-14.7,12-26.7,26.7-26.7h614c14.7,0,26.7,12,26.7,26.7v480.6 " +
            "M910.5,1300.9v45c0,16.7,29.9,30.3,66.8,30.3s66.8-13.6,66.8-30.3v-45l3.1.3c104.1,11.5,176.7,49.3,176.7,95.4s-109.7,100-245.1,100-245.1-44.8-245.1-100,73.9-83.6,175.3-95.8l1.5.2",
        fillColor: "white",
        fillOpacity: 1,
        scale: 0.018,
        strokeColor: "black",
        strokeWeight: 1.5
    };

    filterInitiativesData = ` RecordType.DeveloperName IN ('Initiative', 'Standard') AND Active__c = true AND Publish_to_CityView__c = true AND Deleted__c = false `;

    @track filters = {
        showGrants: false
    };
     
    @wire(MessageContext)
    messageContext;

    handleRecordfetched() {
        this.disableSearchBy = false;
    }

    get showGrants() {
        return this.filters.showGrants;
    }

    get showListView() {
        return this.searchBy == 'BP Work' && this.showGeoAreaDetails == false &&
            ((this.countries && this.countries.length) || (this.cities && this.cities.length) || (this.states && this.states.length) );
    }

    get cityData() {
        return this.cities;
    }
    
     get stateData() {
        return this.states;
    }

    get countryData() {
        return this.countries;
    }

    get showDetails() {
        return this.selectedGeoArea && this.recordTypeName;
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
    get showStateCountryData() {
        return this.isCountrySelected || this.isStateSelected;
    }

    get isNotCountrySelected() {
        return this.searchBy !== 'Country';
    }

    get isInitiativeSelected() {
        return this.searchBy === 'BP Work';
    }

    get showImage() {
        return !this.showDetails && !this.showListView;
    }

    get notShowStateCountryData() {
        return this.searchBy !== 'State' && this.isNotCountrySelected;
    }

    get isBPEngagementSelected() {
        return this.sortField === 'GAFA_weight__c';
    }

    get isAlphabeticallySelected() {
        return this.sortField === 'Name';
    }

    get isSortDisabled() {
        return this.searchBy === 'BP Work';
    }

    get searchPlaceHolder() {
        if(this.searchBy === 'City') {
            return 'Search City…';
        } else if(this.searchBy === 'State') {
            return 'Search State…';
        } else if(this.searchBy === 'Country') {
            return 'Search Country…';
        } else if(this.searchBy === 'BP Work') {
            return 'Search Initiatives, Associations...';
        } else {
            return 'Search…';
        }
    }

    @wire(getGeoArea, { geoAreaId: '$selectedGeoArea' })
    wiredRecord({ error, data }) {
        if(data) {
            this.recordTypeName = data.RecordType.Name;
        } else if(error) {
            console.error('Error fetching record type:', error);
        }
    }
    
     @wire(getRecord, {
        recordId: '$selectedInitiativeId',
        fields: [NAME_FIELD]
    })
    wiredAssociation({ data, error }) {
        if (data) {
            this.listViewGlobalTitle = data.fields.Name.value;
        } 
    }

    connectedCallback() {
        this.hasPermission = hasCustomPermission;
        this.displayEmployeeTravel = hasEmployeeTravelPermission;
        this.shouldShowGrantFilter = CityView_Include_Grants_Filter_Access;
        loadStyle(this, CITYVIEW_STYLES).catch(error => {
            console.error('Error loading styles', error);
        });
    }

    renderedCallback() {
        if(this.showGeoAreaDetails) {
            this.hasRendered = true;
            // Scroll to top on mobile
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        }
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    handleSortChange(event) {
        this.sortField = event.detail.value;
    }

    handleTabChange(event) {
        this.searchBy = event.detail.value;
        this.showGeoAreaDetails = false;
        this.selectedGeoArea = '';
        this.selectedRecordName = '';
        this.selectedCities = [];
        this.cities = [];
        this.countries = [];
        this.isInitiativeSearch = this.searchBy == 'BP Work' ? true : false;
    }

    handleToggle() {
        this.shallShowSpinner = true;
        this.cities = [];
        this.countries = [];
        setTimeout(() => {
            this.shallShowSpinner = false;
        }, 500);
    }

    // Handles the selection of a geographic area from the search component
    handleSelected(event) {
        if(event.detail) {
            if(this.searchBy === 'BP Work') {
                this.showGeoAreaDetails = false;
                this.selectedCities = event.detail;
                this.cities = [];
                this.countries = [];
                if(event.detail.length > 0) {
                    this.selectedInitiativeId = event.detail[0].id;
                    this.fetchListViewData(event.detail[0].id);
                } else {
                    this.selectedCities = [];
                }
            } else {
                this.showGeoAreaDetailsOldValue = false;
                this.selctedCities = event.detail;
                this.showGeoAreaDetails = true;
                if(event.detail.length > 0) {
                    this.selectedGeoArea = event.detail[0].id;
                    this.latitude = event.detail[0].latitude;
                    this.longitude = event.detail[0].longitude;
                    this.selectedRecordName = event.detail[0].name;
                }
            }
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }

    handleInitiativesChange(event) {
        this.selectedInitiatives = event.detail;
        this.showGeoAreaDetails = false;
        this.handleChange(this.selectedInitiatives);
        if(this.selectedInitiativesIds && this.selectedInitiativesIds.length > 0)
            this.fetchListViewData(this.selectedInitiativesIds[0]);
    }

    handleInitiativesRemoval(event) {
        this.selectedInitiatives = event.detail; // single record is passed
        this.handleChange(this.selectedInitiatives);
    }

    handleChange(selectedInitiatives) {
        this.selectedInitiativesIds = [];
        this.selectedFocusAreaNames = new Set();
        selectedInitiatives.forEach(item => {
            const name = item.association?.FC_Focus_Area__c;
            this.selectedInitiativesIds.push(item.Id);
            if(name) {
                this.selectedFocusAreaNames.add(name);
            }
        });
    }

    handleGeoAreaSelected(event) {
        this.showGeoAreaDetails = true;
        this.showGeoAreaDetailsOldValue = false;
        this.selectedGeoArea = event.detail.geoId;
        this.selectedRecordName = event.detail.selectedRecordName;
    }

    navigateBack() {
        this.showGeoAreaDetailsOldValue = this.showGeoAreaDetails;
        this.showGeoAreaDetails = false;
    }

    handleAssociationSelection(event) {
        let associationId = event.detail.recordId;
        this.fetchListViewData(associationId);
    }

    openOrgDetails() {
        if(!this.selectedGeoArea) {
            console.warn('Geo Area Id is not set');
            return;
        }
        getOrgId({ 
            geoAreaId: this.selectedGeoArea 
        }).then(result => {
            this.orgId = result;
            if(this.orgId) {
                // Navigate to the Account record in a new tab
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.orgId,
                        objectApiName: 'Account',
                        actionName: 'view'
                    }
                });
            } else {
                console.warn('No Account found for the provided Geo Area Id');
            }
        }).catch(error => {
            console.error('Error fetching Account Id:', error);
        });
    }

    async fetchListViewData(initiativeId) {
        await getListViewData({ 
            initiativeId: initiativeId 
        }).then(result => {
            this.countries = result.Country && result.Country.length > 0 ? [...result.Country] : [];
            this.states = result.State && result.State.length > 0 ? [...result.State] : [];
            this.cities = result.City && result.City.length > 0 ? [...result.City] : [];
        }).catch(error => {
            console.error('Error fetching geo area data:', error);
            this.countries = [];
            this.cities = [];
            this.states = [];
        });
        const combined = [...this.countries, ...this.states, ...this.cities];
        await getOrgAssociations({
            geoAreaIds: combined.map(r => r.Id)
        }).then(orgAssociationList => {
            const today = new Date();
            const currentYear = today.getUTCFullYear();
            orgAssociationList.forEach(org => {
                if(org.Association__r?.Id == initiativeId) {
                    let showDate = org.Association__r?.Show_Org_Assoc_Dates_on_CityView__c;
                    let toDate = org.To__c ? new Date(org.To__c) : null;
                    let isActive = showDate === true && (toDate === null || toDate.getUTCFullYear() > currentYear);
                    if(isActive) {
                        this.activeGeoIds.add(org.Organization__r?.Government_Geo_Area__c);
                    }
                }
            });
        }).catch(error => {
            console.error('Error fetching org associations:' + JSON.stringify(error.body));
        });
        this.countries = this.countries.map(r => ({ ...r, isActive: this.activeGeoIds.has(r.Id) }));
        this.states = this.states.map(r => ({ ...r, isActive: this.activeGeoIds.has(r.Id) }));
        this.cities = this.cities.map(r => ({ ...r, isActive: this.activeGeoIds.has(r.Id) }));
    }

    handleFilterSelect(event) { 
        const key = event.detail.value;
        this.filters = { ...this.filters, [key]: !this.filters[key] };
        const payload = {
            bubbles: true,
            composed: true,
            filters: { ...this.filters }
        };
        publish(this.messageContext, CITY_VIEW_GLOBAL_FILTERS_CHANNEL, payload);
    }
}