import { LightningElement, api } from 'lwc';
import getUserAccessLevel from '@salesforce/apex/IMUtil.getUserAccessLevel';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/IM_Budget__c.Id";
import CHECKED_OUT_AT from '@salesforce/schema/IM_Budget__c.Checked_Out_At__c';
import CHECKED_OUT_BY from '@salesforce/schema/IM_Budget__c.Checked_Out_By__c';
const NOT_ALLOWED = 'You do not have the permission to perform this action.';
export default class ImClearCheckout extends LightningElement {
    @api recordId;

    @api invoke() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[CHECKED_OUT_AT.fieldApiName] = '';
        fields[CHECKED_OUT_BY.fieldApiName] = '';

        const recordInput = { fields };

        //IM-274: Check if the user access level is read, then throw an error
        const userAccess = getUserAccessLevel({ recordId: this.recordId });
        if (userAccess) {
            if (userAccess.MaxAccessLevel == 'Read') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Clearing Failed:",
                        message: NOT_ALLOWED,
                        variant: "error",
                    }),
                );
            } else {
                updateRecord(recordInput)
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Success",
                                message: "Checkout details cleared succesfully",
                                variant: "success",
                            }),
                        );
                    })
                    .catch((error) => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Error",
                                message: "Error clearing checkout details",
                                variant: "error",
                            }),
                        );
                    });
            }
        }
    }
}