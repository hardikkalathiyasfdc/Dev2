import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getKeyPartners from '@salesforce/apex/CityViewDetailPageController.getKeyPartners';
import hasCustomPermission from '@salesforce/customPermission/CityView_With_Clickthrus';

export default class CityViewKeyPartners extends NavigationMixin(LightningElement) {
    @api isCountrySelected;
    @api isStateSelected;
    @track orgGeoAreas = []; // Stores the geo area data
    @track error; // Stores any error that occurs during fetching data
    isLoading = false; // Flag to show loading state
    _selectedGeoAreaId; // Internal variable to hold the selected geo area ID
    isGeoAreaIdAvailable = false; // Boolean flag to check if Geo Area ID is available
    hasPermission = false; // Flag to check if the user has required permission

    get keyPartnersLabel() {
        return this.isCountrySelected
            ? 'Country Level Partners'
            : this.isStateSelected
                ? 'State Level Partners'
                : 'City Level Partners';
    }

    @api
    get geoAreaId() {
        return this._selctedGeoAreaId;
    }
    set geoAreaId(value) {
        this.isGeoAreaIdAvailable = value ? true : false;
        if (value != this._selctedGeoAreaId) {
            this.fetchGeoAreas(value);
        }
        this._selctedGeoAreaId = value;
    }

    get showOrgGeoArea() {
        return this.orgGeoAreas.length > 0;
    }

    @api formFactor;

    @api
    getKeyParnerData() {
        return this.orgGeoAreas;
    }

    get tableStyle() {
        const normalizedFormFactor = this.formFactor ? this.formFactor.toLowerCase() : '';
        if (normalizedFormFactor === 'large') {
            return 'max-height: 145px; overflow: auto;';
        } else if (normalizedFormFactor === 'small' || normalizedFormFactor === 'medium') {
            return ''; // Empty style for small/medium form factor
        }
    }

    connectedCallback() {
        this.hasPermission = hasCustomPermission;
    }

    fetchGeoAreas(geoAreaId) {
        this.isLoading = true;
        getKeyPartners({
            geoAreaId: geoAreaId
        }).then(result => {
            let orgMap = new Map(); // Map to store unique records based on Organization__c
            if (result && result.length > 0) {
                result.forEach(area => {
                    if (area.Organization__c && !orgMap.has(area.Organization__c)) {
                        orgMap.set(area.Organization__c, area); // Store the entire area object
                    }
                });
                this.orgGeoAreas = Array.from(orgMap.values());
            } else {
                this.orgGeoAreas = [];
            }
            this.isLoading = false;
        }).catch(error => {
            this.error = error;
            this.isLoading = false;
        });
    }


    handleOrgClick(event) {
        const orgId = event.currentTarget.dataset.id; // Get the organization ID from the click event
        if (orgId) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: orgId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            }).then(url => {
                window.open(url, "_blank"); // Open the organization record in a new tab
            });
        }
    }
}