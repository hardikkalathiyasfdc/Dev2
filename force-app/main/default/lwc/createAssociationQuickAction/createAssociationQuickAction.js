import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ASSOCIATION_OBJECT from '@salesforce/schema/Association__c';

export default class CreateAssociationQuickAction extends LightningElement {

    @api recordId;

    recordTypeId;

    @wire(getObjectInfo, { objectApiName: ASSOCIATION_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            const recordTypes = Object.values(data.recordTypeInfos);

            const selectedRecordType = recordTypes.find(
                rt => rt.developerName === 'Initiative'
            );

            if (selectedRecordType) {
                this.recordTypeId = selectedRecordType.recordTypeId;
            }
        }

        if (error) {
            console.error(error);
        }
    }

    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'CityView Initiative created successfully.',
                variant: 'success'
            })
        );

        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(event) {
        console.error(event.detail);
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}