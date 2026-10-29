import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFilterOptions from '@salesforce/apex/PhotoBookBuilderController.getFilterOptions';
import createRequest from '@salesforce/apex/PhotoBookBuilderController.createRequest';
import countMatches from '@salesforce/apex/PhotoBookController.countMatches';

const MAX_KEYWORDS = 4;
const YEAR_RANGE = 30;

export default class PhotoBookBuilder extends NavigationMixin(LightningElement) {
    @track cardFieldOptions = [];
    @track selectedCardFields = [];
    @track defaultCardFields = [];
    isLoading = true;
    orgDisplayFields = ['Search_Display_Name__c', 'AKA__c', 'Legal_Name__c'];
    orgSearchFields = ['Search_Display_Name__c'];
    orgDisplayFieldPrefixes = ['', '', ''];
    orgRecordIds = [];
    employmentOrgRecordIds = [];
    orgRequired = false;
    isOrgMultiSelect = true;
    isEmploymentOrgMultiSelect = false;
    allDepartments = true;
    departmentOptions = [];
    selectedDepartments = [];
    yearOptions = [];
    fromYear = '';
    isGenerating = false;
    isCounting = false;
    matchCount;
    countTimeout;
    keywordFieldOptions = [];
    keywordRows = [{ id: 'kw-0', field: '', value: '' }];
    keywordRowSeq = 1;
    errorMessage;
    selectedLayout = 'department';
    layoutOptions = [
        { label: 'Group by Department', value: 'department' },
        { label: 'Sort Alphabetically', value: 'hr' },
        { label: 'Intern PhotoBook', value: 'intern' }
    ];

    get matchCountLabel() {
        if(this.matchCount === undefined) return '';
        if(this.matchCount === 0) return 'No matching Contacts';
        return this.matchCount === 1
               ? '1 matching Contact'
               : this.matchCount + ' matching Contacts';
    }

    get showDepartmentSelector() {
        return !this.allDepartments;
    }

    get isNotInternBook() {
        return this.selectedLayout !== 'intern';
    }

    get isGenerateDisabled() {
        if(this.errorMessage || this.isGenerating || this.isCounting || this.matchCount === 0) return true;
        return false;
    }

    @wire(getFilterOptions)
    wiredOptions({ data, error }) {
        this.isLoading = false;
        if(data) {
            this.departmentOptions = data.departments;
            this.cardFieldOptions = data.cardFields;
            this.defaultCardFields = data.defaultCardFields;
            this.selectedCardFields = [...this.defaultCardFields];
            this.keywordFieldOptions = data.keywordFields;
            this.errorMessage = undefined;
        } else if(error) {
            this.errorMessage = this.readError(error);
        }
    }

    connectedCallback() {
        this.yearOptions = this.buildYearOptions();
        this.runCount();
    }

    disconnectedCallback() {
        window.clearTimeout(this.countTimeout);
    }

    scheduleCount() {
        window.clearTimeout(this.countTimeout);
        this.countTimeout = window.setTimeout(() => {
            this.runCount();
        }, 500);
    }

    async runCount() {
        if(!this.isNotInternBook) {
            this.matchCount = undefined;
            this.isCounting = false;
            return;
        }
        this.isCounting = true;
        try {
            const result = await countMatches({
                criteriaJson: JSON.stringify(this.buildCriteria())
            });
            this.matchCount = result;
        } catch(error) {
            this.matchCount = undefined;
            this.errorMessage = this.readError(error);
        } finally {
            this.isCounting = false;
        }
    }

    buildYearOptions() {
        const options = [{ label: 'Any Year', value: '' }];
        const currentYear = new Date().getFullYear();
        for(let year = currentYear; year >= currentYear - YEAR_RANGE; year--) {
            options.push({ label: String(year), value: String(year) });
        }
        return options;
    }

    lookupOrgRecord(event) {
        event.preventDefault();
        this.orgRecordIds = event.detail.selectedIds ? event.detail.selectedIds : [];
        this.scheduleCount();
    }

    lookupEmploymentOrgRecord(event) {
        event.preventDefault();
        this.employmentOrgRecordIds = event.detail.selectedIds ? event.detail.selectedIds : [];
        this.scheduleCount();
    }

    handleLayoutChange(event) {
        this.selectedLayout = event.detail.value;
        if(this.isNotInternBook) {
            this.scheduleCount();
        } else {
            window.clearTimeout(this.countTimeout);
            this.matchCount = undefined;
            this.isCounting = false;
        }
    }

    handleAllDepartmentsChange(event) {
        this.allDepartments = event.target.checked;
        if(this.allDepartments) {
            this.selectedDepartments = [];
            this.errorMessage = undefined;
        }
        this.scheduleCount();
    }

    handleDepartmentChange(event) {
        this.selectedDepartments = event.detail.value;
        this.scheduleCount();
    }

    handleFromYearChange(event) {
        this.fromYear = event.detail.value;
        this.scheduleCount();
    }

    handleCardFieldChange(event) {
        let selectedFields = event.detail.value;
        if(selectedFields.length > MAX_KEYWORDS) {
            this.errorMessage = `You can only select a maximum of ${MAX_KEYWORDS} fields to show.`;
            return;
        }
        this.selectedCardFields = selectedFields;
        this.errorMessage = undefined;
    }

    handleAddKeyword() {
        this.keywordRows = [
            ...this.keywordRows,
            { id: 'kw-' + this.keywordRowSeq++, field: '', value: '' }
        ];
    }

    handleRemoveKeyword(event) {
        const id = event.currentTarget.dataset.id;
        this.keywordRows = this.keywordRows.filter((row) => row.id !== id);
        this.scheduleCount();
    }

    handleKeywordFieldChange(event) {
        this.updateKeywordRow(event.currentTarget.dataset.id, { field: event.detail.value });
    }

    handleKeywordValueChange(event) {
        this.updateKeywordRow(event.currentTarget.dataset.id, { value: event.detail.value });
    }

    updateKeywordRow(id, changes) {
        this.keywordRows = this.keywordRows.map((row) =>
            row.id === id ? { ...row, ...changes } : row
        );
        this.scheduleCount();
    }

    completedKeywords() {
        return this.keywordRows
            .filter((row) => row.field && row.value && row.value.trim())
            .map((row) => ({ field: row.field, value: row.value.trim() }));
    }

    handleReset() {

        this.template.querySelectorAll('c-generic-lookup')
        .forEach((lookup) => lookup.clearSelection());

        this.selectedLayout = 'department';
        this.orgRecordIds = [];
        this.allDepartments = true;
        this.selectedDepartments = [];
        this.fromYear = '';
        this.selectedCardFields = [...this.defaultCardFields];
        this.keywordRows = [{ id: 'kw-0', field: '', value: '' }];
        this.keywordRowSeq = 1;
        this.matchCount = undefined;
        this.errorMessage = undefined;
        this.scheduleCount();
    }

    buildCriteria() {
        return {
            groupByDepartment: this.selectedLayout === 'department',
            orgIds: this.orgRecordIds,
            departments: this.allDepartments ? [] : this.selectedDepartments,
            startedFromYear: this.fromYear ? parseInt(this.fromYear, 10) : null,
            cardFields: this.selectedCardFields,
            keywords: this.completedKeywords(),
            employmentOrg: this.employmentOrgRecordIds.length > 0 ? this.employmentOrgRecordIds[0] : ''
        };
    }

    async handleGenerate() {
        if(!this.allDepartments && this.selectedDepartments.length === 0) {
            this.errorMessage = 'Select at least one department, or tick All Departments.';
            return;
        }
        this.isGenerating = true;
        this.errorMessage = undefined;
        try {
            if(this.isNotInternBook) {
                const requestId = await createRequest({
                    criteriaJson: JSON.stringify(this.buildCriteria())
                });
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/apex/PhotoBookBuilderPDF?requestId=' + requestId
                    }
                });
            } else {
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/apex/PhotoBookIntern'
                    }
                });
            }
        } catch(error) {
            this.errorMessage = this.readError(error);
        } finally {
            this.isGenerating = false;
        }
    }

    readError(error) {
        if(error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'Something went wrong. Please try again.';
    }
}