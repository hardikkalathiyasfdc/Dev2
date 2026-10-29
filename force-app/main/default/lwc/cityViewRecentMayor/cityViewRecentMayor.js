import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRecentMayors from '@salesforce/apex/CityViewDetailPageController.getRecentMayors';
import hasCustomPermission from '@salesforce/customPermission/CityView_With_Clickthrus';

export default class CityViewRecentMayor extends NavigationMixin(LightningElement) {
    @api formFactor;
    @track mayors = [];
    @track error;
    isLoading = false;
    _selctedGeoAreaId;
    isGeoAreaIdAvailable = false;
    hasPermission = false;

    @api
    get geoAreaId() {
        return this._selctedGeoAreaId;
    }
    set geoAreaId(value) {
        this.isGeoAreaIdAvailable = value ? true : false;
        if(value != this._selctedGeoAreaId) {
            this.fetchMayors(value);
        }
        this._selctedGeoAreaId = value;
    }

    @api
    getMayors() {
        return this.mayors;
    }
    
    get tableStyle() {
        const normalizedFormFactor = this.formFactor ? this.formFactor.toLowerCase() : '';
        if(normalizedFormFactor === 'large') {
            return 'max-height: 100px; overflow: auto;';
        } else if(normalizedFormFactor === 'small' || normalizedFormFactor === 'medium') {
            return '';
        }
    }
    
    get showRecentMayors() {
        return this.mayors.length > 0;
    }

    connectedCallback() {
        this.hasPermission = hasCustomPermission;
    }

    fetchMayors(geoAreaId) {
        if(!geoAreaId) return;
        this.isLoading = true;
        getRecentMayors({ 
            geoAreaId: geoAreaId 
        }).then(result => {
            this.mayors = [...result].sort((a, b) => {
                // "Present" goes first
                if(!a.To__c && b.To__c) return -1;
                if(a.To__c && !b.To__c) return 1;
                // If both have To__c or both are Present, sort by From__c ascending
                return new Date(b.From__c) - new Date(a.From__c);
            });
            this.isLoading = false;
        }).catch(error => {
            this.error = error;
            this.isLoading = false;
        });
    }

    handleContactClick(event) {
        const contactId = event.currentTarget.dataset.id;
        if(contactId) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: contactId,
                    objectApiName: 'Contact',
                    actionName: 'view'
                }
            }).then(url => {
                window.open(url, "_blank");  // Open the contact record in a new tab
            });
        }
    }
}