import { LightningElement, api, track } from 'lwc';

export default class MultiSortModal extends LightningElement {
    @api isOpen = false;
    @api maxColumns = 5;
    @api columns = []; // expected format: [{ label: 'Event Name', field: 'event.Name', type: 'string' }, ...]
    @track rows = [
        { id: 1, field: '', direction: 'asc' }
    ];

    directionOptions = [
        { label: 'Ascending', value: 'asc' },
        { label: 'Descending', value: 'desc' }
    ];

    get columnOptions() {
        return this.columns.map(col => ({
            label: col.label,
            value: col.field
        }));
    }

    get disableAdd() {
        return this.rows.length >= this.maxColumns;
    }

    get disableApply() {
        return !this.rows.some(row => row.field);
    }

    get limitLabel() {
        return `${this.maxColumns} column limit`;
    }

    connectedCallback() {
        this.normalizeRows();
    }

    @api
    setCriteria(criteria) {
        if(criteria.length) {
            this.rows = criteria.map((item, index) => ({
                id: index + 1,
                field: item.field,
                direction: item.direction || 'asc'
            }));
        } else {
            this.rows = [{ id: 1, field: '', direction: 'asc' }];
        }
        this.normalizeRows();
    }

    normalizeRows() {
        this.rows = this.rows.map((row, index, arr) => ({
            ...row,
            disableUp: index === 0,
            disableDown: index === arr.length - 1,
            disableDelete: arr.length === 1
        }));
    }

    addRow() {
        this.rows = [
            ...this.rows,
            { id: Date.now(), field: '', direction: 'asc' }
        ];
        this.normalizeRows();
    }

    removeRow(event) {
        const index = Number(event.currentTarget.dataset.index);
        this.rows = this.rows.filter((_, i) => i !== index);
        if(!this.rows.length) {
            this.rows = [{ id: 1, field: '', direction: 'asc' }];
        }
        this.normalizeRows();
    }

    moveUp(event) {
        const index = Number(event.currentTarget.dataset.index);
        if(index === 0) return;
        const rows = [...this.rows];
        [rows[index - 1], rows[index]] = [rows[index], rows[index - 1]];
        this.rows = rows;
        this.normalizeRows();
    }

    moveDown(event) {
        const index = Number(event.currentTarget.dataset.index);
        if(index === this.rows.length - 1) return;
        const rows = [...this.rows];
        [rows[index], rows[index + 1]] = [rows[index + 1], rows[index]];
        this.rows = rows;
        this.normalizeRows();
    }

    handleColumnChange(event) {
        const index = Number(event.target.dataset.index);
        const rows = [...this.rows];
        rows[index].field = event.detail.value;
        this.rows = rows;
        this.normalizeRows();
    }

    handleDirectionChange(event) {
        const index = Number(event.target.dataset.index);
        const rows = [...this.rows];
        rows[index].direction = event.detail.value;
        this.rows = rows;
        this.normalizeRows();
    }

    handleClear() {
        this.rows = [{ id: 1, field: '', direction: 'asc' }];
        this.normalizeRows();
        this.dispatchEvent(new CustomEvent('clear'));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleApply() {
        const selected = this.rows
            .filter(row => row.field)
            .map(row => {
                const selectedColumn = this.columns.find(col => col.field === row.field);
                return {
                    field: row.field,
                    direction: row.direction,
                    label: selectedColumn?.label,
                    type: selectedColumn?.type || 'string'
                };
            });
        this.dispatchEvent(new CustomEvent('apply', { detail: selected }));
    }
}