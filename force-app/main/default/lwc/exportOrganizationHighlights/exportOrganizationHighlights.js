import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';
import getOrganizationHighlights from "@salesforce/apex/ExportOrganizationHighlightsController.getOrganizationHighlights";
import getAllOrganizationHighlights from "@salesforce/apex/ExportOrganizationHighlightsController.getAllOrganizationHighlights";
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';

export default class ExportOrganizationHighlights extends NavigationMixin(LightningElement) {
    @api recordId;
    @api exportFromList = false;
    @api organizationIds = '';
    @api navigateToList;
    @api fromQuickAction;
    selectedOption = 'All';
    headers = [];
    columns = [];
    interactions;
    title;
    fromDate;
    toDate;
    exportBtnClick = false;

    get fromDateSelected() {
        return this.fromDate;
    }

    get orgSize() {
        return this.fromQuickAction ? 6 : 4
    }

    get options() {
        return [
            { label: 'Organization Highlights Published to CityView', value: 'OnlyPublishedCityView' },
            { label: 'All Organization Highlights (including those not published to CityView)', value: 'All' }
        ];
    }

    get isRestricted() {
        return hasPrivateNameFieldsAccess;
    }

    get buttonDisable() {
        return this.exportBtnClick;
    }

    connectedCallback() {
        if (this.exportFromList) {
            if (this.organizationIds == undefined || this.organizationIds == null || this.organizationIds == '') {
                const event = new ShowToastEvent({
                    title: 'Select at least one record and try again.',
                    variant: 'error',
                    message: 'Select at least one record and try again.',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                window.history.back();
            }
        }
        this.fromDate = new Date(new Date().setFullYear(new Date().getFullYear() - 1)).toISOString()
        this.toDate = new Date().toISOString()
    }

    handleFromDate(event) {
        this.fromDate = event.detail.value;
    }

    handleToDate(event) {
        this.toDate = event.detail.value;
    }

    handleExportType(event) {
        this.selectedOption = event.detail.value;
    }

    handleExportSelected() {
        this.exportBtnClick = true;
        if (this.exportFromList == true) {
            this.getAllOrganizationHighlights();
        } else {
            this.getOrganizationHighlights();
        }
         this.exportBtnClick = false;
    }

    closeQuickAction() {
        const closeQA = new CustomEvent('closeqa', {});
        this.dispatchEvent(closeQA);
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    getOrganizationHighlights() {
        getOrganizationHighlights({
            "organizationId": this.recordId,
            "exportType": this.selectedOption,
            "fromDate": this.fromDate,
            "toDate": this.toDate
        }).then((result) => {
            let data = JSON.parse(JSON.stringify(result));
            if (data.restrictedOrgCount > 0 && !this.isRestricted) {
                    LightningAlert.open({
                        message: 'You\'ve encountered a problem with some of the records you selected (' + data.restrictedOrgCount + ' records are not exporting), please contact brmpartnerships@bloomberg.org for further assistance.',
                        theme: 'warning',
                        label: 'Warning!'
                    });
                }
            else if (data.restrictedOrgCount > 0) {
                LightningAlert.open({
                    message: 'The Organization Highlights you selected has ' + data.restrictedOrgCount + ' Private Organization(s).',
                    theme: 'warning',
                    label: 'Warning!'
                });
            }
            this.processAndExport(result);
        }).catch((error) => {
            console.log(error);
        });
    }

    getAllOrganizationHighlights() {
        getAllOrganizationHighlights({
            "exportType": this.selectedOption,
            "organizationIds": this.organizationIds,
            "fromDate": this.fromDate,
            "toDate": this.toDate
        }).then((result) => {
            let data = JSON.parse(JSON.stringify(result));
            if (data.restrictedOrgCount > 0 && !this.isRestricted) {
                    LightningAlert.open({
                        message: 'You\'ve encountered a problem with some of the records you selected (' + data.restrictedOrgCount + ' records are not exporting), please contact brmpartnerships@bloomberg.org for further assistance.',
                        theme: 'warning',
                        label: 'Warning!'
                    });
                }
            else if (data.restrictedOrgCount > 0) {
                LightningAlert.open({
                    message: 'The Organization Highlights you selected has ' + data.restrictedOrgCount + ' Private Organization(s).',
                    theme: 'warning',
                    label: 'Warning!'
                });
            }
            this.processAndExport(result);
        }).catch((error) => {
            console.log('Error on getAllOrganizationHighlights: ' + error);
        });
    }

    processAndExport(result) {
        if (result.error) {
            console.log('Error while retrieving data: ' + result.error);
            return;
        }
        this.interactions = result.interactions;
        this.title = result.name;
        this.headers = [];
        this.columns = [];
        const data = result.headers;
        for (let key in data) {
            this.headers.push(data[key]);
            this.columns.push(key);
        }
        this.exportToCSV();
    }

    exportToCSV() {
        var jsonRecordsData = this.interactions;
        let csvSeperator = ",";
        let csvEscapeCharacter = "\"";
        let newLineCharacter = "\n";
        let csv = csvEscapeCharacter;
        for (let i = 0; i < this.headers.length; i++) {
            csv += this.headers[i];
            if (i < this.headers.length - 1) {
                csv += csvEscapeCharacter + csvSeperator + csvEscapeCharacter;
            } else {
                csv += csvEscapeCharacter + newLineCharacter;
            }
        }
        if (csv == "") return;
        for (let i = 0; i < jsonRecordsData.length; i++) {
            for (let j = 0; j < this.columns.length; j++) {
                let col = this.columns[j];
                let dVal = jsonRecordsData[i][col];
                if (dVal == undefined) {
                    dVal = '';
                } else if (col === 'CreatedDate') {
                    dVal = this.convertDateFormat(dVal);
                }
                csv += csvEscapeCharacter + dVal;
                if (j < this.columns.length - 1) {
                    csv += csvEscapeCharacter + csvSeperator;
                } else {
                    csv += csvEscapeCharacter + newLineCharacter;
                }
            }
        }
        this.download(csv);
    }

    convertDateFormat(value) {
        const d = new Date(value);
        const mm = String(d.getUTCMonth() + 1);
        const dd = String(d.getUTCDate());
        const yyyy = d.getUTCFullYear();
        return `${mm}/${dd}/${yyyy}`;
    }

    download(data) {
        data = !data ? "" : data;
        let hiddenElement = document.createElement("a");
        hiddenElement.href =
            "data:text/csv;charset=utf-8,%EF%BB%BF" + encodeURIComponent(data);
        hiddenElement.download = this.title + ".csv";
        document.body.appendChild(hiddenElement);
        hiddenElement.click();
        hiddenElement.remove();
        this.closeQuickAction();
        if (!this.exportFromList) {
            window.history.back();
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}