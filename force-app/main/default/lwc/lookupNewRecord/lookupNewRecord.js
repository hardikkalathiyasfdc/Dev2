import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getFieldSetFields from '@salesforce/apex/GenericLookupController.getFieldSetFields';

export default class LookupNewRecord extends LightningElement {
    @api objectApiName;
    @api newRecordSettings = {};

    @track step = 'form';
    @track recordTypeOptions = [];
    @track selectedRecordTypeId;
    @track fieldSetFieldNames = [];
    @track isLoading = true;
    @track isSaving = false;
    @track lookupFieldValues = {};

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo({ error, data }) {
        if (data) {
            const rtInfos = data.recordTypeInfos;
            const accessible = Object.values(rtInfos).filter(rt => rt.available && !rt.master);
            const defaultApiName = this.newRecordSettings && this.newRecordSettings.defaultRecordTypeApiName;
            if (defaultApiName) {
                const matched = accessible.find(rt => rt.developerName === defaultApiName);
                if (matched) {
                    this.selectedRecordTypeId = matched.recordTypeId;
                }
                this.step = 'form';
                this.loadFieldSetFields();
            } else if (accessible.length === 1) {
                this.selectedRecordTypeId = accessible[0].recordTypeId;
                this.step = 'form';
                this.loadFieldSetFields();
            } else if (accessible.length > 1) {
                this.recordTypeOptions = accessible.map(rt => ({
                    label: rt.name,
                    value: rt.recordTypeId
                }));
                this.step = 'recordType';
                this.isLoading = false;
            } else {
                this.step = 'form';
                this.loadFieldSetFields();
            }
        } else if (error) {
            this.step = 'form';
            this.loadFieldSetFields();
        }
    }

    get modalTitle() {
        return this.step === 'recordType' ? 'Select Record Type' : 'New Record';
    }

    get showRecordTypeStep() {
        return this.step === 'recordType';
    }

    get showFormLoading() {
        return this.step === 'form' && this.isLoading;
    }

    get showFormStep() {
        return this.step === 'form' && !this.isLoading;
    }

    get isNextDisabled() {
        return !this.selectedRecordTypeId;
    }

    get processedFields() {
        const overrides = (this.newRecordSettings && this.newRecordSettings.fieldOverrides) || {};
        return this.fieldSetFieldNames.map(fieldName => {
            const override = overrides[fieldName];
            if (override && override.componentType === 'genericLookup') {
                return {
                    fieldName,
                    isLookup: true,
                    isStandard: false,
                    objectApiName: override.objectApiName,
                    displayFields: override.displayFields || [],
                    searchFields: override.searchFields || [],
                    filterClause: override.filterClause || '',
                    icon: override.icon || 'standard:default',
                    allowNewRecord: override.allowNewRecord || false,
                    newRecordSettings: override.newRecordSettings || null,
                    label: override.label || fieldName
                };
            }
            return {
                fieldName,
                isLookup: false,
                isStandard: true
            };
        });
    }

    async loadFieldSetFields() {
        this.isLoading = true;
        try {
            const fieldSetName = this.newRecordSettings && this.newRecordSettings.fieldSetName;
            if (fieldSetName) {
                const fields = await getFieldSetFields({
                    objectApiName: this.objectApiName,
                    fieldSetName: fieldSetName
                });
                this.fieldSetFieldNames = fields || [];
            }
        } catch (error) {
            this.fieldSetFieldNames = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.detail.value;
    }

    handleNext() {
        if (this.selectedRecordTypeId) {
            this.step = 'form';
            this.loadFieldSetFields();
        }
    }

    handleLookupChange(event) {
        const fieldName = event.currentTarget.dataset.fieldName;
        const selectedIds = event.detail.selectedIds;
        const value = selectedIds && selectedIds.length > 0 ? selectedIds[0] : null;
        this.lookupFieldValues = { ...this.lookupFieldValues, [fieldName]: value };
    }

    handleFormSubmit(event) {
        event.preventDefault();
        this.isSaving = true;
        const fields = { ...event.detail.fields };
        Object.keys(this.lookupFieldValues).forEach(fieldName => {
            if (this.lookupFieldValues[fieldName]) {
                fields[fieldName] = this.lookupFieldValues[fieldName];
            }
        });
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleError() {
        this.isSaving = false;
    }

    handleSuccess(event) {
        this.isSaving = false;
        event.stopPropagation();
        const newRecordId = event.detail.id;
        this.dispatchEvent(new CustomEvent('success', { detail: { id: newRecordId } }));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}