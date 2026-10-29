import { LightningElement, api, track } from 'lwc';

export default class CustomGroupDropdown extends LightningElement {
    @api optionsMap = {};
    @api placeholder = 'Select options';
    @api label = '';
    @track selectedValues = {};
    dropdownOpen = false;

    get hasSelections() {
        return Object.keys(this.selectedValues).length > 0;
    }

    get selectedValuesArray() {
        return Object.keys(this.selectedValues).map(group => {
            return {
                group,
                label: `${group}: ${this.selectedValues[group]}`
            };
        });
    }

    get optionGroups() {
        return Object.keys(this.optionsMap).map(key => ({
            heading: key,
            options: this.optionsMap[key],
            value: this.selectedValues[key] || ''
        }));
    }

    get comboboxClass() {
        let baseClass = 'slds-combobox slds-dropdown-trigger';
        return this.dropdownOpen ? baseClass + 'slds-is-open' : baseClass;
    }

    toggleDropdown() {
       this.dropdownOpen = !this.dropdownOpen;
    }

    closeDropdown() {
        this.dropdownOpen = false;
    }

    handleRadioChange(event) {
        const group = event.target.dataset.group;
        const value = event.target.value;
        this.selectedValues = {
            ...this.selectedValues,
            [group]: value
        };
        this.dispatchChangeToParent();
    }

    handlePillRemove(event) {
        const group = event.target.name;
        delete this.selectedValues[group];
        this.selectedValues = { ...this.selectedValues };
        this.dispatchChangeToParent();
    }

    dispatchChangeToParent() {
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { ...this.selectedValues }
        }));
    }
}