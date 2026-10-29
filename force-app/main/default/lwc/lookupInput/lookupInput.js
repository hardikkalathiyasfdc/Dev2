import { LightningElement, api, track } from 'lwc';

export default class LookupInput extends LightningElement {
    @api placeholder = 'Search...';
    @api disabled = false;
    
    @track inputValue = '';

    get showClearIcon() {
        return this.inputValue && !this.disabled;
    }

    get showSearchIcon() {
        return !this.inputValue;
    }

    handleFocus() {
        this.dispatchEvent(new CustomEvent('focus', {
            detail: { searchTerm: this.inputValue }
        }));
    }

    handleInput(event) {
        this.inputValue = event.target.value;
        this.dispatchEvent(new CustomEvent('search', {
            detail: { searchTerm: this.inputValue }
        }));
    }

    handleClear() {
        this.inputValue = '';
        this.dispatchEvent(new CustomEvent('clear'));
        this.dispatchEvent(new CustomEvent('search', {
            detail: { searchTerm: '' }
        }));
    }

    handleKeyDown(event) {
        if (event.key === 'Escape') {
            this.handleClear();
        }
    }

    @api
    clear() {
        this.inputValue = '';
    }

    @api
    focus() {
        const input = this.template.querySelector('input');
        if (input) {
            input.focus();
        }
    }
}