import { LightningElement, track, api } from 'lwc';
import getBloombergAddresses from '@salesforce/apex/CityViewDetailPageController.getOfficeMapDetails';

export default class CityViewOfficeMap extends LightningElement {
    @api markerOfficeIcon;
    @api isCountrySelected;
    @api isStateSelected;
    @track bmoAddresses = [];
    @track error;
    _geoAreaId;
    isLoading = false;
    _selectedGeoAreaId;
    isGeoAreaIdAvailable = false;
    mapMarkers = [];
    mapOptions = {
        disableDefaultUI: true,
        zoomControl: true,
        scrollwheel: true,
    };
    detailPageCenter = {};
    fitAllMarkers = false;

    @api
    get geoAreaId() {
        return this._selectedGeoAreaId;
    }
    set geoAreaId(value) {
        this.isGeoAreaIdAvailable = !!value;
        if(value !== this._selectedGeoAreaId) {
            this.fetchCityViewBloombergOfficeAddress(value);
        }
        this._selectedGeoAreaId = value;
    }

    get zoomLevel() {
        return this.isCountrySelected ? 5 : 11;
    }

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

    fetchCityViewBloombergOfficeAddress(geoAreaId) {
        this.isLoading = true;
        this.bmoAddresses = [];
        this.mapMarkers = [];
        let countrySelected;
        // Ensure fitAllMarkers is updated based on current `isCountrySelected` state
        this.fitAllMarkers = this.isCountrySelected;
        getBloombergAddresses({ 
            geoAreaId: geoAreaId 
        }).then(result => {
            let markers = []; // Temporary array to store markers
            result.forEach(marker => {
                if(marker.geoArea) {
                    // If geoArea is true, use latitude and longitude
                    if(marker.bmoOfficeId == geoAreaId) {
                        this.detailPageCenter = {
                            location: { Latitude: marker.latitude, Longitude: marker.longitude },
                        };
                        let markerObj = {
                            location: {
                                Latitude: marker.latitude,
                                Longitude: marker.longitude
                            },
                            title: marker.addressText,
                            value: marker.bmoOfficeId
                        };
                        if(this.isCountrySelected) {
                            markerObj.mapIcon = {
                                ...this.triangleIcon,
                                fillColor: marker.colorCode,
                                strokeColor: marker.colorCode
                            };
                        } else if(this.isStateSelected) {
                            markerObj.mapIcon = {
                                ...this.squareIcon,
                                fillColor: marker.colorCode,
                                strokeColor: marker.colorCode
                            };
                        } else {
                            markerObj.mapIcon = {
                                ...this.markerIcon,
                                fillColor: marker.colorCode,
                                strokeColor: marker.colorCode
                            };
                        }
                        markers.push(markerObj);
                    } else {
                        markers.push({
                            location: {
                                Latitude: marker.latitude,
                                Longitude: marker.longitude
                            },
                            title: marker.addressText,
                            value: marker.bmoOfficeId,
                            mapIcon: {
                                ...this.markerIcon,
                                fillColor: marker.colorCode,
                                strokeColor: marker.colorCode
                            }
                        });
                    }
                } else {
                    // If geoArea is false, use address fields
                    markers.push({
                        location: {
                            Street: marker.street,
                            City: marker.city,
                            State: marker.state,
                            Country: marker.country,
                            PostalCode: marker.postalCode
                        },
                        title: marker.addressText,
                        value: marker.bmoOfficeId,
                        mapIcon: this.markerOfficeIcon
                    });
                }
            });
            // Assign markers to trigger reactivity
            this.mapMarkers = [...markers];
            this.isLoading = false;
        }).catch(error => {
            this.error = error;
            this.isLoading = false;
        });
    }

    handleMarkerSelect(event) {
        const selectedMarker = event.detail.selectedMarkerValue;
        const marker = this.mapMarkers.find(m => m.value === selectedMarker);
        if(marker && marker.location && marker.location.Latitude) {
            const { Latitude, Longitude } = marker.location;
            const googleMapsUrl = `https://www.google.com/maps?q=${Latitude},${Longitude}`;
            window.open(googleMapsUrl, '_blank');
        } else {
            const encodedAddress = encodeURIComponent(marker.title);
            const googleMapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodedAddress}`;
            window.open(googleMapsUrl, '_blank');
        }
    }
}