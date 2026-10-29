import { LightningElement, track, api } from 'lwc';
import getBloombergAddresses from '@salesforce/apex/CityViewDetailPageController.getOfficeMapDetails';

export default class CityViewBloombergOffice extends LightningElement {
    @api officeIconPath = '';
    @api formFactor;
    @track bmoAddresses = [];
    @track error;
    isLoading = false;
    _selctedGeoAreaId;
    isGeoAreaIdAvailable = false;

    @api
    get geoAreaId() {
        return this._selctedGeoAreaId;
    }

    set geoAreaId(value) {
        this.isGeoAreaIdAvailable = value ? true : false;
        if (value != this._selctedGeoAreaId) {
            this.fetchAddresses(value);
        }
        this._selctedGeoAreaId = value;
    }

    get showAddress() {
        return this.bmoAddresses.length > 0;
    }

    @api
    getBmoAddressData() {
        const filteredBMOAddress = this.bmoAddresses;
        return filteredBMOAddress;
    }

    get tableStyle() {
        const normalizedFormFactor = this.formFactor ? this.formFactor.toLowerCase() : '';
        if (normalizedFormFactor === 'large') {
            return 'max-height: 210px; overflow: auto;';
        } else if (normalizedFormFactor === 'small' || normalizedFormFactor === 'medium') {
            return ''; // Empty style for small/medium form factor
        }
    }

    fetchAddresses(geoAreaId) {
        this.isLoading = true;
        getBloombergAddresses({
            geoAreaId: geoAreaId
        }).then(result => {
            if (result && result.length > 0) {
                this.bmoAddresses = result.filter(record =>
                    record.geoArea == false
                );
            } else {
                this.bmoAddresses = [];
            }
            this.isLoading = false;
        }).catch(error => {
            console.error('Error fetching bloomberg offices:', error);
            this.error = error;
            this.isLoading = false;
        });
    }
}