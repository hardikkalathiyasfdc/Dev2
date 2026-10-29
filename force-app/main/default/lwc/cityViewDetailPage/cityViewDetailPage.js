import { LightningElement, api, wire } from 'lwc';
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import { getRecord } from 'lightning/uiRecordApi';
import { generateDocument } from 'c/cityViewOnePager';
import { loadStyle } from 'lightning/platformResourceLoader';
import GEO_AREA_FIELD from '@salesforce/schema/Account.Government_Geo_Area__c';
import GEO_AREA_NAME_FIELD from '@salesforce/schema/Account.Government_Geo_Area__r.Name';
import FORM_FACTOR from '@salesforce/client/formFactor';
import CITYVIEW_STYLES from '@salesforce/resourceUrl/cityViewCustomCSS';
import CITY_VIEW_MAIN_PAGE_MESSAGE_CHANNEL from '@salesforce/messageChannel/cityViewMainPage__c';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';
import hasEmployeeTravelPermission from '@salesforce/customPermission/CityView_Employee_Travel_Custom_Permission';

export default class CityViewDetailPage extends LightningElement {
    @api recordId;
    @api geoAreaId;
    @api selectedMapMarker;
    @api isCountrySelected;
    @api isStateSelected;
    @api showDetailPage;
    @api selectedGroupByForStateOnCountryLevel;
    @api selectedGroupByForCityOnCountryLevel;
    @api selectedHighlightSort;
    @api markerOfficeIcon;
    formFactor = FORM_FACTOR;
    userName;
    displayEmployeeTravel = false;
    filterSubscription = null;
    _shallShowGrants = false;
    selectedDescriptionSetting;

    @api
    get shallShowGrants() {
        return this._shallShowGrants;
    }
    set shallShowGrants(value) {
        this._shallShowGrants = value;
    }

    get isNotCountrySelected() {
        return !this.isCountrySelected && !this.isStateSelected;
    }

    get showCityWorkCmp() {
        return this.isCountrySelected || this.isStateSelected;
    }

    get hasRecordId() {
        return this.recordId !== undefined && this.recordId !== null;
    }

    get culturalAccessClass() {
        return this.hasRecordId ? 'slds-col slds-size_1-of-1' : 'slds-col slds-size_6-of-12';
    }

    get showOfficeMap() {
        return !this.hasRecordId;
    }

    get showGenerateButton() {
        return this.hasRecordId;
    }

    get latitude() {
        return this.selectedMapMarker?.location?.Latitude;
    }

    get longitude() {
        return this.selectedMapMarker?.location?.Longitude;
    }

    @wire(MessageContext) messageContext;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [GEO_AREA_FIELD, GEO_AREA_NAME_FIELD],
        optionalFields: ['Account.Government_Geo_Area__r.RecordType.Name']
    }) wiredRecord({ error, data }) {
        if(data) {
            this.geoAreaId = data.fields.Government_Geo_Area__c.value;
            const geoArea = data.fields.Government_Geo_Area__r?.value;
            const geoAreaName = geoArea?.fields?.Name?.value;
            const recordType = geoArea?.fields?.RecordType?.value?.fields?.Name?.value;
            if(recordType == 'Country') {
                this.isCountrySelected = true;
            } else if(recordType == 'State') {
                this.isCountrySelected = false;
                this.isStateSelected = true;
            }
            this.selectedMapMarker = {
                title: geoAreaName,
                geoAreaId: this.geoAreaId
            };
        } else if(error) {
            console.error('Error fetching record data:', error);
        }
    }

    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME] })
    userDetails({ error, data }) {
        if(error) {
            this.error = error;
        } else if(data) {
            if(data.fields.Name.value != null) {
                this.userName = data.fields.Name.value;
            }
        }
    }

    connectedCallback() {
        this.displayEmployeeTravel = hasEmployeeTravelPermission;
        loadStyle(this, CITYVIEW_STYLES).catch(error => {
            console.error('Error loading styles', error);
        });
        if(!this.filterSubscription) {
            this.filterSubscription = subscribe(
                this.messageContext,
                CITY_VIEW_MAIN_PAGE_MESSAGE_CHANNEL,
                (message) => message
            );
        }
    }

    @api
    getCityViewRecentMayorsCmp() {
        const recentMayorCmp = this.template.querySelector('c-city-view-recent-mayor');
        return recentMayorCmp?.getMayors() || [];
    }

    @api
    getCityViewCityLevelCmp() {
        const cityLevelWorkCmp = this.template.querySelector('c-city-view-city-level-work');
        return cityLevelWorkCmp?.getCityLevelData() || [];
    }

    @api
    getCityViewOfficesCmp() {
        const officeCmp = this.template.querySelector('c-city-view-bloomberg-office');
        return officeCmp?.getBmoAddressData() || [];
    }

    @api
    getCityViewCulturalAccessCmp() {
        const culturalCmp = this.template.querySelector('c-city-view-cultural-access');
        const culData = culturalCmp?.getCulturalAccessData() || [];
        return culData;
    }

    @api
    getCityViewHighlightsCmp() {
        const highlightsCmp = this.template.querySelector('c-city-view-highlights');
        return highlightsCmp?.getHighlightsData() || [];
    }

    @api
    getCityKeyPartnerCmp() {
        const keyPartnerCmp = this.template.querySelector('c-city-view-key-partners');
        return keyPartnerCmp?.getKeyParnerData() || [];
    }

    generateOnePager() {
        const recentMayorCmp = this.template.querySelector('c-city-view-recent-mayor');
        const mayors = recentMayorCmp?.getMayors() || [];

        const cityLevelWorkCmp = this.template.querySelector('c-city-view-city-level-work');
        const cityData = cityLevelWorkCmp?.getCityLevelData() || [];

        const officeCmp = this.template.querySelector('c-city-view-bloomberg-office');
        const offices = officeCmp?.getBmoAddressData() || [];

        const highlightsCmp = this.template.querySelector('c-city-view-highlights');
        const highlights = highlightsCmp?.getHighlightsData() || [];

        const culturalAccessCmp = this.template.querySelector('c-city-view-cultural-access');
        const culturalAccess = culturalAccessCmp?.getCulturalAccessData() || [];

        const travelCalendarCmp = this.template.querySelector('c-city-view-travel-calendar');
        const events = travelCalendarCmp?.getEventsData() || [];

        const cityLevelWorkCountry = this.template.querySelector('c-city-level-work-for-selected-country');
        const cityLevelWorkCountryData = cityLevelWorkCountry?.getCityLevelData() || [];

        const cityViewCountryLevelWork = this.template.querySelector('c-city-view-country-level-work');
        const cityViewCountryLevelWorkData = cityViewCountryLevelWork?.getCityLevelData() || [];

        const keyPartnerCmp = this.template.querySelector('c-city-view-key-partners');
        const keyPartnerData = keyPartnerCmp?.getKeyParnerData() || [];

        const data = {
            selectedMapMarker: this.selectedMapMarker,
            mayors: mayors,
            cityData: cityData,
            offices: offices,
            highlights: highlights,
            culturalAccess: culturalAccess,
            events: events,
            userName: this.userName,
            isCountrySelected: this.isCountrySelected,
            isStateSelected: this.isStateSelected,
            cityLevelWorkCountryData: cityLevelWorkCountryData,
            selectedGroupByForStateOnCountryLevel: this.selectedGroupByForStateOnCountryLevel,
            selectedGroupByForCityOnCountryLevel: this.selectedGroupByForCityOnCountryLevel,
            keyPartners: keyPartnerData,
            addDescription: (this.selectedDescriptionSetting === 'withDescription'),
            cityViewCountryLevelWorkData: cityViewCountryLevelWorkData
        };
        generateDocument(this, data);
    }

    handleDetailClose() {
        this.dispatchEvent(new CustomEvent('detailclose'), {
            detail: {},
            bubbles: true,
            composed: true
        });
        const payload = { showMainPage: true };
        publish(this.messageContext, CITY_VIEW_MAIN_PAGE_MESSAGE_CHANNEL, payload);
    }

    handleOnMenuItem(event) {
        this.selectedDescriptionSetting = event.detail.value;
        this.generateOnePager();
    }
}