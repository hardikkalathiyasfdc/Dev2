import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import { generateDocument } from 'c/cityViewOnePager';
import GEO_AREA_MESSAGE_CHANNEL from '@salesforce/messageChannel/geoAreaSelected__c';
import TOGGLE_FILTERS_CHANNEL from '@salesforce/messageChannel/ToggleFiltersMessageChannel__c';
import hasCustomPermission from '@salesforce/customPermission/CityView_With_Clickthrus';
import getOrgId from '@salesforce/apex/CityViewDetailPageController.getFirstOrgIdByGeoArea';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';
import FORM_FACTOR from '@salesforce/client/formFactor';
import NAME_FIELD from '@salesforce/schema/Geo_Area__c.Name';

export default class CityViewSummary extends LightningElement {
    @api officeIconPath;
    @api isCountrySelected;
    @api isStateSelected;
    @api selectedGroupByForStateOnCountryLevel;
    @api selectedGroupByForCityOnCountryLevel;
    _geoAreaId;
    _selectedMapMarker;
    formFactor = FORM_FACTOR;
    userName;
    orgId;
    selectedRecordName;
    _shallShowGrants = false;
    selectedDescriptionSetting;

    @api
    get shallShowGrants() {
        return this._shallShowGrants;
    }
    set shallShowGrants(value) {
        this._shallShowGrants = value;
    }

    @api
    get geoAreaId() {
        return this._geoAreaId;
    }

    @api
    get selectedMapMarker() {
        return this._selectedMapMarker;
    }
    set selectedMapMarker(value) {
        if(value !== this._selectedMapMarker) {
            this._selectedMapMarker = value;
            this._geoAreaId = value?.geoAreaId;
        }
    }

    get hasPermission() {
        return hasCustomPermission;
    }

    get isNotCountrySelected() {
        return !this.isCountrySelected && !this.isStateSelected;
    }

    get showCityWorkCmp() {
        return this.isCountrySelected || this.isStateSelected;
    }

    get selectedGeoAreaFullName() {
        return this.selectedRecordName ? this.selectedRecordName : '';
    }

    @wire(MessageContext) messageContext;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME]
    }) userDetails({ error, data }) {
        if(error) {
            this.error = error;
        } else if(data) {
            if(data.fields.Name.value != null) {
                this.userName = data.fields.Name.value;
            }
        }
    }

    // Fetching record details for selected geo area
    @wire(getRecord, { recordId: '$geoAreaId', fields: [NAME_FIELD] })
    wiredRecord({ error, data }) {
        if(data) {
            this.selectedRecordName = data.fields.Name.value;
        } else if(error) {
            this.selectedRecordName = '';//'Error fetching name';
        }
    }

    handleDetailOpen() {
        this.showMainPage = false;
        const payload = {
            bubbles: true,
            composed: true,
            geoAreaId: this._geoAreaId,
            showDetailPage: true,
            viewDetailFromSummary: true
        };
        publish(this.messageContext, GEO_AREA_MESSAGE_CHANNEL, payload);
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

        const keyPartnerCmp = this.template.querySelector('c-city-view-key-partners');
        const keyPartnerData = keyPartnerCmp?.getKeyParnerData() || [];

        const cityViewCountryLevelWork = this.template.querySelector('c-city-view-country-level-work');
        const cityViewCountryLevelWorkData = cityViewCountryLevelWork?.getCityLevelData() || [];

        const data = {
            selectedMapMarker: this._selectedMapMarker,
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

    openOrgDetails() {
        if(!this._geoAreaId) {
            console.warn('Geo Area Id is not set');
            return;
        }
        getOrgId({
            geoAreaId: this._geoAreaId
        }).then(result => {
            this.orgId = result;
            if(this.orgId) {
                // Navigate to the Account record in a new tab
                window.open(`/lightning/r/Account/${this.orgId}/view`, '_blank');
            } else {
                console.warn('No Account found for the provided Geo Area Id');
            }
        }).catch(error => {
            console.error('Error fetching Account Id:', error);
        });
    }

    toggleFilters() {
        const message = { toggle: true };
        publish(this.messageContext, TOGGLE_FILTERS_CHANNEL, message);
    }

    handleOnMenuItem(event) {
        this.selectedDescriptionSetting = event.detail.value;
        this.generateOnePager();
    }
}