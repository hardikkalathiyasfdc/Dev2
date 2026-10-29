import { LightningElement, api, track } from 'lwc';

export default class CityViewListTable extends LightningElement {
    @api tableLabel = 'Cities';
    @api isInitiativeSearch;
    @api shallShowGrants;

    @track _data = [];
    @track sortedData = [];

    sortBy = 'bpCount';
    sortDirection = 'DESC';
    shallShowSpinner = false;
    showTooltip = false;
    showActiveOnly = false;
    userSorted = false;

    _isInitiativeSearch;

    get showGrantYearRange() {
        return this.shallShowGrants && this._isInitiativeSearch;
    }

    connectedCallback() {
        this._isInitiativeSearch = this.isInitiativeSearch;
    }

    @api
    get data() {
        return this.sortedData;
    }

    set data(value) {
        if (value) {
            if(this.userSorted){
             this.userSorted  = false;
            }
            this._data = [...value];
            this.setDefaultSort();
        }
    }

    get rowCount() {
        return this.sortedData.length || 0;
    }

    get shouldShowTable() {
        return this.shallShowSpinner ||
            (this.sortedData && this.sortedData.length > 0);
    }

    get rowsToRender() {
        const rows = this.data || [];

        if (this.isInitiativeSearch && this.showActiveOnly) {
            const flagPresent = rows.some(r =>
                Object.prototype.hasOwnProperty.call(
                    r,
                    'hasActiveInitiative'
                )
            );

            if (!flagPresent) {
                return rows;
            }

            return rows.filter(
                r => r.hasActiveInitiative === true
            );
        }

        return rows;
    }

    get activeRowCount() {
        return this.data.filter(
            r => r.hasActiveInitiative === true
        ).length;
    }

    get sortDirectionIcon() {
        return this.sortDirection === 'ASC'
            ? 'utility:arrowup'
            : 'utility:arrowdown';
    }

    get isSortedByName() {
        return this.sortBy === 'name';
    }

    get isSortedByBpCount() {
        return this.sortBy === 'bpCount';
    }

    get isSortedByHighlightCount() {
        return this.sortBy === 'highlightCount';
    }

    get isSortedByOfficeCount() {
        return this.sortBy === 'officeCount';
    }

    get isSortedByCulturalAccess() {
        return this.sortBy === 'hasCulturalAccess';
    }

    get isSortedByActiveInitiative() {
        return this.sortBy === 'hasActiveInitiative';
    }

    get isSortedByInitiativeYear() {
        return this.sortBy === 'initiativeYear';
    }

    get isSortedByGrantYear() {
        return this.sortBy === 'grantYear';
    }

    get activePillClass() {
        return this.showActiveOnly
            ? 'slds-badge slds-theme_success slds-badge_inverse'
            : 'slds-badge';
    }

    setDefaultSort() {
        if (this.userSorted) {
            return;
        }

        const defaultSortBy = 'hasActiveInitiative';

        if (this.sortBy !== defaultSortBy) {
            this.sortBy = defaultSortBy;
        }

        this.applySort();
    }

    toggleActiveOnly() {
        this.showActiveOnly = !this.showActiveOnly;
    }

    stopHeaderSort(event) {
        event.stopPropagation();
    }

    handleTableSort(event) {
        const field = event.currentTarget.dataset.field;
        this.userSorted = true;

        if (this.sortBy === field) {
            this.sortDirection =
                this.sortDirection === 'ASC'
                    ? 'DESC'
                    : 'ASC';
        } else {
            this.sortBy = field;
        }

        if (field === 'initiativeYear') {
            this.sortedData = [
                ...this.sortByYearRange(
                    this.sortedData,
                    'initiativeMinYear',
                    'initiativeMaxYear'
                )
            ];
        } else if (field === 'grantYear') {
            this.sortedData = [
                ...this.sortByYearRange(
                    this.sortedData,
                    'grantMinYear',
                    'grantMaxYear'
                )
            ];
        } else {
            this.shallShowSpinner = true;

            setTimeout(() => {
                this.applySort();
                this.shallShowSpinner = false;
            }, 100);
        }
    }

    applySort() {
        const sortBy = this.sortBy;
        const sortDirection = this.sortDirection;

        this.sortedData = [...this._data].sort((a, b) => {
            if (sortBy === 'hasActiveInitiative') {
                const aActive = !!a.hasActiveInitiative;
                const bActive = !!b.hasActiveInitiative;

                if (aActive !== bActive) {
                    const base = aActive ? -1 : 1;
                    return sortDirection === 'DESC'
                        ? base
                        : -base;
                }

                const nameA =
                    (a.name ?? '')
                        .toString()
                        .toLowerCase();
                const nameB =
                    (b.name ?? '')
                        .toString()
                        .toLowerCase();

                if (nameA < nameB) return -1;
                if (nameA > nameB) return 1;
                return 0;
            }

            let valA = a[sortBy] ?? '';
            let valB = b[sortBy] ?? '';

            if (typeof valA === 'string') {
                valA = valA.toLowerCase();
            }
            if (typeof valB === 'string') {
                valB = valB.toLowerCase();
            }
            if (typeof valA === 'boolean') {
                valA = valA ? 1 : 0;
            }
            if (typeof valB === 'boolean') {
                valB = valB ? 1 : 0;
            }

            if (!isNaN(valA) && !isNaN(valB)) {
                valA = Number(valA);
                valB = Number(valB);
            }

            if (valA < valB) {
                return sortDirection === 'ASC' ? -1 : 1;
            }
            if (valA > valB) {
                return sortDirection === 'ASC' ? 1 : -1;
            }

            return 0;
        });
    }

    sortByYearRange(records, startField, endField) {
        const multiplier =
            this.sortDirection === 'DESC' ? -1 : 1;

        return [...records].sort((a, b) => {
            const startA = a[startField] ?? 0;
            const startB = b[startField] ?? 0;

            if (startA !== startB) {
                return (startA - startB) * multiplier;
            }

            const endA = a[endField] ?? 9999;
            const endB = b[endField] ?? 9999;

            return (endA - endB) * multiplier;
        });
    }

    handleNameClick(event) {
        const id = event.currentTarget.dataset.id;

        this.dispatchEvent(
            new CustomEvent('geoareaselected', {
                detail: id
            })
        );
    }

    handleSegmentHover(event) {
        const focusArea = event.target.dataset.focus;
        const count = event.target.dataset.count;

        event.target.classList.add('segment-hover');

        const rect = event.target.getBoundingClientRect();

        this.tooltipText = `${focusArea}: ${count}`;
        this.tooltipStyle = `
            top: ${rect.top - 182}px;
            left: ${rect.left + 3}px;
        `;
        this.showTooltip = true;
    }

    handleSegmentLeave(event) {
        event.target.classList.remove('segment-hover');
        this.showTooltip = false;
    }
}