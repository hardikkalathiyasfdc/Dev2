import { api, track, LightningElement } from 'lwc';
import fetchStaffContacts from '@salesforce/apex/ListEditCmpController.fetchStaffContacts';

export default class CustomAdditionalEmailLookup extends LightningElement {
    @api context;
    @api field;
    @track selectedContacts = [];
    @track contacts = [];
    isModalOpen = false;
    addOtherChecked = false;
    otherEmails = '';
    emailMap = new Map();
    _value = '';
    shallDisableSaveButton = false;
    otherEmailsError = '';
    displayFields = ['role', 'org', 'email', 'primary'];

    @api
    get value() {
        return this._value;
    }
    set value(v) {
        this._value = (v || '').toString();
        if(this.contacts && this.contacts.length) {
            this.initializeFromExistingValue();
        }
    }

    get preselectedIds() {
        return this.selectedContacts.map(c => c.id ?? c.Id).filter(Boolean);
    }

    async connectedCallback() {
        await this.fetchStaffContacts();
        this.initializeFromExistingValue();
    }

    async fetchStaffContacts() {
        try {
            const rows = await fetchStaffContacts({ listMemberId: this.context });
            this.contacts = Array.isArray(rows) ? rows : [];
            this.buildEmailMap();
        } catch (e) {
            this.contacts = [];
            this.emailMap.clear();
        }
    }

    buildEmailMap() {
        this.emailMap.clear();
        for(const c of this.contacts) {
            const e = (c?.email || '').toString().trim().toLowerCase();
            if(e && !this.emailMap.has(e)) {
                this.emailMap.set(e, c);
            }
        }
    }

    splitCsvEmails(str) {
        if(!str) return [];
        return str.split(',').map(s => s.trim()).filter(Boolean);
    }

    initializeFromExistingValue() {
        const emails = this.splitCsvEmails(this._value);
        if(!emails.length) {
            this.selectedContacts = [];
            this.addOtherChecked = false;
            this.otherEmails = '';
            return;
        }
        const seen = new Set();
        const matched = [];
        const extras = [];
        for(const raw of emails) {
            const key = raw.toLowerCase();
            if(seen.has(key)) continue;
            seen.add(key);
            const contact = this.emailMap.get(key);
            if(contact) {
                matched.push(contact);
            } else {
                extras.push(raw);
            }
        }
        this.selectedContacts = matched;
        this.addOtherChecked = extras.length > 0;
        this.otherEmails = extras.join(', ');
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleLookupChange(event) {
        this.selectedContacts = event.detail.selected;
    }

    handleAdditionalEmailToggle(event) {
        this.addOtherChecked = event.target.checked;
        this.otherEmailsError = '';
        this.updateSaveDisabledAndError();
    }

    handleOtherEmailsChange(event) {
        this.otherEmails = event.target.value;
        this.updateSaveDisabledAndError();
    }

    handleSave() {
        const err = this.validateEmailsString(this.otherEmails);
        if(err) {
            this.otherEmailsError = err;
            this.shallDisableSaveButton = true;
            return;
        }
        const selected = Array.isArray(this.selectedContacts) ? this.selectedContacts : [];
        const selectedEmails = selected.map(s => (s && s.email ? String(s.email).trim() : ''));
        const extras = (this.addOtherChecked && this.otherEmails)
                       ? this.otherEmails.split(',').map(s => s.trim()).filter(Boolean)
                       : [];
        const csv = Array.from(
            new Set([
                ...selectedEmails,
                ...extras
            ].filter(Boolean))
        ).join(', ');
        this.dispatchEvent(new CustomEvent("emaillookupchanged", {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { 
                    context: this.context, 
                    value: csv, 
                    field: this.field 
                }
            }
        }));
        this.closeModal();
    }

    isValidEmail(email) {
        const re = /^[A-Za-z0-9._%+\-']+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/;
        return re.test(String(email || '').trim());
    }

    parseEmails(str) {
        if(!str) return [];
        return str.split(',').map(s => s.trim()).filter(Boolean);
    }

    validateEmailsString(str) {
        if(!this.addOtherChecked) return '';
        const emails = this.parseEmails(str);
        if(emails.length === 0) return 'Provide at least one email.';
        const invalidEmails = emails.filter(e => !this.isValidEmail(e));
        if(invalidEmails.length === 0) return '';
        const preview = invalidEmails.slice(0, 3).join(', ');
        return invalidEmails.length > 3 ? `Invalid email(s): ${preview}…` : `Invalid email(s): ${preview}`;
    }
       
    updateSaveDisabledAndError() {
        const err = this.validateEmailsString(this.otherEmails);
        this.otherEmailsError = err;
        this.shallDisableSaveButton = !!err;
    }
}