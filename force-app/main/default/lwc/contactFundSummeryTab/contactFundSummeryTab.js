import { LightningElement ,api, wire, track} from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getAccountList from '@salesforce/apex/Fundraising_Summary.getFundraisingList';
import getFundRecpt from '@salesforce/apex/Fundraising_Summary.getFundraisingRecepient';
import getRecordDetails from '@salesforce/apex/Fundraising_Summary.getRecordDetails';

export default class contactFundSummaryTab extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @track currenObjectName;
    @track sortBy;
    @track sortByFocs;
    @track sortDirection;
    @track sortByRecieve;
    @track sortDatarecieve;
    @track error;
    @track accList;
    @track fundRecp;
    @track currentPageReference;
    @track recordDetails = {};
    hasDataLoaded = false;
    sortedColumn;
    sortedDirection = 'asc';
    sortedColumnProject;
    sortedDirectionProject = 'asc';
    isFundraising = false;
    isFundRept = false;

    @track columns = [{
        label: 'Fundraising Project',
        fieldName: 'NameURL',
        type: 'url',
        sortable: true,
        initialWidth: 160,
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    }, {
        label: 'Pledge Year - Year',
        fieldName: 'startDate',
        type: 'text',
        sortable: true,
        initialWidth: 160
    }, {
        label: 'Total Pledge Amount (USD)',
        fieldName: 'Revenue',
        type: 'currency',
        sortable: true,
        initialWidth: 210,
        typeAttributes: {
            currencyCode: 'USD',
            currencyDisplayAs: 'symbol',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        },
        cellAttributes: {
            alignment: 'left'
        }
    }, {
        label: 'Pledge Amount (USD)',
        fieldName: 'givingDisplay',
        type: 'text',
        sortable: false,
        initialWidth: 190,
        cellAttributes: {
            class: { fieldName: 'givingAmountClass' }
        }
    }, {
        label: 'Anonymous Pledge Amount (USD)',
        fieldName: 'anonGivingDisplay',
        type: 'text',
        sortable: false,
        initialWidth: 260,
        cellAttributes: {
            class: { fieldName: 'anonymousGivingAmountClass' }
        }
    }];

    get fundRecpData() {
        return this.fundRecp;
    }

    get accListData() {
        return this.accList;
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
    }

    connectedCallback() {
        this.getaccountlist(this.recordId);
        this.currenObjectName = this.objectApiName;
        if(this.currenObjectName == 'Account' || this.currenObjectName == 'Contact') {
            this.getFundRecipient( this.recordId);
        }
        this.getRecordDetails();
    }

    getRecordDetails () {
        getRecordDetails({
            recordId: this.recordId
        }).then(result => {
			this.recordDetails = result || {};
            this.hasDataLoaded = true;
		}).catch(error => {
			this.error = error;
            console.log('Error - ' + JSON.stringify(error));
			this.recordDetails = undefined;
            this.hasDataLoaded = true;
		})
    }

    getaccountlist(recordId) {
        getAccountList({
            recordId: recordId
        }).then((result) => {
            if(result) {
                let tempRecs = [];
                let totalAmount = 0;
                result.forEach((record) => {
                    if(tempRecs.length < 3) {
                        let tempRec = Object.assign({}, record);
                        tempRec.NameURL = '/' + tempRec.FundId;
                        tempRec.Revenue = Math.trunc(Number(tempRec.Revenue) || 0);
                        tempRec.givingAmountClass = tempRec.givingDisplay ? 'slds-text-title_bold slds-theme_shade' : '';
                        tempRec.anonymousGivingAmountClass = tempRec.anonGivingDisplay ? 'slds-text-title_bold slds-theme_shade' : '';
                        tempRecs.push(tempRec);
                    }
                });
                if(tempRecs.length > 0) this.isFundraising = true;
                this.accList = tempRecs;
                this.sortData('Name', 'asc');
                this.error = undefined;
            }
        }).catch(error => {
            console.log('get child records error >>>>>', error);
        })
    }

    getFundRecipient(recordId) {
        getFundRecpt({
            recordId: recordId
        }).then((result) => {
            if(result) {
                let tempRecs = [];
                result.forEach((record) => {
                    if(tempRecs.length < 3) {
                        let tempRec = Object.assign({}, record);
                        tempRec.NameURL = '/' + tempRec.FundId;
                        tempRec.Revenue = Math.trunc(Number(tempRec.Revenue) || 0);
                        tempRec.givingAmountClass = tempRec.givingDisplay ? 'slds-text-title_bold slds-theme_shade' : '';
                        tempRec.anonymousGivingAmountClass = tempRec.anonGivingDisplay ? 'slds-text-title_bold slds-theme_shade' : '';
                        tempRecs.push(tempRec);
                    }
                });
                if(tempRecs.length > 0) this.isFundRept = true;
                this.fundRecp = tempRecs;
                this.error = undefined;
            }
        }).catch(error => {
            console.log('get child records error >>>>>', error);
        })
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        let sortedBy;
        if(event.detail.fieldName === 'NameURL') {
            sortedBy = 'Name';
        } else {
            sortedBy = event.detail.fieldName;
        }
        this.sortDirection = event.detail.sortDirection;
        this.sortData(sortedBy, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.accList));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.accList = parseData;
        this.accList = [...this.accList];
    }

    sortProject(event) {
        const colName = event.detail.fieldName;
        if(this.sortedColumnProject === colName) {
            this.sortedDirectionProject =
                this.sortedDirectionProject === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortedDirectionProject = 'asc';
        }
        const isReverse = this.sortedDirectionProject === 'asc' ? 1 : -1;
        this.sortedColumnProject = colName;
        this.fundRecp = [...this.fundRecp].sort((a, b) => {
            let valueA;
            let valueB;
            if(colName === 'NameURL') {
                valueA = (a.Name || '').toLowerCase();
                valueB = (b.Name || '').toLowerCase();
            } else if(colName === 'Revenue') {
                valueA = Number(a.Revenue) || 0;
                valueB = Number(b.Revenue) || 0;
            } else {
                valueA = (a[colName] || '').toString().toLowerCase();
                valueB = (b[colName] || '').toString().toLowerCase();
            }
            return isReverse * ((valueA > valueB) - (valueB > valueA));
        });
    }

    viewAllData() {
         this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'fundSummaryApp',
            },
            state: {
                c__recordId: this.recordId,
                c__objectType: this.objectApiName
            }
        });
    }
}