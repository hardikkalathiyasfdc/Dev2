import { LightningElement, api, track } from 'lwc';

export default class EventsManagementMobileView extends LightningElement {
    @api fieldOptions;
    @api eventStatusOptions;
    @api shallShowProgramManagedToggle;
    @api eventTypeOptions;
    @api timezoneOptions;
    @api programmaticFilterOptions;
    @api disableToggle;
    @api isProgramManagedChecked;
    @api isGalaChecked;
    @api shallShowGalaToggle;
    @api disableGalaToggle;
    @api shallShowEventError = false;
    eventStatus = 'Upcoming';
    selectedPicklistValue;
    selectedKeyValue;
    isEventCompleted = false;
    isTextField = true;
    isNumberField = false;
    isPicklist = false;
    picklistPlaceholder = '';
    isLookup = false;
    isCheckbox = false;
    isStartDate = false;
    shallShowSpinner = false;
    selectedSearchByFieldName = 'Name';
    selectedFilter = 'Contains';
    _events = [];
    _searchTimer;

    @api
    get displayEvents() {
        return this._events;
    }
    set displayEvents(val) {
        const arr = Array.isArray(val) ? val : [];
        this._events = arr.map(item => {
            const e = item.event || {};
            return {
                ...item,
                event: e,
                dateRange: this.buildDateRange(item),
                coordinatorName: e?.EventCoordinator__r?.Name || '',
                tags: this.buildTags(item),
                yesBadgeClass: `slds-var-m-top_x-small slds-var-p-around_xx-small slds-var-m-right_xx-small stat-badge ${Number(e?.TotalYes__c) > 0 ? 'yes-badge' : ''}`.trim(),
                noBadgeClass: `slds-var-m-top_x-small slds-var-p-around_xx-small stat-badge ${Number(e?.TotalNo__c) > 0 ? 'no-badge' : ''}`.trim(),
                coordinatorPhotoUrl: this.extractPhotoUrl(item.coordinatorBioPhotoRichText),

            };
        });
        this.shallShowSpinner = false;
    }

    get sectionLabel() {
        return (this.eventStatus === '' ? 'All' : this.eventStatus) + ' Events';
    }

    get shallShowNoDataFound() {
        return (!this.displayEvents || this.displayEvents.length === 0) && !this.shallShowEventError;
    }

    handleSearchByFieldChange(event) {
		let fieldName = event.target.value;
		this.selectedSearchByFieldName = fieldName;
		this.isTextField = false;
		this.isNumberField = false;
		this.isPicklist = false;
		this.isLookup = false;
		this.isCheckbox = false;
		this.isStartDate = false;
        this.selectedKeyValue = null;
        this.selectedPicklistValue = '';
        this.selectedFilter = 'Equals';
		if(fieldName == 'Name') {
			this.isTextField = true;
			this.selectedFilter = 'Contains';
		} else if(fieldName == 'EventType__c') {
			this.isPicklist = true;
            this.picklistPlaceholder = 'Select Event Type...';
			this.dataOptions = this.eventTypeOptions;
		} else if(fieldName == 'Event_Start_Date_Time__c') {
			this.isStartDate = true;
            this.selectedFilter = '=';
		} else if(fieldName == 'TimeZone__c') {
			this.isPicklist = true;
            this.picklistPlaceholder = 'Select Timezone...';
			this.dataOptions = this.timezoneOptions;
		} else if(fieldName == 'TotalGuests__c') {
			this.isNumberField = true;
            this.selectedFilter = '=';
		} else if(fieldName == 'EventCoordinator__c') {
			this.isLookup = true;
		} else if(fieldName == 'Programmatic__c') {
			this.isCheckbox = true;
			this.dataOptions = this.programmaticFilterOptions;
		}
	}

    fireSearchNow() {
        let selectedSearchByFieldName = this.selectedSearchByFieldName;
        if(!this.selectedKeyValue) selectedSearchByFieldName = '';
        this.shallShowSpinner = true;
        this.dispatchEvent(
            new CustomEvent('search', {
                detail: {
                    selectedFieldName: selectedSearchByFieldName,
                    selectedFilter: this.selectedFilter || '',
                    selectedKeyValue: this.selectedKeyValue,
                    eventStatus: this.eventStatus || '',
                    isProgramManagedChecked: this.isProgramManagedChecked,
                    isGalaChecked: this.isGalaChecked
                },
                bubbles: true,
                composed: true
            })
        );
        this.shallShowSpinner = false;
    }

    fireSearchDebounced() {
        window.clearTimeout(this._searchTimer);
        this._searchTimer = window.setTimeout(() => {
            this.fireSearchNow();
        }, 300);
    }

    handleClear() {
        this.isTextField = false;
		this.isNumberField = false;
		this.isPicklist = false;
		this.isLookup = false;
		this.isCheckbox = false;
		this.isStartDate = false;
        this.selectedKeyValue = '';
        this.selectedPicklistValue = '';
        this.selectedSearchByFieldName = 'Name';
        this.isTextField = true;
        this.selectedFilter = 'Contains';
        this.eventStatus = 'Upcoming';
        if(!this.disableToggle) this.isProgramManagedChecked = false;
        if(!this.disableGalaToggle) this.isGalaChecked = false;
        this.fireSearchNow();
    }

    handleEventStatusChange(event) {
		this.eventStatus = event.target.value;
        this.isEventCompleted = this.eventStatus.includes('Complete');
        this.fireSearchNow();
	}

    handleInputFieldChange(event) {
        let value = event.detail.value;
        this.selectedKeyValue = value;
        if(this.isPicklist) this.selectedPicklistValue = this.selectedKeyValue;
        if(this.isTextField) {
            this.fireSearchDebounced();
        } else {
            this.fireSearchNow();
        }
    }

	handleUserSelected(event) {
		this.selectedKeyValue = event.detail.recordId;
        this.fireSearchNow();
	}

    handleProgramToggleChange(event) {
        this.isProgramManagedChecked = event.target.checked;
		this.fireSearchNow();
    }

    handleGalaToggleChange(event) {
        this.isGalaChecked = event.target.checked;
        this.fireSearchNow();
    }

    extractPhotoUrl(richText) {
        if(!richText) return '';
        const match = String(richText).match(/<img[^>]+src=["']([^"']+)["']/i);
        return match ? match[1].replace(/&amp;/g, '&') : '';
    }

    buildDateRange(item) {
        const e = item.event || {};
        const tz = item.timeZone || e.TimeZone__c || 'UTC';
        const startIso = e.Start_Date_Time__c;
        const endIso = e.End_Date_Time__c;
        if(!startIso) return '';
        const start = new Date(startIso);
        if(isNaN(start.getTime())) return '';
        const end = endIso ? new Date(endIso) : null;
        const hasValidEnd = end && !isNaN(end.getTime());
        const dateFmt = new Intl.DateTimeFormat('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            timeZone: tz
        });
        const tzNameFmt = new Intl.DateTimeFormat('en-US', {
            timeZone: tz,
            timeZoneName: 'short'
        });
        const parts = tzNameFmt.formatToParts(start);
        const tzLabel = parts.find(p => p.type === 'timeZoneName')?.value || '';
        const startParts = this.getTimeParts(start, tz);
        const startDateStr = dateFmt.format(start);
        if(!hasValidEnd) {
            return `${startDateStr}, ${startParts.time} ${startParts.dayPeriod}${tzLabel ? ` (${tzLabel})` : ''}`;
        }
        const endParts = this.getTimeParts(end, tz);
        const endDateStr = dateFmt.format(end);
        const sameDay = this.isSameDayInTZ(start, end, tz);
        // If both AM or both PM, omit dayPeriod on start and keep on end only.
        const sameMeridiem = startParts.dayPeriod && endParts.dayPeriod && startParts.dayPeriod === endParts.dayPeriod;
        const startTimeStr = sameMeridiem
            ? `${startParts.time}`              
            : `${startParts.time} ${startParts.dayPeriod}`;
        const endTimeStr = `${endParts.time} ${endParts.dayPeriod}`;
        if(sameDay) {
            return `${startDateStr}, ${startTimeStr} - ${endTimeStr}${tzLabel ? ` (${tzLabel})` : ''}`;
        }
        return `${startDateStr}, ${startParts.time} ${startParts.dayPeriod} - ${endDateStr}, ${endTimeStr}${tzLabel ? ` (${tzLabel})` : ''}`;
    }

    getTimeParts(dateObj, tz) {
        const parts = new Intl.DateTimeFormat('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZone: tz
        }).formatToParts(dateObj);
        const hour = parts.find(p => p.type === 'hour')?.value;
        const minute = parts.find(p => p.type === 'minute')?.value;
        const dayPeriod = parts.find(p => p.type === 'dayPeriod')?.value;
        return {
            time: `${hour}:${minute}`,
            dayPeriod
        };
    }

    isSameDayInTZ(a, b, tz) {
        const fmt = new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            timeZone: tz
        });
        return fmt.format(a) === fmt.format(b);
    }

    buildTags(item) {
        const e = item.event || {};
        const tags = [];
        if(e.HowMRBAttended__c?.includes('Yes')) {
            tags.push(this.makeTag('MRB', 'mrb'));
        }
        if(e.HowPHAttending__c?.includes('Yes')) {
            tags.push(this.makeTag('PH', 'ph'));
        }
        return tags;
    }

    makeTag(label, variant) {
        return {
            key: `${label}-${variant}`,
            label,
            className: `slds-var-p-around_xx-small slds-var-m-right_xx-small tag-badge tag-${variant}`
        };
    }

    handleSelectEvent(event) {
        const eventId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('selected', { detail: eventId }));
    }
}