import { LightningElement, api } from 'lwc';

export default class CustomToggle extends LightningElement {
    @api option1 = 'Map View';
    @api option2 = 'List View';
    @api currentView; 

    get sliderStyle() {
        return `left: ${this.currentView === this.option1 ? '0%' : '48%'}`;
    }

    get option1Class() {
        return `switch-option ${this.currentView === this.option1 ? 'active' : ''}`;
    }

    get option2Class() {
        return `switch-option ${this.currentView === this.option2 ? 'active' : ''}`;
    }

    toggleView() {
        this.currentView = this.currentView === this.option1 ? this.option2 : this.option1;
        this.dispatchEvent(new CustomEvent('viewchange', { detail: this.currentView }));
    }
}