import { api, LightningElement } from 'lwc';

export default class ExportListMembers extends LightningElement {
    @api exportFields;
    @api selectedFields;

    handleChange(e) {
        console.log(e.detail.value);
        this.selectedFields = e.detail.value;
    }

    closeExport() {
        this.sendExportEvent(false);
    }

    handleExport() {
        this.sendExportEvent(true);
    }

    sendExportEvent(isExport) {
        const selectedEvent = new CustomEvent("closeexport", {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                isExport: isExport, selected: this.selectedFields
            }
          });
          this.dispatchEvent(selectedEvent);
    }

    get isExportDisabled() {
        return !this.selectedFields || this.selectedFields.length == 0;
    }
}