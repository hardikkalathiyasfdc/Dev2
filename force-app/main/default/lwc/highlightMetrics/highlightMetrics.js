import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasMetricsReviewerPermission from '@salesforce/customPermission/Highlights_Metrics_Reviewer';
import STATUS_FIELD from '@salesforce/schema/Highlight_Interaction__c.Status__c';
import getMetricRows from '@salesforce/apex/HighlightMetricsController.getMetricRows';
import saveMetricValues from '@salesforce/apex/HighlightMetricsController.saveMetricValues';

const KEY_FIELD = 'metricId';
const DRAFT_STATUS = 'Draft';

const COLUMNS = [
    {
        label: 'Metric',
        fieldName: 'metricName',
        type: 'text',
        wrapText: true,
        hideDefaultActions: true
    },
    {
        label: 'Most Recent Submission',
        fieldName: 'previousValue',
        type: 'text',
        initialWidth: 220,
        wrapText: true,
        hideDefaultActions: true
    },
    {
        label: 'Value',
        fieldName: 'value',
        type: 'number',
        editable: true,
        initialWidth: 140,
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: true
    },
    {
        label: 'Date',
        fieldName: 'valueDate',
        type: 'date-local',
        editable: true,
        initialWidth: 140,
        typeAttributes: { month: '2-digit', day: '2-digit', year: 'numeric' },
        hideDefaultActions: true
    },
    {
        label: 'Notes',
        fieldName: 'notes',
        type: 'text',
        editable: true,
        wrapText: true,
        hideDefaultActions: true
    }
];

export default class HighlightMetrics extends LightningElement {
    @api recordId;

    @track draftValues = [];
    @track tableErrors = { rows: {} };
    rows = [];
    teamName;
    hasTeam = false;
    isLoading = false;
    isEditing = false;
    loadError;

    wiredRows;
    workingDrafts = [];

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD] })
    highlightRecord;

    @wire(getMetricRows, { highlightId: '$recordId' })
    handleWiredRows(result) {
        this.wiredRows = result;
        const { data, error } = result;

        if (data) {
            this.rows = data.rows || [];
            this.teamName = data.teamName;
            this.hasTeam = !!data.teamId;
            this.loadError = undefined;
        } else if (error) {
            this.rows = [];
            this.loadError = this.reduceError(error);
        }
    }

    get highlightStatus() {
        return this.highlightRecord && this.highlightRecord.data
            ? getFieldValue(this.highlightRecord.data, STATUS_FIELD)
            : undefined;
    }

    get canEditMetrics() {
        if (!this.highlightStatus) {
            return false;
        }
        return this.highlightStatus === DRAFT_STATUS || hasMetricsReviewerPermission === true;
    }

    get columns() {
        return COLUMNS.map((column) =>
            column.editable ? { ...column, editable: this.isEditing } : column
        );
    }

    get rowsById() {
        return this.rows.reduce((acc, row) => {
            acc[row.metricId] = row;
            return acc;
        }, {});
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get submittedCount() {
        return this.rows.filter((row) => row.submitted).length;
    }

    get cardTitle() {
        return this.hasTeam ? `Metrics — ${this.teamName}` : 'Metrics';
    }

    get progressLabel() {
        return `${this.submittedCount} of ${this.rows.length} entered`;
    }

    handleEdit() {
        this.isEditing = true;
        this.workingDrafts = [];
        this.draftValues = [];
        this.tableErrors = { rows: {} };
    }

    handleCancelEdit() {
        this.isEditing = false;
        this.workingDrafts = [];
        this.draftValues = [];
        this.tableErrors = { rows: {} };
    }

    handleCellChange(event) {
        const changed = event.detail.draftValues || [];
        if (!changed.length) {
            return;
        }

        const byKey = new Map();
        this.workingDrafts.forEach((draft) => {
            byKey.set(draft[KEY_FIELD], { ...draft });
        });
        changed.forEach((draft) => {
            const key = draft[KEY_FIELD];
            const existing = byKey.get(key) || { [KEY_FIELD]: key };
            byKey.set(key, { ...existing, ...draft });
        });

        const lookup = this.rowsById;
        let autoFilled = false;

        byKey.forEach((draft, key) => {
            const row = lookup[key] || {};
            const value = this.toNumber(
                draft.value !== undefined ? draft.value : row.value
            );
            const valueDate = this.toDateString(
                draft.valueDate !== undefined ? draft.valueDate : row.valueDate
            );

            if (value !== null && !valueDate) {
                draft.valueDate = this.todayAsIsoDate();
                autoFilled = true;
            }
        });

        this.workingDrafts = Array.from(byKey.values());

        if (autoFilled) {
            this.draftValues = [...this.workingDrafts];
        }
    }

    async handleSaveClick() {
        const drafts = this.workingDrafts;
        if (!drafts.length) {
            this.isEditing = false;
            return;
        }

        const lookup = this.rowsById;
        const resolved = [];
        const rowErrors = {};
        let errorCount = 0;

        drafts.forEach((draft) => {
            const rowKey = draft[KEY_FIELD];
            const row = lookup[rowKey];
            if (!row) {
                return;
            }

            const value = this.toNumber(
                draft.value !== undefined ? draft.value : row.value
            );
            const valueDate = this.toDateString(
                draft.valueDate !== undefined ? draft.valueDate : row.valueDate
            );
            const notes = this.toText(
                draft.notes !== undefined ? draft.notes : row.notes
            );

            if (value !== null && valueDate) {
                resolved.push({ row, action: 'save', value, valueDate, notes });
                return;
            }

            if (value === null && row.metricValueId) {
                resolved.push({ row, action: 'remove' });
                return;
            }

            if (value === null && !valueDate && !notes) {
                resolved.push({ row, action: 'skip' });
                return;
            }

            const missing = [];
            if (value === null) {
                missing.push('value');
            }
            if (!valueDate) {
                missing.push('valueDate');
            }

            rowErrors[rowKey] = this.rowError(row, missing, this.missingMessage(missing));
            errorCount += 1;
        });

        if (errorCount) {
            this.tableErrors = {
                rows: rowErrors,
                table: {
                    title: 'Nothing was saved',
                    messages: [this.errorMessage(errorCount)]
                }
            };
            this.toast('Nothing was saved', this.errorMessage(errorCount), 'error');
            return;
        }

        const values = [];
        const removedIds = [];

        resolved.forEach((item) => {
            if (item.action === 'save') {
                const record = {
                    sobjectType: 'Metric_Value__c',
                    Metric__c: item.row.metricId,
                    Highlight_Interaction__c: this.recordId,
                    Value__c: item.value,
                    Date__c: item.valueDate,
                    Notes__c: item.notes
                };
                if (item.row.metricValueId) {
                    record.Id = item.row.metricValueId;
                }
                values.push(record);
            } else if (item.action === 'remove') {
                removedIds.push(item.row.metricValueId);
            }
        });

        if (!values.length && !removedIds.length) {
            this.exitEditMode();
            return;
        }

        this.isLoading = true;
        try {
            await saveMetricValues({ values, removedIds });
            this.exitEditMode();
            await refreshApex(this.wiredRows);
            this.toast('Success', this.savedMessage(values.length, removedIds.length), 'success');
        } catch (error) {
            this.toast('Values not saved', this.reduceError(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    exitEditMode() {
        this.isEditing = false;
        this.workingDrafts = [];
        this.draftValues = [];
        this.tableErrors = { rows: {} };
    }

    todayAsIsoDate() {
        const now = new Date();
        const month = `${now.getMonth() + 1}`.padStart(2, '0');
        const day = `${now.getDate()}`.padStart(2, '0');
        return `${now.getFullYear()}-${month}-${day}`;
    }

    savedMessage(saved, removed) {
        const parts = [];
        if (saved) {
            parts.push(`${saved} ${saved === 1 ? 'value' : 'values'} saved`);
        }
        if (removed) {
            parts.push(`${removed} removed`);
        }
        return `${parts.join(', ')}.`;
    }

    rowError(row, fieldNames, message) {
        return {
            title: row.metricName,
            messages: [message],
            fieldNames
        };
    }

    missingMessage(missing) {
        if (missing.length === 2) {
            return 'Enter a value and a date for this metric.';
        }
        return missing[0] === 'valueDate'
            ? 'Enter a date for this value.'
            : 'Enter a value for this date.';
    }

    errorMessage(count) {
        return count === 1
            ? 'One row needs both a value and a date. Fix it and save again.'
            : `${count} rows need both a value and a date. Fix them and save again.`;
    }

    toNumber(raw) {
        if (raw === null || raw === undefined || raw === '') {
            return null;
        }
        const parsed = parseFloat(raw);
        return Number.isNaN(parsed) ? null : parsed;
    }

    toDateString(raw) {
        if (!raw) {
            return null;
        }
        return String(raw).substring(0, 10);
    }

    toText(raw) {
        return raw === undefined || raw === null || raw === '' ? null : String(raw);
    }

    reduceError(error) {
        if (error && error.body) {
            if (Array.isArray(error.body)) {
                return error.body.map((e) => e.message).join(', ');
            }
            if (error.body.message) {
                return error.body.message;
            }
        }
        return 'Something went wrong. Try again, or contact your administrator.';
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}