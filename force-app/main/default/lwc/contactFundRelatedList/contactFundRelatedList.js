import { LightningElement ,api, wire, track} from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import getAccountList from '@salesforce/apex/Fundraising_Summary.getFundraisingList';
import getFundRecpt from '@salesforce/apex/Fundraising_Summary.getFundraisingRecepient';
import getRecordDetails from '@salesforce/apex/Fundraising_Summary.getRecordDetails';

export default class LightningDatatableLWCExample extends NavigationMixin(LightningElement) {
    @api c__recordId;
    @api objectApiName;
    @track currenObjectName;
    @track recordDetails = {};
    @track sortBy;
    @track sortByFocs;
    @track sortDirection;
    @track sortByRecieve;
    @track sortDirectionapeal;
    @track sortDatarecieve;
    @track error;
    @track accList ;
    @track fundRecp ;
    sortedColumn;
    sortedDirection = 'asc';
    sortedColumnproj;
    sortedDirectionProj = 'asc';
    totalfund;
    totalfundrecpt;
    isFundraising = false;
    isfundRept = false;
    isRun = false;
    recordIdrecor;
    isLoaded = false;

    @track columns = [{
        label: 'Fundraising Project', fieldName: 'NameURL', type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    }, {
        label: 'Pledge Year - Year',
        fieldName: 'startDate',
        type: 'text',
        sortable: true
    }, {
        label: 'Total Pledge Amount (USD)',
        fieldName: 'Revenue',
        type: 'currency',
        sortable: true,
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
        cellAttributes: {
            class: { fieldName: 'givingAmountClass' }
        }
    }, {
        label: 'Anonymous Pledge Amount (USD)',
        fieldName: 'anonGivingDisplay',
        type: 'text',
        sortable: false,
        cellAttributes: {
            class: { fieldName: 'anonymousGivingAmountClass' }
        }
    }, {
        label: 'Focus Area',
        fieldName: 'Fundr',
        type: 'text',
        sortable: true
    }, {
        label: 'Initiative',
        fieldName: 'InitiaT',
        type: 'text',
        sortable: true
    }];

    get fundRecpData() {
        return this.fundRecp;
    }

    get accListData() {
        return this.accList;
    }

    get recordName() {
        return this.recordDetails?.name || '';
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.isFundraising = false;
        this.isfundRept = false;
        this.recordIdrecor = currentPageReference.state?.c__recordId;
        this.currenObjectName = currentPageReference.state?.c__objectType;
        try {
            this.isRun = true;
            this.init();
        } catch(err) {
            this.isLoaded = true;
            console.log('Error in fetching record details: ' + JSON.stringify(err));
        }
    }

    init() {
        this.isLoaded = false;
        try {
            this.getaccountlist(this.recordIdrecor);
            this.getFundReciepnt(this.recordIdrecor);
            this.getRecordDetails();
        } catch(err) {
            this.isLoaded = true;
        }
    }

    getRecordDetails () {
        getRecordDetails({
            recordId: this.recordIdrecor
        }).then(result => {
			this.recordDetails = result || {};
            this.isLoaded = true;
		}).catch(error => {
			this.error = error;
			this.recordDetails = undefined;
            this.isLoaded = true;
		})
    }

    getaccountlist(recordId) {
        getAccountList({
            recordId: recordId
        }).then((result) => {
            if(result) {
                let tempRecs = [];
                let totalAmt = 0;
                result.forEach( ( record ) => {
                    let tempRec = Object.assign( {}, record );
                    tempRec.NameURL = '/' + tempRec.FundId;
                    tempRec.Revenue = Math.trunc(Number(tempRec.Revenue) || 0);
                    tempRec.givingAmountClass = tempRec.givingDisplay ? 'slds-text-title_bold slds-theme_shade' : '';
                    tempRec.anonymousGivingAmountClass = tempRec.anonGivingDisplay ? 'slds-text-title_bold slds-theme_shade' : '';
                    totalAmt += tempRec.Revenue;
                    tempRecs.push(tempRec);
                });
                if(tempRecs.length > 0) this.isFundraising = true;
                this.totalfund = totalAmt;
                this.accList = tempRecs;
                this.error = undefined;
            }
        }).catch(() => {
            this.isLoaded = true;
        })
    }

    getFundReciepnt(recordId) {
        getFundRecpt({
            recordId: recordId
        }).then((result) => {
            if (result) {
                let tempRecs = [];
                let totalAmount = 0;
                result.forEach((record) => {
                    let tempRec = Object.assign({}, record);
                    tempRec.NameURL = '/' + tempRec.FundId;
                    tempRec.Revenue = Math.trunc(Number(tempRec.Revenue) || 0);
                    tempRec.givingAmountClass = tempRec.givingDisplay ? 'slds-text-title_bold slds-theme_shade' : '';
                    tempRec.anonymousGivingAmountClass = tempRec.anonGivingDisplay ? 'slds-text-title_bold slds-theme_shade' : '';
                    totalAmount += tempRec.Revenue;
                    tempRecs.push(tempRec);

                });
                if(tempRecs.length > 0) this.isfundRept = true;
                this.totalfundrecpt = totalAmount;
                this.fundRecp = tempRecs;
                this.error = undefined;
            }
        }).catch(() => {
            this.isLoaded = true;
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
        if(this.sortedColumnproj === colName) {
            this.sortedDirectionProj = this.sortedDirectionProj === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortedDirectionProj = 'asc';
        }
        const isReverse = this.sortedDirectionProj === 'asc' ? 1 : -1;
        this.sortedColumnproj = colName;
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
}