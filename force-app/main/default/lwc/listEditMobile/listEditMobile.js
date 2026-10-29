import { LightningElement, api, wire, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getCampaignMembers from '@salesforce/apex/ListEditCmpController.getCampaignMembers';
import getUserListView from '@salesforce/apex/ListEditCmpController.getUserListView'
import CUSTOM_OBJECT from '@salesforce/schema/Custom_List_View__c';

export default class ListEditMobile extends NavigationMixin(LightningElement) {
    @api recordId;
    @track members = [];
    @track rsvpCounts = {};
    @track attendanceCounts = {};
    @track activeRsvpFilters = {};
    @track activeAttendanceFilters = {};
    title;
    showRsvpSection = false;
    showAttendenceSection = false;
    searchKey = '';
    debounceTimeout;
    showModal = false;
    tempSelectedFields = [];
    selectedFields = [];
    selectedViewId;

    mobileOptions = [
        { label: 'RSVP', value: 'RSVPStatus__c' },
        { label: 'First Name', value: 'UB_FirstName__c' },
        { label: 'Last Name', value: 'UB_LastName__c' },
        { label: 'Attendance', value: 'AttendedStatus__c' },
        { label: 'RSVP/Event Notes', value: 'RSVPNotes__c' },
        { label: 'Party Size', value: 'PartySize__c' },
        { label: 'Dietary', value: 'Dietary__c' },
        { label: 'Source', value: 'Source__c' },
        { label: 'Guest Of', value: 'GuestOf__c' },
        { label: 'Organization / Company', value: 'UB_Company__c' },
        { label: 'Business Phone', value: 'Business_Phone__c' },
        { label: 'Mobile Phone', value: 'Mobile_Phone__c' },
    ];

    statusColorMap = {
        'YES': 'blue',
        'YES - VIRTUALLY': 'blue',
        'YES - COCKTAILS ONLY': 'blue',
        'YES - IN PERSON': 'blue',
        'NO': 'red',
        'PEND': 'amber',
        'WAITLIST 1': 'amber',
        'WAITLIST 2': 'amber',
        'DID NOT ATTEND': 'red',
        'DID NOT ATTEND - CANCELLED RSVP': 'red'
    };

    rsvpOrder = [
        'YES', 'YES - VIRTUALLY', 'YES - COCKTAILS ONLY', 'YES - IN PERSON',
        'NO', 'PEND', 'WAITLIST 1', 'WAITLIST 2'
    ];

    attendanceOrder = [
        'YES - COCKTAILS ONLY',
        'YES - IN PERSON',
        'YES - VIRTUALLY',
        'DID NOT ATTEND',
        'DID NOT ATTEND - CANCELLED RSVP'
    ];

    get iconRsvpSection() {
        return this.showRsvpSection ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get iconAttendenceSection() {
        return this.showAttendenceSection ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get eventSummary() {
        return this.rsvpOrder.map(status => {
            const count = this.rsvpCounts[status] || 0;
            const color = count > 0 ? (this.statusColorMap[status] || '') : '';
            const isSelected = !!this.activeRsvpFilters[status];
            return {
                label: status,
                count,
                filterKey: status,
                isSelected,
                ...this.buildCardClasses(color, isSelected)
            };
        });
    }

    get attendenceSummary() {
        return this.attendanceOrder.map(status => {
            const count = this.attendanceCounts[status] || 0;
            const color = count > 0 ? (this.statusColorMap[status] || '') : '';
            const isSelected = !!this.activeAttendanceFilters[status];
            return {
                label: status,
                count,
                filterKey: status,
                isSelected,
                ...this.buildCardClasses(color, isSelected)
            };
        });
    }

    get rsvpProgressStyle() {
        let blue = 0;
        let red = 0;
        let amber = 0;
        this.rsvpOrder.forEach(status => {
            const count = Number(this.rsvpCounts[status] || 0);
            const color = this.statusColorMap[status];
            if(color === 'blue') blue += count;
            if(color === 'red') red += count;
            if(color === 'amber') amber += count;
        });
        return this.buildProgressStyle(blue, red, amber);
    }

    get attendanceProgressStyle() {
        let blue = 0;
        let red = 0;
        this.attendanceOrder.forEach(status => {
            const count = Number(this.attendanceCounts[status] || 0);
            const color = this.statusColorMap[status];
            if(color === 'blue') blue += count;
            if(color === 'red') red += count;
        });
        return this.buildProgressStyle(blue, red, 0);
    }

    get guestLabel() {
        return `Guests: ${this.members.length}`;
    }

    get filteredData() {
        let data = [...this.members];
        const hasRsvpFilter = Object.keys(this.activeRsvpFilters).length > 0;
        const hasAttFilter = Object.keys(this.activeAttendanceFilters).length > 0;
        if(hasRsvpFilter || hasAttFilter) {
            data = data.filter(row => {
                const rsvpVal = row.RSVPStatus__c ? row.RSVPStatus__c.trim().toUpperCase() : null;
                const attVal = row.AttendedStatus__c ? row.AttendedStatus__c.trim().toUpperCase() : null;
                const rsvpOk = hasRsvpFilter
                               ? Object.keys(this.activeRsvpFilters).some(k => k.trim().toUpperCase() === rsvpVal)
                               : false;
                const attOk = hasAttFilter
                              ? Object.keys(this.activeAttendanceFilters).some(k => k.trim().toUpperCase() === attVal)
                              : false;
                return rsvpOk || attOk;
            });
        }
        if(this.searchKey) {
            data = data.filter(row =>
                this.selectedFields.some(field => {
                    const val = row[field];
                    return val && String(val).toLowerCase().includes(this.searchKey);
                })
            );
        }
        return data.map(row => ({
            ...row,
            recordLink: '/' + row.Id,
            firstNameLabel: row.UB_FirstName__c || 'View',
            lastNameLabel: row.UB_LastName__c || 'View'
        }));
    }

    get columns() {
        const clickableFieldMap = {
            'UB_FirstName__c': 'firstNameLabel',
            'UB_LastName__c': 'lastNameLabel'
        };
        return this.selectedFields.map(field => {
            const option = this.mobileOptions.find(o => o.value === field);
            const isClickable = clickableFieldMap[field];
            return {
                label: option ? option.label : field,
                fieldName: isClickable ? 'recordLink' : field,
                type: isClickable ? 'url' : 'text',
                typeAttributes: isClickable
                    ? {
                        label: { fieldName: clickableFieldMap[field] },
                        target: '_blank'
                    }
                    : undefined,
                wrapText: true,
                initialWidth: 150
            };
        });
    }

    get selectedItems() {
        return this.tempSelectedFields.map(val =>
            this.mobileOptions.find(opt => opt.value === val)
        ).filter(Boolean);
    }

    get availableOptions() {
        return this.mobileOptions.filter(opt =>
            !this.tempSelectedFields.includes(opt.value)
        );
    }

    get hasActiveFilters() {
        return Object.keys(this.activeRsvpFilters).length > 0
            || Object.keys(this.activeAttendanceFilters).length > 0;
    }

    get activeFilterList() {
        const rsvpPills = Object.keys(this.activeRsvpFilters).map(key => ({
            key: 'rsvp__' + key,
            filterKey: key,
            section: 'rsvp',
            label: 'RSVP: ' + key,
            pillClass: this._pillClass(key)
        }));
        const attPills = Object.keys(this.activeAttendanceFilters).map(key => ({
            key: 'att__' + key,
            filterKey: key,
            section: 'attendance',
            label: 'Attendance: ' + key,
            pillClass: this._pillClass(key)
        }));
        return [...rsvpPills, ...attPills];
    }

    get iconRsvpChevron() {
        return this.showRsvpSection
            ? 'status-card__chevron status-card__chevron_open'
            : 'status-card__chevron';
    }

    get iconAttChevron() {
        return this.showAttendenceSection
            ? 'status-card__chevron status-card__chevron_open'
            : 'status-card__chevron';
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(pageRef) {
        this.currentPageReference = pageRef;
        if(pageRef) {
            this.activeRsvpFilters = {};
            this.activeAttendanceFilters = {};
            this.searchKey = '';
            this.showModal = false;
        }
    }

    @wire(getCampaignMembers, {
        campaignId: '$recordId'
    }) wiredData({ data, error }) {
        if(data) {
            this.members = data.members;
            this.rsvpCounts = data.rsvpCounts || {};
            this.attendanceCounts = data.attendanceCounts || {};
            let eventStatus = data.members[0].Campaign.EventStatus__c;
            this.title = data.members[0].Campaign.Name;
            this.showRsvpSection = eventStatus === 'Upcoming' || eventStatus === 'Cancelled';
            this.showAttendenceSection = eventStatus === 'Cancelled' || eventStatus === 'Complete';
        } else if(error) {
            console.error(error);
        }
    }

    @wire(getUserListView, {
        view: 'Mobile'
    }) listView({ error, data }) {
        if(data) {
            if(data && data.length > 0) {
                this.selectedViewId = data[0].Id;
                this.selectedFields = data[0].Column__c.split(',');
            } else {
                this.selectedFields = ['RSVPStatus__c', 'UB_FirstName__c', 'UB_LastName__c'];
            }
        } else {
            console.log(error);
        }
    }

    toggleRsvpSection() {
        this.showRsvpSection = !this.showRsvpSection;
    }

    toggleAttendenceSection() {
        this.showAttendenceSection = !this.showAttendenceSection;
    }

    buildCardClasses(color, isSelected) {
        const sel = isSelected ? ' selected' : '';
        return {
            cardClass: `stat-card${color ? ' ' + color : ''}${sel}`,
            cardLabel: `card-label${color ? ' ' + color : ''}`,
            cardValue: `card-value${color ? ' ' + color : ''}`
        };
    }

    handleFilterBoxClick(event) {
        const filter = event.currentTarget.dataset.filter;
        const section = event.currentTarget.dataset.section;
        if(!filter || !section) return;
        if(section === 'rsvp') {
            const updated = { ...this.activeRsvpFilters };
            if(updated[filter]) {
                delete updated[filter];
            } else {
                updated[filter] = true;
            }
            this.activeRsvpFilters = updated;
        } else {
            const updated = { ...this.activeAttendanceFilters };
            if(updated[filter]) {
                delete updated[filter];
            } else {
                updated[filter] = true;
            }
            this.activeAttendanceFilters = updated;
        }
    }

    removeFilter(event) {
        const filter = event.currentTarget.dataset.filter;
        const section = event.currentTarget.dataset.section;
        if(section === 'rsvp') {
            const updated = { ...this.activeRsvpFilters };
            delete updated[filter];
            this.activeRsvpFilters = updated;
        } else {
            const updated = { ...this.activeAttendanceFilters };
            delete updated[filter];
            this.activeAttendanceFilters = updated;
        }
    }

    clearAllFilters() {
        this.activeRsvpFilters = {};
        this.activeAttendanceFilters = {};
    }

    buildProgressStyle(blue, red, grey) {
        const b = Number(blue || 0);
        const r = Number(red || 0);
        const g = Number(grey || 0);
        const total = b + r + g;
        if(total === 0) {
            return 'background:#e0e0e0;';
        }
        if(b > 0 && r === 0 && g === 0) {
            return 'background:#1b96ff;';
        }
        if(r > 0 && b === 0 && g === 0) {
            return 'background:#e62323;';
        }
        if(g > 0 && b === 0 && r === 0) {
            return 'background:#e0e0e0;';
        }
        const bPct = Math.round((b / total) * 100);
        const rPct = Math.round((r / total) * 100);
        let gradient = [];
        let start = 0;
        if(b > 0) {
            gradient.push(`#1b96ff ${start}% ${start + bPct}%`);
            start += bPct;
        }
        if(r > 0) {
            gradient.push(`#e62323 ${start}% ${start + rPct}%`);
            start += rPct;
        }
        if(g > 0) {
            gradient.push(`#e0e0e0 ${start}% 100%`);
        }
        return `background: linear-gradient(to right, ${gradient.join(', ')});`;
    }

    handleSearch(event) {
        const value = event.target.value;
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.searchKey = value ? value.toLowerCase() : '';
        }, 300);
    }

    openModal() {
        this.tempSelectedFields = [...this.selectedFields];
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }

    handleDualListChange(event) {
        this.tempSelectedFields = event.detail.value;
    }

    handleSave() {
        this.selectedFields = [...this.tempSelectedFields];
        if(this.selectedViewId) {
            this.handleUpdate(this.selectedViewId);
        } else {
            this.handleCreate();
        }
    }

    handleCreate() {
        let fields = {};
        fields['Name'] = 'Test Record';
        fields['Column__c'] = this.selectedFields.join(',');
        fields['View__c'] = 'Mobile';
        const recordInput = {
            apiName: CUSTOM_OBJECT.objectApiName,
            fields
        };
        createRecord(recordInput)
            .then(() => {
                this.closeModal();
            }).catch(error => {
                console.error('Error:', error);
            });
    }

    resetListView() {
        this.selectedFields = ['RSVPStatus__c', 'UB_FirstName__c', 'UB_LastName__c']
        this.handleUpdate(this.selectedViewId);
    }

    handleUpdate(recordId) {
        let fields = {};
        fields['Id'] = recordId;
        fields['Column__c'] = this.selectedFields.join(',');
        fields['View__c'] = 'Mobile';
        updateRecord({
            fields
        }).then(() => {
            this.closeModal();
        }).catch(error => {
            console.error(error);
        });
    }

    handleTitleClick() {
        this.navigateToRecord(this.recordId);
    }

    navigateToRecord(rowId) {
        if(!rowId || !rowId.length) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: rowId,
                actionName: 'view'
            }
        });
    }

    handleChange(event) {
        const selected = [...event.target.options]
            .filter(option => option.selected)
            .map(option => option.value);
        this.tempSelectedFields = selected;
    }

    addItem(event) {
        const value = event.currentTarget.dataset.value;
        if(!this.tempSelectedFields.includes(value)) {
            this.tempSelectedFields = [...this.tempSelectedFields, value];
        }
    }

    removeItem(event) {
        const value = event.currentTarget.dataset.value;
        this.tempSelectedFields = this.tempSelectedFields.filter(v => v !== value);
    }

    moveUp(event) {
        const index = Number(event.currentTarget.dataset.index);
        if(index === 0) return;
        let arr = [...this.tempSelectedFields];
        [arr[index - 1], arr[index]] = [arr[index], arr[index - 1]];
        this.tempSelectedFields = arr;
    }

    moveDown(event) {
        const index = Number(event.currentTarget.dataset.index);
        let arr = [...this.tempSelectedFields];
        if(index === arr.length - 1) return;
        [arr[index + 1], arr[index]] = [arr[index], arr[index + 1]];
        this.tempSelectedFields = arr;
    }

    _pillClass(key) {
        const color = this.statusColorMap[key] || 'neu';
        return `filter-pill pill-${color}`;
    }
}