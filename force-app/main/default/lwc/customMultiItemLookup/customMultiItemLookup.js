import { LightningElement, api, track } from 'lwc';

export default class CustomMultiItemLookup extends LightningElement {
    @api label = 'Lookup';
    @api placeholder = 'Search...';
    @api iconName = 'standard:contact';
    @api keyField = 'id';
    @api primaryField = 'name';
    @track _selected = new Map();
    @track filteredItems = [];
    dropdownOpen = false;
    searchTerm = '';
    _preselectedIds = [];
    _items = [];
    _normalized = [];
    _displayFields = [];

    @api
    get displayFields() {
        return this._displayFields;
    }
    set displayFields(val) {
        this._displayFields = Array.isArray(val)
                              ? val
                              : (typeof val === 'string'
                                 ? val.split(',').map(s => s.trim()).filter(Boolean)
                                 : []);
        this._normalizeItems();
        this._filter();
    }

    @api
    get preselectedIds() {
        return this._preselectedIds;
    }
    set preselectedIds(val) {
        this._preselectedIds = Array.isArray(val) ? val : (val == null ? [] : [val]);
        this.initPreselectedIds();
    }
   
    @api
    get items() { return this._items; }
    set items(val) {
        this._items = Array.isArray(val) ? val : [];
        this._normalizeItems();
        this.initPreselectedIds();
        this._filter();
    }

    get selectedList() {
        return Array.from(this._selected.values());
    }

    get hasResults() {
        return this.filteredItems && this.filteredItems.length > 0;
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.dropdownOpen ? 'slds-is-open' : ''}`;
    }

    connectedCallback() {
        this._normalizeItems(); 
        this.initPreselectedIds();
        this._filter();
        document.addEventListener('mousedown', this._onDocMouseDown, true);
    }

    disconnectedCallback() {
        document.removeEventListener('mousedown', this._onDocMouseDown, true);
    }

    _onDocMouseDown(evt) {
        if(!this.dropdownOpen) return;
        const path = typeof evt.composedPath === 'function' ? evt.composedPath() : null;
        const clickedInside = path
            ? path.some(n => n && n.dataset && Object.prototype.hasOwnProperty.call(n.dataset, 'mlRoot'))
            : this.template.contains(evt.target);
        if(!clickedInside) this.closeDropdown();
    }

    handleFocusOut(e) {
        const next = e.relatedTarget;
        if(!this.template.contains(next)) this.closeDropdown();
    }

    _normalizeItems() {
        const p = this.primaryField || 'name';
        const extraFields = this._displayFields;
        const k = this.keyField || 'id';
        this._normalized = this._items.map(raw => {
            const id = raw?.[k];
            if (id === undefined || id === null) return null;
            const line1 = this._safeString(raw?.[p]);
            const lines = extraFields.map(f => this._safeString(raw?.[f])).filter(Boolean);
            return { id, line1, lines, raw };
        }).filter(Boolean);
    }

    _safeString(v) { 
        return (v === undefined || v === null) ? '' : String(v); 
    }

    _filter() {
        const term = (this.searchTerm || '').toLowerCase().trim();
        if(!term) {
            this.filteredItems = this._normalized.filter(n => !this._selected.has(n.id));
            return;
        }
        this.filteredItems = this._normalized.filter(n => {
            if(this._selected.has(n.id)) return false;
            const allLines = [n.line1, ...(n.lines || [])].join(' ').toLowerCase();
            return allLines.includes(term);
        });
    }

    initPreselectedIds() {
        if(!this._normalized || this._normalized.length === 0) return;
        if(!this._preselectedIds || this._preselectedIds.length === 0) return;
        let added = false;
        for(const keyId of this._preselectedIds) {
            const key = this._safeString(keyId);
            const found = this._normalized.find(n => this._safeString(n.id) === key);
            if(found && !this._selected.has(found.id)) {
                this._selected.set(found.id, found);
                added = true;
            }
        }
        if(added) {
            this._selected = new Map(this._selected);
            this._filter();
        }
    }

    openDropdown() { this.dropdownOpen = true; }

    closeDropdown() { this.dropdownOpen = false; }

    handleInputClick(e) {
        if(this.dropdownOpen) {
            e.stopPropagation();
            this.closeDropdown();
        } else {
            this.openDropdown();
        }
    }

    handleKeydown(e) {
        if(e.key === 'Escape') {
            this.closeDropdown();
        } else if(e.key === 'Enter' && this.filteredItems.length > 0) {
            this._select(this.filteredItems[0].id);
        }
    }

    handleSelect(e) {
        e.preventDefault();
        e.stopPropagation();
        const id = e.currentTarget?.dataset?.id;
        this._select(id);
    }

    handleRemovePill(e) {
        const id = e.currentTarget?.dataset?.id;
        if(id && this._selected.has(id)) {
            this._selected.delete(id);
            this._selected = new Map(this._selected);
            this._filter();
            this._notify();
        }
    }
    
    handleInput(e) {
        this.searchTerm = e.target.value || '';
        this._filter();
        this.openDropdown();
    }

    _select(id) {
        if(!id) return;
        if(this._selected.has(id)) return;
        const found = this._normalized.find(n => n.id == id);
        if(found) {
            this._selected.set(found.id, found);
            this._selected = new Map(this._selected);
            this._filter();
            this.searchTerm = '';
            this._notify();
            this.openDropdown();
            const input = this.template.querySelector('input.slds-input');
            if(input) input.focus();
        }
    }

    _notify() {
        const payload = Array.from(this._selected.values()).map(n => n.raw);
        this.dispatchEvent(new CustomEvent('selectionchange', { detail: { selected: payload } }));
    }
}