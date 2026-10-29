import { LightningElement, track, wire } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getCityViewMarkersData from '@salesforce/apex/CityViewController.getCityViewMarkersData';

export default class CityViewContainer extends LightningElement {

    isDesktop = false;
    isMobile = false;
    isLoading = true;
    @track rawData = [];
    @track gcomGeoAreas = [];

    connectedCallback() {
        if (FORM_FACTOR === 'Large') {
            this.isDesktop = true;
        } else if (FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium') {
            this.isMobile = true;
        }
        document.title = 'CityView';
    }

    renderedCallback() {
        if (!this.template.querySelector('style')) {
            const style = document.createElement('style');
            style.innerText = `
                :host {
                    padding: 0 !important;
                    margin: 0 !important;
                    background-color: white !important;
                }
                .slds-brand-band,
                .slds-brand-band_cover,
                .slds-brand-band_medium,
                .slds-template_default,
                .forceBrandBand, 
                body, 
                .slds-template__container {
                    padding: 0 !important;
                    margin: 0 !important;
                    background-color: white !important;
                }
            `;
            const divElement = this.template.querySelector('div');
            if (divElement) {
                divElement.appendChild(style);
            }
        }

        const mainContentDiv = this.template.querySelector('.fullheight.center.oneCenterStage.mainContentMark');
        if (mainContentDiv) {
            mainContentDiv.style.padding = '0';
            mainContentDiv.style.margin = '0';
            mainContentDiv.style.height = '100%';
        }
    }

    @wire(getCityViewMarkersData)
    wiredGeoAreaFocusData({ error, data }) {
        if (data) {
            this.rawData = data;
            console.log('data returned ::::::::: ' + JSON.stringify(data));
            this.isLoading = false;
        } else if (error) {
            console.error('Error fetching data:', error);
            this.isLoading = false;
        }
    }
}