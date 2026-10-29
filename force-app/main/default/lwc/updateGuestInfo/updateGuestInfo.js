import { LightningElement, api, wire } from 'lwc';
import LightningModal from "lightning/modal";
import getUpdateFieldList from '@salesforce/apex/ListEditCmpController.getUpdateFieldList';

// Constants
const GUEST_OF = 'GuestOf__c';

export default class UpdateGuestInfo extends LightningModal {

    @api object;
    @api recType;
    columnlabel;
    value;
    selectedColumn;
    columnOptions = [];
    columnLabelMap = new Map();

    @wire(getUpdateFieldList, { recordType: "$recType" })
    updateFieldsList({ error, data }) {
        if(data && data.length > 0) {
            for(const column of data){
                const options = {
                    value: column.fieldApi,
                    label: column.label
                }
                this.columnOptions = [...this.columnOptions, options];
                this.columnLabelMap.set(column.fieldApi, column.label);
            }
        } else {
            console.error(error);
        }
    }

    handleColumnChange(event) {
        this.selectedColumn = event.detail.value;
        this.value = '';
        this.columnLabel = this.columnLabelMap.get(event.detail.value);
    }

    handleChange(event) {
        if(this.selectedColumn === GUEST_OF) {
            this.value = event.detail.value[0];
        }else {
            this.value = event.detail.value;
        }
    }

    handleClose() {
        this.close('close');
    }

    handleSave() {
        this.close(this.updatedGuestInfo());
    }

    updatedGuestInfo() {
        const updatedGuestInfo = {
            columnLabel: this.columnLabel,
            fieldName: this.selectedColumn,
            value: this.value
        }
        return updatedGuestInfo;
    }
}